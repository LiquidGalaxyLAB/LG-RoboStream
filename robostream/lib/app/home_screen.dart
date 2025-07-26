import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/widgets/widgets.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/services/server_config_manager.dart';
import 'package:robostream/services/lg_server_service.dart';
import 'package:robostream/app/server_config_screen.dart';
import 'package:robostream/app/lg_config_screen.dart';
import 'package:robostream/assets/styles/app_styles.dart';

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
  String _selectedSensor = '';
  bool _isStreamingToLG = false;
  bool _isLGConnected = false;
  String _lgHost = '192.168.1.100';
  String _lgUsername = 'lg';
  String _lgPassword = 'lg';
  int _lgTotalScreens = 3;
  String _serverHost = '192.168.1.100';

  String? _lastSensorDataHash;
  String? _lastActuatorDataHash;
  DateTime? _lastForceUpdateTime;

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
  }

  void _initializeServerConnection() async {
    try {
      await _loadServerConfig();
      await _serverService.checkConnection();
    } catch (e) {
      // Handle error gracefully
    }
    
    // Start streaming once regardless of connection status
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
      // Handle error
    }
  }

  Future<void> _checkLGConnection() async {
    try {
      // Since we're using server-based LG, just check if we have config
      final config = await LGConfigService.getLGConfig();
      if (mounted) {
        setState(() {
          _isLGConnected = config['host']?.isNotEmpty == true;
        });
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
        });
        // Verificar si los datos del servidor han cambiado durante el streaming
        if (_isStreamingToLG && _lgService != null && _selectedSensor.isNotEmpty) {
          _handleServerDataChange(sensorData);
        }
      }
    });

    _serverService.actuatorStream.listen((actuatorData) {
      if (mounted) {
        setState(() {
          _actuatorData = actuatorData;
        });
        // También verificar cambios en los datos del actuador durante el streaming
        if (_isStreamingToLG && _lgService != null && _selectedSensor.isNotEmpty && _sensorData != null) {
          _handleActuatorDataChange(actuatorData);
        }
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

    // Fade-in animation controller
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
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    
    // Verificar la conexión del servidor
    await _serverService.checkConnection();
    
    // Si no está streaming, intentar iniciarlo
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
        onSelectionConfirmed: (selectedSensor) {
          print('Debug: Sensor selected: "$selectedSensor"');
          _selectedSensor = selectedSensor;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liquid Galaxy configuration saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startStreamingToLG() async {
    print('Debug: Starting LG streaming with selectedSensor: "$_selectedSensor"');
    
    setState(() {
      _isStreamingToLG = true;
    });
    
    // Resetear los hashes de datos para forzar una actualización inicial
    _lastSensorDataHash = null;
    _lastActuatorDataHash = null;
    _lastForceUpdateTime = null;
    
    // Get server host from config
    final serverIp = await ServerConfigManager.instance.getSavedServerIp();
    _serverHost = serverIp ?? '192.168.1.100';
    
    _lgService = LGServerService(serverHost: _serverHost);
    
    // Server-based LG doesn't need explicit connection, just set as connected if config exists
    final lgConfig = await LGConfigService.getLGConfig();
    bool hasLGConfig = lgConfig['host']?.isNotEmpty == true;
    
    print('Debug: LG Config: $lgConfig');
    print('Debug: Has LG Config: $hasLGConfig');
    
    if (mounted) {
      setState(() {
        _isLGConnected = hasLGConfig;
      });
      
      if (!hasLGConfig) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Liquid Galaxy configuration found'),
            backgroundColor: Colors.orange,
          ),
        );
        _stopStreamingToLG();
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        _isLGConnected = true;
      });
    }

    if (!_serverService.isStreaming) {
      _serverService.startStreaming();
    }
    
    final currentSensorData = _sensorData;
    if (currentSensorData != null) {
      await _sendSelectedSensorsToLG(currentSensorData);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Streaming $_selectedSensor to Liquid Galaxy'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendSelectedSensorsToLG(SensorData sensorData) async {
    if (_lgService == null || _selectedSensor.isEmpty) {
      print('Debug: Cannot send to LG - lgService: ${_lgService != null}, selectedSensor: "$_selectedSensor"');
      return;
    }

    try {
      print('Debug: Sending $_selectedSensor to LG via server');
      if (_selectedSensor == 'RGB Camera') {
        final result = await _lgService?.showRGBCameraImage();
        print('Debug: RGB Camera result: $result');
      } else if (_selectedSensor == 'All Sensors') {
        List<String> allSensors = ['GPS Position', 'IMU Sensors', 'Temperature', 'Wheel Motors', 'RGB Camera'];
        final result = await _lgService?.showSensorData(allSensors);
        print('Debug: All Sensors result: $result');
      } else {
        final result = await _lgService?.showSensorData([_selectedSensor]);
        print('Debug: Single sensor ($_selectedSensor) result: $result');
      }
    } catch (e) {
      print('Debug: Error sending to LG: $e');
    }
  }

  void _stopStreamingToLG() async {
    setState(() {
      _isStreamingToLG = false;
    });
    
    // Resetear los hashes de datos
    _lastSensorDataHash = null;
    _lastActuatorDataHash = null;
    _lastForceUpdateTime = null;
    
    try {
      if (_lgService != null) {
        await _lgService?.hideSensorData();
        await _lgService?.disconnect();
        _lgService = null;
      }
    } catch (e) {
      // Handle error silently
    }
    
    _selectedSensor = '';
  }

  /// Maneja los cambios en los datos del servidor durante el streaming
  void _handleServerDataChange(SensorData sensorData) async {
    // Crear un hash de los datos del sensor para detectar cambios
    String currentDataHash = _generateSensorDataHash(sensorData);
    
    // Verificar si ha pasado suficiente tiempo para forzar una actualización (cada 30 segundos)
    final now = DateTime.now();
    final shouldForceUpdate = _lastForceUpdateTime == null || 
        now.difference(_lastForceUpdateTime!).inSeconds > 30;
    
    // Verificar si los datos han cambiado realmente o si necesitamos forzar actualización
    final hasDataChanged = _lastSensorDataHash != currentDataHash;
    final shouldUpdate = hasDataChanged || shouldForceUpdate;
    if (shouldUpdate) {
      // Actualizar el hash y timestamp
      _lastSensorDataHash = currentDataHash;
      _lastForceUpdateTime = now;
      
      // Regenerar y enviar la imagen automáticamente
      await _sendSelectedSensorsToLG(sensorData);
    }
  }
  
  /// Genera un hash simplificado basado en los datos del sensor para detectar cambios
  String _generateSensorDataHash(SensorData sensorData) {
    return '${sensorData.gps.latitude.toStringAsFixed(4)}'
           '${sensorData.gps.longitude.toStringAsFixed(4)}'
           '${sensorData.timestamp.toInt()}';
  }

  /// Maneja los cambios en los datos del actuador durante el streaming
  void _handleActuatorDataChange(ActuatorData actuatorData) async {
    // Crear un hash de los datos del actuador para detectar cambios
    String currentDataHash = _generateActuatorDataHash(actuatorData);
    
    // Verificar si los datos han cambiado realmente
    if (_lastActuatorDataHash != currentDataHash) {
      // Actualizar el hash
      _lastActuatorDataHash = currentDataHash;
      
      // Regenerar y enviar la imagen automáticamente si el sensor seleccionado incluye datos del actuador
      if (_selectedSensor == 'Temperature' || _selectedSensor == 'Wheel Motors' || _selectedSensor == 'All Sensors') {
        await _sendSelectedSensorsToLG(_sensorData!);
      }
    }
  }
  
  /// Genera un hash simplificado basado en los datos del actuador para detectar cambios
  String _generateActuatorDataHash(ActuatorData actuatorData) {
    return '${actuatorData.frontLeftWheel.speed}'
           '${actuatorData.frontRightWheel.speed}'
           '${actuatorData.backLeftWheel.speed}'
           '${actuatorData.backRightWheel.speed}';
  }

  Future<void> _refreshConnectionStatus() async {
    // Forzar verificación de conexión
    final isConnected = await _serverService.checkConnection();
    
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
    
    // Si la conexión es exitosa y el streaming no está activo, iniciarlo
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
        selectedSensor: _selectedSensor,
        onTap: _showStreamingMenu,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );

    // Solo aplicar fade-in si viene del login
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
            print('Debug: RGB Camera selected from menu');
            _selectedSensor = 'RGB Camera';
            _startStreamingToLG();
          },
          onAllSensorsTap: () {
            Navigator.pop(context);
            print('Debug: All Sensors selected from menu, showing dialog');
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
            // Actualizar la URL del servidor
            _serverService.updateServerUrl(result);
            
            // Refrescar inmediatamente el estado de conexión
            await _refreshConnectionStatus();
            
            // Pequeña pausa para animación
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
