import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'server.dart';
import 'kml_builder.dart';
import 'kml_sender.dart';
import 'image_generator.dart';

class SensorOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  bool isSelected;

  SensorOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isSelected = false,
  });
}

class LGService {
  final String _host;
  final String _username;
  final String _password;
  SSHClient? _client;
  KMLBuilder? _kmlBuilder;
  KMLSender? _kmlSender;

  LGService({
    required String host,
    required String username,
    required String password,
  })  : _host = host,
        _username = username,
        _password = password;

  Future<bool> connect() async {
    try {
      final socket = await SSHSocket.connect(_host, 22);
      _client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _password,
      );
      
      await _client!.run('echo "Connection successful"');
      
      _kmlBuilder = KMLBuilder(lgHost: _host);
      _kmlSender = KMLSender(client: _client!);
      
      return true;
    } catch (e) {
      _client?.close();
      _client = null;
      _kmlBuilder = null;
      _kmlSender = null;
      return false;
    }
  }

  Future<bool> sendFile(String localAssetPath, String remotePath) async {
    if (_client == null) return false;
    
    try {
      final ByteData data = await rootBundle.load(localAssetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      final sftp = await _client!.sftp();
      final file = await sftp.open(remotePath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await file.writeBytes(bytes);
      await file.close();
      sftp.close();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendLGCommand(String command) async {
    if (_client == null) {
      return false;
    }

    try {
      await _client!.run(command);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> showLogoUsingKML() async {
    if (_kmlBuilder == null || _kmlSender == null) return false;
    
    bool logoSent = await sendFile('lib/assets/Images/ROBOSTREAM_FINAL_LOGO.png', '/var/www/html/robostream_logo.png');
    if (!logoSent) return false;
    
    String logoKML = _kmlBuilder!.buildLogoKML();
    return await _kmlSender!.sendKMLToSlave(logoKML, 3);
  }

  Future<bool> showRGBCameraImage(String serverHost) async {
    if (_kmlBuilder == null || _kmlSender == null) return false;
    
    String cameraKML = _kmlBuilder!.buildCameraKML(serverHost);
    return await _kmlSender!.sendKMLToSlave(cameraKML, 2);
  }

  Future<bool> showSensorData(SensorData sensorData, List<String> selectedSensors) async {
    if (_kmlBuilder == null || _kmlSender == null || selectedSensors.isEmpty) return false;
    
    List<String> sensorOverlays = [];
    bool allImagesUploaded = true;
    
    for (String selectedSensor in selectedSensors) {
      if (selectedSensor == 'RGB Camera') {
        String serverHost = _host;
        int overlayIndex = sensorOverlays.length;
        double xPosition = 0.98 - (overlayIndex * 0.2);
        String cameraOverlay = '''
      <ScreenOverlay>
        <name>RGBCamera</name>
        <Icon>
          <href>http://$serverHost:8000/rgb-camera/image</href>
        </Icon>
        <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="$xPosition" y="0.98" xunits="fraction" yunits="fraction"/>
        <size x="0.15" y="0.12" xunits="fraction" yunits="fraction"/>
      </ScreenOverlay>''';
        sensorOverlays.add(cameraOverlay);
        continue;
      }
      
      Map<String, dynamic> sensorInfo = _kmlBuilder!.buildSensorData(sensorData, selectedSensor);
      
      Uint8List imageBytes = await ImageGenerator.generateSensorImage(sensorInfo);
      
      String imageName = sensorInfo['imageName'] as String;
      bool imageSent = await _kmlSender!.sendImagePNG(imageBytes, imageName);
      if (!imageSent) {
        allImagesUploaded = false;
        continue;
      }
      
      int overlayIndex = sensorOverlays.length;
      double xPosition = 0.98 - (overlayIndex * 0.2);
      String sensorOverlay = '''
      <ScreenOverlay>
        <name>$selectedSensor</name>
        <Icon>
          <href>http://$_host:81/$imageName</href>
        </Icon>
        <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="$xPosition" y="0.98" xunits="fraction" yunits="fraction"/>
      </ScreenOverlay>''';
      sensorOverlays.add(sensorOverlay);
    }
    
    String combinedKML = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>MultiSensorData</name>
${sensorOverlays.join('\n')}
  </Document>
</kml>''';
    
    bool kmlSent = await _kmlSender!.sendKMLToSlave(combinedKML, 2);
    
    return allImagesUploaded && kmlSent;
  }

  Future<bool> showSingleSensorData(SensorData sensorData, String selectedSensor) async {
    return await showSensorData(sensorData, [selectedSensor]);
  }

  Future<bool> hideSensorData() async {
    if (_kmlSender == null) return false;
    return await _kmlSender!.clearSlave(2);
  }

  void disconnect() {
    _client?.close();
    _client = null;
    _kmlBuilder = null;
    _kmlSender = null;
  }
}
