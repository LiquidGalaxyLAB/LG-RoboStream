import 'package:shared_preferences/shared_preferences.dart';

class ServerConfigManager {
  static const String _serverIpKey = 'server_ip';
  static const String _serverPortKey = 'server_port';
  static const String _defaultPort = '8000';
  
  static ServerConfigManager? _instance;
  static ServerConfigManager get instance => _instance ??= ServerConfigManager._internal();
  
  ServerConfigManager._internal();

  /// Guarda la IP del servidor
  Future<void> saveServerIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverIpKey, ip.trim());
    } catch (e) {
      print('Error saving server IP: $e');
    }
  }

  /// Obtiene la IP del servidor guardada
  Future<String?> getSavedServerIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_serverIpKey);
    } catch (e) {
      print('Error getting saved server IP: $e');
      return null;
    }
  }

  /// Guarda el puerto del servidor
  Future<void> saveServerPort(String port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverPortKey, port.trim());
    } catch (e) {
      print('Error saving server port: $e');
    }
  }

  /// Obtiene el puerto del servidor guardado
  Future<String> getSavedServerPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_serverPortKey) ?? _defaultPort;
    } catch (e) {
      print('Error getting saved server port: $e');
      return _defaultPort;
    }
  }

  /// Construye la URL completa del servidor
  Future<String?> getServerUrl() async {
    final ip = await getSavedServerIp();
    if (ip == null || ip.isEmpty) {
      return null;
    }
    final port = await getSavedServerPort();
    return 'http://$ip:$port';
  }

  /// Limpia toda la configuración del servidor
  Future<void> clearServerConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_serverIpKey);
      await prefs.remove(_serverPortKey);
    } catch (e) {
      print('Error clearing server config: $e');
    }
  }

  /// Verifica si hay una configuración de servidor guardada
  Future<bool> hasServerConfig() async {
    final ip = await getSavedServerIp();
    return ip != null && ip.isNotEmpty;
  }
}
