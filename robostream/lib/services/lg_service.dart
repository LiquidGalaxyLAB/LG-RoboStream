import 'server.dart';
import 'lg_config_service.dart';
import 'lg_connection_manager.dart';
import 'lg_file_manager.dart';
import 'image_generator.dart';

// Login result class to handle login responses
class LoginResult {
  final bool success;
  final String message;
  
  const LoginResult({required this.success, required this.message});
}

/// Main service class that orchestrates Liquid Galaxy operations
class LGService {
  final LGConnectionManager _connectionManager;
  LGFileManager? _fileManager;

  LGService({
    required String host,
    required String username,
    required String password,
    required int totalScreens,
  }) : _connectionManager = LGConnectionManager(
          host: host,
          username: username,
          password: password,
          totalScreens: totalScreens,
        );

  /// Getters for accessing managers
  bool get isConnected => _connectionManager.isConnected;

  /// Performs login with validation and connection test
  static Future<LoginResult> login({
    required String lgIpAddress,
    required String lgUsername,
    required String lgPassword,
    required int totalScreens,
  }) async {
    if (lgIpAddress.isEmpty ||
        lgUsername.isEmpty ||
        lgPassword.isEmpty ||
        totalScreens <= 0) {
      return const LoginResult(
        success: false,
        message: 'Please fill in all fields correctly.'
      );
    }

    try {
      final lgService = LGService(
        host: lgIpAddress,
        username: lgUsername,
        password: lgPassword,
        totalScreens: totalScreens,
      );

      final bool isConnected = await lgService.connect();

      if (isConnected) {
        await lgService.showLogoUsingKML();
        
        await LGConfigService.saveLGConfig(
          host: lgIpAddress,
          username: lgUsername,
          password: lgPassword,
          totalScreens: totalScreens,
        );
        
        return const LoginResult(
          success: true,
          message: 'Connected successfully. Configuration saved automatically.'
        );
      } else {
        return const LoginResult(
          success: false,
          message: 'Could not connect to Liquid Galaxy. Verify the connection details.'
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Connection error: ${e.toString()}'
      );
    }
  }

  /// Establishes connection and initializes managers
  Future<bool> connect() async {
    final bool connected = await _connectionManager.connect();
    
    if (connected && _connectionManager.client != null) {
      _fileManager = LGFileManager(client: _connectionManager.client!);
    }
    
    return connected;
  }

  /// Shows the RoboStream logo using KMLBuilder and KMLSender
  Future<bool> showLogoUsingKML() async {
    if (!isConnected) return false;
    
    // Send logo file first
    bool logoSent = await _fileManager!.sendFile(
      'lib/assets/Images/ROBOSTREAM_FINAL_LOGO.png',
      '/var/www/html/robostream_logo.png'
    );
    if (!logoSent) return false;
    
    // Generate and send KML
    String logoKML = _connectionManager.kmlBuilder!.buildLogoKML();
    return await _connectionManager.kmlSender!.sendKMLToLeftmostScreen(logoKML);
  }

  /// Shows RGB camera image using KMLBuilder and KMLSender
  Future<bool> showRGBCameraImage(String serverHost) async {
    if (!isConnected) return false;
    
    String cameraKML = _connectionManager.kmlBuilder!.buildCameraKML(serverHost);
    return await _connectionManager.kmlSender!.sendKMLToRightmostScreen(cameraKML);
  }

  /// Shows sensor data overlays using existing services
  Future<bool> showSensorData(SensorData sensorData, List<String> selectedSensors) async {
    if (!isConnected || selectedSensors.isEmpty) return false;
    
    print('🚀 Mostrando datos de sensores en LG: ${selectedSensors.join(", ")}');
    
    List<String> sensorOverlays = [];
    bool allImagesUploaded = true;
    
    for (String selectedSensor in selectedSensors) {
      if (selectedSensor == 'RGB Camera') {
        String cameraOverlay = _buildCameraOverlay(sensorOverlays.length);
        sensorOverlays.add(cameraOverlay);
        continue;
      }
      
      // Use KMLBuilder to get sensor info
      Map<String, dynamic> sensorInfo = _connectionManager.kmlBuilder!.buildSensorData(sensorData, selectedSensor);
      
      // Generate image
      var imageBytes = await ImageGenerator.generateSensorImage(sensorInfo);
      
      String imageName = sensorInfo['imageName'] as String;
      bool imageSent = await _connectionManager.kmlSender!.sendImageToRightmostScreen(imageBytes, imageName);
      if (!imageSent) {
        print('❌ Error al enviar imagen para sensor: $selectedSensor');
        allImagesUploaded = false;
        continue;
      }
      
      String sensorOverlay = _buildSensorOverlay(selectedSensor, imageName, sensorOverlays.length);
      sensorOverlays.add(sensorOverlay);
    }
    
    String combinedKML = _buildCombinedKML(sensorOverlays);
    bool kmlSent = await _connectionManager.kmlSender!.sendKMLToRightmostScreen(combinedKML);
    
    if (allImagesUploaded && kmlSent) {
      print('✅ Datos de sensores enviados exitosamente a LG');
    } else {
      print('❌ Error al enviar algunos datos de sensores a LG');
    }
    
    return allImagesUploaded && kmlSent;
  }

  /// Hides sensor data using KMLSender
  Future<bool> hideSensorData() async {
    if (!isConnected) return false;
    return await _connectionManager.kmlSender!.clearSlave(_connectionManager.kmlSender!.rightmostScreen);
  }

  /// Sends a file to the Liquid Galaxy system
  Future<bool> sendFile(String localAssetPath, String remotePath) async {
    if (_fileManager == null) return false;
    return await _fileManager!.sendFile(localAssetPath, remotePath);
  }

  /// Sends a command to the Liquid Galaxy system
  Future<bool> sendLGCommand(String command) async {
    if (_fileManager == null) return false;
    return await _fileManager!.sendLGCommand(command);
  }

  /// Disconnects from the Liquid Galaxy system
  void disconnect() {
    _connectionManager.disconnect();
    _fileManager = null;
  }

  /// Builds camera overlay KML
  String _buildCameraOverlay(int overlayIndex) {
    double xPosition = 0.98 - (overlayIndex * 0.2);
    return '''
      <ScreenOverlay>
        <name>RGBCamera</name>
        <Icon>
          <href>http://${_connectionManager.host}:8000/rgb-camera/image</href>
        </Icon>
        <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="$xPosition" y="0.98" xunits="fraction" yunits="fraction"/>
        <size x="0.15" y="0.12" xunits="fraction" yunits="fraction"/>
      </ScreenOverlay>''';
  }

  /// Builds sensor overlay KML
  String _buildSensorOverlay(String sensorName, String imageName, int overlayIndex) {
    double xPosition = 0.98 - (overlayIndex * 0.2);
    return '''
      <ScreenOverlay>
        <name>$sensorName</name>
        <Icon>
          <href>http://${_connectionManager.host}:81/$imageName</href>
        </Icon>
        <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="$xPosition" y="0.98" xunits="fraction" yunits="fraction"/>
      </ScreenOverlay>''';
  }

  /// Builds combined KML document
  String _buildCombinedKML(List<String> sensorOverlays) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>MultiSensorData</name>
${sensorOverlays.join('\n')}
  </Document>
</kml>''';
  }
}
