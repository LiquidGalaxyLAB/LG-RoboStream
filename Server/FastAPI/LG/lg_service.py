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

class Coordinates:
    def __init__(self, latitude, longitude, elevation, tilt, bearing, altitude):
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.tilt = tilt
        self.bearing = bearing
        self.altitude = altitude

    def LookAt(self):
        return f"<LookAt><latitude>{self.latitude}</latitude><longitude>{self.longitude}</longitude><altitude>{self.altitude}</altitude><tilt>{self.tilt}</tilt><heading>{self.bearing}</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>"

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
        
        # Variables for placemark file management to avoid cache issues
        self.placemark_counter = 0
        self.current_placemark_file = None
        
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
        # Clean up current placemark file reference (but keep counter for next session)
        self.current_placemark_file = None
        
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
    
    async def send_robot_placemark(self, latitude: float, longitude: float, altitude: float = 0) -> bool:
        if not self.is_connected or not self.client or not self.sftp:
            return False
            
        try:
            # Delete previous placemark file if exists
            await self._delete_previous_placemark()
            
            # Generate new placemark filename with counter to avoid cache
            self.placemark_counter += 1
            new_placemark_filename = f"placemark{self.placemark_counter}.kml"
            self.current_placemark_file = new_placemark_filename
            
            # CRITICAL: Always upload Amiga robot icon to LG1 first before creating placemark
            robot_icon_path = "AMIGA_ROBOT_PNG/amiga-base.png"
            if not os.path.exists(robot_icon_path):
                print(f"ERROR: Amiga robot icon file not found at {robot_icon_path}")
                return False
                
            # Ensure the Amiga icon is uploaded to the master server (LG1)
            icon_uploaded = await self._upload_robot_icon(robot_icon_path)
            if not icon_uploaded:
                print("ERROR: Failed to upload Amiga robot icon to LG1. Cannot create placemark.")
                return False
            
            # Small delay to ensure the file is fully written and accessible
            await asyncio.sleep(0.1)
            
            placemark_kml = f'''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Style id="robotStyle">
      <IconStyle>
        <Icon>
          <href>http://{self.host}:81/amiga-base.png</href>
        </Icon>
        <scale>2.5</scale>
      </IconStyle>
    </Style>
    <Placemark>
      <name></name>
      <styleUrl>#robotStyle</styleUrl>
      <Point>
        <coordinates>{longitude},{latitude},{altitude}</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>'''
            
            remote_path = f'/var/www/html/{new_placemark_filename}'
            with BytesIO(placemark_kml.encode('utf-8')) as kml_io:
                self.sftp.putfo(kml_io, remote_path)
            await self.update_kmls_txt()
            
            print(f"Robot placemark updated: {new_placemark_filename} at coordinates {latitude}, {longitude}")
            return True
        except Exception as e:
            print(f"Error sending robot placemark: {e}")
            return False

    async def _delete_previous_placemark(self) -> bool:
        """Delete the previous placemark file to avoid cache issues"""
        if not self.current_placemark_file or not self.is_connected or not self.client:
            return True
            
        try:
            # Remove the file from the server
            command = f"rm -f /var/www/html/{self.current_placemark_file}"
            stdin, stdout, stderr = self.client.exec_command(command)
            stdout.read()
            
            print(f"Previous placemark file deleted: {self.current_placemark_file}")
            return True
        except Exception as e:
            print(f"Error deleting previous placemark file {self.current_placemark_file}: {e}")
            return False

    async def _upload_robot_icon(self, local_icon_path: str) -> bool:
        """Upload robot icon to the server ensuring it's available on the master server (LG1)"""
        if not self.is_connected or not self.sftp:
            return False
            
        try:
            remote_icon_path = "/var/www/html/amiga-base.png"
            
            # Always ensure the icon is available on the server
            # Even if it exists, we'll verify/re-upload to make sure it's properly accessible
            if os.path.exists(local_icon_path):
                # Upload the icon to the master server (LG1)
                self.sftp.put(local_icon_path, remote_icon_path)
                
                # Set proper permissions to ensure it's accessible via HTTP
                command = f"chmod 644 {remote_icon_path}"
                stdin, stdout, stderr = self.client.exec_command(command)
                stdout.read()
                
                print(f"Amiga robot icon uploaded to master server (LG1): {local_icon_path} -> {remote_icon_path}")
                return True
            else:
                print(f"Local Amiga robot icon file not found: {local_icon_path}")
                return False
        except Exception as e:
            print(f"Error uploading Amiga robot icon to master server: {e}")
            return False
    
    async def update_kmls_txt(self) -> bool:
        if not self.is_connected or not self.client or not self.current_placemark_file:
            return False
            
        try:
            try:
                stdin, stdout, stderr = self.client.exec_command('cat /var/www/html/kmls.txt')
                current_content = stdout.read().decode('utf-8').strip()
            except:
                current_content = ""

            # Create new placemark line with current file name
            placemark_line = f"http://{self.host}:81/{self.current_placemark_file}"
            lines = current_content.split('\n') if current_content else []

            # Remove any existing placemark lines (both old Placemark.kml and new placemark*.kml)
            lines = [line.strip() for line in lines if line.strip() and 
                    'Placemark.kml' not in line and 'placemark' not in line.lower()]
            lines.append(placemark_line)

            new_content = '\n'.join(lines)
            command = f"echo '{new_content}' > /var/www/html/kmls.txt"
            stdin, stdout, stderr = self.client.exec_command(command)
            stdout.read()
            
            print(f"kmls.txt updated with new placemark: {placemark_line}")
            return True
        except Exception as e:
            print(f"Error updating kmls.txt: {e}")
            return False

    async def clean_all_placemark_files(self) -> bool:
        """Clean all placemark files (both old Placemark.kml and new placemark*.kml) from the server"""
        if not self.is_connected or not self.client:
            return False
            
        try:
            # Remove all placemark files
            commands = [
                'rm -f /var/www/html/Placemark.kml',  # Old static file
                'rm -f /var/www/html/placemark*.kml'  # New dynamic files
            ]
            
            for command in commands:
                stdin, stdout, stderr = self.client.exec_command(command)
                stdout.read()
            
            # Update kmls.txt to remove all placemark lines
            try:
                stdin, stdout, stderr = self.client.exec_command('cat /var/www/html/kmls.txt')
                current_content = stdout.read().decode('utf-8').strip()
            except:
                current_content = ""

            if current_content:
                lines = current_content.split('\n')
                # Remove any lines containing placemark references
                lines = [line.strip() for line in lines if line.strip() and 
                        'Placemark.kml' not in line and 'placemark' not in line.lower()]
                
                new_content = '\n'.join(lines)
                command = f"echo '{new_content}' > /var/www/html/kmls.txt"
                stdin, stdout, stderr = self.client.exec_command(command)
                stdout.read()

            # Reset current file reference
            self.current_placemark_file = None
            print("All placemark files cleaned from server")
            return True
        except Exception as e:
            print(f"Error cleaning placemark files: {e}")
            return False
    
    async def remove_robot_placemark(self) -> bool:
        if not self.is_connected or not self.client:
            return False
            
        try:
            # Remove current placemark file if it exists
            if self.current_placemark_file:
                command = f'rm -f /var/www/html/{self.current_placemark_file}'
                stdin, stdout, stderr = self.client.exec_command(command)
                stdout.read()
            
            # Also remove old static Placemark.kml file for backward compatibility
            stdin, stdout, stderr = self.client.exec_command('rm -f /var/www/html/Placemark.kml')
            stdout.read()
            
            # Update kmls.txt to remove all placemark lines
            try:
                stdin, stdout, stderr = self.client.exec_command('cat /var/www/html/kmls.txt')
                current_content = stdout.read().decode('utf-8').strip()
                
                if current_content:
                    lines = current_content.split('\n')
                    # Remove any lines containing placemark references
                    lines = [line.strip() for line in lines if line.strip() and 
                            'Placemark.kml' not in line and 'placemark' not in line.lower()]
                    new_content = '\n'.join(lines)
                    
                    command = f"echo '{new_content}' > /var/www/html/kmls.txt"
                    stdin, stdout, stderr = self.client.exec_command(command)
                    stdout.read()
            except Exception as e:
                print(f"Error updating kmls.txt during removal: {e}")
            
            # Clear current file reference
            self.current_placemark_file = None
            print("Robot placemark removed from server")
            return True
        except Exception as e:
            print(f"Error removing robot placemark: {e}")
            return False
    
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

    async def navigate(self, coordinates: Coordinates) -> Optional[str]:
        """Navigate to specified coordinates using flytoview command"""
        try:
            if not self.is_connected or not self.client:
                print("Error: LG not connected")
                return None
                
            coordinates_lookat = coordinates.LookAt()
            # Escape quotes properly for shell command
            escaped_lookat = coordinates_lookat.replace('"', '\\"')
            command = f'echo "flytoview={escaped_lookat}" > /tmp/query.txt'
            
            # Debug: Print the exact command being sent
            print(f"Debug: Executing command: {command}")
            print(f"Debug: LookAt XML: {coordinates_lookat}")
            
            stdin, stdout, stderr = self.client.exec_command(command)
            stdout.read()
            
            print(f"Debug: Navigate command sent - Lat: {coordinates.latitude}, Lon: {coordinates.longitude}")
            return coordinates_lookat
        except Exception as e:
            print(f"Error in navigate: {e}")
            return None

class LGService:
    def __init__(self):
        self.connection_manager: Optional[LGConnectionManager] = None
        self.gps_flyto_sent = False
        self.robot_tracking_active = False
        
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

            if 'GPS Position' in selected_sensors and not self.gps_flyto_sent:
                await self._fly_to_default_gps_location(manager)
                self.gps_flyto_sent = True
            
            if 'GPS Position' in selected_sensors:
                gps_data = sensor_data.get('gps', {})
                latitude = gps_data.get('latitude', 0.0)
                longitude = gps_data.get('longitude', 0.0)
                altitude = gps_data.get('altitude', 0.0)
                
                print(f"Debug: Showing robot placemark at GPS position: {latitude}, {longitude}, {altitude}")
                await manager.send_robot_placemark(latitude, longitude, altitude)
                self.robot_tracking_active = True
            
            return kml_sent
        except Exception as e:
            print(f"Error showing sensor data: {e}")
            return False
    
    async def _fly_to_default_gps_location(self, manager) -> bool:
        try:
            coords = Coordinates(
                latitude=41.606515,  
                longitude=0.607994,  
                elevation=226.0573119713049,       
                tilt=35,            
                bearing=225,    
                altitude=197        
            )

            result = await manager.navigate(coords)
            if result:
                print("Debug: Successfully navigated to GPS position")
                return True
            else:
                print("Debug: Failed to navigate to GPS position")
                return False
                
        except Exception as e:
            print(f"Error flying to GPS location: {e}")
            return False

    async def _fly_to_gps_location(self, gps_data: Dict[str, Any], manager) -> bool:
        """Navigate to GPS location using Coordinates class and flytoview"""
        try:
            latitude = gps_data.get('latitude', 0.0)
            longitude = gps_data.get('longitude', 0.0)
            altitude = gps_data.get('altitude', 100.0)
            
            print(f"Debug: GPS data received - Lat: {latitude}, Lon: {longitude}, Alt: {altitude}")

            # Create coordinates object
            coords = Coordinates(
                latitude=latitude,
                longitude=longitude,
                elevation=altitude,
                tilt=45,
                bearing=0,
                altitude=altitude + 100
            )
            
            # Use the navigate method
            result = await manager.navigate(coords)
            if result:
                print(f"Debug: Successfully navigated to GPS coordinates: {latitude}, {longitude}")
                return True
            else:
                print(f"Debug: Failed to navigate to GPS coordinates: {latitude}, {longitude}")
                return False
                
        except Exception as e:
            print(f"Error flying to GPS location: {e}")
            return False

    async def hide_sensor_data(self) -> bool:
        self.gps_flyto_sent = False  # Reset on hide
        manager = self._get_connection_manager()
        if not manager:
            return False
            
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False
            
            # Clear sensor data from screen
            clear_result = await manager.clear_slave(manager.slave_calculator.rightmost_screen)
            
            # Also hide robot placemark if it was being displayed
            if self.robot_tracking_active:
                print("Debug: Hiding robot placemark when stopping sensor streaming")
                await manager.remove_robot_placemark()
                self.robot_tracking_active = False
            
            return clear_result
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

    async def clear_logos(self) -> bool:
        """Clear logos from the leftmost screen by sending an empty KML."""
        manager = self._get_connection_manager()
        if not manager:
            return False
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False

            leftmost = manager.slave_calculator.leftmost_screen
            result = await manager.clear_slave(leftmost)
            if not result:
                print(f"Failed to clear leftmost screen {leftmost}")
            return result
        except Exception as e:
            print(f"Error clearing logos (leftmost screen): {e}")
            return False

    async def clean_kml_and_logos(self) -> bool:
        """Clear both rightmost screen KML overlays and leftmost screen logos."""
        manager = self._get_connection_manager()
        if not manager:
            return False
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False

            leftmost = manager.slave_calculator.leftmost_screen
            rightmost_cleared = await manager.clear_rightmost_screen()
            leftmost_cleared = await manager.clear_slave(leftmost)
            return rightmost_cleared and leftmost_cleared
        except Exception as e:
            print(f"Error cleaning KML + logos: {e}")
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

    async def show_robot_location(self, latitude: float, longitude: float, altitude: float = 0) -> bool:
        """Show robot location on LG with placemark"""
        print(f"Debug: show_robot_location called with lat={latitude}, lon={longitude}, alt={altitude}")
        manager = self._get_connection_manager()
        if not manager:
            print("Debug: No connection manager available")
            return False
            
        try:
            if not manager.is_connected:
                print("Debug: Attempting to connect to LG...")
                connected = await manager.connect()
                if not connected:
                    print("Debug: Failed to connect to LG")
                    return False
            
            print("Debug: Sending robot placemark...")
            result = await manager.send_robot_placemark(latitude, longitude, altitude)
            print(f"Debug: send_robot_placemark result: {result}")
            
            if result:
                self.robot_tracking_active = True
                print(f"Debug: Robot location updated successfully at {latitude}, {longitude}")
            
            return result
        except Exception as e:
            print(f"Error showing robot location: {e}")
            return False
    
    async def hide_robot_location(self) -> bool:
        """Hide robot location from LG"""
        print("Debug: hide_robot_location called")
        manager = self._get_connection_manager()
        if not manager:
            print("Debug: No connection manager available")
            return False
            
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False
            
            print("Debug: Removing robot placemark...")
            result = await manager.remove_robot_placemark()
            print(f"Debug: remove_robot_placemark result: {result}")
            
            if result:
                self.robot_tracking_active = False
                print("Debug: Robot location hidden successfully")
            
            return result
        except Exception as e:
            print(f"Error hiding robot location: {e}")
            return False
    
    def is_robot_tracking_active(self) -> bool:
        """Check if robot tracking is currently active"""
        return self.robot_tracking_active

lg_service = LGService()
