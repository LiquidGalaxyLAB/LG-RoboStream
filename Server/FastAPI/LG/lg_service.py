import asyncio
import base64
import json
import time
from typing import Optional, List, Dict, Any
import paramiko
from io import BytesIO
import os

from . import lg_data
from .slave_calculator import SlaveCalculator
from .kml_builder import KMLBuilder

class LoginResult:
    def __init__(self, success: bool, message: str):
        self.success = success
        self.message = message

class LGConnectionManager:
    def __init__(self, host: str, username: str, password: str, total_screens: int):
        self.host = host
        self.username = username
        self.password = password
        self.total_screens = total_screens
        self.client: Optional[paramiko.SSHClient] = None
        self.sftp: Optional[paramiko.SFTPClient] = None
        self.is_connected = False
        
        self.slave_calculator = SlaveCalculator(total_screens)
        self.kml_builder = KMLBuilder(host)
        
    async def connect(self) -> bool:
        try:
            self.client = paramiko.SSHClient()
            self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            self.client.connect(
                hostname=self.host,
                username=self.username,
                password=self.password,
                timeout=10
            )
            
            stdin, stdout, stderr = self.client.exec_command('echo "Connection successful"')
            stdout.read()
            
            self.sftp = self.client.open_sftp()
            
            self.is_connected = True
            return True
            
        except Exception as e:
            print(f"LG Connection error: {e}")
            await self.disconnect()
            return False
    
    async def disconnect(self):
        if self.sftp:
            self.sftp.close()
            self.sftp = None
        if self.client:
            self.client.close()
            self.client = None
        self.is_connected = False
    
    async def send_kml_to_slave(self, kml_content: str, slave_number: int) -> bool:
        if not self.is_connected or not self.client:
            return False
            
        try:
            command = f"echo '{kml_content}' > /var/www/html/kml/slave_{slave_number}.kml"
            stdin, stdout, stderr = self.client.exec_command(command)
            stdout.read()
            return True
        except Exception as e:
            print(f"Error sending KML to slave {slave_number}: {e}")
            return False
    
    async def send_kml_to_leftmost_screen(self, kml_content: str) -> bool:
        return await self.send_kml_to_slave(kml_content, self.slave_calculator.leftmost_screen)
    
    async def send_kml_to_rightmost_screen(self, kml_content: str) -> bool:
        return await self.send_kml_to_slave(kml_content, self.slave_calculator.rightmost_screen)
    
    async def send_image(self, image_bytes: bytes, filename: str) -> bool:
        if not self.is_connected or not self.sftp:
            return False
            
        try:
            base_name = filename.split('_')[0]
            await self.cleanup_old_images(f'{base_name}_*.png')
            
            remote_path = f'/var/www/html/{filename}'
            with BytesIO(image_bytes) as image_io:
                self.sftp.putfo(image_io, remote_path)
            
            return True
        except Exception as e:
            print(f"Error sending image {filename}: {e}")
            return False
    
    async def send_file_from_path(self, local_path: str, remote_path: str) -> bool:
        if not self.is_connected or not self.sftp:
            return False
            
        try:
            if os.path.exists(local_path):
                self.sftp.put(local_path, remote_path)
                return True
            return False
        except Exception as e:
            print(f"Error sending file {local_path}: {e}")
            return False
    
    async def cleanup_old_images(self, pattern: str) -> bool:
        if not self.is_connected or not self.client:
            return False
            
        try:
            command = f'find /var/www/html/ -name "{pattern}" -type f -mmin +5 -delete'
            stdin, stdout, stderr = self.client.exec_command(command)
            stdout.read()
            return True
        except Exception as e:
            print(f"Error cleaning up images: {e}")
            return False
    
    async def clear_slave(self, slave_number: int) -> bool:
        empty_kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>'''
        return await self.send_kml_to_slave(empty_kml, slave_number)
    
    async def clear_rightmost_screen(self) -> bool:

        try:
            if not self.is_connected:
                return False

            if lg_data.LG_TOTAL_SCREENS is None:
                print("Error: LG_TOTAL_SCREENS not configured")
                return False

            rightmost_screen = self.slave_calculator.rightmost_screen

            result = await self.clear_slave(rightmost_screen)
            if not result:
                print(f"Failed to clear rightmost screen {rightmost_screen}")
                        
            return result
        except Exception as e:
            print(f"Error clearing rightmost screen: {e}")
            return False
    
    async def relaunch_lg(self) -> bool:

        try:
            if not self.is_connected:
                return False

            if lg_data.LG_TOTAL_SCREENS is None:
                print("Error: LG_TOTAL_SCREENS not configured")
                return False
                
            password = lg_data.LG_PASSWORD
            username = lg_data.LG_USERNAME
            total_screens = lg_data.LG_TOTAL_SCREENS
            
            if not password or not username:
                print("Error: LG credentials not configured")
                return False
            
            print(f"Starting LG relaunch for {total_screens} screens")

            for i in range(total_screens, 0, -1):
                try:
                    print(f"Relaunching screen lg{i}")

                    lg_relaunch_cmd = f'"/home/{username}/bin/lg-relaunch" > /home/{username}/log.txt'
                    stdin, stdout, stderr = self.client.exec_command(lg_relaunch_cmd)
                    await asyncio.sleep(1) 

                    relaunch_command = f'''RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\$(service \\$SERVICE status) =~ 'stop' ]]; then
  echo {password} | sudo -S service \\${{SERVICE}} start
else
  echo {password} | sudo -S service \\${{SERVICE}} restart
fi
" && sshpass -p {password} ssh -x -t {username}@lg{i} "$RELAUNCH_CMD"'''
                    
                    stdin, stdout, stderr = self.client.exec_command(relaunch_command)

                    await asyncio.sleep(2)
                    
                    print(f"Relaunch command sent to lg{i}")
                    
                except Exception as screen_error:
                    print(f"Error relaunching screen lg{i}: {screen_error}")
                    continue
            
            print("LG relaunch commands completed for all screens")
            return True
                
        except Exception as e:
            print(f"Error executing lg-relaunch command: {e}")
            return False

class LGService:
    def __init__(self):
        self.connection_manager: Optional[LGConnectionManager] = None
        
    def _get_connection_manager(self) -> Optional[LGConnectionManager]:
        if not all([lg_data.LG_HOST, lg_data.LG_USERNAME, lg_data.LG_PASSWORD, lg_data.LG_TOTAL_SCREENS]):
            return None
            
        if (not self.connection_manager or 
            self.connection_manager.host != lg_data.LG_HOST or
            self.connection_manager.username != lg_data.LG_USERNAME or
            self.connection_manager.password != lg_data.LG_PASSWORD or
            self.connection_manager.total_screens != lg_data.LG_TOTAL_SCREENS):
            
            self.connection_manager = LGConnectionManager(
                lg_data.LG_HOST, lg_data.LG_USERNAME, lg_data.LG_PASSWORD, lg_data.LG_TOTAL_SCREENS
            )
        
        return self.connection_manager
    
    async def login(self, host: str, username: str, password: str, total_screens: int) -> LoginResult:
        if not host or not username or not password or total_screens <= 0:
            return LoginResult(False, 'Please fill in all fields correctly.')
        
        try:
            test_manager = LGConnectionManager(host, username, password, total_screens)
            connected = await test_manager.connect()
            
            if connected:
                await self._show_logo_with_manager(test_manager)
                await test_manager.disconnect()
                
                lg_data.LG_HOST = host
                lg_data.LG_USERNAME = username
                lg_data.LG_PASSWORD = password
                lg_data.LG_TOTAL_SCREENS = total_screens
                
                print(f"Debug: Configuration saved - Host: {lg_data.LG_HOST}, Username: {lg_data.LG_USERNAME}, Screens: {lg_data.LG_TOTAL_SCREENS}")
                
                return LoginResult(True, 'Connected successfully. Configuration saved automatically.')
            else:
                return LoginResult(False, 'Could not connect to Liquid Galaxy. Verify the connection details.')
                
        except Exception as e:
            return LoginResult(False, f'Connection error: {str(e)}')
    
    async def _show_logo_with_manager(self, manager: LGConnectionManager) -> bool:
        try:
            logo_kml = manager.kml_builder.build_logo_kml()

            logo_path = "LOGO_IMAGES/robostream_complete_logo.png"
            if os.path.exists(logo_path):
                await manager.send_file_from_path(logo_path, '/var/www/html/robostream_complete_logo.png')

            return await manager.send_kml_to_leftmost_screen(logo_kml)
        except Exception as e:
            print(f"Error showing logo: {e}")
            return False
    
    async def show_logo(self) -> bool:
        print("Debug: show_logo() called")
        manager = self._get_connection_manager()
        if not manager:
            print("Debug: No connection manager available")
            return False
            
        try:
            print(f"Debug: Manager is_connected: {manager.is_connected}")
            if not manager.is_connected:
                print("Debug: Attempting to connect to LG...")
                connected = await manager.connect()
                print(f"Debug: Connection result: {connected}")
                if not connected:
                    print("Debug: Failed to connect to LG")
                    return False
            
            print("Debug: Calling _show_logo_with_manager...")
            result = await self._show_logo_with_manager(manager)
            print(f"Debug: _show_logo_with_manager result: {result}")
            return result
        except Exception as e:
            print(f"Error showing logo: {e}")
            return False
    
    async def show_rgb_camera(self, server_host: str) -> bool:
        print(f"Debug: show_rgb_camera() called with server_host: {server_host}")
        manager = self._get_connection_manager()
        if not manager:
            print("Debug: No connection manager available")
            return False
            
        try:
            print(f"Debug: Manager is_connected: {manager.is_connected}")
            if not manager.is_connected:
                print("Debug: Attempting to connect to LG...")
                connected = await manager.connect()
                print(f"Debug: Connection result: {connected}")
                if not connected:
                    print("Debug: Failed to connect to LG")
                    return False
            
            print("Debug: Building camera KML...")
            camera_kml = manager.kml_builder.build_camera_kml(server_host)
            print("Debug: Sending KML to rightmost screen...")
            result = await manager.send_kml_to_rightmost_screen(camera_kml)
            print(f"Debug: send_kml_to_rightmost_screen result: {result}")
            return result
        except Exception as e:
            print(f"Error showing RGB camera: {e}")
            return False
    
    async def show_sensor_data(self, sensor_data: Dict[str, Any], selected_sensors: List[str]) -> bool:
        print(f"Debug: show_sensor_data() called with sensors: {selected_sensors}")
        manager = self._get_connection_manager()
        if not manager or not selected_sensors:
            print("Debug: No connection manager or no sensors selected")
            return False
            
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False

            camera_overlay = ""
            non_camera_sensors = [s for s in selected_sensors if s != 'RGB Camera']
            
            if 'RGB Camera' in selected_sensors:
                camera_overlay = self._build_camera_overlay(manager.host, 0)

            balloon_kml = ""
            if non_camera_sensors:
                if len(non_camera_sensors) == 1:
                    balloon_kml = manager.kml_builder.build_sensor_balloon_kml(sensor_data, non_camera_sensors[0])
                else:
                    balloon_kml = manager.kml_builder.build_multi_sensor_balloon_kml(sensor_data, non_camera_sensors)
                    
            if camera_overlay and balloon_kml:
                kml_sent = await manager.send_kml_to_rightmost_screen(balloon_kml)
            elif balloon_kml:
                kml_sent = await manager.send_kml_to_rightmost_screen(balloon_kml)
            elif camera_overlay:
                combined_kml = self._build_combined_kml([camera_overlay])
                kml_sent = await manager.send_kml_to_rightmost_screen(combined_kml)
            else:
                return False

            if 'GPS Position' in selected_sensors and sensor_data.get('gps'):
                await self._fly_to_gps_location(sensor_data['gps'], manager)
            
            return kml_sent
        except Exception as e:
            print(f"Error showing sensor data: {e}")
            return False
    
    async def _fly_to_gps_location(self, gps_data: Dict[str, Any], manager) -> bool:
        try:
            latitude = gps_data.get('latitude', 0.0)
            longitude = gps_data.get('longitude', 0.0)
            altitude = gps_data.get('altitude', 100.0)
            
            print(f"Debug: GPS data received - Lat: {latitude}, Lon: {longitude}, Alt: {altitude}")

            look_at_kml = f'''<LookAt><longitude>{longitude}</longitude><latitude>{latitude}</latitude><altitude>{altitude + 100}</altitude><heading>0</heading><tilt>45</tilt><range>1000</range><altitudeMode>relativeToGround</altitudeMode></LookAt>'''

            escaped_look_at = look_at_kml.replace('"', '\\"')

            command = f'echo "flytoview={escaped_look_at}" > /tmp/query.txt'
            
            if manager.client:
                stdin, stdout, stderr = manager.client.exec_command(command)
                stdout.read()
                print(f"Debug: FlyTo command sent for GPS coordinates: {latitude}, {longitude}")
                return True
            return False
        except Exception as e:
            print(f"Error flying to GPS location: {e}")
            return False

    async def hide_sensor_data(self) -> bool:
        manager = self._get_connection_manager()
        if not manager:
            return False
            
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False
            
            return await manager.clear_slave(manager.slave_calculator.rightmost_screen)
        except Exception as e:
            print(f"Error hiding sensor data: {e}")
            return False
    
    def _build_camera_overlay(self, host: str, overlay_index: int) -> str:
        x_position = 0.98 - (overlay_index * 0.2)
        return f'''
      <ScreenOverlay>
        <name>RGBCamera</name>
        <Icon>
          <href>http://{host}:8000/rgb-camera/image</href>
        </Icon>
        <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="{x_position}" y="0.98" xunits="fraction" yunits="fraction"/>
        <size x="0.15" y="0.12" xunits="fraction" yunits="fraction"/>
      </ScreenOverlay>'''
    
    def _build_sensor_overlay(self, sensor_name: str, image_name: str, host: str, overlay_index: int) -> str:
        x_position = 0.98 - (overlay_index * 0.2)
        return f'''
      <ScreenOverlay>
        <name>{sensor_name}</name>
        <Icon>
          <href>http://{host}:81/{image_name}</href>
        </Icon>
        <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="{x_position}" y="0.98" xunits="fraction" yunits="fraction"/>
      </ScreenOverlay>'''
    
    def _build_combined_kml(self, sensor_overlays: List[str]) -> str:
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>MultiSensorData</name>
{chr(10).join(sensor_overlays)}
  </Document>
</kml>'''
    
    async def disconnect(self):
        if self.connection_manager:
            await self.connection_manager.disconnect()
    
    async def clear_all_kml(self) -> bool:
        manager = self._get_connection_manager()
        if not manager:
            return False
            
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False
            
            return await manager.clear_rightmost_screen()
        except Exception as e:
            print(f"Error clearing rightmost screen KML: {e}")
            return False
    
    async def relaunch_lg(self) -> bool:
        manager = self._get_connection_manager()
        if not manager:
            return False
            
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False
            
            return await manager.relaunch_lg()
        except Exception as e:
            print(f"Error relaunching Liquid Galaxy: {e}")
            return False

lg_service = LGService()
