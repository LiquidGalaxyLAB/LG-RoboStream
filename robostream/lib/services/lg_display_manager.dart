import 'dart:typed_data';
import 'kml_builder.dart';
import 'kml_sender.dart';
import 'lg_file_manager.dart';
import 'image_generator.dart';
import 'server.dart';

/// Handles display operations for Liquid Galaxy screens
class LGDisplayManager {
  final String _host;
  final LGFileManager _fileManager;
  final KMLBuilder _kmlBuilder;
  final KMLSender _kmlSender;

  LGDisplayManager({
    required String host,
    required LGFileManager fileManager,
    required KMLBuilder kmlBuilder,
    required KMLSender kmlSender,
  })  : _host = host,
        _fileManager = fileManager,
        _kmlBuilder = kmlBuilder,
        _kmlSender = kmlSender;

  /// Shows the RoboStream logo on the leftmost screen
  Future<bool> showLogoUsingKML() async {
    bool logoSent = await _fileManager.sendFile(
      'lib/assets/Images/ROBOSTREAM_FINAL_LOGO.png',
      '/var/www/html/robostream_logo.png'
    );
    if (!logoSent) return false;
    
    String logoKML = _kmlBuilder.buildLogoKML();
    return await _kmlSender.sendKMLToLeftmostScreen(logoKML);
  }

  /// Shows RGB camera image on the rightmost screen
  Future<bool> showRGBCameraImage(String serverHost) async {
    String cameraKML = _kmlBuilder.buildCameraKML(serverHost);
    return await _kmlSender.sendKMLToRightmostScreen(cameraKML);
  }

  /// Shows sensor data overlays on the rightmost screen
  Future<bool> showSensorData(SensorData sensorData, List<String> selectedSensors) async {
    if (selectedSensors.isEmpty) return false;
    
    List<String> sensorOverlays = [];
    bool allImagesUploaded = true;
    
    for (String selectedSensor in selectedSensors) {
      if (selectedSensor == 'RGB Camera') {
        String cameraOverlay = _buildCameraOverlay(sensorOverlays.length);
        sensorOverlays.add(cameraOverlay);
        continue;
      }
      
      Map<String, dynamic> sensorInfo = _kmlBuilder.buildSensorData(sensorData, selectedSensor);
      
      Uint8List imageBytes = await ImageGenerator.generateSensorImage(sensorInfo);
      
      String imageName = sensorInfo['imageName'] as String;
      bool imageSent = await _kmlSender.sendImageToRightmostScreen(imageBytes, imageName);
      if (!imageSent) {
        allImagesUploaded = false;
        continue;
      }
      
      String sensorOverlay = _buildSensorOverlay(selectedSensor, imageName, sensorOverlays.length);
      sensorOverlays.add(sensorOverlay);
    }
    
    String combinedKML = _buildCombinedKML(sensorOverlays);
    bool kmlSent = await _kmlSender.sendKMLToRightmostScreen(combinedKML);
    
    return allImagesUploaded && kmlSent;
  }

  /// Hides sensor data from the rightmost screen
  Future<bool> hideSensorData() async {
    return await _kmlSender.clearSlave(_kmlSender.rightmostScreen);
  }

  /// Builds camera overlay KML
  String _buildCameraOverlay(int overlayIndex) {
    double xPosition = 0.98 - (overlayIndex * 0.2);
    return '''
      <ScreenOverlay>
        <name>RGBCamera</name>
        <Icon>
          <href>http://$_host:8000/rgb-camera/image</href>
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
          <href>http://$_host:81/$imageName</href>
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
