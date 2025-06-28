import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/widgets/widgets.dart';
import 'package:robostream/assets/styles/home_styles.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/services/lg_service.dart';
import 'package:robostream/app/server_config_screen.dart';
import 'package:robostream/app/lg_config_screen.dart';
import 'package:robostream/config/server_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _parallaxController;
  late AnimationController _statsController;
  late AnimationController _pulseController;
  
  late Animation<double> _parallaxAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _pulseAnimation;
  
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  bool _isStreaming = false;
  
  // Servicio del servidor y datos
  final RobotServerService _serverService = RobotServerService();
  SensorData? _sensorData;
  ActuatorData? _actuatorData;
  int _imageRefreshKey = 0; // Para forzar actualización de imagen

  // Servicio de Liquid Galaxy y configuración
  LGService? _lgService;
  List<String> _selectedSensors = [];
  bool _isStreamingToLG = false;
  String _lgHost = '192.168.1.100';
  String _lgUsername = 'lg';
  String _lgPassword = 'lg';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startContinuousAnimations();
    _setupServerConnection();
  }

  void _setupServerConnection() {
    // Configurar listeners para los streams del servidor
    _serverService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    _serverService.sensorStream.listen((sensorData) {
      if (mounted) {
        setState(() {
          _sensorData = sensorData;
          _imageRefreshKey++; // Incrementar para forzar actualización de imagen
        });
        
        // Si estamos streaming al LG y hay sensores seleccionados, enviar datos actualizados
        if (_isStreamingToLG && _lgService != null && _selectedSensors.isNotEmpty) {
          _sendSelectedSensorsToLG(sensorData);
        }
      }
    });

    _serverService.actuatorStream.listen((actuatorData) {
      if (mounted) {
        setState(() {
          _actuatorData = actuatorData;
        });
      }
    });

    // NO iniciar las solicitudes automáticamente
    // El usuario debe presionar el botón para comenzar
  }

  void _initializeAnimations() {
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: HomeStyles.statsDuration,
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.linear),
    );
    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: AppStyles.bouncyCurve),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _statsController.forward();
  }

  void _startContinuousAnimations() {
    _parallaxController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _statsController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _serverService.dispose(); // Limpiar el servicio del servidor
    _lgService?.disconnect(); // Limpiar el servicio del LG
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    // Hacer una solicitud manual al servidor
    await _serverService.checkConnection();
    await Future.delayed(const Duration(milliseconds: 1500));
    HapticFeedback.selectionClick();
  }

  void _toggleStreaming() {
    HapticFeedback.mediumImpact();
    
    if (_isStreamingToLG) {
      // Detener solo el streaming al LG, mantener conexión con robot
      _stopStreamingToLG();
    } else {
      // Verificar si hay conexión al robot primero
      if (!_isConnected) {
        // Si no hay conexión al robot, iniciarla primero
        _startRobotConnection();
        // Dar tiempo para establecer conexión antes de mostrar el diálogo
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_isConnected) {
            _showSensorSelectionDialog();
          }
        });
      } else {
        // Si ya hay conexión al robot, ir directo al diálogo de sensores
        _showSensorSelectionDialog();
      }
    }
  }

  void _startRobotConnection() {
    // Iniciar las solicitudes de datos del servidor si no están ya iniciadas
    if (!_serverService.isStreaming) {
      _serverService.startStreaming();
      print('Conexión al robot iniciada');
    }
  }

  void _showSensorSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SensorSelectionDialog(
        onSelectionConfirmed: (selectedSensors) {
          _selectedSensors = selectedSensors;
          _startStreamingToLG();
        },
      ),
    );
  }

  Future<void> _showLGConfigDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LGConfigScreen(
          currentHost: _lgHost,
          currentUsername: _lgUsername,
          currentPassword: _lgPassword,
          onConfigSaved: (host, username, password) {
            setState(() {
              _lgHost = host;
              _lgUsername = username;
              _lgPassword = password;
            });
          },
        ),
      ),
    );
    
    if (result == true) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liquid Galaxy configuration saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startStreamingToLG() async {
    print('🚀 Iniciando streaming al LG...');
    print('Sensores seleccionados: $_selectedSensors');
    
    setState(() {
      _isStreamingToLG = true;
    });
    
    // Inicializar servicio LG con configuración actual
    print('Configuración LG:');
    print('  Host: $_lgHost');
    print('  Usuario: $_lgUsername');
    print('  Password: ${_lgPassword.length > 0 ? '[CONFIGURADA]' : '[VACÍA]'}');
    
    _lgService = LGService(
      host: _lgHost,
      username: _lgUsername,
      password: _lgPassword,
    );
    
    // Intentar conectar al LG
    print('Conectando al LG...');
    bool connected = await _lgService!.connect();
    if (!connected) {
      print('❌ Error: No se pudo conectar al LG');
      // Si no se puede conectar, mostrar error y detener
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to Liquid Galaxy'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _stopStreamingToLG();
      return;
    }
    
    print('✅ Conectado al LG exitosamente');
    
    // Iniciar las solicitudes de datos del servidor SOLO si no están ya iniciadas
    if (!_serverService.isStreaming) {
      print('Iniciando streaming del servidor robot...');
      _serverService.startStreaming();
    }
    
    // Verificar si tenemos datos del sensor para enviar
    if (_sensorData != null) {
      await _sendSelectedSensorsToLG(_sensorData!);
    }
    
    print('✅ Proceso completado');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Streaming ${_selectedSensors.length} sensors to Liquid Galaxy'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendSelectedSensorsToLG(SensorData sensorData) async {
    if (_lgService == null || _selectedSensors.isEmpty) return;

    String serverBaseUrl = _serverService.currentBaseUrl;
    String serverHost = serverBaseUrl.replaceAll('http://', '').replaceAll(':8000', '');
    
    print('URL base del servidor: $serverBaseUrl');
    print('Host extraído: $serverHost');

    // Si se seleccionó solo la cámara RGB, usar el método simple
    if (_selectedSensors.length == 1 && _selectedSensors.contains('RGB Camera')) {
      await _lgService!.showRGBCameraImage(serverHost);
    } else {
      // Usar el método completo de sensores
      await _lgService!.showSensorData(sensorData, _selectedSensors);
    }
  }

  void _stopStreamingToLG() async {
    setState(() {
      _isStreamingToLG = false;
    });
    
    // NO detener el streaming del servidor - solo limpiar el LG
    // _serverService.stopStreaming(); // <-- ESTA LÍNEA ERA EL PROBLEMA
    
    // Limpiar datos del LG
    if (_lgService != null) {
      await _lgService!.hideSensorData();
      _lgService!.disconnect();
      _lgService = null;
    }
    
    _selectedSensors.clear();
    print('Streaming al LG detenido - conexión con robot mantenida');
  }

  @override
  Widget build(BuildContext context) {
    // Generar datos de tarjetas con información del servidor
    final cardsData = _generateCardsData();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppStyles.backgroundGradient,
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          backgroundColor: Colors.white,
          color: AppStyles.primaryColor,
          strokeWidth: 3,
          displacement: 120,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildEnhancedAppBar(),
              _buildStatsSection(),
              _buildEnhancedGrid(cardsData),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamingButton(
        isStreaming: _isStreamingToLG,
        isEnabled: _isConnected,
        onPressed: _toggleStreaming,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Map<String, dynamic>> _generateCardsData() {
    // Si no hay datos del sensor, usar valores por defecto
    final gpsData = _sensorData?.gps;
    final imuData = _sensorData?.imu;
    final lidarStatus = _sensorData?.lidar ?? 'Disconnected';
    final timestamp = _sensorData?.timestamp;
    
    // Calcular aceleración total para mostrar actividad del IMU
    double totalAcceleration = 0.0;
    if (imuData != null) {
      final acc = imuData.accelerometer;
      totalAcceleration = math.sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z);
    }
    
    // Calcular velocidad promedio de las ruedas
    double avgWheelSpeed = 0.0;
    if (_actuatorData != null) {
      final wheels = _actuatorData!;
      avgWheelSpeed = (wheels.frontLeftWheel.speed + 
                      wheels.frontRightWheel.speed + 
                      wheels.backLeftWheel.speed + 
                      wheels.backRightWheel.speed) / 4.0;
    }
    
    // Tiempo desde la última actualización
    String lastUpdateText = 'N/A';
    if (timestamp != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
      final now = DateTime.now();
      final diff = now.difference(lastUpdate).inSeconds;
      lastUpdateText = diff < 60 ? '${diff}s ago' : 'Stale';
    }
    
    // Datos de la cámara RGB
    final rgbCamera = _sensorData?.rgbCamera;
    String rgbCameraStatus = rgbCamera?.status ?? 'Offline';
    String rgbCameraValue = 'N/A';
    Color rgbCameraColor = const Color(0xFF64748B);
    
    if (rgbCamera != null && rgbCamera.status == 'Active') {
      rgbCameraValue = '${rgbCamera.resolution}@${rgbCamera.fps}fps';
      rgbCameraColor = const Color(0xFF6366F1);
    }
    
    return [
      {
        'icon': Icons.camera_alt_outlined, 
        'label': 'RGB Camera', 
        'color': rgbCameraColor,
        'status': rgbCameraStatus,
        'value': rgbCameraValue
      },
      {
        'icon': Icons.radar_outlined, 
        'label': 'LiDAR Sensor', 
        'color': lidarStatus == 'Connected' ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
        'status': lidarStatus,
        'value': lidarStatus == 'Connected' ? '360° scan' : 'N/A'
      },
      {
        'icon': Icons.location_on_outlined, 
        'label': 'GPS Position', 
        'color': gpsData != null ? const Color(0xFF06B6D4) : const Color(0xFF64748B),
        'status': gpsData != null ? 'Active' : 'Offline',
        'value': gpsData != null ? 'Tracking' : 'N/A'
      },
      {
        'icon': Icons.speed_outlined, 
        'label': 'Movement', 
        'color': gpsData != null && gpsData.speed > 0 ? const Color(0xFF10B981) : const Color(0xFF64748B),
        'status': gpsData != null ? 'Tracking' : 'Offline',
        'value': gpsData != null ? '${gpsData.speed.toStringAsFixed(1)} m/s' : 'N/A'
      },
      {
        'icon': Icons.settings_input_component_outlined, 
        'label': 'IMU Sensors', 
        'color': imuData != null ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
        'status': imuData != null ? 'Active' : 'Offline',
        'value': imuData != null ? '${totalAcceleration.toStringAsFixed(1)} m/s²' : 'N/A'
      },
      {
        'icon': Icons.precision_manufacturing_outlined, 
        'label': 'Wheel Motors', 
        'color': _actuatorData != null ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
        'status': _actuatorData != null ? 'Ready' : 'Offline',
        'value': _actuatorData != null ? '${avgWheelSpeed.toStringAsFixed(0)} RPM' : 'N/A'
      },
      {
        'icon': Icons.thermostat_outlined, 
        'label': 'Temperature', 
        'color': _actuatorData != null ? const Color(0xFFEF4444) : const Color(0xFF64748B),
        'status': _actuatorData != null ? 'Monitoring' : 'Offline',
        'value': _actuatorData != null ? 
            '${((_actuatorData!.frontLeftWheel.temperature + _actuatorData!.frontRightWheel.temperature + _actuatorData!.backLeftWheel.temperature + _actuatorData!.backRightWheel.temperature) / 4).toStringAsFixed(1)}°C' : 'N/A'
      },
      {
        'icon': Icons.cloud_outlined, 
        'label': 'Server Link', 
        'color': _isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        'status': _isConnected ? 'Online' : 'Offline',
        'value': _isConnected ? lastUpdateText : 'N/A'
      },
    ];
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      pinned: true,
      expandedHeight: 180.0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        centerTitle: true,
        title: _buildHeaderTitle(),        background: AnimatedBuilder(
          animation: _parallaxAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                ...List.generate(6, (index) => _buildBackgroundParticle(index)),
                child!,
              ],
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppStyles.backgroundColor.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Botón de configuración LG
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: AppStyles.cardShadow,
              ),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.cast_connected),
                  color: AppStyles.primaryColor,
                  iconSize: 24,
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await _showLGConfigDialog();
                  },
                ),
              ),
            ),
          ),
        ),
        // Botón de configuración del servidor
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: AppStyles.cardShadow,
              ),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: AppStyles.primaryColor,
                  iconSize: 24,
                  onPressed: () async {
                HapticFeedback.lightImpact();
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServerConfigScreen(
                      serverService: _serverService,
                    ),
                  ),
                );
                
                // Si se devolvió una nueva URL, forzar una actualización
                if (result != null && result.isNotEmpty) {
                  // La configuración ya se actualizó en el servicio
                  // Solo necesitamos forzar una actualización de la UI
                  await Future.delayed(const Duration(milliseconds: 500));
                  HapticFeedback.selectionClick();
                }
              },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _statsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _statsAnimation.value)),
            child: Opacity(
              opacity: _statsAnimation.value.clamp(0.0, 1.0),
              child: CustomCard(
                margin: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Server Status',
                        _isConnected ? 'Online' : 'Offline',
                        Icons.cloud,
                        _isConnected ? AppStyles.successColor : const Color(0xFFEF4444),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Altitude',
                        '${_sensorData?.gps.altitude.toStringAsFixed(0) ?? '0'}m',
                        Icons.height,
                        AppStyles.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackgroundParticle(int index) {
    final positions = [
      const Offset(50, 30),
      const Offset(250, 80),
      const Offset(150, 40),
      const Offset(300, 60),
      const Offset(100, 120),
      const Offset(200, 100),
    ];
    final sizes = [60.0, 80.0, 70.0, 90.0, 65.0, 75.0];

    return AnimatedBuilder(
      animation: _parallaxAnimation,
      builder: (context, child) {
        final animatedValue = (_parallaxAnimation.value + (index * 0.16)) % 1.0;
        final sinValue = math.sin(animatedValue * math.pi);
        final baseOpacity = 0.04;
        final variation = 0.03 * sinValue.abs();
        final opacity = (baseOpacity + variation).clamp(0.0, 1.0);
        
        return Positioned(
          left: positions[index].dx + (15 * math.sin(animatedValue * 2 * math.pi)),
          top: positions[index].dy + (10 * math.cos(animatedValue * 2 * math.pi)),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppStyles.primaryColor.withOpacity(0.12),
                    AppStyles.accentColor.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildEnhancedGrid(List<Map<String, dynamic>> cardsData) {
    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
        children: List.generate(cardsData.length, (index) {
          return _buildAnimatedCard(cardsData[index], index);
        }),
      ),
    );
  }

  Widget _buildAnimatedCard(Map<String, dynamic> cardData, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: AppStyles.bouncyCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: CustomCard.simple(
        icon: cardData['icon'] as IconData,
        name: cardData['label'] as String,
        color: cardData['color'] as Color,
        onTap: () {
          HapticFeedback.mediumImpact();
          _showCardDetails(cardData);
        },
      ),
    );
  }
  Widget _buildFooterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: SystemInfoCard(
          isConnected: _isConnected,
        ),
      ),
    );
  }

  void _showCardDetails(Map<String, dynamic> cardData) {
    final String label = cardData['label'] as String;
    List<Widget> detailWidgets = [];

    // Agregar información específica basada en el tipo de tarjeta
    if (label == 'GPS Position' && _sensorData?.gps != null) {
      final gps = _sensorData!.gps;
      detailWidgets.addAll([
        _buildDetailRow('Latitude', '${gps.latitude.toStringAsFixed(6)}°'),
        _buildDetailRow('Longitude', '${gps.longitude.toStringAsFixed(6)}°'),
        _buildDetailRow('Altitude', '${gps.altitude.toStringAsFixed(1)} m'),
        _buildDetailRow('Speed', '${gps.speed.toStringAsFixed(2)} m/s'),
      ]);
    } else if (label == 'Wheel Motors' && _actuatorData != null) {
      final actuators = _actuatorData!;
      detailWidgets.addAll([
        _buildDetailRow('Front Left', '${actuators.frontLeftWheel.speed} RPM • ${actuators.frontLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Front Right', '${actuators.frontRightWheel.speed} RPM • ${actuators.frontRightWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Left', '${actuators.backLeftWheel.speed} RPM • ${actuators.backLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Right', '${actuators.backRightWheel.speed} RPM • ${actuators.backRightWheel.temperature.toStringAsFixed(1)}°C'),
        const SizedBox(height: 8),
        _buildDetailRow('Avg Power', '${((actuators.frontLeftWheel.consumption + actuators.frontRightWheel.consumption + actuators.backLeftWheel.consumption + actuators.backRightWheel.consumption) / 4).toStringAsFixed(2)} A'),
        _buildDetailRow('Avg Voltage', '${((actuators.frontLeftWheel.voltage + actuators.frontRightWheel.voltage + actuators.backLeftWheel.voltage + actuators.backRightWheel.voltage) / 4).toStringAsFixed(1)} V'),
      ]);
    } else if (label == 'IMU Sensors' && _sensorData?.imu != null) {
      final imu = _sensorData!.imu;
      detailWidgets.addAll([
        const Text(
          'Accelerometer (m/s²)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        _buildDetailRow('X-axis', '${imu.accelerometer.x.toStringAsFixed(2)}'),
        _buildDetailRow('Y-axis', '${imu.accelerometer.y.toStringAsFixed(2)}'),
        _buildDetailRow('Z-axis', '${imu.accelerometer.z.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        const Text(
          'Gyroscope (rad/s)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        _buildDetailRow('X-axis', '${imu.gyroscope.x.toStringAsFixed(3)}'),
        _buildDetailRow('Y-axis', '${imu.gyroscope.y.toStringAsFixed(3)}'),
        _buildDetailRow('Z-axis', '${imu.gyroscope.z.toStringAsFixed(3)}'),
        const SizedBox(height: 12),
        const Text(
          'Magnetometer (µT)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        _buildDetailRow('X-axis', '${imu.magnetometer.x.toStringAsFixed(2)}'),
        _buildDetailRow('Y-axis', '${imu.magnetometer.y.toStringAsFixed(2)}'),
        _buildDetailRow('Z-axis', '${imu.magnetometer.z.toStringAsFixed(2)}'),
      ]);
    } else if (label == 'LG Streaming') {
      detailWidgets.addAll([
        _buildDetailRow('Status', _isStreaming ? 'Streaming Active' : 'Not Streaming'),
        _buildDetailRow('Connection', _isConnected ? 'Robot Connected' : 'Robot Offline'),
        _buildDetailRow('Data Rate', _isStreaming ? '10 Hz' : 'N/A'),
        _buildDetailRow('Last Sync', _isStreaming ? 'Live' : 'N/A'),
        if (_isStreaming) ...[
          const SizedBox(height: 8),
          _buildDetailRow('GPS Data', _sensorData?.gps != null ? 'Transmitting' : 'No Data'),
          _buildDetailRow('Camera Feed', _sensorData?.camera == 'Streaming' ? 'Transmitting' : 'No Feed'),
          _buildDetailRow('Sensor Data', _sensorData?.imu != null ? 'Transmitting' : 'No Data'),
        ],
      ]);
    } else if (label == 'Server Link') {
      final timestamp = _sensorData?.timestamp;
      detailWidgets.addAll([
        _buildDetailRow('Status', _isConnected ? 'Connected' : 'Disconnected'),
        _buildDetailRow('Server URL', _serverService.currentBaseUrl),
        _buildDetailRow('Update Interval', '${ServerConfig.updateInterval.inSeconds}s'),
        if (timestamp != null) ...[
          _buildDetailRow('Last Update', 
            DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt())
              .toString().substring(11, 19)),
          _buildDetailRow('Data Age', 
            '${DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt())).inSeconds}s'),
        ],
      ]);
    } else if (label == 'Temperature' && _actuatorData != null) {
      final actuators = _actuatorData!;
      detailWidgets.addAll([
        _buildDetailRow('Front Left Motor', '${actuators.frontLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Front Right Motor', '${actuators.frontRightWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Left Motor', '${actuators.backLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Right Motor', '${actuators.backRightWheel.temperature.toStringAsFixed(1)}°C'),
        const SizedBox(height: 8),
        _buildDetailRow('Average', '${((actuators.frontLeftWheel.temperature + actuators.frontRightWheel.temperature + actuators.backLeftWheel.temperature + actuators.backRightWheel.temperature) / 4).toStringAsFixed(1)}°C'),
        _buildDetailRow('Max Safe Temp', '80.0°C'),
      ]);
    } else if (label == 'RGB Camera' && _sensorData?.rgbCamera != null) {
      final rgbCamera = _sensorData!.rgbCamera!;
      detailWidgets.addAll([
        _buildCameraPreview(),
        const SizedBox(height: 12),
        _buildDetailRow('Camera ID', rgbCamera.cameraId),
        _buildDetailRow('Resolution', rgbCamera.resolution),
        _buildDetailRow('Frame Rate', '${rgbCamera.fps} FPS'),
      ]);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),            ),
            const SizedBox(height: 20), // Reducido de 24 a 20
            Icon(
              cardData['icon'] as IconData,
              size: 48,
              color: cardData['color'] as Color,
            ),
            const SizedBox(height: 14), // Reducido de 16 a 14
            Text(
              cardData['label'] as String,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6), // Reducido de 8 a 6
            Text(
              'Status: ${cardData['status']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Value: ${cardData['value']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),            if (detailWidgets.isNotEmpty) ...[
              const SizedBox(height: 20), // Reducido de 24 a 20
              const Divider(),
              const SizedBox(height: 14), // Reducido de 16 a 14
              ...detailWidgets,            ],
            const SizedBox(height: 20), // Reducido de 24 a 20
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],      ),
    );
  }

  Widget _buildHeaderTitle() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppStyles.primaryGradient.createShader(bounds),
            child: const Text(
              'RoboStream',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                _buildConnectionStatus(),
                const SizedBox(width: 16),
                _buildStreamingStatusHeader(),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? AppStyles.successColor : AppStyles.errorColor,
              boxShadow: [
                BoxShadow(
                  color: (_isConnected ? AppStyles.successColor : AppStyles.errorColor)
                      .withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected ? 'Robot Connected' : 'Robot Offline',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingStatusHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isStreamingToLG ? const Color(0xFF10B981) : Colors.grey.shade400,
              boxShadow: [
                BoxShadow(
                  color: (_isStreamingToLG ? const Color(0xFF10B981) : Colors.grey.shade400)
                      .withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isStreamingToLG ? 'Streaming to LG' : 'LG Offline',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final imageUrl = _serverService.getRGBCameraImageUrl();
    
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          '$imageUrl?refresh=$_imageRefreshKey', // Agregar query param para forzar refresh
          key: ValueKey(_imageRefreshKey), // Key único para forzar rebuild del widget
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[100],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      ),
    );
  }
}
