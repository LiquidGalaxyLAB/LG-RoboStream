import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/widgets/widgets.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/services/lg_service.dart';
import 'package:robostream/services/lg_config_service.dart';
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
  
  late Animation<double> _parallaxAnimation;
  
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
    _loadLGConfigFromLogin(); // Cargar configuración guardada del login
  }

  /// Carga la configuración de LG guardada desde el login exitoso
  void _loadLGConfigFromLogin() async {
    try {
      final config = await LGConfigService.getLGConfig();
      if (mounted) {
        setState(() {
          _lgHost = config['host'] ?? '192.168.1.100';
          _lgUsername = config['username'] ?? 'lg';
          _lgPassword = config['password'] ?? 'lg';
        });
        print('✅ Configuración LG cargada desde login: $_lgHost, $_lgUsername');
      }
    } catch (e) {
      print('❌ Error cargando configuración LG: $e');
    }
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
    
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.linear),
    );
  }

  void _startContinuousAnimations() {
    _parallaxController.repeat();
  }

  @override
  void dispose() {
    _parallaxController.dispose();
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
          onConfigSaved: (host, username, password) async {
            setState(() {
              _lgHost = host;
              _lgUsername = username;
              _lgPassword = password;
            });
            
            // Guardar también en el servicio de configuración
            await LGConfigService.saveLGConfig(
              host: host,
              username: username,
              password: password,
            );
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFE2E8F0).withOpacity(0.8),
              const Color(0xFFF1F5F9),
            ],
            stops: const [0.0, 0.7, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
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
              _buildEnhancedGrid(cardsData),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildModernStreamingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Map<String, dynamic>> _generateCardsData() {
    // Datos simplificados - solo lo básico para mostrar las tarjetas
    // Los detalles se mostrarán cuando se abra cada tarjeta
    final gpsData = _sensorData?.gps;
    final imuData = _sensorData?.imu;
    final lidarStatus = _sensorData?.lidar ?? 'Disconnected';
    final rgbCamera = _sensorData?.rgbCamera;
    
    return [
      {
        'icon': Icons.camera_alt_outlined, 
        'label': 'RGB Camera', 
        'color': rgbCamera != null && rgbCamera.status == 'Active' 
            ? const Color(0xFF6366F1) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.radar_outlined, 
        'label': 'LiDAR Sensor', 
        'color': lidarStatus == 'Connected' 
            ? const Color(0xFF8B5CF6) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.location_on_outlined, 
        'label': 'GPS Position', 
        'color': gpsData != null 
            ? const Color(0xFF06B6D4) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.speed_outlined, 
        'label': 'Movement', 
        'color': gpsData != null && gpsData.speed > 0 
            ? const Color(0xFF10B981) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.settings_input_component_outlined, 
        'label': 'IMU Sensors', 
        'color': imuData != null 
            ? const Color(0xFFF59E0B) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.precision_manufacturing_outlined, 
        'label': 'Wheel Motors', 
        'color': _actuatorData != null 
            ? const Color(0xFF8B5CF6) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.thermostat_outlined, 
        'label': 'Temperature', 
        'color': _actuatorData != null 
            ? const Color(0xFFEF4444) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.cloud_outlined, 
        'label': 'Server Link', 
        'color': _isConnected 
            ? const Color(0xFF10B981) 
            : const Color(0xFFEF4444),
      },
    ];
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      pinned: true,
      expandedHeight: 200.0,
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
                // Fondo gradiente moderno
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Partículas de fondo animadas
                ...List.generate(8, (index) => _buildModernBackgroundParticle(index)),
                // Overlay de gradiente
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppStyles.backgroundColor.withOpacity(0.2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        // Botón de configuración unificado
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildUnifiedConfigButton(),
        ),
      ],
    );
  }
  Widget _buildModernBackgroundParticle(int index) {
    final positions = [
      const Offset(50, 30),
      const Offset(250, 80),
      const Offset(150, 40),
      const Offset(300, 60),
      const Offset(100, 120),
      const Offset(200, 100),
      const Offset(70, 90),
      const Offset(320, 100),
    ];
    final sizes = [80.0, 60.0, 90.0, 70.0, 85.0, 75.0, 65.0, 95.0];
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
    ];

    return AnimatedBuilder(
      animation: _parallaxAnimation,
      builder: (context, child) {
        final animatedValue = (_parallaxAnimation.value + (index * 0.125)) % 1.0;
        final sinValue = math.sin(animatedValue * math.pi * 2);
        final cosValue = math.cos(animatedValue * math.pi * 2);
        final baseOpacity = 0.03;
        final variation = 0.02 * sinValue.abs();
        final opacity = (baseOpacity + variation).clamp(0.0, 1.0);
        
        return Positioned(
          left: positions[index].dx + (20 * sinValue),
          top: positions[index].dy + (15 * cosValue),
          child: Transform.rotate(
            angle: animatedValue * math.pi * 2,
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors[index].withOpacity(opacity),
                    colors[index].withOpacity(opacity * 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
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
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 0.9,
        children: List.generate(cardsData.length, (index) {
          return _buildModernAnimatedCard(cardsData[index], index);
        }),
      ),
    );
  }

  Widget _buildModernAnimatedCard(Map<String, dynamic> cardData, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 120)),
      curve: Curves.fastOutSlowIn,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: _buildModernCard(cardData, index),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> cardData, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (cardData['color'] as Color).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: (cardData['color'] as Color).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact();
            _showCardDetails(cardData);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono principal
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        (cardData['color'] as Color).withOpacity(0.15),
                        (cardData['color'] as Color).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    cardData['icon'] as IconData,
                    color: cardData['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                // Título solamente
                Text(
                  cardData['label'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildFooterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: SystemInfoCard(
            isConnected: _isConnected,
          ),
        ),
      ),
    );
  }

  void _showCardDetails(Map<String, dynamic> cardData) {
    final String label = cardData['label'] as String;
    
    // Calcular dinámicamente el status y value para cada tarjeta
    String status = 'Offline';
    String value = 'N/A';
    
    // Determinar status y value basado en el tipo de tarjeta
    if (label == 'RGB Camera') {
      final rgbCamera = _sensorData?.rgbCamera;
      status = rgbCamera?.status ?? 'Offline';
      value = rgbCamera != null && rgbCamera.status == 'Active' 
          ? '${rgbCamera.resolution}@${rgbCamera.fps}fps' 
          : 'N/A';
    } else if (label == 'LiDAR Sensor') {
      final lidarStatus = _sensorData?.lidar ?? 'Disconnected';
      status = lidarStatus;
      value = lidarStatus == 'Connected' ? '360° scan' : 'N/A';
    } else if (label == 'GPS Position') {
      final gpsData = _sensorData?.gps;
      status = gpsData != null ? 'Active' : 'Offline';
      value = gpsData != null ? 'Tracking' : 'N/A';
    } else if (label == 'Movement') {
      final gpsData = _sensorData?.gps;
      status = gpsData != null ? 'Tracking' : 'Offline';
      value = gpsData != null ? '${gpsData.speed.toStringAsFixed(1)} m/s' : 'N/A';
    } else if (label == 'IMU Sensors') {
      final imuData = _sensorData?.imu;
      status = imuData != null ? 'Active' : 'Offline';
      if (imuData != null) {
        final acc = imuData.accelerometer;
        final totalAcceleration = math.sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z);
        value = '${totalAcceleration.toStringAsFixed(1)} m/s²';
      }
    } else if (label == 'Wheel Motors') {
      status = _actuatorData != null ? 'Ready' : 'Offline';
      if (_actuatorData != null) {
        final wheels = _actuatorData!;
        final avgWheelSpeed = (wheels.frontLeftWheel.speed + 
                              wheels.frontRightWheel.speed + 
                              wheels.backLeftWheel.speed + 
                              wheels.backRightWheel.speed) / 4.0;
        value = '${avgWheelSpeed.toStringAsFixed(0)} RPM';
      }
    } else if (label == 'Temperature') {
      status = _actuatorData != null ? 'Monitoring' : 'Offline';
      if (_actuatorData != null) {
        final actuators = _actuatorData!;
        final avgTemp = (actuators.frontLeftWheel.temperature + 
                        actuators.frontRightWheel.temperature + 
                        actuators.backLeftWheel.temperature + 
                        actuators.backRightWheel.temperature) / 4;
        value = '${avgTemp.toStringAsFixed(1)}°C';
      }
    } else if (label == 'Server Link') {
      status = _isConnected ? 'Online' : 'Offline';
      if (_isConnected && _sensorData?.timestamp != null) {
        final lastUpdate = DateTime.fromMillisecondsSinceEpoch((_sensorData!.timestamp * 1000).toInt());
        final now = DateTime.now();
        final diff = now.difference(lastUpdate).inSeconds;
        value = diff < 60 ? '${diff}s ago' : 'Stale';
      }
    }
    
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
              'Status: $status',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Value: $value',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título principal sin recuadro
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'RoboStream',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              letterSpacing: -1.2,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Contenedor moderno para los indicadores de estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 8,
                offset: const Offset(0, -1),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernConnectionStatus(),
              Container(
                width: 1,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade300.withOpacity(0.0),
                      Colors.grey.shade300,
                      Colors.grey.shade300.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              _buildModernStreamingStatus(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernConnectionStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isConnected 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isConnected 
                    ? const Color(0xFF10B981) 
                    : const Color(0xFFEF4444)).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Server',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isConnected 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStreamingStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isStreamingToLG 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isStreamingToLG 
                    ? const Color(0xFF10B981) 
                    : const Color(0xFFEF4444)).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Streaming',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isStreamingToLG 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
            letterSpacing: 0.2,
          ),
        ),
      ],
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

  Widget _buildUnifiedConfigButton() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            HapticFeedback.lightImpact();
            _showConfigurationMenu();
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF6366F1).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF6366F1),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  void _showConfigurationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Título
            const Text(
              'Configuration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what you want to configure',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // Opciones de configuración
            _buildConfigOption(
              icon: Icons.dns_rounded,
              title: 'Robot Server',
              subtitle: 'Configure robot connection settings',
              color: const Color(0xFF6366F1),
              onTap: () async {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServerConfigScreen(
                      serverService: _serverService,
                    ),
                  ),
                );
                
                if (result != null && result.isNotEmpty) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  HapticFeedback.selectionClick();
                }
              },
            ),
            const SizedBox(height: 16),
            _buildConfigOption(
              icon: Icons.cast_connected_rounded,
              title: 'Liquid Galaxy',
              subtitle: 'Configure LG connection settings',
              color: const Color(0xFF8B5CF6),
              onTap: () async {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                await _showLGConfigDialog();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStreamingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _isConnected 
                ? (_isStreamingToLG ? const Color(0xFFEF4444) : const Color(0xFF6366F1))
                : Colors.grey.shade400,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _isConnected ? _showStreamingMenu : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: _isConnected
                  ? LinearGradient(
                      colors: _isStreamingToLG
                          ? [
                              const Color(0xFFEF4444),
                              const Color(0xFFDC2626),
                            ]
                          : [
                              const Color(0xFF6366F1),
                              const Color(0xFF4F46E5),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade500,
                      ],
                    ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono animado
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey(_isStreamingToLG),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(
                      _isStreamingToLG ? Icons.stop_rounded : Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Texto con animación
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isStreamingToLG ? 'Stop Streaming' : (_isConnected ? 'Start Streaming' : 'Robot Offline'),
                    key: ValueKey('${_isStreamingToLG}_${_isConnected}'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStreamingMenu() {
    HapticFeedback.mediumImpact();
    
    if (_isStreamingToLG) {
      // Si ya está streaming, detener directamente
      _stopStreamingToLG();
    } else {
      // Si no está streaming, mostrar menú de opciones
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Icono y título
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Start Streaming',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select sensors to stream to Liquid Galaxy',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              // Opciones de sensores
              _buildSensorStreamOption(
                icon: Icons.camera_alt_rounded,
                title: 'RGB Camera Only',
                subtitle: 'Stream camera feed only',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.pop(context);
                  _selectedSensors = ['RGB Camera'];
                  _startStreamingToLG();
                },
              ),
              const SizedBox(height: 16),
              _buildSensorStreamOption(
                icon: Icons.sensors_rounded,
                title: 'All Sensors',
                subtitle: 'Stream all available sensor data',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  _showSensorSelectionDialog();
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSensorStreamOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}