import 'server.dart';

class KMLBuilder {
  final String _lgHost;

  KMLBuilder({required String lgHost}) : _lgHost = lgHost;

  String buildLogoKML() {
    return _buildKMLDocument(
      'RoboStreamLogo',
      _buildScreenOverlay(
        'RoboStreamLogo',
        'http://$_lgHost:81/robostream_complete_logo.png',
        overlayXY: '0,1',
        screenXY: '0.02,0.98',
        size: '554,550,pixels',
      ),
    );
  }

  String buildCameraKML(String serverHost) {
    return _buildKMLDocument(
      'RoboStreamCameraFeed',
      _buildScreenOverlay(
        'RGBCamera',
        'http://$serverHost:8000/rgb-camera/image',
        overlayXY: '1,1',
        screenXY: '0.98,0.98',
        size: '400,300,pixels',
      ),
    );
  }

  String buildSensorDataKML(String sensorType) {
    String imageName = _getSensorImageName(sensorType);
    return _buildKMLDocument(
      'RoboStream $sensorType Data',
      _buildScreenOverlay(
        '$sensorType Data',
        'http://$_lgHost:81/$imageName',
        overlayXY: '1,1',
        screenXY: '0.98,0.98',
        size: '0,0,pixels',
      ),
    );
  }

  String buildEmptyKML() {
    return _buildKMLDocument('Empty', '');
  }

  /// Helper method to build KML document structure
  String _buildKMLDocument(String name, String content) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$name</name>
$content
  </Document>
</kml>''';
  }

  /// Helper method to build ScreenOverlay
  String _buildScreenOverlay(String name, String href, {
    required String overlayXY,
    required String screenXY,
    required String size,
  }) {
    final overlayParts = overlayXY.split(',');
    final screenParts = screenXY.split(',');
    final sizeParts = size.split(',');
    
    return '''    <ScreenOverlay>
      <name>$name</name>
      <Icon>
        <href>$href</href>
      </Icon>
      <overlayXY x="${overlayParts[0]}" y="${overlayParts[1]}" xunits="fraction" yunits="fraction"/>
      <screenXY x="${screenParts[0]}" y="${screenParts[1]}" xunits="fraction" yunits="fraction"/>
      <size x="${sizeParts[0]}" y="${sizeParts[1]}" xunits="${sizeParts[2]}" yunits="${sizeParts[2]}"/>
    </ScreenOverlay>''';
  }

  String _getSensorImageName(String sensorType) {
    // Agregar timestamp para forzar actualización de cache
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const sensorImages = {
      'GPS Position': 'gps_data',
      'IMU Sensors': 'imu_data',
      'LiDAR Status': 'lidar_data',
      'Temperature': 'temperature_data',
      'Wheel Motors': 'motors_data',
      'Server Link': 'server_data',
    };
    final baseName = sensorImages[sensorType] ?? 'sensor_data';
    return '${baseName}_$timestamp.png';
  }

  Map<String, dynamic> buildSensorData(SensorData sensorData, String selectedSensor) {
    final sensorConfigs = {
      'GPS Position': {
        'title': '📍 GPS Position',
        'data': [
          {'label': 'Latitude', 'value': '${sensorData.gps.latitude.toStringAsFixed(6)}°'},
          {'label': 'Longitude', 'value': '${sensorData.gps.longitude.toStringAsFixed(6)}°'},
          {'label': 'Altitude', 'value': '${sensorData.gps.altitude.toStringAsFixed(1)} m'},
          {'label': 'Speed', 'value': '${sensorData.gps.speed.toStringAsFixed(2)} m/s'},
        ],
      },
      'IMU Sensors': {
        'title': '⚡ IMU Sensors',
        'data': [
          {'label': 'Accel X', 'value': '${sensorData.imu.accelerometer.x.toStringAsFixed(2)} m/s²'},
          {'label': 'Accel Y', 'value': '${sensorData.imu.accelerometer.y.toStringAsFixed(2)} m/s²'},
          {'label': 'Accel Z', 'value': '${sensorData.imu.accelerometer.z.toStringAsFixed(2)} m/s²'},
          {'label': 'Gyro X', 'value': '${sensorData.imu.gyroscope.x.toStringAsFixed(3)} rad/s'},
          {'label': 'Gyro Y', 'value': '${sensorData.imu.gyroscope.y.toStringAsFixed(3)} rad/s'},
          {'label': 'Gyro Z', 'value': '${sensorData.imu.gyroscope.z.toStringAsFixed(3)} rad/s'},
        ],
      },
      'LiDAR Status': {
        'title': '🎯 LiDAR Status',
        'data': [
          {'label': 'Status', 'value': sensorData.lidar},
          {'label': 'Last Update', 'value': DateTime.now().toString().substring(11, 19)},
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
          {'label': 'Last Update', 'value': DateTime.now().toString().substring(11, 19)},
        ],
      },
    };

    final config = sensorConfigs[selectedSensor] ?? {
      'title': '📊 Unknown Sensor',
      'data': [{'label': 'Status', 'value': 'No Data'}],
    };

    return {
      'title': config['title'],
      'data': config['data'],
      'imageName': _getSensorImageName(selectedSensor),
    };
  }
}
