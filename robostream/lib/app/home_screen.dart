import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/app/telemetry_card.dart';
import 'package:robostream/app/app_theme.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/app/server_config_screen.dart';
import 'package:robostream/config/server_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _parallaxController;
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _pulseController;
  
  late Animation<double> _fabAnimation;
  late Animation<double> _parallaxAnimation;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _pulseAnimation;
  
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isConnected = false;
  bool _isStreaming = false; // Estado del streaming
  
  // Servicio del servidor y datos
  final RobotServerService _serverService = RobotServerService();
  SensorData? _sensorData;
  ActuatorData? _actuatorData;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
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
        });
      }
    });

    _serverService.actuatorStream.listen((actuatorData) {
      if (mounted) {
        setState(() {
          _actuatorData = actuatorData;
        });
      }
    });

    // Sincronizar el estado de streaming con el servicio
    setState(() {
      _isStreaming = _serverService.isStreaming;
    });

    // NO iniciar las solicitudes automáticamente
    // El usuario debe presionar el botón para comenzar
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: AppTheme.mediumDuration,
      vsync: this,
    );
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: AppTheme.bouncyCurve),
    );
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.linear),
    );
    _headerSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerController, curve: AppTheme.smoothCurve),
    );
    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: AppTheme.bouncyCurve),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fabController.forward();
    _headerController.forward();
    _statsController.forward();
  }

  void _startContinuousAnimations() {
    _parallaxController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _parallaxController.dispose();
    _headerController.dispose();
    _statsController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _serverService.dispose(); // Limpiar el servicio del servidor
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    // Hacer una solicitud manual al servidor
    await _serverService.checkConnection();
    await Future.delayed(const Duration(milliseconds: 1500));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    // Generar datos de tarjetas con información del servidor
    final cardsData = _generateCardsData();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          backgroundColor: Colors.white,
          color: AppTheme.primaryColor,
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
      floatingActionButton: _buildEnhancedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Map<String, dynamic>> _generateCardsData() {
    // Si no hay datos del sensor, usar valores por defecto
    final gpsData = _sensorData?.gps;
    final imuData = _sensorData?.imu;
    final cameraStatus = _sensorData?.camera ?? 'Offline';
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
    
    return [
      {
        'icon': Icons.camera_alt_outlined, 
        'label': 'RGB Camera', 
        'color': cameraStatus == 'Streaming' ? const Color(0xFF6366F1) : const Color(0xFF64748B),
        'status': cameraStatus,
        'value': cameraStatus == 'Streaming' ? '1080p@30fps' : 'N/A'
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
        'value': gpsData != null ? '${gpsData.satellites} sats' : 'N/A'
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
        'icon': Icons.cloud_outlined, 
        'label': 'Server Link', 
        'color': _isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        'status': _isConnected ? 'Online' : 'Offline',
        'value': _isConnected ? lastUpdateText : 'N/A'
      },
      {
        'icon': Icons.thermostat_outlined, 
        'label': 'Temperature', 
        'color': _actuatorData != null ? const Color(0xFFEF4444) : const Color(0xFF64748B),
        'status': _actuatorData != null ? 'Monitoring' : 'Offline',
        'value': _actuatorData != null ? 
            '${((_actuatorData!.frontLeftWheel.temperature + _actuatorData!.frontRightWheel.temperature + _actuatorData!.backLeftWheel.temperature + _actuatorData!.backRightWheel.temperature) / 4).toStringAsFixed(1)}°C' : 'N/A'
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
        centerTitle: false,
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_headerSlideAnimation.value, -_scrollOffset * 0.1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
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
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _pulseAnimation.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isConnected ? AppTheme.successColor : AppTheme.errorColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isConnected ? AppTheme.successColor : AppTheme.errorColor)
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
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        background: AnimatedBuilder(
          animation: _parallaxAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                ...List.generate(6, (index) => _buildBackgroundParticle(index)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.backgroundColor.withOpacity(0.3),
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
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderButton(
                icon: Icons.settings_outlined,
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
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.notifications_outlined,
                onPressed: () => HapticFeedback.lightImpact(),
                badge: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool badge = false,
  }) {
    return AnimatedContainer(
      duration: AppTheme.mediumDuration,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon),
            color: AppTheme.primaryColor,
            iconSize: 24,
            onPressed: onPressed,
          ),
          if (badge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.errorColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
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
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFFAFBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'GPS Satellites',
                        _sensorData?.gps.satellites.toString() ?? '0',
                        Icons.satellite_alt,
                        AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Server Status',
                        _isConnected ? 'Online' : 'Offline',
                        Icons.cloud,
                        _isConnected ? AppTheme.successColor : const Color(0xFFEF4444),
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
                        AppTheme.accentColor,
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
                    AppTheme.primaryColor.withOpacity(0.12),
                    AppTheme.accentColor.withOpacity(0.06),
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
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: AppTheme.bouncyCurve,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: TelemetryCard(
                      icon: cardsData[index]['icon'] as IconData,
                      label: cardsData[index]['label'] as String,
                      color: cardsData[index]['color'] as Color,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showCardDetails(cardsData[index]);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildFooterSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.accentColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'System Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ROS2 Humble • Ubuntu 22.04 • Build v1.2.3',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFAB() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.heavyImpact();
            _toggleStreaming();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          splashColor: Colors.white.withOpacity(0.3),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_isStreaming),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                _isStreaming ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isStreaming ? 'Stop Stream' : 'Start Stream',
              key: ValueKey(_isStreaming),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleStreaming() {
    // Usar el método toggleStreaming del servicio
    _serverService.toggleStreaming();
    
    // Actualizar el estado local de streaming
    setState(() {
      _isStreaming = _serverService.isStreaming;
    });
    
    // El estado de _isConnected se actualizará automáticamente 
    // a través del stream connectionStream cuando el servicio
    // actualice su estado de conexión
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
        _buildDetailRow('Satellites', '${gps.satellites}'),
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
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              cardData['icon'] as IconData,
              size: 48,
              color: cardData['color'] as Color,
            ),
            const SizedBox(height: 16),
            Text(
              cardData['label'] as String,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
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
            ),
            if (detailWidgets.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              ...detailWidgets,
            ],
            const SizedBox(height: 24),
          ],
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
        ],
      ),
    );
  }
}