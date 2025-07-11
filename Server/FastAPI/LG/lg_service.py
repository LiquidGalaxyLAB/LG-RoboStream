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
from .image_generator import ImageGenerator

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
        
        # Initialize components
        self.slave_calculator = SlaveCalculator(total_screens)
        self.kml_builder = KMLBuilder(host)
        
    async def connect(self) -> bool:
        """Establishes SSH connection to Liquid Galaxy"""
        try:
            self.client = paramiko.SSHClient()
            self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            # Connect to SSH
            self.client.connect(
                hostname=self.host,
                username=self.username,
                password=self.password,
                timeout=10
            )
            
            # Test connection
            stdin, stdout, stderr = self.client.exec_command('echo "Connection successful"')
            stdout.read()
            
            # Open SFTP
            self.sftp = self.client.open_sftp()
            
            self.is_connected = True
            return True
            
        except Exception as e:
            print(f"LG Connection error: {e}")
            await self.disconnect()
            return False
    
    async def disconnect(self):
        """Closes SSH connection"""
        if self.sftp:
            self.sftp.close()
            self.sftp = None
        if self.client:
            self.client.close()
            self.client = None
        self.is_connected = False
    
    async def send_kml_to_slave(self, kml_content: str, slave_number: int) -> bool:
        """Sends KML content to a specific slave"""
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
        """Sends KML to leftmost screen (for logos)"""
        return await self.send_kml_to_slave(kml_content, self.slave_calculator.leftmost_screen)
    
    async def send_kml_to_rightmost_screen(self, kml_content: str) -> bool:
        """Sends KML to rightmost screen (for data and camera)"""
        return await self.send_kml_to_slave(kml_content, self.slave_calculator.rightmost_screen)
    
    async def send_image(self, image_bytes: bytes, filename: str) -> bool:
        """Sends image to LG server"""
        if not self.is_connected or not self.sftp:
            return False
            
        try:
            # Cleanup old images with similar names
            base_name = filename.split('_')[0]
            await self.cleanup_old_images(f'{base_name}_*.png')
            
            # Send image
            remote_path = f'/var/www/html/{filename}'
            with BytesIO(image_bytes) as image_io:
                self.sftp.putfo(image_io, remote_path)
            
            return True
        except Exception as e:
            print(f"Error sending image {filename}: {e}")
            return False
    
    async def send_file_from_path(self, local_path: str, remote_path: str) -> bool:
        """Sends a file from local path to remote path"""
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
        """Cleans up old images matching pattern"""
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
        """Clears KML content from a slave"""
        empty_kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>'''
        return await self.send_kml_to_slave(empty_kml, slave_number)
    
    async def clear_all_screens(self) -> bool:
        """Clears KML content from ALL screens"""
        try:
            if not self.is_connected:
                return False
                
            # Check if total screens is configured
            if lg_data.LG_TOTAL_SCREENS is None:
                print("Error: LG_TOTAL_SCREENS not configured")
                return False
                
            # Clear all slaves
            success = True
            for slave_num in range(1, lg_data.LG_TOTAL_SCREENS + 1):
                if slave_num != lg_data.LG_TOTAL_SCREENS // 2 + 1:  # Skip master screen
                    result = await self.clear_slave(slave_num)
                    if not result:
                        success = False
                        print(f"Failed to clear slave {slave_num}")
                        
            return success
        except Exception as e:
            print(f"Error clearing all screens: {e}")
            return False

class LGService:
    def __init__(self):
        self.connection_manager: Optional[LGConnectionManager] = None
        self.image_generator = ImageGenerator()
        
    def _get_connection_manager(self) -> Optional[LGConnectionManager]:
        """Gets connection manager with current LG configuration"""
        print(f"Debug: _get_connection_manager called")
        print(f"Debug: LG_HOST={lg_data.LG_HOST}, LG_USERNAME={lg_data.LG_USERNAME}, LG_PASSWORD={lg_data.LG_PASSWORD}, LG_TOTAL_SCREENS={lg_data.LG_TOTAL_SCREENS}")
        
        if not all([lg_data.LG_HOST, lg_data.LG_USERNAME, lg_data.LG_PASSWORD, lg_data.LG_TOTAL_SCREENS]):
            print("Debug: Missing LG configuration, returning None")
            return None
            
        if (not self.connection_manager or 
            self.connection_manager.host != lg_data.LG_HOST or
            self.connection_manager.username != lg_data.LG_USERNAME or
            self.connection_manager.password != lg_data.LG_PASSWORD or
            self.connection_manager.total_screens != lg_data.LG_TOTAL_SCREENS):
            
            print("Debug: Creating new connection manager")
            self.connection_manager = LGConnectionManager(
                lg_data.LG_HOST, lg_data.LG_USERNAME, lg_data.LG_PASSWORD, lg_data.LG_TOTAL_SCREENS
            )
        else:
            print("Debug: Reusing existing connection manager")
        
        return self.connection_manager
    
    async def login(self, host: str, username: str, password: str, total_screens: int) -> LoginResult:
        """Performs login with validation and connection test"""
        if not host or not username or not password or total_screens <= 0:
            return LoginResult(False, 'Please fill in all fields correctly.')
        
        try:
            # Test connection
            test_manager = LGConnectionManager(host, username, password, total_screens)
            connected = await test_manager.connect()
            
            if connected:
                # Show logo on successful connection
                await self._show_logo_with_manager(test_manager)
                await test_manager.disconnect()
                
                # Save configuration globally
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
        """Shows logo using specific connection manager"""
        try:
            # Generate logo KML
            logo_kml = manager.kml_builder.build_logo_kml()
            
            # Send logo file (assuming it exists in server)
            logo_path = "LOGO_IMAGES/robostream_complete_logo.png"
            if os.path.exists(logo_path):
                await manager.send_file_from_path(logo_path, '/var/www/html/robostream_complete_logo.png')
            
            # Send KML
            return await manager.send_kml_to_leftmost_screen(logo_kml)
        except Exception as e:
            print(f"Error showing logo: {e}")
            return False
    
    async def show_logo(self) -> bool:
        """Shows the RoboStream logo"""
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
        """Shows RGB camera image"""
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
        """Shows sensor data overlays"""
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
            
            sensor_overlays = []
            all_images_uploaded = True
            
            for i, selected_sensor in enumerate(selected_sensors):
                if selected_sensor == 'RGB Camera':
                    camera_overlay = self._build_camera_overlay(manager.host, i)
                    sensor_overlays.append(camera_overlay)
                    continue
                
                # Get sensor info and generate image
                sensor_info = manager.kml_builder.build_sensor_data(sensor_data, selected_sensor)
                image_bytes = await self.image_generator.generate_sensor_image(sensor_info)
                
                if image_bytes:
                    image_name = sensor_info['imageName']
                    image_sent = await manager.send_image(image_bytes, image_name)
                    if not image_sent:
                        all_images_uploaded = False
                        continue
                    
                    sensor_overlay = self._build_sensor_overlay(selected_sensor, image_name, manager.host, i)
                    sensor_overlays.append(sensor_overlay)
                else:
                    all_images_uploaded = False
            
            # Send combined KML
            combined_kml = self._build_combined_kml(sensor_overlays)
            kml_sent = await manager.send_kml_to_rightmost_screen(combined_kml)
            
            return all_images_uploaded and kml_sent
        except Exception as e:
            print(f"Error showing sensor data: {e}")
            return False
    
    async def hide_sensor_data(self) -> bool:
        """Hides sensor data"""
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
        """Builds camera overlay KML"""
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
        """Builds sensor overlay KML"""
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
        """Builds combined KML document"""
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>MultiSensorData</name>
{chr(10).join(sensor_overlays)}
  </Document>
</kml>'''
    
    async def disconnect(self):
        """Disconnects from LG"""
        if self.connection_manager:
            await self.connection_manager.disconnect()
    
    async def clear_all_kml(self) -> bool:
        """Clears ALL KML content from ALL screens"""
        manager = self._get_connection_manager()
        if not manager:
            return False
            
        try:
            if not manager.is_connected:
                connected = await manager.connect()
                if not connected:
                    return False
            
            return await manager.clear_all_screens()
        except Exception as e:
            print(f"Error clearing all KML: {e}")
            return False

# Global LG service instance
lg_service = LGService()
