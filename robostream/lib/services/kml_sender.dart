import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'slave_calculator.dart';

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

  Future<bool> sendHTMLContent(String htmlContent, String fileName) async {
    try {
      final htmlCommand = '''echo '$htmlContent' > /var/www/html/$fileName''';
      await _client.run(htmlCommand);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendCommand(String command) async {
    try {
      await _client.run(command);
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
}
