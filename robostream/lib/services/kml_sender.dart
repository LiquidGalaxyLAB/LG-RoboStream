import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';

class KMLSender {
  final SSHClient _client;

  KMLSender({required SSHClient client}) : _client = client;

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
    
    for (int i = 1; i <= 5; i++) {
      final result = await clearSlave(i);
      if (!result) success = false;
    }
    
    return success;
  }

  Future<bool> sendImagePNG(Uint8List imageBytes, String fileName) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final imageCommand = '''echo '$base64Image' | base64 -d > /var/www/html/$fileName''';
      await _client.run(imageCommand);
      return true;
    } catch (e) {
      return false;
    }
  }
}
