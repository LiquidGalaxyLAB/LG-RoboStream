import 'dart:convert';
import 'package:http/http.dart' as http;

class OrbitService {
  final String baseUrl;

  OrbitService({required this.baseUrl});

  Future<bool> startOrbit({
    required double latitude,
    required double longitude,
    int zoom = 4000,
    int tilt = 60,
    int steps = 360,
    int stepMs = 30,
    double startHeading = 0,
  }) async {
    try {

      final response = await http.post(
        Uri.parse('$baseUrl/orbit/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'zoom': zoom.round(),
          'tilt': tilt,
          'steps': steps,
          'step_ms': stepMs,
          'start_heading': startHeading,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true || data['status'] == 'started';
      }
      return false;
    } catch (e) {
      print('Error starting orbit: $e');
      return false;
    }
  }

  Future<bool> startQuickOrbit({
    double latitude = 41.605725,
    double longitude = 0.606787,
    String orbitType = "normal",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orbit/quick-start?latitude=$latitude&longitude=$longitude&orbit_type=$orbitType'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true || data['status'] == 'started';
      }
      return false;
    } catch (e) {
      print('Error starting quick orbit: $e');
      return false;
    }
  }

  Future<bool> startDefaultOrbit() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orbit/default'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true || data['status'] == 'started';
      }
      return false;
    } catch (e) {
      print('Error starting default orbit: $e');
      return false;
    }
  }

  Future<bool> stopOrbit({
    bool force = false,
    double timeout = 2.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orbit/stop?force=$force&timeout=$timeout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true || data['status'] == 'stopped';
      }
      return false;
    } catch (e) {
      print('Error stopping orbit: $e');
      return false;
    }
  }

  Future<bool> isOrbitRunning() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orbit/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_running'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking orbit status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrbitConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orbit/config'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting orbit config: $e');
      return null;
    }
  }
}
