// Contenido para: lib/data/services/lg_service.dart

import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'server.dart';

// Modelo para los sensores seleccionables
class SensorOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  bool isSelected;

  SensorOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isSelected = false,
  });
}

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
      return false;
    }
  }

  /// Ejecuta un comando SSH en el Liquid Galaxy
  Future<bool> sendLGCommand(String command) async {
    if (_client == null) {
      return false;
    }

    try {
      await _client!.run(command);
      return true;
    } catch (e) {
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

  /// Muestra solo la imagen de la cámara RGB en el slave 2
  Future<void> showRGBCameraImage(String serverHost) async {
    if (_client == null) {
      return;
    }
    
    // Crear KML que muestre la imagen pequeña en la esquina superior derecha del slave 2
    final kmlCommand = '''echo '<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>RoboStreamCameraFeed</name>
    <ScreenOverlay>
      <name>RGBCamera</name>
      <Icon>
        <href>http://$serverHost:8000/rgb-camera/image</href>
      </Icon>
      <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.98" y="0.98" xunits="fraction" yunits="fraction"/>
      <size x="200" y="150" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>' > /var/www/html/kml/slave_2.kml''';
    
    await sendLGCommand(kmlCommand);
  }

  /// Muestra datos de sensores seleccionados en el slave 2
  Future<void> showSensorData(SensorData sensorData, List<String> selectedSensors) async {
    if (_client == null || selectedSensors.isEmpty) return;
    
    String htmlContent = _generateSensorHTML(sensorData, selectedSensors);
    
    // Escribir el archivo HTML al servidor web del LG
    final htmlCommand = '''echo '$htmlContent' > /var/www/html/sensor_data.html''';
    await sendLGCommand(htmlCommand);
    
    // Crear KML que muestre la página HTML en el slave 2
    final kmlCommand = '''echo '<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>RoboStreamSensorData</name>
    <ScreenOverlay>
      <name>SensorData</name>
      <Icon>
        <href>http://$_host:81/sensor_data.html</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <size x="1" y="1" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
  </Document>
</kml>' > /var/www/html/kml/slave_2.kml''';
    
    await sendLGCommand(kmlCommand);
  }

  /// Genera HTML para mostrar los datos de sensores seleccionados
  String _generateSensorHTML(SensorData sensorData, List<String> selectedSensors) {
    String sensorsHTML = '';
    
    for (String sensorType in selectedSensors) {
      switch (sensorType) {
        case 'GPS Position':
          sensorsHTML += '''
            <div class="sensor-card">
              <h2><i class="icon">📍</i> GPS Position</h2>
              <div class="data-grid">
                <div class="data-item">
                  <span class="label">Latitude:</span>
                  <span class="value">${sensorData.gps.latitude.toStringAsFixed(6)}°</span>
                </div>
                <div class="data-item">
                  <span class="label">Longitude:</span>
                  <span class="value">${sensorData.gps.longitude.toStringAsFixed(6)}°</span>
                </div>
                <div class="data-item">
                  <span class="label">Altitude:</span>
                  <span class="value">${sensorData.gps.altitude.toStringAsFixed(1)} m</span>
                </div>
                <div class="data-item">
                  <span class="label">Speed:</span>
                  <span class="value">${sensorData.gps.speed.toStringAsFixed(2)} m/s</span>
                </div>
              </div>
            </div>
          ''';
          break;
        case 'IMU Sensors':
          sensorsHTML += '''
            <div class="sensor-card">
              <h2><i class="icon">⚡</i> IMU Sensors</h2>
              <div class="imu-section">
                <h3>Accelerometer (m/s²)</h3>
                <div class="data-grid">
                  <div class="data-item">
                    <span class="label">X-axis:</span>
                    <span class="value">${sensorData.imu.accelerometer.x.toStringAsFixed(2)}</span>
                  </div>
                  <div class="data-item">
                    <span class="label">Y-axis:</span>
                    <span class="value">${sensorData.imu.accelerometer.y.toStringAsFixed(2)}</span>
                  </div>
                  <div class="data-item">
                    <span class="label">Z-axis:</span>
                    <span class="value">${sensorData.imu.accelerometer.z.toStringAsFixed(2)}</span>
                  </div>
                </div>
              </div>
              <div class="imu-section">
                <h3>Gyroscope (rad/s)</h3>
                <div class="data-grid">
                  <div class="data-item">
                    <span class="label">X-axis:</span>
                    <span class="value">${sensorData.imu.gyroscope.x.toStringAsFixed(3)}</span>
                  </div>
                  <div class="data-item">
                    <span class="label">Y-axis:</span>
                    <span class="value">${sensorData.imu.gyroscope.y.toStringAsFixed(3)}</span>
                  </div>
                  <div class="data-item">
                    <span class="label">Z-axis:</span>
                    <span class="value">${sensorData.imu.gyroscope.z.toStringAsFixed(3)}</span>
                  </div>
                </div>
              </div>
            </div>
          ''';
          break;
        case 'RGB Camera':
          if (sensorData.rgbCamera != null) {
            sensorsHTML += '''
              <div class="sensor-card camera-card">
                <h2><i class="icon">📷</i> RGB Camera Feed</h2>
                <div class="camera-info">
                  <div class="data-grid">
                    <div class="data-item">
                      <span class="label">Camera ID:</span>
                      <span class="value">${sensorData.rgbCamera!.cameraId}</span>
                    </div>
                    <div class="data-item">
                      <span class="label">Resolution:</span>
                      <span class="value">${sensorData.rgbCamera!.resolution}</span>
                    </div>
                    <div class="data-item">
                      <span class="label">Frame Rate:</span>
                      <span class="value">${sensorData.rgbCamera!.fps} FPS</span>
                    </div>
                    <div class="data-item">
                      <span class="label">Status:</span>
                      <span class="value">${sensorData.rgbCamera!.status}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div class="camera-overlay">
                <img src="http://$_host:8000/rgb-camera/image" alt="Live Camera Feed" id="cameraFeed" />
              </div>
            ''';
          }
          break;
        case 'LiDAR Status':
          sensorsHTML += '''
            <div class="sensor-card">
              <h2><i class="icon">🎯</i> LiDAR Status</h2>
              <div class="status-display">
                <span class="status ${sensorData.lidar.toLowerCase()}">${sensorData.lidar}</span>
              </div>
            </div>
          ''';
          break;
        case 'Temperature':
          // Calcular temperatura promedio de los motores si hay datos de actuadores disponibles
          sensorsHTML += '''
            <div class="sensor-card">
              <h2><i class="icon">🌡️</i> Motor Temperature</h2>
              <div class="data-grid">
                <div class="data-item">
                  <span class="label">Average Temp:</span>
                  <span class="value">N/A°C</span>
                </div>
                <div class="data-item">
                  <span class="label">Status:</span>
                  <span class="value">Monitoring</span>
                </div>
              </div>
            </div>
          ''';
          break;
        case 'Wheel Motors':
          sensorsHTML += '''
            <div class="sensor-card">
              <h2><i class="icon">⚙️</i> Wheel Motors</h2>
              <div class="data-grid">
                <div class="data-item">
                  <span class="label">Status:</span>
                  <span class="value">Active</span>
                </div>
                <div class="data-item">
                  <span class="label">Motors:</span>
                  <span class="value">4 Connected</span>
                </div>
              </div>
            </div>
          ''';
          break;
        case 'Server Link':
          sensorsHTML += '''
            <div class="sensor-card">
              <h2><i class="icon">☁️</i> Server Connection</h2>
              <div class="data-grid">
                <div class="data-item">
                  <span class="label">Status:</span>
                  <span class="value">Connected</span>
                </div>
                <div class="data-item">
                  <span class="label">Last Update:</span>
                  <span class="value">${DateTime.now().toString().substring(11, 19)}</span>
                </div>
              </div>
            </div>
          ''';
          break;
      }
    }
    
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RoboStream Sensor Data</title>
    <style>
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            color: white;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            font-size: 2.5rem;
            margin: 0;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .timestamp {
            font-size: 1.1rem;
            opacity: 0.8;
            margin-top: 10px;
        }
        .sensors-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        .sensor-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .sensor-card h2 {
            margin: 0 0 20px 0;
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .icon {
            font-size: 1.8rem;
        }
        .data-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 15px;
        }
        .data-item {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .label {
            font-size: 0.9rem;
            opacity: 0.8;
            font-weight: 500;
        }
        .value {
            font-size: 1.2rem;
            font-weight: 700;
            color: #FFD700;
        }
        .imu-section {
            margin-bottom: 20px;
        }
        .imu-section h3 {
            margin: 0 0 10px 0;
            font-size: 1.1rem;
            opacity: 0.9;
        }
        .camera-preview img {
            width: 100%;
            max-width: 300px;
            height: auto;
            border-radius: 10px;
            margin-bottom: 15px;
        }
        .camera-overlay {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
            background: rgba(0, 0, 0, 0.8);
            border-radius: 15px;
            padding: 10px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            border: 2px solid rgba(255, 255, 255, 0.2);
        }
        .camera-overlay img {
            width: 200px;
            height: 150px;
            object-fit: cover;
            border-radius: 10px;
            display: block;
        }
        .camera-card {
            border: 2px solid #F59E0B;
        }
        .status-display {
            text-align: center;
            padding: 20px;
        }
        .status {
            font-size: 1.5rem;
            font-weight: bold;
            padding: 10px 20px;
            border-radius: 25px;
            text-transform: uppercase;
        }
        .status.connected {
            background: #10B981;
        }
        .status.disconnected {
            background: #EF4444;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.7; }
        }
        .pulse {
            animation: pulse 2s infinite;
        }
    </style>
    <script>
        // Auto-refresh every second to sync with data updates
        setTimeout(() => {
            window.location.reload();
        }, 1000);
        
        // Update camera image every 500ms for smoother video-like experience
        function updateCameraFeed() {
            const cameraImg = document.getElementById('cameraFeed');
            if (cameraImg) {
                const timestamp = new Date().getTime();
                const baseUrl = cameraImg.src.split('?')[0]; // Remove existing timestamp
                cameraImg.src = baseUrl + '?t=' + timestamp;
            }
        }
        
        // Update camera every 500ms
        setInterval(updateCameraFeed, 500);
    </script>
</head>
<body>
    <div class="header">
        <h1>🤖 RoboStream Sensor Data</h1>
        <div class="timestamp">Last Update: ${DateTime.now().toString().substring(0, 19)}</div>
    </div>
    <div class="sensors-container">
        $sensorsHTML
    </div>
</body>
</html>
    ''';
  }

  /// Ocultar datos de sensores (limpiar slave 2)
  Future<void> hideSensorData() async {
    if (_client == null) return;
    
    // Limpiar el KML del slave 2
    final kmlCommand = '''echo '<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>' > /var/www/html/kml/slave_2.kml''';
    
    await sendLGCommand(kmlCommand);
  }

  // Aunque no envíes comandos ahora, es buena práctica tener el método para desconectar.
  void disconnect() {
    _client?.close();
    _client = null;
  }
}