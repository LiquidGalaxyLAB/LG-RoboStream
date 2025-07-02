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
  // Constants for better performance
  static const Duration _animationDuration = Duration(milliseconds: 3000);
  static const Duration _indicatorDuration = Duration(milliseconds: 600);
  static const Duration _indicatorReverseDuration = Duration(milliseconds: 450);
  static const Duration _refreshDelay = Duration(milliseconds: 1500);
  
  late AnimationController _parallaxController;
  late AnimationController _indicatorsController;
  
  late Animation<double> _parallaxAnimation;
  late Animation<double> _indicatorsAnimation;
  
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  bool _isStreaming = false;
  bool _lastHadEnoughHeight = true;
  
  final RobotServerService _serverService = RobotServerService();
  SensorData? _sensorData;
  ActuatorData? _actuatorData;
  int _imageRefreshKey = 0;

  LGService? _lgService;
  List<String> _selectedSensors = [];
  bool _isStreamingToLG = false;
  bool _isLGConnected = false;
  String _lgHost = '192.168.1.100';
  String _lgUsername = 'lg';
  String _lgPassword = 'lg';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startContinuousAnimations();
    _setupServerConnection();
    _loadLGConfigFromLogin();
    
    _indicatorsController.value = 1.0;
  }

  void _loadLGConfigFromLogin() async {
    try {
      final config = await LGConfigService.getLGConfig();
      if (mounted) {
        setState(() {
          _lgHost = config['host'] ?? '192.168.1.100';
          _lgUsername = config['username'] ?? 'lg';
          _lgPassword = config['password'] ?? 'lg';
        });
        
        _checkLGConnection();
      }
    } catch (e) {
    }
  }

  Future<void> _checkLGConnection() async {
    try {
      final testLGService = LGService(
        host: _lgHost,
        username: _lgUsername,
        password: _lgPassword,
      );
      
      bool connected = await testLGService.connect();
      if (mounted) {
        setState(() {
          _isLGConnected = connected;
        });
      }
      
      if (connected) {
        testLGService.disconnect();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLGConnected = false;
        });
      }
    }
  }

  void _setupServerConnection() {
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
          _imageRefreshKey++;
        });
        
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

  }

  void _initializeAnimations() {
    _parallaxController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.linear),
    );

    _indicatorsController = AnimationController(
      duration: _indicatorDuration,
      reverseDuration: _indicatorReverseDuration,
      vsync: this,
    );
    
    _indicatorsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorsController, 
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  void _startContinuousAnimations() {
    _parallaxController.repeat();
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _indicatorsController.dispose();
    _scrollController.dispose();
    _serverService.dispose();
    _lgService?.disconnect();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _serverService.checkConnection();
    await Future.delayed(_refreshDelay);
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
            
            await LGConfigService.saveLGConfig(
              host: host,
              username: username,
              password: password,
            );
            
            _checkLGConnection();
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
    setState(() {
      _isStreamingToLG = true;
    });
    
    _lgService = LGService(
      host: _lgHost,
      username: _lgUsername,
      password: _lgPassword,
    );
    
    bool connected = await _lgService!.connect();
    if (!connected) {
      if (mounted) {
        setState(() {
          _isLGConnected = false;
        });
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
    
    if (mounted) {
      setState(() {
        _isLGConnected = true;
      });
    }

    if (!_serverService.isStreaming) {
      _serverService.startStreaming();
    }
    
    if (_sensorData != null) {
      await _sendSelectedSensorsToLG(_sensorData!);
    }
    
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

    if (_selectedSensors.length == 1 && _selectedSensors.contains('RGB Camera')) {
      await _lgService!.showRGBCameraImage(serverHost);
    } else {
      await _lgService!.showSensorData(sensorData, _selectedSensors);
    }
  }

  void _stopStreamingToLG() async {
    setState(() {
      _isStreamingToLG = false;
    });
    
    if (_lgService != null) {
      await _lgService!.hideSensorData();
      _lgService!.disconnect();
      _lgService = null;
    }
    
    _selectedSensors.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cardsData = _generateCardsData();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9).withOpacity(0.9),
              const Color(0xFFF1F5F9),
            ],
            stops: const [0.0, 0.6, 0.8, 1.0],
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
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                ...List.generate(8, (index) => _buildModernBackgroundParticle(index)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
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
        final baseOpacity = 0.01;
        final variation = 0.005 * sinValue.abs();
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
      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
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
    
    String status = 'Offline';
    String value = 'N/A';
    
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
        _buildSectionTitle('Accelerometer (m/s²)', Icons.speed_rounded),
        const SizedBox(height: 8),
        _buildDetailRow('X-axis', '${imu.accelerometer.x.toStringAsFixed(2)}'),
        _buildDetailRow('Y-axis', '${imu.accelerometer.y.toStringAsFixed(2)}'),
        _buildDetailRow('Z-axis', '${imu.accelerometer.z.toStringAsFixed(2)}'),
        const SizedBox(height: 16),
        _buildSectionTitle('Gyroscope (rad/s)', Icons.rotate_right_rounded),
        const SizedBox(height: 8),
        _buildDetailRow('X-axis', '${imu.gyroscope.x.toStringAsFixed(3)}'),
        _buildDetailRow('Y-axis', '${imu.gyroscope.y.toStringAsFixed(3)}'),
        _buildDetailRow('Z-axis', '${imu.gyroscope.z.toStringAsFixed(3)}'),
        const SizedBox(height: 16),
        _buildSectionTitle('Magnetometer (µT)', Icons.explore_rounded),
        const SizedBox(height: 8),
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

    // Calcular el tamaño inicial basado en el contenido
    double initialSize = 0.5; // Tamaño base
    if (detailWidgets.isNotEmpty) {
      // Si hay datos detallados, expandir más para mostrarlos
      if (detailWidgets.length > 5) {
        initialSize = 0.75; // Mucho contenido
      } else if (detailWidgets.length > 2) {
        initialSize = 0.65; // Contenido moderado
      } else {
        initialSize = 0.55; // Poco contenido adicional
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true, // Permite cerrar tocando fuera
      enableDrag: true, // Permite cerrar arrastrando
      builder: (context) => GestureDetector(
        onTap: () {
          // Detecta toques en el área fuera del contenido del modal
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              // Evita que los toques en el contenido del modal lo cierren
              // Este GestureDetector intercepta los toques en el contenido
            },
            child: StatefulBuilder(
              builder: (context, setState) => DraggableScrollableSheet(
                initialChildSize: initialSize, // Tamaño dinámico basado en contenido
                minChildSize: 0.3, // Mínimo 30% de la pantalla
                maxChildSize: 0.8, // Máximo 80% de la pantalla como solicitado
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF8FAFC),
                const Color(0xFFF1F5F9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: (cardData['color'] as Color).withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, -15),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
            border: Border.all(
              color: (cardData['color'] as Color).withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle de arrastre mejorado con indicador visual
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (cardData['color'] as Color).withOpacity(0.6),
                            (cardData['color'] as Color).withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Desliza para ajustar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      (cardData['color'] as Color),
                      (cardData['color'] as Color).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (cardData['color'] as Color).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  cardData['icon'] as IconData,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                cardData['label'] as String,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: status == 'Active' || status == 'Online' || status == 'Tracking'
                        ? [
                            const Color(0xFF10B981).withOpacity(0.15),
                            const Color(0xFF10B981).withOpacity(0.08),
                          ]
                        : [
                            Colors.grey.withOpacity(0.15),
                            Colors.grey.withOpacity(0.08),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: status == 'Active' || status == 'Online' || status == 'Tracking'
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status == 'Active' || status == 'Online' || status == 'Tracking'
                            ? const Color(0xFF10B981)
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == 'Active' || status == 'Online' || status == 'Tracking'
                            ? const Color(0xFF10B981)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (cardData['color'] as Color).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (detailWidgets.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (cardData['color'] as Color).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...detailWidgets,
              ],
              const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ), // Cierre del DraggableScrollableSheet
      ), // Cierre del StatefulBuilder
      ), // Cierre del segundo GestureDetector (contenido)
      ), // Cierre del Container
      ), // Cierre del primer GestureDetector (fuera del modal)
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.15),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool hasEnoughHeight = constraints.maxHeight > 70;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (hasEnoughHeight && !_lastHadEnoughHeight) {
              _indicatorsController.forward();
            } else if (!hasEnoughHeight && _lastHadEnoughHeight) {
              _indicatorsController.reverse();
            }
            _lastHadEnoughHeight = hasEnoughHeight;
          }
        });
        
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: hasEnoughHeight ? 28 : 22,
                    letterSpacing: -1.2,
                    height: 0.95,
                  ),
                  child: const Text(
                    'RoboStream',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _indicatorsAnimation,
                builder: (context, child) {
                  double opacity = _indicatorsAnimation.value.clamp(0.0, 1.0);
                  
                  double scale = (0.7 + (0.3 * opacity)).clamp(0.1, 1.0);
                  
                  double translateY = (1.0 - opacity) * 8.0;
                  
                  double translateX = (1.0 - opacity) * 2.0;
                  
                  if (opacity < 0.02) {
                    return const SizedBox.shrink();
                  }
                  
                  return AnimatedContainer(
                    duration: Duration(milliseconds: hasEnoughHeight ? 0 : 250),
                    curve: Curves.easeOutCubic,
                    height: hasEnoughHeight ? null : 0,
                    child: ClipRect(
                      child: Transform.translate(
                        offset: Offset(translateX, translateY),
                        child: Transform.scale(
                          scale: scale,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: opacity,
                            curve: Curves.easeInOutSine,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06 * opacity * opacity),
                                      blurRadius: 10 * opacity,
                                      offset: Offset(0, 2 * opacity),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.7 * opacity),
                                      blurRadius: 6 * opacity,
                                      offset: Offset(0, -0.5 * opacity),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5 * opacity),
                                    width: 1.5,
                                  ),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 100),
                                        opacity: opacity,
                                        child: _buildModernConnectionStatus(),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: 1 * opacity,
                                        height: 14,
                                        margin: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.grey.shade300.withOpacity(0.0),
                                              Colors.grey.shade300.withOpacity(0.8 * opacity),
                                              Colors.grey.shade300.withOpacity(0.0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 100),
                                        opacity: opacity,
                                        child: _buildModernStreamingStatus(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
            color: _isLGConnected 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isLGConnected 
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
          'LG Connection',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isLGConnected 
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
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          '$imageUrl?refresh=$_imageRefreshKey',
          key: ValueKey(_imageRefreshKey),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.1),
                            const Color(0xFFF59E0B).withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Loading camera feed...',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.1),
                            Colors.grey.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        size: 24,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Camera feed unavailable',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
      isDismissible: true, // Permite cerrar tocando fuera
      enableDrag: true, // Permite cerrar arrastrando
      builder: (context) => GestureDetector(
        onTap: () {
          // Detecta toques en el área fuera del contenido del modal
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              // Evita que los toques en el contenido del modal lo cierren
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
      ), // Cierre del Container principal
      ), // Cierre del segundo GestureDetector (contenido)
      ), // Cierre del Container exterior
      ), // Cierre del primer GestureDetector (fuera del modal)
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isStreamingToLG ? 'Stop Streaming' : (_isConnected ? 'Start Streaming' : 'Streaming Offline'),
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
      _stopStreamingToLG();
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true, // Permite cerrar tocando fuera
        enableDrag: true, // Permite cerrar arrastrando
        builder: (context) => GestureDetector(
          onTap: () {
            // Detecta toques en el área fuera del contenido del modal
            Navigator.of(context).pop();
          },
          child: Container(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                // Evita que los toques en el contenido del modal lo cierren
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
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
        ), // Cierre del Container principal
        ), // Cierre del segundo GestureDetector (contenido)
        ), // Cierre del Container exterior
        ), // Cierre del primer GestureDetector (fuera del modal)
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