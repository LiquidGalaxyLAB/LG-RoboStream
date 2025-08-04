import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:robostream/widgets/widgets.dart';
import 'package:robostream/widgets/common/custom_snackbar.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/services/server_config_manager.dart';
import 'package:robostream/services/lg_server_service.dart';
import 'package:robostream/services/lg_config_service.dart';
import 'package:robostream/app/server_config_screen.dart';
import 'package:robostream/app/lg_config_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool fromLogin;
  const HomeScreen({super.key, this.fromLogin = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 3000);
  static const Duration _indicatorDuration = Duration(milliseconds: 600);
  static const Duration _indicatorReverseDuration = Duration(milliseconds: 450);
  static const Duration _refreshDelay = Duration(milliseconds: 1500);
  
  late AnimationController _parallaxController;
  late AnimationController _indicatorsController;
  late AnimationController _fadeInController;
  
  late Animation<double> _parallaxAnimation;
  late Animation<double> _indicatorsAnimation;
  late Animation<double> _fadeInAnimation;
  
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  
  final RobotServerService _serverService = RobotServerService();
  SensorData? _sensorData;
  ActuatorData? _actuatorData;

  LGServerService? _lgService;
  List<String> _selectedSensors = [];
  bool _isStreamingToLG = false;
  bool _isLGConnected = false;
  String _lgHost = '192.168.1.100';
  String _lgUsername = 'lg';
  String _lgPassword = 'lg';
  int _lgTotalScreens = 3;
  String _serverHost = '192.168.1.100';


  
  Timer? _lgStreamingTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startContinuousAnimations();
    _setupServerConnection();
    _loadLGConfigFromLogin();
    _initializeServerConnection();
    
    _indicatorsController.value = 1.0;
    
    if (widget.fromLogin) {
      _fadeInController.forward();
    } else {
      _fadeInController.value = 1.0;
    }
    
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkLGConnection();
      } else {
        timer.cancel();
      }
    });
  }

  void _initializeServerConnection() async {
    try {
      await _loadServerConfig();
      await _serverService.checkConnection();
    } catch (e) {

    }
    
    if (!_serverService.isStreaming) {
      _serverService.startStreaming();
    }
  }

  Future<void> _loadServerConfig() async {
    final serverUrl = await ServerConfigManager.instance.getServerUrl();
    if (serverUrl != null) {
      _serverService.updateServerUrl(serverUrl);
    }
  }

  void _loadLGConfigFromLogin() async {
    try {
      final config = await LGConfigService.getLGConfig();
      final totalScreens = await LGConfigService.getTotalScreens();
      if (mounted) {
        setState(() {
          _lgHost = config['host'] ?? '192.168.1.100';
          _lgUsername = config['username'] ?? 'lg';
          _lgPassword = config['password'] ?? 'lg';
          _lgTotalScreens = totalScreens;
        });
        
        _checkLGConnection();
      }
    } catch (e) {

    }
  }

  void refreshLGConnectionStatus() {
    _checkLGConnection();
  }

  Future<void> _checkLGConnection() async {
    try {

      if (!_isConnected) {

        if (mounted) {
          setState(() {
            _isLGConnected = false;
          });
        }
        return;
      }

      final config = await LGConfigService.getLGConfig();
      
      bool hasValidLocalConfig = config['host'] != null && 
                                config['host']!.isNotEmpty &&
                                config['username'] != null && 
                                config['username']!.isNotEmpty &&
                                config['password'] != null && 
                                config['password']!.isNotEmpty;

      if (!hasValidLocalConfig) {

        if (mounted) {
          setState(() {
            _isLGConnected = false;
          });
        }
        return;
      }

      await _checkServerLGConfig();
        
    } catch (e) {

      if (mounted) {
        setState(() {
          _isLGConnected = false;
        });
      }
    }
  }

  Future<void> _checkServerLGConfig() async {
    try {
      final serverIp = await ServerConfigManager.instance.getSavedServerIp();
      final serverHost = serverIp ?? '192.168.1.100';
      
      final response = await http.get(
        Uri.parse('http://$serverHost:8000/lg-config'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        bool hasValidServerConfig = data['host'] != null && 
                                   data['host'].toString().isNotEmpty &&
                                   data['username'] != null && 
                                   data['username'].toString().isNotEmpty &&
                                   data['password'] != null && 
                                   data['password'].toString().isNotEmpty &&
                                   data['total_screens'] != null &&
                                   data['total_screens'] > 0;
        if (mounted) {
          setState(() {
            _isLGConnected = hasValidServerConfig;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLGConnected = false;
          });
        }
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
        
        _checkLGConnection();
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

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeInController,
        curve: Curves.easeOut,
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
    _fadeInController.dispose();
    _scrollController.dispose();
    _serverService.dispose();
    _lgService?.disconnect();
    _lgStreamingTimer?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    
    await _serverService.checkConnection();
    
    if (!_serverService.isStreaming) {
      _serverService.startStreaming();
    }
    
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
          currentTotalScreens: _lgTotalScreens,
          onConfigSaved: (host, username, password, totalScreens) async {
            setState(() {
              _lgHost = host;
              _lgUsername = username;
              _lgPassword = password;
              _lgTotalScreens = totalScreens;
            });
            
            await LGConfigService.saveLGConfig(
              host: host,
              username: username,
              password: password,
              totalScreens: totalScreens,
            );
            
            _checkLGConnection();
          },
        ),
      ),
    );
    
    if (result == true) {
      HapticFeedback.selectionClick();
      CustomSnackBar.showSuccess(context, 'Liquid Galaxy configuration saved');
    }
  }

  void _startStreamingToLG() async {
    setState(() {
      _isStreamingToLG = true;
    });
    
    if (!_isConnected) {
      CustomSnackBar.showWarning(context, 'Server not connected. Cannot stream to Liquid Galaxy.');
      _stopStreamingToLG();
      return;
    }

    final serverIp = await ServerConfigManager.instance.getSavedServerIp();
    _serverHost = serverIp ?? '192.168.1.100';
    
    _lgService = LGServerService(serverHost: _serverHost);
    
    final lgConfig = await LGConfigService.getLGConfig();
    bool hasValidLocalConfig = lgConfig['host'] != null && 
                               lgConfig['host']!.isNotEmpty &&
                               lgConfig['username'] != null && 
                               lgConfig['username']!.isNotEmpty &&
                               lgConfig['password'] != null && 
                               lgConfig['password']!.isNotEmpty;
    
    if (!hasValidLocalConfig) {
      CustomSnackBar.showWarning(context, 'No valid local Liquid Galaxy configuration found. Please configure LG connection.');
      _stopStreamingToLG();
      return;
    }
    
    try {
      await _checkServerLGConfig();
      
      if (!_isLGConnected) {
        CustomSnackBar.showWarning(context, 'Liquid Galaxy not properly configured on server. Please check server LG configuration.');
        _stopStreamingToLG();
        return;
      }
    } catch (e) {
      CustomSnackBar.showWarning(context, 'Unable to verify Liquid Galaxy configuration on server.');
      _stopStreamingToLG();
      return;
    }

    if (!_serverService.isStreaming) {
      _serverService.startStreaming();
    }
    
    final currentSensorData = _sensorData;
    if (currentSensorData != null) {
      await _sendSelectedSensorsToLG(currentSensorData);
    }
    
    _startLGStreamingTimer();
    
    if (mounted) {
      CustomSnackBar.showSuccess(context, 'Streaming ${_selectedSensors.join(", ")} to Liquid Galaxy');
    }
  }

  Future<void> _sendSelectedSensorsToLG(SensorData sensorData) async {
    if (_lgService == null || _selectedSensors.isEmpty) {
      return;
    }

    try {
      Future<bool?> sendOperation;
      
      if (_selectedSensors.contains('RGB Camera') && _selectedSensors.length == 1) {
        sendOperation = _lgService?.showRGBCameraImage() ?? Future.value(false);
      } else {
        sendOperation = _lgService?.showSensorData(_selectedSensors) ?? Future.value(false);
      }
      
      await Future.any([
        sendOperation,
        Future.delayed(const Duration(seconds: 3), () => null)
      ]);
      
    } catch (e) {

    }
  }

  void _stopStreamingToLG() {
    _lgStreamingTimer?.cancel();
    _lgStreamingTimer = null;
    
    _selectedSensors = [];
    
    if (mounted) {
      setState(() {
        _isStreamingToLG = false;
      });
      
      CustomSnackBar.showInfo(context, 'Streaming stopped');
    }
    
    _hideSensorDataInBackground();
    
    _cleanupLGServiceInBackground();
  }

  void _hideSensorDataInBackground() {
    if (_lgService != null) {
      Future.delayed(Duration.zero, () async {
        try {
          await _lgService!.hideSensorData().timeout(const Duration(seconds: 5));
        } catch (e) {
        }
      });
    }
  }
  
  void _cleanupLGServiceInBackground() {
    if (_lgService != null) {
      Future.delayed(Duration.zero, () async {
        try {
        } catch (e) {
        } finally {
          _lgService = null;
        }
      });
    }
  }

  void _startLGStreamingTimer() {

    _lgStreamingTimer?.cancel();
    
    _lgStreamingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isStreamingToLG && _lgService != null && _selectedSensors.isNotEmpty && _sensorData != null) {
        try {
          await Future.any([
            _sendSelectedSensorsToLG(_sensorData!),
            Future.delayed(const Duration(seconds: 8))
          ]);
        } catch (e) {
        }
      }
    });
  }

  Future<void> _refreshConnectionStatus() async {

    final isConnected = await _serverService.checkConnection();
    
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
    
    if (isConnected && !_serverService.isStreaming) {
      _serverService.startStreaming();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsData = _generateCardsData();

    Widget homeContent = Scaffold(
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
              EnhancedAppBar(
                parallaxAnimation: _parallaxAnimation,
                indicatorsAnimation: _indicatorsAnimation,
                isConnected: _isConnected,
                isLGConnected: _isLGConnected,
                onConfigTap: _showConfigurationMenu,
              ),
              _buildEnhancedGrid(cardsData),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: ModernStreamingButton(
        isConnected: _isConnected,
        isStreamingToLG: _isStreamingToLG,
        selectedSensors: _selectedSensors,
        onTap: _showStreamingMenu,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );

    if (widget.fromLogin) {
      return AnimatedBuilder(
        animation: _fadeInAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _fadeInAnimation.value) * 20),
            child: Opacity(
              opacity: _fadeInAnimation.value,
              child: homeContent,
            ),
          );
        },
      );
    } else {
      return homeContent;
    }
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
        'value': rgbCamera != null 
            ? '${rgbCamera.status} - ${rgbCamera.resolution}' 
            : 'Disconnected',
        'color': rgbCamera != null && rgbCamera.status == 'Active' 
            ? const Color(0xFF6366F1) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.radar_outlined, 
        'label': 'LiDAR Sensor', 
        'value': lidarStatus,
        'color': lidarStatus == 'Connected' 
            ? const Color(0xFF8B5CF6) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.location_on_outlined, 
        'label': 'GPS Position', 
        'value': gpsData != null 
            ? '${gpsData.latitude.toStringAsFixed(6)}\n${gpsData.longitude.toStringAsFixed(6)}' 
            : 'No GPS Signal',
        'color': gpsData != null 
            ? const Color(0xFF06B6D4) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.speed_outlined, 
        'label': 'Movement', 
        'value': gpsData != null 
            ? '${gpsData.speed.toStringAsFixed(1)} m/s' 
            : '0.0 m/s',
        'color': gpsData != null && gpsData.speed > 0 
            ? const Color(0xFF10B981) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.settings_input_component_outlined, 
        'label': 'IMU Sensors', 
        'value': imuData != null 
            ? 'Acc: ${imuData.accelerometer.x.toStringAsFixed(1)}\nGyro: ${imuData.gyroscope.x.toStringAsFixed(1)}' 
            : 'No IMU Data',
        'color': imuData != null 
            ? const Color(0xFFF59E0B) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.precision_manufacturing_outlined, 
        'label': 'Wheel Motors', 
        'value': _actuatorData != null 
            ? 'FL: ${_actuatorData!.frontLeftWheel.speed}\nFR: ${_actuatorData!.frontRightWheel.speed}' 
            : 'Motor Data N/A',
        'color': _actuatorData != null 
            ? const Color(0xFF8B5CF6) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.thermostat_outlined, 
        'label': 'Temperature', 
        'value': _actuatorData != null 
            ? '${_actuatorData!.frontLeftWheel.temperature.toStringAsFixed(1)}°C' 
            : 'Temp N/A',
        'color': _actuatorData != null 
            ? const Color(0xFFEF4444) 
            : const Color(0xFF64748B),
      },
      {
        'icon': Icons.cloud_outlined, 
        'label': 'Server Link', 
        'value': _isConnected 
            ? 'Connected' 
            : 'Disconnected',
        'color': _isConnected 
            ? const Color(0xFF10B981) 
            : const Color(0xFFEF4444),
      },
    ];
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
          return ModernAnimatedCard(
            cardData: cardsData[index],
            index: index,
            onTap: () => _showCardDetails(cardsData[index]),
          );
        }),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => CardDetailSheet(
        cardData: cardData,
        sensorData: _sensorData,
        actuatorData: _actuatorData,
        isConnected: _isConnected,
        serverBaseUrl: _serverService.currentBaseUrl,
        serverService: _serverService,
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
        isDismissible: true,
        enableDrag: true,
        builder: (context) => StreamingMenu(
          onRGBCameraOnlyTap: () {
            Navigator.pop(context);
            _selectedSensors = ['RGB Camera'];
            _startStreamingToLG();
          },
          onAllSensorsTap: () {
            Navigator.pop(context);
            _showSensorSelectionDialog();
          },
        ),
      );
    }
  }

  void _showConfigurationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => ConfigurationMenu(
        onServerConfigTap: () async {
          HapticFeedback.lightImpact();
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => ServerConfigScreen(serverService: _serverService),
            ),
          );
          
          if (result != null && result.isNotEmpty) {

            _serverService.updateServerUrl(result);
            
            await _refreshConnectionStatus();
            
            await Future.delayed(const Duration(milliseconds: 500));
            HapticFeedback.selectionClick();
          }
        },
        onLGConfigTap: () async {
          HapticFeedback.lightImpact();
          await _showLGConfigDialog();
        },
      ),
    );
  }
}
