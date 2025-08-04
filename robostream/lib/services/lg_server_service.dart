import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:robostream/services/lg_config_service.dart';

class LoginResult {
  final bool success;
  final String message;
  
  const LoginResult({required this.success, required this.message});
}

class LGServerService {
  final String _serverHost;
  
  LGServerService({required String serverHost}) : _serverHost = serverHost;

  static Future<LoginResult> login({
    required String lgIpAddress,
    required String lgUsername,
    required String lgPassword,
    required int totalScreens,
    required String serverHost,
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
      final response = await http.post(
        Uri.parse('http://$serverHost:8000/lg/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host': lgIpAddress,
          'username': lgUsername,
          'password': lgPassword,
          'total_screens': totalScreens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          await LGConfigService.saveLGConfig(
            host: lgIpAddress,
            username: lgUsername,
            password: lgPassword,
            totalScreens: totalScreens,
          );
        }
        
        return LoginResult(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Unknown response'
        );
      } else {
        return LoginResult(
          success: false,
          message: 'Server error: ${response.statusCode}'
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Connection error: ${e.toString()}'
      );
    }
  }

  Future<bool> showLogo() async {
    try {
      final url = 'http://$_serverHost:8000/lg/show-logo';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> showRGBCameraImage() async {
    try {
      final url = 'http://$_serverHost:8000/lg/show-camera';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'server_host': _serverHost,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> showSensorData(List<String> selectedSensors) async {
    if (selectedSensors.isEmpty) return false;
    
    try {
      final url = 'http://$_serverHost:8000/lg/show-sensors';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'selected_sensors': selectedSensors,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hideSensorData() async {
    try {
      final response = await http.post(
        Uri.parse('http://$_serverHost:8000/lg/hide-sensors'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final response = await http.post(
        Uri.parse('http://$_serverHost:8000/lg/disconnect'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
