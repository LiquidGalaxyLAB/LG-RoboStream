import time
from typing import Dict, Any, List

import time
from .balloon_maker import BalloonMaker

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
        # Add timestamp to force image refresh and avoid caching
        timestamp = int(time.time())
        return self._build_kml_document(
            'RoboStreamCameraFeed',
            self._build_screen_overlay(
                'RGBCamera',
                f'http://{server_host}:8000/rgb-camera/image?t={timestamp}',
                overlay_xy='1,1',
                screen_xy='0.98,0.98',
                size='600,500,pixels',
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
    
    def build_sensor_balloon_kml(self, sensor_data: Dict[str, Any], selected_sensor: str) -> str:
        """Builds KML for showing sensor data using balloons instead of images"""
        # Prepare structured data for single sensor
        structured_data = self._prepare_structured_sensor_data(sensor_data, [selected_sensor])
        # Return balloon directly since it's already a complete KML document
        return BalloonMaker.generate_sensor_balloon(structured_data, selected_sensor)
    
    def build_multi_sensor_balloon_kml(self, sensor_data: Dict[str, Any], selected_sensors: List[str]) -> str:
        """Builds KML for showing multiple sensor data using balloons"""
        # Prepare structured data for balloon
        structured_data = self._prepare_structured_sensor_data(sensor_data, selected_sensors)
        # Return balloon directly since it's already a complete KML document
        return BalloonMaker.generate_multi_sensor_balloon(structured_data, selected_sensors)
    
    def _prepare_structured_sensor_data(self, sensor_data: Dict[str, Any], selected_sensors: List[str]) -> Dict[str, Any]:
        """Prepares structured sensor data for balloon generation"""
        data_list = []
        
        for sensor in selected_sensors:
            if sensor == 'RGB Camera':
                continue  # Skip camera
                
            sensor_items = self._get_sensor_items(sensor_data, sensor)
            for item in sensor_items:
                item['category'] = sensor  # Add category for organization
                data_list.append(item)
        
        return {'data': data_list}
    
    def _get_sensor_items(self, sensor_data: Dict[str, Any], sensor_name: str) -> List[Dict[str, Any]]:
        """Gets sensor items for a specific sensor type"""
        if sensor_name == 'GPS Position':
            return [
                {'label': 'Latitude', 'value': f"{sensor_data.get('gps', {}).get('latitude', 0.0):.6f}", 'unit': '°'},
                {'label': 'Longitude', 'value': f"{sensor_data.get('gps', {}).get('longitude', 0.0):.6f}", 'unit': '°'},
                {'label': 'Altitude', 'value': f"{sensor_data.get('gps', {}).get('altitude', 0.0):.1f}", 'unit': 'm'},
                {'label': 'Speed', 'value': f"{sensor_data.get('gps', {}).get('speed', 0.0):.2f}", 'unit': 'm/s'},
            ]
        elif sensor_name == 'IMU Sensors':
            imu_data = sensor_data.get('imu', {})
            accel = imu_data.get('accelerometer', {})
            gyro = imu_data.get('gyroscope', {})
            mag = imu_data.get('magnetometer', {})
            return [
                {'label': 'Accel X', 'value': f"{accel.get('x', 0.0):.2f}", 'unit': 'm/s²'},
                {'label': 'Accel Y', 'value': f"{accel.get('y', 0.0):.2f}", 'unit': 'm/s²'},
                {'label': 'Accel Z', 'value': f"{accel.get('z', 0.0):.2f}", 'unit': 'm/s²'},
                {'label': 'Gyro X', 'value': f"{gyro.get('x', 0.0):.3f}", 'unit': 'rad/s'},
                {'label': 'Gyro Y', 'value': f"{gyro.get('y', 0.0):.3f}", 'unit': 'rad/s'},
                {'label': 'Gyro Z', 'value': f"{gyro.get('z', 0.0):.3f}", 'unit': 'rad/s'},
                {'label': 'Mag X', 'value': f"{mag.get('x', 0.0):.2f}", 'unit': 'μT'},
                {'label': 'Mag Y', 'value': f"{mag.get('y', 0.0):.2f}", 'unit': 'μT'},
                {'label': 'Mag Z', 'value': f"{mag.get('z', 0.0):.2f}", 'unit': 'μT'},
            ]
        elif sensor_name == 'LiDAR Status':
            return [
                {'label': 'Status', 'value': sensor_data.get('lidar', 'Unknown'), 'unit': ''},
                {'label': 'Camera Status', 'value': sensor_data.get('camera', 'Unknown'), 'unit': ''},
                {'label': 'Last Update', 'value': time.strftime('%H:%M:%S'), 'unit': ''},
            ]
        elif sensor_name == 'Temperature':
            # Get actual temperature data from actuators
            actuators = sensor_data.get('actuators', {})
            temps = []
            motor_status = []
            
            for wheel_name, wheel_data in actuators.items():
                if isinstance(wheel_data, dict) and 'temperature' in wheel_data:
                    temps.append(wheel_data['temperature'])
                    motor_status.append(wheel_data.get('status', 'Unknown'))
            
            avg_temp = sum(temps) / len(temps) if temps else 0.0
            active_motors = sum(1 for status in motor_status if status == 'Operational')
            
            return [
                {'label': 'Average Temp', 'value': f"{avg_temp:.1f}", 'unit': '°C'},
                {'label': 'Min Temp', 'value': f"{min(temps):.1f}" if temps else "N/A", 'unit': '°C'},
                {'label': 'Max Temp', 'value': f"{max(temps):.1f}" if temps else "N/A", 'unit': '°C'},
                {'label': 'Active Motors', 'value': f"{active_motors}", 'unit': f'/ {len(motor_status)}'},
                {'label': 'Status', 'value': 'Normal' if avg_temp < 70 else 'High' if avg_temp < 80 else 'Critical', 'unit': ''},
            ]
        elif sensor_name == 'Wheel Motors':
            # Get detailed actuator data
            actuators = sensor_data.get('actuators', {})
            items = []
            
            for wheel_name, wheel_data in actuators.items():
                if isinstance(wheel_data, dict):
                    wheel_display = wheel_name.replace('_', ' ').title()
                    items.extend([
                        {'label': f'{wheel_display} Speed', 'value': f"{wheel_data.get('speed', 0)}", 'unit': 'RPM'},
                        {'label': f'{wheel_display} Temp', 'value': f"{wheel_data.get('temperature', 0.0):.1f}", 'unit': '°C'},
                        {'label': f'{wheel_display} Current', 'value': f"{wheel_data.get('consumption', 0.0):.2f}", 'unit': 'A'},
                        {'label': f'{wheel_display} Voltage', 'value': f"{wheel_data.get('voltage', 0.0):.1f}", 'unit': 'V'},
                        {'label': f'{wheel_display} Status', 'value': wheel_data.get('status', 'Unknown'), 'unit': ''},
                    ])
            
            if not items:
                items = [{'label': 'Status', 'value': 'No Motor Data', 'unit': ''}]
            
            return items
        elif sensor_name == 'Server Link':
            return [
                {'label': 'Status', 'value': 'Connected', 'unit': ''},
                {'label': 'Last Update', 'value': time.strftime('%H:%M:%S'), 'unit': ''},
                {'label': 'Timestamp', 'value': f"{sensor_data.get('timestamp', 0.0):.0f}", 'unit': ''},
            ]
        else:
            return [{'label': 'Status', 'value': 'No Data', 'unit': ''}]
