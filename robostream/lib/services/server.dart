import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:robostream/config/server_config.dart';

// Modelos de datos que coinciden con el servidor FastAPI
class ThreeAxisData {
  final double x;
  final double y;
  final double z;

  ThreeAxisData({required this.x, required this.y, required this.z});

  factory ThreeAxisData.fromJson(Map<String, dynamic> json) {
    return ThreeAxisData(
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      z: json['z']?.toDouble() ?? 0.0,
    );
  }
}

class IMUData {
  final ThreeAxisData accelerometer;
  final ThreeAxisData gyroscope;
  final ThreeAxisData magnetometer;

  IMUData({
    required this.accelerometer,
    required this.gyroscope,
    required this.magnetometer,
  });

  factory IMUData.fromJson(Map<String, dynamic> json) {
    return IMUData(
      accelerometer: ThreeAxisData.fromJson(json['accelerometer'] ?? {}),
      gyroscope: ThreeAxisData.fromJson(json['gyroscope'] ?? {}),
      magnetometer: ThreeAxisData.fromJson(json['magnetometer'] ?? {}),
    );
  }
}

class GPSData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;

  GPSData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
  });

  factory GPSData.fromJson(Map<String, dynamic> json) {
    return GPSData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      altitude: json['altitude']?.toDouble() ?? 0.0,
      speed: json['speed']?.toDouble() ?? 0.0,
    );
  }
}

class RGBCameraData {
  final String cameraId;
  final String resolution;
  final int fps;
  final String status;
  final String currentImage;
  final double imageTimestamp;
  final int imagesAvailable;
  final int rotationInterval;

  RGBCameraData({
    required this.cameraId,
    required this.resolution,
    required this.fps,
    required this.status,
    required this.currentImage,
    required this.imageTimestamp,
    required this.imagesAvailable,
    required this.rotationInterval,
  });

  factory RGBCameraData.fromJson(Map<String, dynamic> json) {
    return RGBCameraData(
      cameraId: json['camera_id'] ?? 'Unknown',
      resolution: json['resolution'] ?? 'Unknown',
      fps: json['fps']?.toInt() ?? 0,
      status: json['status'] ?? 'Offline',
      currentImage: json['current_image'] ?? '',
      imageTimestamp: json['image_timestamp']?.toDouble() ?? 0.0,
      imagesAvailable: json['images_available']?.toInt() ?? 0,
      rotationInterval: json['rotation_interval']?.toInt() ?? 0,
    );
  }
}

class SensorData {
  final double timestamp;
  final IMUData imu;
  final GPSData gps;
  final String lidar;
  final String camera;
  final RGBCameraData? rgbCamera;

  SensorData({
    required this.timestamp,
    required this.imu,
    required this.gps,
    required this.lidar,
    required this.camera,
    this.rgbCamera,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: json['timestamp']?.toDouble() ?? 0.0,
      imu: IMUData.fromJson(json['imu'] ?? {}),
      gps: GPSData.fromJson(json['gps'] ?? {}),
      lidar: json['lidar'] ?? 'Disconnected',
      camera: json['camera'] ?? 'Offline',
      rgbCamera: json['rgb_camera'] != null 
        ? RGBCameraData.fromJson(json['rgb_camera'])
        : null,
    );
  }
}

class ServoData {
  final int speed;
  final double temperature;
  final double consumption;
  final double voltage;
  final String status;

  ServoData({
    required this.speed,
    required this.temperature,
    required this.consumption,
    required this.voltage,
    required this.status,
  });

  factory ServoData.fromJson(Map<String, dynamic> json) {
    return ServoData(
      speed: json['speed']?.toInt() ?? 0,
      temperature: json['temperature']?.toDouble() ?? 0.0,
      consumption: json['consumption']?.toDouble() ?? 0.0,
      voltage: json['voltage']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Unknown',
    );
  }
}

class ActuatorData {
  final ServoData frontLeftWheel;
  final ServoData frontRightWheel;
  final ServoData backLeftWheel;
  final ServoData backRightWheel;

  ActuatorData({
    required this.frontLeftWheel,
    required this.frontRightWheel,
    required this.backLeftWheel,
    required this.backRightWheel,
  });

  factory ActuatorData.fromJson(Map<String, dynamic> json) {
    return ActuatorData(
      frontLeftWheel: ServoData.fromJson(json['front_left_wheel'] ?? {}),
      frontRightWheel: ServoData.fromJson(json['front_right_wheel'] ?? {}),
      backLeftWheel: ServoData.fromJson(json['back_left_wheel'] ?? {}),
      backRightWheel: ServoData.fromJson(json['back_right_wheel'] ?? {}),
    );
  }
}

class RobotServerService {
  // Constants for better performance
  static const Duration _timeout = ServerConfig.requestTimeout;
  static const Duration _updateInterval = ServerConfig.updateInterval;
  
  Timer? _timer;
  SensorData? _lastSensorData;
  ActuatorData? _lastActuatorData;
  bool _isConnected = false;
  String _currentBaseUrl = ServerConfig.baseUrl;
  bool _isStreaming = false; // Estado del streaming
  
  // Stream controllers para datos en tiempo real
  final _sensorController = StreamController<SensorData>.broadcast();
  final _actuatorController = StreamController<ActuatorData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  // Getters para los streams
  Stream<SensorData> get sensorStream => _sensorController.stream;
  Stream<ActuatorData> get actuatorStream => _actuatorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  
  // Getters para datos actuales
  SensorData? get currentSensorData => _lastSensorData;
  ActuatorData? get currentActuatorData => _lastActuatorData;
  bool get isConnected => _isConnected;
  String get currentBaseUrl => _currentBaseUrl;
  bool get isStreaming => _isStreaming;

  // Actualizar la URL del servidor
  void updateServerUrl(String newUrl) {
    // Si estamos cambiando la URL y actualmente hay streaming, detenerlo
    if (_currentBaseUrl != newUrl && _isStreaming) {
      stopStreaming();
    }
    
    _currentBaseUrl = newUrl;
    _updateConnectionStatus(false); // Reset connection status
  }  // Iniciar las solicitudes periódicas con el intervalo configurado
  void startPeriodicRequests() {
    stopPeriodicRequests(); // Asegurar que no hay timers duplicados
    
    _timer = Timer.periodic(_updateInterval, (timer) {
      if (_isStreaming) {
        _fetchAllData();
      }
    });
    
    // Hacer la primera solicitud inmediatamente si está streaming
    if (_isStreaming) {
      _fetchAllData();
    }
  }

  // Detener las solicitudes periódicas
  void stopPeriodicRequests() {
    _timer?.cancel();
    _timer = null;
  }  // Iniciar el streaming de datos
  void startStreaming() {
    if (!_isStreaming) {
      _isStreaming = true;
      _updateConnectionStatus(false); // Reset connection status
      startPeriodicRequests(); // Iniciar el temporizador
    }
  }
  // Detener el streaming de datos
  void stopStreaming() {
    if (_isStreaming) {
      _isStreaming = false;
      stopPeriodicRequests(); // Detener el temporizador
      _updateConnectionStatus(false);
    }
  }

  // Alternar el estado del streaming
  void toggleStreaming() {
    if (_isStreaming) {
      stopStreaming();
    } else {
      startStreaming();
    }
  }

  // Obtener datos de sensores
  Future<SensorData?> getSensorData() async {
    try {      final response = await http.get(
        Uri.parse('$_currentBaseUrl/sensors'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final sensorData = SensorData.fromJson(jsonData);
        _lastSensorData = sensorData;
        _updateConnectionStatus(true);
        return sensorData;
      } else {
        _updateConnectionStatus(false);        return null;
      }
    } catch (e) {
      _updateConnectionStatus(false);
      return null;
    }
  }

  // Obtener datos de actuadores
  Future<ActuatorData?> getActuatorData() async {
    try {      final response = await http.get(
        Uri.parse('$_currentBaseUrl/actuators'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final actuatorData = ActuatorData.fromJson(jsonData);
        _lastActuatorData = actuatorData;
        return actuatorData;
      } else {        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Obtener datos específicos de la cámara RGB
  Future<RGBCameraData?> getRGBCameraData() async {
    try {
      final response = await http.get(
        Uri.parse('$_currentBaseUrl/rgb-camera'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RGBCameraData.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Obtener datos completos de la cámara RGB con metadatos
  Future<Map<String, dynamic>?> getRGBCameraImageData() async {
    try {
      final response = await http.get(
        Uri.parse('$_currentBaseUrl/rgb-camera/image-data'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Obtener URL de la imagen actual de la cámara RGB
  String getRGBCameraImageUrl() {
    return '$_currentBaseUrl/rgb-camera/image';
  }

  // Verificar conexión con el servidor
  Future<bool> checkConnection() async {
    try {      final response = await http.get(
        Uri.parse('$_currentBaseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final isConnected = response.statusCode == 200;
      _updateConnectionStatus(isConnected);
      return isConnected;
    } catch (e) {
      _updateConnectionStatus(false);
      return false;
    }
  }

  // Obtener todos los datos de una vez
  Future<void> _fetchAllData() async {
    try {
      // Obtener datos de sensores y actuadores en paralelo
      final results = await Future.wait([
        getSensorData(),
        getActuatorData(),
      ]);

      final sensorData = results[0] as SensorData?;
      final actuatorData = results[1] as ActuatorData?;

      // Enviar datos a los streams si están disponibles
      if (sensorData != null) {
        _sensorController.add(sensorData);
      }
      if (actuatorData != null) {
        _actuatorController.add(actuatorData);      }
    } catch (e) {
      // Error handling without print
    }
  }

  // Actualizar estado de conexión
  void _updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionController.add(connected);
    }
  }

  // Limpiar recursos
  void dispose() {
    stopPeriodicRequests();
    _sensorController.close();
    _actuatorController.close();
    _connectionController.close();
  }
}