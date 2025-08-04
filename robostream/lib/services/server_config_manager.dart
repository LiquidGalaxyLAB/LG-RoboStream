import 'package:shared_preferences/shared_preferences.dart';

class ServerConfigManager {
  static const String _serverIpKey = 'server_ip';
  static const String _serverPortKey = 'server_port';
  static const String _defaultPort = '8000';
  
  static ServerConfigManager? _instance;
  static ServerConfigManager get instance => _instance ??= ServerConfigManager._internal();
  
  ServerConfigManager._internal();

  Future<void> saveServerIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverIpKey, ip.trim());
    } catch (e) {
    }
  }

  Future<String?> getSavedServerIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_serverIpKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveServerPort(String port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverPortKey, port.trim());
    } catch (e) {
    }
  }

  Future<String> getSavedServerPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_serverPortKey) ?? _defaultPort;
    } catch (e) {
      return _defaultPort;
    }
  }

  Future<String?> getServerUrl() async {
    final ip = await getSavedServerIp();
    if (ip == null || ip.isEmpty) {
      return null;
    }
    final port = await getSavedServerPort();
    return 'http://$ip:$port';
  }

  Future<void> clearServerConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_serverIpKey);
      await prefs.remove(_serverPortKey);
    } catch (e) {
    }
  }

  Future<bool> hasServerConfig() async {
    final ip = await getSavedServerIp();
    return ip != null && ip.isNotEmpty;
  }
}
