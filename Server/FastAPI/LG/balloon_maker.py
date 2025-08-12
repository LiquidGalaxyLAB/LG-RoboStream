from typing import Dict, Any, List
import time

class BalloonMaker:
    
    @staticmethod
    def generate_sensor_balloon(sensor_data: Dict[str, Any], selected_sensor: str) -> str:

        data_list = sensor_data.get('data', [])
        sensor_items = [item for item in data_list if item.get('category') == selected_sensor]
        
        if not sensor_items:
            sensor_items = data_list
        
        html_content = BalloonMaker._generate_sensor_html(selected_sensor, sensor_items)
        
        return BalloonMaker.screenOverlayBalloon(html_content)
    
    @staticmethod
    def generate_multi_sensor_balloon(sensor_data: Dict[str, Any], selected_sensors: List[str]) -> str:

        data_list = sensor_data.get('data', [])

        organized_data = {}
        for sensor in selected_sensors:
            if sensor == 'RGB Camera':
                continue 
            sensor_items = [item for item in data_list if item.get('category') == sensor]
            if sensor_items:
                organized_data[sensor] = sensor_items

        if not organized_data and data_list:
            organized_data['All Sensors'] = data_list

        html_content = BalloonMaker._generate_multi_sensor_html(organized_data)
        
        return BalloonMaker.screenOverlayBalloon(html_content)
    
    @staticmethod
    def screenOverlayBalloon(html_content: str) -> str:
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
<Document id="balloon">
   <name>Balloon</name>
  <open>1</open>
  <Style id="purple_paddle">
    <BalloonStyle>
          <text><![CDATA[
          {html_content}
      ]]></text>
      <bgColor>ff1e1e1e</bgColor>
    </BalloonStyle>
  </Style>
    <styleUrl>#purple_paddle</styleUrl>
    <gx:balloonVisibility>1</gx:balloonVisibility>
</Document>
</kml>'''
    
    @staticmethod
    def _generate_sensor_html(sensor_name: str, sensor_items: List[Dict[str, Any]]) -> str:

        data_rows = ""
        for item in sensor_items:
            label = item.get('label', 'Unknown')
            value = item.get('value', 'N/A')
            unit = item.get('unit', '')

            display_value = f"{value} {unit}".strip()
            
            color = BalloonMaker._get_sensor_color(sensor_name, label, value)
            
            data_rows += f'''
        <tr>
          <td style="padding: 14px; border-bottom: 1px solid #374151; color: #9CA3AF; font-size: 24px;">
            {label}
          </td>
          <td style="padding: 14px; border-bottom: 1px solid #374151; color: {color}; font-size: 26px; font-weight: bold; text-align: right;">
            {display_value}
          </td>
        </tr>'''
        
        return f'''<div style="width: 700px; color: white; padding-left: 18px; padding-right: 18px;">
      <center>
        <h1 style="color:white; font-size: 46px;">{sensor_name}</h1>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 34px;">
          {data_rows}
        </table>
        <br>
        <p style="color:white; font-size: 25px;">RoboStream | Liquid Galaxy | GSoC 2025</p>
      </center>
    </div>'''
    
    @staticmethod
    def _generate_multi_sensor_html(organized_data: Dict[str, List[Dict[str, Any]]]) -> str:
        
        sections = ""
        for sensor_name, sensor_items in organized_data.items():
            data_rows = ""
            for item in sensor_items:
                label = item.get('label', 'Unknown')
                value = item.get('value', 'N/A')
                unit = item.get('unit', '')
                
                display_value = f"{value} {unit}".strip()
                color = BalloonMaker._get_sensor_color(sensor_name, label, value)
                
                data_rows += f'''
          <tr>
            <td style="padding: 10px 14px; color: #9CA3AF; font-size: 21px;">
              {label}
            </td>
            <td style="padding: 10px 14px; color: {color}; font-size: 24px; font-weight: bold; text-align: right;">
              {display_value}
            </td>
          </tr>'''

            sections += f'''
        <h3 style="color: #F3F4F6; font-size: 30px; margin: 26px 0 14px 0; font-weight: 600;">
          {sensor_name}
        </h3>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
          {data_rows}
        </table>'''
        
        return f'''<div style="width: 800px; color: white; padding-left: 18px; padding-right: 18px;">
      <center>
        <h1 style="color:white; font-size: 46px;">Multi-Sensor Dashboard</h1>
        {sections}
        <br>
        <p style="color:white; font-size: 25px;">RoboStream | Liquid Galaxy | GSoC 2025</p>
      </center>
    </div>'''
    
    @staticmethod
    def _get_sensor_color(sensor_name: str, label: str, value: Any) -> str:

        default_color = "#F3F4F6"  
        good_color = "#10B981"    
        warning_color = "#F59E0B"  
        error_color = "#EF4444"   
        info_color = "#06B6D4"   
        purple_color = "#8B5CF6"  

        value_str = str(value).lower()
        
        if sensor_name == 'GPS Position':
            if 'latitude' in label.lower() or 'longitude' in label.lower():
                return info_color
            elif 'altitude' in label.lower():
                return good_color
            elif 'speed' in label.lower():
                return purple_color

        elif sensor_name == 'IMU Sensors':
            if 'gyroscope' in label.lower() or 'gyro' in label.lower():
                return purple_color 
            elif 'accelerometer' in label.lower() or 'accel' in label.lower():
                return warning_color  
            elif 'magnetometer' in label.lower() or 'mag' in label.lower():
                return info_color  

        elif sensor_name == 'Temperature':
            try:
                temp_val = float(value)
                if temp_val < 40:
                    return good_color   
                elif temp_val < 60:
                    return info_color   
                elif temp_val < 75:
                    return warning_color 
                else:
                    return error_color   
            except:
                pass

        elif sensor_name == 'Wheel Motors':
            if 'speed' in label.lower() or 'rpm' in label.lower():
                return purple_color
            elif 'temp' in label.lower():
                try:
                    temp_val = float(value)
                    if temp_val < 50:
                        return good_color
                    elif temp_val < 70:
                        return warning_color
                    else:
                        return error_color
                except:
                    pass
            elif 'current' in label.lower() or 'consumption' in label.lower():
                return info_color
            elif 'voltage' in label.lower():
                return warning_color

        elif sensor_name == 'LiDAR Status':
            if 'camera' in label.lower():
                return purple_color
        
        if any(status in value_str for status in ['connected', 'active', 'online', 'ok', 'good', 'operational', 'streaming']):
            return good_color
        elif any(status in value_str for status in ['warning', 'slow', 'degraded', 'high']):
            return warning_color
        elif any(status in value_str for status in ['error', 'failed', 'offline', 'bad', 'critical', 'disconnected']):
            return error_color
        elif any(status in value_str for status in ['unknown', 'n/a', 'null', 'monitoring', 'normal']):
            return info_color
        
        return default_color
