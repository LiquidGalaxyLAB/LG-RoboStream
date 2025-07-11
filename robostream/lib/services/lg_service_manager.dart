import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'server.dart';
import 'slave_calculator.dart';

/// Configuration service for Liquid Galaxy settings
class LGConfigService {
  // Keys for SharedPreferences
  static const String _lgHostKey = 'lg_host';
  static const String _lgUsernameKey = 'lg_username';
  static const String _lgPasswordKey = 'lg_password';
  static const String _lgTotalScreensKey = 'lg_total_screens';
  
  // Default values
  static const String _defaultTotalScreens = '3';

  /// Saves Liquid Galaxy configuration persistently
  static Future<void> saveLGConfig({
    required String host,
    required String username,
    required String password,
    int totalScreens = 3,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lgHostKey, host.trim());
      await prefs.setString(_lgUsernameKey, username.trim());
      await prefs.setString(_lgPasswordKey, password);
      await prefs.setInt(_lgTotalScreensKey, totalScreens);
    } catch (e) {
      // Error saving LG config - silent fail
    }
  }

  /// Gets all LG configuration
  static Future<Map<String, String>> getLGConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'host': prefs.getString(_lgHostKey) ?? '',
        'username': prefs.getString(_lgUsernameKey) ?? '',
        'password': prefs.getString(_lgPasswordKey) ?? '',
        'totalScreens': prefs.getInt(_lgTotalScreensKey)?.toString() ?? _defaultTotalScreens,
      };
    } catch (e) {
      return {
        'host': '',
        'username': '',
        'password': '',
        'totalScreens': _defaultTotalScreens,
      };
    }
  }

  /// Gets the total number of screens
  static Future<int> getTotalScreens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lgTotalScreensKey) ?? int.parse(_defaultTotalScreens);
    } catch (e) {
      return int.parse(_defaultTotalScreens);
    }
  }

  /// Clears all LG configuration
  static Future<void> clearLGConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lgHostKey);
      await prefs.remove(_lgUsernameKey);
      await prefs.remove(_lgPasswordKey);
      await prefs.remove(_lgTotalScreensKey);
    } catch (e) {
      // Error clearing LG config - silent fail
    }
  }
}

/// Builds KML documents for Liquid Galaxy visualization
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

/// Sends KML content and manages files on Liquid Galaxy
class KMLSender {
  final SSHClient _client;
  final SlaveCalculator _slaveCalculator;

  KMLSender({
    required SSHClient client,
    required SlaveCalculator slaveCalculator,
  }) : _client = client, _slaveCalculator = slaveCalculator;

  Future<bool> sendKMLToSlave(String kmlContent, int slaveNumber) async {
    try {
      final kmlCommand = '''echo '$kmlContent' > /var/www/html/kml/slave_$slaveNumber.kml''';
      await _client.run(kmlCommand);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sends KML content to the leftmost screen (for logo)
  Future<bool> sendKMLToLeftmostScreen(String kmlContent) async {
    return await sendKMLToSlave(kmlContent, _slaveCalculator.leftmostScreen);
  }

  /// Sends KML content to the rightmost screen (for data and camera)
  Future<bool> sendKMLToRightmostScreen(String kmlContent) async {
    return await sendKMLToSlave(kmlContent, _slaveCalculator.rightmostScreen);
  }

  /// Sends image to the rightmost screen (for camera data)
  Future<bool> sendImageToRightmostScreen(Uint8List imageBytes, String fileName) async {
    try {
      final baseName = fileName.split('_').first;
      await cleanupOldImages('${baseName}_*.png');
      
      final base64Image = base64Encode(imageBytes);
      final imageCommand = '''echo '$base64Image' | base64 -d > /var/www/html/$fileName''';
      await _client.run(imageCommand);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the rightmost screen number
  int get rightmostScreen => _slaveCalculator.rightmostScreen;

  Future<bool> clearSlave(int slaveNumber) async {
    const emptyKML = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';
    
    return await sendKMLToSlave(emptyKML, slaveNumber);
  }

  Future<bool> clearAllSlaves() async {
    bool success = true;
    
    for (int i = 1; i <= _slaveCalculator.totalScreens; i++) {
      final result = await clearSlave(i);
      if (!result) success = false;
    }
    
    return success;
  }

  Future<bool> cleanupOldImages(String pattern) async {
    try {
      final cleanupCommand = '''find /var/www/html/ -name "$pattern" -type f -mmin +5 -delete''';
      await _client.run(cleanupCommand);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Handles file operations and command execution for Liquid Galaxy
class LGFileManager {
  final SSHClient _client;

  LGFileManager({required SSHClient client}) : _client = client;

  /// Sends a file from local assets to remote path
  Future<bool> sendFile(String localAssetPath, String remotePath) async {
    try {
      final ByteData data = await rootBundle.load(localAssetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      return await sendBytes(bytes, remotePath);
    } catch (e) {
      return false;
    }
  }

  /// Sends raw bytes to remote path
  Future<bool> sendBytes(Uint8List bytes, String remotePath) async {
    try {
      final sftp = await _client.sftp();
      final file = await sftp.open(remotePath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await file.writeBytes(bytes);
      await file.close();
      sftp.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Executes a command on the Liquid Galaxy system
  Future<bool> sendLGCommand(String command) async {
    try {
      await _client.run(command);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Manages SSH connections and authentication for Liquid Galaxy
class LGConnectionManager {
  final String _host;
  final String _username;
  final String _password;
  final int _totalScreens;
  
  SSHClient? _client;
  KMLBuilder? _kmlBuilder;
  KMLSender? _kmlSender;
  SlaveCalculator? _slaveCalculator;

  LGConnectionManager({
    required String host,
    required String username,
    required String password,
    required int totalScreens,
  })  : _host = host,
        _username = username,
        _password = password,
        _totalScreens = totalScreens;

  // Essential getters only
  String get host => _host;
  SSHClient? get client => _client;
  KMLBuilder? get kmlBuilder => _kmlBuilder;
  KMLSender? get kmlSender => _kmlSender;
  bool get isConnected => _client != null;

  /// Establishes SSH connection and initializes services
  Future<bool> connect() async {
    try {
      final socket = await SSHSocket.connect(_host, 22);
      _client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _password,
      );
      
      if (_client == null) return false;
      
      await _client!.run('echo "Connection successful"');
      
      _slaveCalculator = SlaveCalculator(totalScreens: _totalScreens);
      _kmlBuilder = KMLBuilder(lgHost: _host);
      _kmlSender = KMLSender(client: _client!, slaveCalculator: _slaveCalculator!);
      
      return true;
    } catch (e) {
      _client?.close();
      _client = null;
      _kmlBuilder = null;
      _kmlSender = null;
      return false;
    }
  }

  /// Disconnects from SSH and cleans up resources
  void disconnect() {
    _client?.close();
    _client = null;
    _kmlBuilder = null;
    _kmlSender = null;
  }
}
