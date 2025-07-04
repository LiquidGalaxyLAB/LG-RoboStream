import 'server.dart';

class KMLBuilder {
  final String _lgHost;

  KMLBuilder({required String lgHost}) : _lgHost = lgHost;

  String buildLogoKML() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>RoboStreamLogo</name>
    <ScreenOverlay>
      <name>RoboStreamLogo</name>
      <Icon>
        <href>http://$_lgHost:81/robostream_complete_logo.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.98" xunits="fraction" yunits="fraction"/>
      <size x="554" y="550" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  String buildCameraKML(String serverHost) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>RoboStreamCameraFeed</name>
    <ScreenOverlay>
      <name>RGBCamera</name>
      <Icon>
        <href>http://$serverHost:8000/rgb-camera/image</href>
      </Icon>
      <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.98" y="0.98" xunits="fraction" yunits="fraction"/>
      <size x="400" y="300" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  String buildSensorDataKML(String sensorType) {
    String imageName = _getSensorImageName(sensorType);
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>RoboStream $sensorType Data</name>
    
    <!-- ScreenOverlay para datos del sensor en pantalla -->
    <ScreenOverlay>
      <name>$sensorType Data</name>
      <Icon>
        <href>http://$_lgHost:81/$imageName</href>
      </Icon>
      <!-- Punto de la imagen que se alinea: (1,1) = esquina superior derecha de la imagen -->
      <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
      <!-- Punto de la pantalla: (1,1) = esquina superior derecha de la ventana -->
      <screenXY x="0.98" y="0.98" xunits="fraction" yunits="fraction"/>
      <!-- Sin escalado: usa el tamaño real de la imagen -->
      <size x="0" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
    
  </Document>
</kml>''';
  }

  String _getSensorImageName(String sensorType) {
    switch (sensorType) {
      case 'GPS Position':
        return 'gps_data.png';
      case 'IMU Sensors':
        return 'imu_data.png';
      case 'LiDAR Status':
        return 'lidar_data.png';
      case 'Temperature':
        return 'temperature_data.png';
      case 'Wheel Motors':
        return 'motors_data.png';
      case 'Server Link':
        return 'server_data.png';
      default:
        return 'sensor_data.png';
    }
  }

  String buildEmptyKML() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';
  }

  Map<String, dynamic> buildSensorData(SensorData sensorData, String selectedSensor) {
    Map<String, dynamic> sensorInfo = {
      'title': '',
      'icon': '',
      'data': <Map<String, String>>[],
      'imageName': _getSensorImageName(selectedSensor),
    };
    
    switch (selectedSensor) {
      case 'GPS Position':
        sensorInfo['title'] = '📍 GPS Position';
        sensorInfo['data'] = [
          {'label': 'Latitude', 'value': '${sensorData.gps.latitude.toStringAsFixed(6)}°'},
          {'label': 'Longitude', 'value': '${sensorData.gps.longitude.toStringAsFixed(6)}°'},
          {'label': 'Altitude', 'value': '${sensorData.gps.altitude.toStringAsFixed(1)} m'},
          {'label': 'Speed', 'value': '${sensorData.gps.speed.toStringAsFixed(2)} m/s'},
        ];
        break;
        
      case 'IMU Sensors':
        sensorInfo['title'] = '⚡ IMU Sensors';
        sensorInfo['data'] = [
          {'label': 'Accel X', 'value': '${sensorData.imu.accelerometer.x.toStringAsFixed(2)} m/s²'},
          {'label': 'Accel Y', 'value': '${sensorData.imu.accelerometer.y.toStringAsFixed(2)} m/s²'},
          {'label': 'Accel Z', 'value': '${sensorData.imu.accelerometer.z.toStringAsFixed(2)} m/s²'},
          {'label': 'Gyro X', 'value': '${sensorData.imu.gyroscope.x.toStringAsFixed(3)} rad/s'},
          {'label': 'Gyro Y', 'value': '${sensorData.imu.gyroscope.y.toStringAsFixed(3)} rad/s'},
          {'label': 'Gyro Z', 'value': '${sensorData.imu.gyroscope.z.toStringAsFixed(3)} rad/s'},
        ];
        break;
        
      case 'LiDAR Status':
        sensorInfo['title'] = '🎯 LiDAR Status';
        sensorInfo['data'] = [
          {'label': 'Status', 'value': sensorData.lidar},
          {'label': 'Last Update', 'value': DateTime.now().toString().substring(11, 19)},
        ];
        break;
        
      case 'Temperature':
        sensorInfo['title'] = '🌡️ Motor Temperature';
        sensorInfo['data'] = [
          {'label': 'Average Temp', 'value': 'N/A°C'},
          {'label': 'Status', 'value': 'Monitoring'},
        ];
        break;
        
      case 'Wheel Motors':
        sensorInfo['title'] = '⚙️ Wheel Motors';
        sensorInfo['data'] = [
          {'label': 'Status', 'value': 'Active'},
          {'label': 'Motors', 'value': '4 Connected'},
        ];
        break;
        
      case 'Server Link':
        sensorInfo['title'] = '☁️ Server Connection';
        sensorInfo['data'] = [
          {'label': 'Status', 'value': 'Connected'},
          {'label': 'Last Update', 'value': DateTime.now().toString().substring(11, 19)},
        ];
        break;
        
      default:
        sensorInfo['title'] = '📊 Unknown Sensor';
        sensorInfo['data'] = [
          {'label': 'Status', 'value': 'No Data'},
        ];
        break;
    }
    
    return sensorInfo;
  }
}
