import 'package:flutter/material.dart';
import 'package:robostream/config/server_config.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/services/server_config_manager.dart';
import 'package:robostream/widgets/common/custom_snackbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:robostream/services/lg_service_manager.dart';

class ServerConfigScreen extends StatefulWidget {
  final RobotServerService? serverService;
  
  const ServerConfigScreen({super.key, this.serverService});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  // Constants for repeated colors and styles
  static const Color _primaryColor = Color(0xFF6366F1);
  static const Color _secondaryColor = Color(0xFF8B5CF6);
  static const Color _textPrimaryColor = Color(0xFF1E293B);
  static const Color _textSecondaryColor = Color(0xFF64748B);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _backgroundLight = Color(0xFFF8FAFC);
  static const Color _backgroundDark = Color(0xFFF1F5F9);

  final TextEditingController _urlController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionStatus;
  RobotServerService? _testService;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    if (!mounted) return;
    
    // Primero intentar cargar desde el servicio centralizado
    final savedUrl = await ServerConfigManager.instance.getServerUrl();
    final currentUrl = savedUrl ?? widget.serverService?.currentBaseUrl ?? ServerConfig.baseUrl;
    
    setState(() {
      _urlController.text = currentUrl;
    });
  }

  @override
  void dispose() {
    _testService?.dispose();
    _testService = null;
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String url) async {
    if (!mounted) return;
    
    _testService?.dispose();
    _testService = null;
    
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      _testService = RobotServerService();
      _testService!.updateServerUrl(url);
      
      // Try connection with retry mechanism
      bool isConnected = false;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (!isConnected && retryCount < maxRetries) {
        isConnected = await _testService!.checkConnection();
        if (!isConnected) {
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        if (isConnected) {
          _connectionStatus = 'Connected successfully!';
        } else {
          _connectionStatus = 'Connection failed after $maxRetries attempts. Please check the server URL and ensure the server is running.';
        }
        _isTestingConnection = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _connectionStatus = 'Error: ${e.toString()}';
        _isTestingConnection = false;
      });
    } finally {
      _testService?.dispose();
      _testService = null;
    }
  }

  // Helper methods for common UI patterns
  LinearGradient get _primaryGradient => const LinearGradient(
    colors: [_primaryColor, _secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get _backgroundGradient => const LinearGradient(
    colors: [_backgroundLight, _backgroundDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      colors: [Colors.white, Colors.white.withOpacity(0.95)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: _primaryColor.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(
      color: _primaryColor.withOpacity(0.08),
      width: 1,
    ),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildServerConfigCard(),
                      const SizedBox(height: 20),
                      _buildAdvancedSettingsCard(),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: _primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Server Configuration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure robot server connection',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.dns_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerConfigCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.1),
                        _primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_ethernet_rounded,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configure the robot server endpoint',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Server URL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                color: Colors.grey.shade50,
              ),
              child: TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'Enter server URL (e.g., http://192.168.1.100:8000)',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(
                    Icons.link_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTestConnectionButton(),
            if (_connectionStatus != null) ...[
              const SizedBox(height: 16),
              _buildConnectionStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestConnectionButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isTestingConnection
            ? LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400],
              )
            : _primaryGradient,
        boxShadow: _isTestingConnection
            ? null
            : [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isTestingConnection
              ? null
              : () => _testConnection(_urlController.text),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isTestingConnection)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.wifi_find_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isTestingConnection ? 'Testing Connection...' : 'Test Connection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isSuccess = _connectionStatus!.contains('successfully');
    final color = isSuccess ? _successColor : _errorColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _connectionStatus!,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        _secondaryColor.withOpacity(0.1),
                        _secondaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _secondaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Presets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Common server configurations',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPresetOption(
              'Local Development',
              'http://localhost:8000',
              Icons.laptop_rounded,
            ),
            _buildPresetOption(
              'Local Network',
              'http://192.168.1.100:8000',
              Icons.router_rounded,
            ),
            _buildPresetOption(
              'Android Emulator',
              'http://10.0.2.2:8000',
              Icons.phone_android_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetOption(String title, String url, IconData icon) {
    final isSelected = _urlController.text == url;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _urlController.text = url;
          _connectionStatus = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? _primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected
                ? _primaryColor.withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isSelected
                    ? _primaryColor
                    : Colors.grey.shade300,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? _primaryColor
                          : _textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: _primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _primaryGradient,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _saveConfiguration(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Save Configuration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    print('🔴 DEBUG: _saveConfiguration() called - START');
    
    final newUrl = _urlController.text.trim();
    print('🔴 DEBUG: newUrl = $newUrl');
    
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please enter a valid URL')),
            ],
          ),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      // Save configuration immediately without testing
      await ServerConfigManager.instance.saveServerIp(newUrl.replaceAll('http://', '').replaceAll(':8000', ''));

      // Update existing service if it exists
      if (widget.serverService != null) {
        // Update URL
        widget.serverService!.updateServerUrl(newUrl);
        
        // Start background connection verification and streaming setup
        _startBackgroundConnectionVerification(widget.serverService!);
      }

      // Try to fetch and save LG config in background
      _fetchAndSaveLGConfig(newUrl);
      
      // Send current LG config to server immediately
      print('🔴 DEBUG: About to call _sendCurrentLGConfigToServer()');
      await _sendCurrentLGConfigToServer(newUrl);
      print('🔴 DEBUG: _sendCurrentLGConfigToServer() completed');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Configuration saved successfully')),
            ],
          ),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      
      // Return immediately to home screen
      Navigator.pop(context, newUrl);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error saving configuration: ${e.toString()}')),
            ],
          ),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _startBackgroundConnectionVerification(RobotServerService service) async {
    // This runs in background after user returns to home screen
    try {
      // Stop current streaming if running
      if (service.isStreaming) {
        service.stopStreaming();
      }
      
      // Wait a moment for the UI to settle
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Try to establish connection with 5-second timeout
      bool isConnected = false;
      int retryCount = 0;
      const maxRetries = 2; // Reduced retries for faster response
      
      while (!isConnected && retryCount < maxRetries) {
        try {
          isConnected = await service.checkConnection().timeout(
            const Duration(seconds: 5),
            onTimeout: () => false,
          );
          if (!isConnected) {
            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        } catch (e) {
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
      
      // Start streaming regardless of connection status
      // The connection indicator will update automatically through the stream
      service.startStreaming();
      
    } catch (e) {
      // Silent error handling - just start streaming anyway
      service.startStreaming();
    }
  }

  Future<void> _fetchAndSaveLGConfig(String serverUrl) async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/lg-config'));
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        await LGConfigService.saveLGConfig(
          host: config['host'] ?? '',
          username: config['username'] ?? '',
          password: config['password'] ?? '',
          totalScreens: config['total_screens'] ?? 3,
        );
      }
    } catch (e) {
      print('Could not fetch LG config from server during server setup: $e');
    }
  }

  Future<void> _sendCurrentLGConfigToServer(String serverUrl) async {
    print('🔴🔴🔴 DEBUG: _sendCurrentLGConfigToServer called with URL: $serverUrl 🔴🔴🔴');
    
    try {
      // Get current LG configuration from local storage
      print('🔴 DEBUG: Getting LG config from local storage...');
      final lgConfig = await LGConfigService.getLGConfig();
      final totalScreens = await LGConfigService.getTotalScreens();
      
      print('🔴 DEBUG: Retrieved LG config from local storage:');
      print('🔴   Host: ${lgConfig['host']}');
      print('🔴   Username: ${lgConfig['username']}');
      print('🔴   Password: ${lgConfig['password']}');
      print('🔴   Total screens: $totalScreens');
      
      // Only send if we have valid configuration
      final host = lgConfig['host'];
      if (host != null && host.isNotEmpty) {
        print('🔴 DEBUG: Host is valid, sending LG configuration to server: $host');
        
        final requestBody = {
          'host': host,
          'username': lgConfig['username'] ?? 'lg',
          'password': lgConfig['password'] ?? '',
          'total_screens': totalScreens,
        };
        
        final requestBodyJson = jsonEncode(requestBody);
        print('🔴 DEBUG: Request body: $requestBodyJson');
        
        print('🔴 DEBUG: Making HTTP POST request to: $serverUrl/lg-config');
        final response = await http.post(
          Uri.parse('$serverUrl/lg-config'),
          headers: {'Content-Type': 'application/json'},
          body: requestBodyJson,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('🔴 DEBUG: HTTP request timeout');
            throw Exception('Request timeout');
          },
        );
        
        print('🔴 DEBUG: HTTP response received');
        print('🔴 DEBUG: Server response status: ${response.statusCode}');
        print('🔴 DEBUG: Server response body: ${response.body}');
        
        if (response.statusCode == 200) {
          print('🔴 ✅ LG configuration sent to server successfully');
        } else {
          print('🔴 ❌ Failed to send LG configuration to server: ${response.statusCode}');
          print('🔴 ❌ Response body: ${response.body}');
        }
      } else {
        print('🔴 ❌ No valid LG configuration found to send to server');
        print('🔴    Host is null or empty: $host');
        print('🔴    Full config: $lgConfig');
      }
    } catch (e, stackTrace) {
      print('🔴 ❌ EXCEPTION in _sendCurrentLGConfigToServer: $e');
      print('🔴 ❌ Stack trace: $stackTrace');
    }
    
    print('🔴🔴🔴 DEBUG: _sendCurrentLGConfigToServer completed 🔴🔴🔴');
  }
}
