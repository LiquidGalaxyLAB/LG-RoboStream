import time
from typing import Dict, Any, List

class KMLBuilder:
    def __init__(self, lg_host: str):
        self.lg_host = lg_host
    
    def build_logo_kml(self) -> str:
        """Builds KML for showing RoboStream logo"""
        return self._build_kml_document(
            'RoboStreamLogo',
            self._build_screen_overlay(
                'RoboStreamLogo',
                f'http://{self.lg_host}:81/robostream_complete_logo.png',
                overlay_xy='0,1',
                screen_xy='0.02,0.98',
                size='554,550,pixels',
            ),
        )
    
    def build_camera_kml(self, server_host: str) -> str:
        """Builds KML for showing RGB camera feed"""
        return self._build_kml_document(
            'RoboStreamCameraFeed',
            self._build_screen_overlay(
                'RGBCamera',
                f'http://{server_host}:8000/rgb-camera/image',
                overlay_xy='1,1',
                screen_xy='0.98,0.98',
                size='400,300,pixels',
            ),
        )
    
    def build_sensor_data_kml(self, sensor_type: str) -> str:
        """Builds KML for showing sensor data"""
        image_name = self._get_sensor_image_name(sensor_type)
        return self._build_kml_document(
            f'RoboStream {sensor_type} Data',
            self._build_screen_overlay(
                f'{sensor_type} Data',
                f'http://{self.lg_host}:81/{image_name}',
                overlay_xy='1,1',
                screen_xy='0.98,0.98',
                size='0,0,pixels',
            ),
        )
    
    def build_empty_kml(self) -> str:
        """Builds empty KML document"""
        return self._build_kml_document('Empty', '')
    
    def _build_kml_document(self, name: str, content: str) -> str:
        """Helper method to build KML document structure"""
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>{name}</name>
{content}
  </Document>
</kml>'''
    
    def _build_screen_overlay(self, name: str, href: str, **kwargs) -> str:
        """Helper method to build ScreenOverlay"""
        overlay_xy = kwargs.get('overlay_xy', '1,1')
        screen_xy = kwargs.get('screen_xy', '0.98,0.98') 
        size = kwargs.get('size', '0,0,pixels')
        
        overlay_parts = overlay_xy.split(',')
        screen_parts = screen_xy.split(',')
        size_parts = size.split(',')
        
        return f'''    <ScreenOverlay>
      <name>{name}</name>
      <Icon>
        <href>{href}</href>
      </Icon>
      <overlayXY x="{overlay_parts[0]}" y="{overlay_parts[1]}" xunits="fraction" yunits="fraction"/>
      <screenXY x="{screen_parts[0]}" y="{screen_parts[1]}" xunits="fraction" yunits="fraction"/>
      <size x="{size_parts[0]}" y="{size_parts[1]}" xunits="{size_parts[2]}" yunits="{size_parts[2]}"/>
    </ScreenOverlay>'''
    
    def _get_sensor_image_name(self, sensor_type: str) -> str:
        """Gets image name for sensor type with timestamp"""
        timestamp = int(time.time() * 1000)
        sensor_images = {
            'GPS Position': 'gps_data',
            'IMU Sensors': 'imu_data',
            'LiDAR Status': 'lidar_data',
            'Temperature': 'temperature_data',
            'Wheel Motors': 'motors_data',
            'Server Link': 'server_data',
        }
        base_name = sensor_images.get(sensor_type, 'sensor_data')
        return f'{base_name}_{timestamp}.png'
    
    def build_sensor_data(self, sensor_data: Dict[str, Any], selected_sensor: str) -> Dict[str, Any]:
        """Builds sensor data configuration for image generation"""
        sensor_configs = {
            'GPS Position': {
                'title': '📍 GPS Position',
                'data': [
                    {'label': 'Latitude', 'value': f"{sensor_data.get('gps', {}).get('latitude', 0.0):.6f}°"},
                    {'label': 'Longitude', 'value': f"{sensor_data.get('gps', {}).get('longitude', 0.0):.6f}°"},
                    {'label': 'Altitude', 'value': f"{sensor_data.get('gps', {}).get('altitude', 0.0):.1f} m"},
                    {'label': 'Speed', 'value': f"{sensor_data.get('gps', {}).get('speed', 0.0):.2f} m/s"},
                ],
            },
            'IMU Sensors': {
                'title': '⚡ IMU Sensors',
                'data': [
                    {'label': 'Accel X', 'value': f"{sensor_data.get('imu', {}).get('accelerometer', {}).get('x', 0.0):.2f} m/s²"},
                    {'label': 'Accel Y', 'value': f"{sensor_data.get('imu', {}).get('accelerometer', {}).get('y', 0.0):.2f} m/s²"},
                    {'label': 'Accel Z', 'value': f"{sensor_data.get('imu', {}).get('accelerometer', {}).get('z', 0.0):.2f} m/s²"},
                    {'label': 'Gyro X', 'value': f"{sensor_data.get('imu', {}).get('gyroscope', {}).get('x', 0.0):.3f} rad/s"},
                    {'label': 'Gyro Y', 'value': f"{sensor_data.get('imu', {}).get('gyroscope', {}).get('y', 0.0):.3f} rad/s"},
                    {'label': 'Gyro Z', 'value': f"{sensor_data.get('imu', {}).get('gyroscope', {}).get('z', 0.0):.3f} rad/s"},
                ],
            },
            'LiDAR Status': {
                'title': '🎯 LiDAR Status',
                'data': [
                    {'label': 'Status', 'value': sensor_data.get('lidar', 'Unknown')},
                    {'label': 'Last Update', 'value': time.strftime('%H:%M:%S')},
                ],
            },
            'Temperature': {
                'title': '🌡️ Motor Temperature',
                'data': [
                    {'label': 'Average Temp', 'value': 'N/A°C'},
                    {'label': 'Status', 'value': 'Monitoring'},
                ],
            },
            'Wheel Motors': {
                'title': '⚙️ Wheel Motors',
                'data': [
                    {'label': 'Status', 'value': 'Active'},
                    {'label': 'Motors', 'value': '4 Connected'},
                ],
            },
            'Server Link': {
                'title': '☁️ Server Connection', 
                'data': [
                    {'label': 'Status', 'value': 'Connected'},
                    {'label': 'Last Update', 'value': time.strftime('%H:%M:%S')},
                ],
            },
        }
        
        config = sensor_configs.get(selected_sensor, {
            'title': '📊 Unknown Sensor',
            'data': [{'label': 'Status', 'value': 'No Data'}],
        })
        
        return {
            'title': config['title'],
            'data': config['data'],
            'imageName': self._get_sensor_image_name(selected_sensor),
        }
