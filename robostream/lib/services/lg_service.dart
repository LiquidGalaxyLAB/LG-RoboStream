// Contenido para: lib/data/services/lg_service.dart

import 'package:dartssh2/dartssh2.dart';

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

  // Aunque no envíes comandos ahora, es buena práctica tener el método para desconectar.
  void disconnect() {
    _client?.close();
    _client = null;
  }
}