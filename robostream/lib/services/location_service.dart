import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  final String baseUrl;

  LocationService({required this.baseUrl});

  Future<Map<String, dynamic>?> getGPSSimulationZones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/gps-simulation-zones'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting GPS simulation zones: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrbitCoordinates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/orbit-coordinates'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting orbit coordinates: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRobotPositions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/robot-positions'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting robot positions: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrbitParameters(String orbitType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/orbit-parameters?orbit_type=$orbitType'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting orbit parameters: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLocationInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/info'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting location info: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> setLocation(String locationName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/set?location_name=$locationName'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error setting location: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGPSStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/gps-status'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting GPS status: $e');
      return null;
    }
  }
}
