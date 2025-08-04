import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:robostream/services/server_config_manager.dart';

class RobotConfigManager {
  static const String _robotIpKey = 'robot_ip';
  
  static RobotConfigManager? _instance;
  static RobotConfigManager get instance => _instance ??= RobotConfigManager._internal();
  
  RobotConfigManager._internal();

  Future<void> saveRobotIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_robotIpKey, ip.trim());

      await _sendRobotIpToServer(ip.trim());
    } catch (e) {
    }
  }

  Future<String?> getSavedRobotIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_robotIpKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendRobotIpToServer(String robotIp) async {
    try {
      final serverUrl = await ServerConfigManager.instance.getServerUrl();
      if (serverUrl != null) {
        final response = await http.post(
          Uri.parse('$serverUrl/set-robot-ip'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'robot_ip': robotIp}),
        );
        
        if (response.statusCode != 200) {
        }
      }
    } catch (e) {
    }
  }

  Future<void> clearRobotConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_robotIpKey);
    } catch (e) {
    }
  }

  Future<bool> hasRobotConfig() async {
    final ip = await getSavedRobotIp();
    return ip != null && ip.isNotEmpty;
  }
}
