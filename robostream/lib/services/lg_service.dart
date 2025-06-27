// Contenido para: lib/data/services/lg_service.dart

import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';

class LGService {
  final String _host;
  final String _username;
  final String _password;
  SSHClient? _client;

  LGService({
    required String host,
    required String username,
    required String password,
  })  : _host = host,
        _username = username,
        _password = password;

  /// Establece la conexión SSH con Liquid Galaxy.
  /// Devuelve 'true' si la conexión es exitosa, 'false' en caso contrario.
  Future<bool> connect() async {
    try {
      final socket = await SSHSocket.connect(_host, 22);
      _client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _password,
      );
      
      // Ejecutamos un comando simple para verificar que la autenticación es correcta.
      // Si esto falla, lanzará una excepción.
      await _client!.run('echo "Connection successful"');
      
      return true;
    } catch (e) {
      _client?.close(); // Cerramos si algo ha fallado.
      _client = null;
      return false;
    }
  }

  /// Envía un archivo por SCP al Liquid Galaxy
  Future<bool> sendFile(String localAssetPath, String remotePath) async {
    if (_client == null) return false;
    
    try {
      // Cargar el archivo desde los assets
      final ByteData data = await rootBundle.load(localAssetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Enviar archivo por SFTP
      final sftp = await _client!.sftp();
      final file = await sftp.open(remotePath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await file.writeBytes(bytes);
      await file.close();
      sftp.close();
      
      return true;
    } catch (e) {
      print('Error sending file: $e');
      return false;
    }
  }

  /// Ejecuta un comando SSH en el Liquid Galaxy
  Future<bool> sendLGCommand(String command) async {
    if (_client == null) return false;
    
    try {
      await _client!.run(command);
      return true;
    } catch (e) {
      print('Error executing command: $e');
      return false;
    }
  }

  /// Muestra el logo de RoboStream usando KML
  Future<void> showLogoUsingKML() async {
    // Primero enviar el logo
    await sendFile('lib/assets/Images/ROBOSTREAM_FINAL_LOGO.png', '/var/www/html/robostream_logo.png');
    
    // Luego enviar el KML
    final kmlCommand = '''echo '<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>RoboStreamLogo</name>
    <ScreenOverlay>
      <name>RoboStreamLogo</name>
      <Icon>
        <href>http://$_host:81/robostream_logo.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY  x="0.02" y="0.98" xunits="fraction" yunits="fraction"/>
      <size     x="150" y="150" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>' > /var/www/html/kml/slave_3.kml''';
    
    await sendLGCommand(kmlCommand);
  }

  // Aunque no envíes comandos ahora, es buena práctica tener el método para desconectar.
  void disconnect() {
    _client?.close();
    _client = null;
  }
}