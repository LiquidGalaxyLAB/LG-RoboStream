import 'package:flutter/material.dart';
import 'package:robostream/config/server_config.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/assets/Styles/server_config_styles.dart';

class ServerConfigScreen extends StatefulWidget {
  final RobotServerService? serverService;
  
  const ServerConfigScreen({super.key, this.serverService});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _currentUrl = ServerConfig.baseUrl;
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }  Future<void> _loadConfiguration() async {
    // Cargar configuración del servidor
    setState(() {
      // Usar la URL actual del servicio si está disponible
      _currentUrl = widget.serverService?.currentBaseUrl ?? ServerConfig.baseUrl;
      _urlController.text = _currentUrl;
    });  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String url) async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      // Crear un servicio temporal para probar la conexión
      final testService = RobotServerService();
      testService.updateServerUrl(url);
      
      final isConnected = await testService.checkConnection();
      
      setState(() {
        _connectionStatus = isConnected ? 'Connected successfully!' : 'Connection failed';
        _isTestingConnection = false;
      });
      
      testService.dispose();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: ${e.toString()}';
        _isTestingConnection = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ServerConfigStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Server Configuration',
          style: ServerConfigStyles.appBarTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ServerConfigStyles.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),      body: SingleChildScrollView(
        padding: ServerConfigStyles.screenPadding,child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [            Container(
              padding: ServerConfigStyles.containerPadding,
              decoration: ServerConfigStyles.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  Row(
                    children: [
                      Container(
                        padding: ServerConfigStyles.iconContainerPadding,
                        decoration: ServerConfigStyles.getIconContainerDecoration(ServerConfigStyles.primaryColor),
                        child: const Icon(
                          Icons.settings_ethernet,
                          color: ServerConfigStyles.primaryColor,
                          size: ServerConfigStyles.iconSize,
                        ),
                      ),
                      const SizedBox(width: ServerConfigStyles.smallSpacing),
                      Text(
                        'Server Settings',
                        style: ServerConfigStyles.sectionTitleStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: ServerConfigStyles.itemSpacing),
                  Text(
                    'Server URL',
                    style: ServerConfigStyles.fieldLabelStyle,
                  ),
                  const SizedBox(height: ServerConfigStyles.fieldSpacing),
                  TextField(
                    controller: _urlController,
                    decoration: ServerConfigStyles.textFieldDecoration,
                  ),                  const SizedBox(height: ServerConfigStyles.smallSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestingConnection ? null : () {
                            _testConnection(_urlController.text);
                          },
                          icon: _isTestingConnection 
                              ? const SizedBox(
                                  width: ServerConfigStyles.smallIconSize,
                                  height: ServerConfigStyles.smallIconSize,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.wifi_find, size: ServerConfigStyles.smallIconSize),
                          label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                          style: ServerConfigStyles.testButtonStyle,
                        ),
                      ),
                    ],
                  ),                  if (_connectionStatus != null) ...[
                    const SizedBox(height: ServerConfigStyles.smallSpacing),
                    Container(
                      padding: ServerConfigStyles.statusContainerPadding,
                      decoration: ServerConfigStyles.getStatusDecoration(_connectionStatus!.contains('successfully')),
                      child: Row(
                        children: [
                          Icon(
                            _connectionStatus!.contains('successfully') 
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _connectionStatus!.contains('successfully')
                                ? ServerConfigStyles.successColor
                                : ServerConfigStyles.errorColor,
                            size: ServerConfigStyles.smallIconSize,
                          ),
                          const SizedBox(width: ServerConfigStyles.tinySpacing),
                          Expanded(
                            child: Text(
                              _connectionStatus!,
                              style: ServerConfigStyles.getStatusTextStyle(_connectionStatus!.contains('successfully')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),            const SizedBox(height: ServerConfigStyles.sectionSpacing),
            Container(
              padding: ServerConfigStyles.containerPadding,
              decoration: ServerConfigStyles.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Common Configurations',
                    style: ServerConfigStyles.labelStyle,
                  ),
                  const SizedBox(height: ServerConfigStyles.labelFontSize),
                  _buildConfigOption(
                    'Local Docker',
                    'http://localhost:8000',
                    Icons.computer,
                  ),
                  _buildConfigOption(
                    'Docker Desktop',
                    'http://host.docker.internal:8000',
                    Icons.desktop_windows,
                  ),
                  _buildConfigOption(
                    'Custom IP',
                    'http://000.000.0.000:0000',
                    Icons.router,
                  ),
                  _buildConfigOption(
                    'Flutter phone simulation',
                    'http://10.0.2.2:8000',
                    Icons.phone_android,
                  ),
                ],
              ),
            ),            const SizedBox(height: ServerConfigStyles.sectionSpacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newUrl = _urlController.text.trim();
                  if (newUrl.isNotEmpty) {
                    // Actualizar la URL del servicio si está disponible
                    widget.serverService?.updateServerUrl(newUrl);
                    
                    // Mostrar mensaje de confirmación
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: ServerConfigStyles.tinySpacing),
                            Text('Server URL updated to: $newUrl'),
                          ],
                        ),
                        backgroundColor: ServerConfigStyles.successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ServerConfigStyles.buttonBorderRadius),
                        ),
                      ),
                    );
                    
                    // Devolver la nueva URL para que la pantalla principal se actualice
                    Navigator.pop(context, newUrl);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid URL'),
                        backgroundColor: ServerConfigStyles.errorColor,
                      ),
                    );
                  }
                },
                style: ServerConfigStyles.saveButtonStyle,
                child: Text(
                  'Save Configuration',
                  style: ServerConfigStyles.buttonTextStyle,
                ),
              ),
            ),
            const SizedBox(height: ServerConfigStyles.sectionSpacing), // Add bottom padding for safe area
          ],
        ),
      ),
    );
  }  Widget _buildConfigOption(String title, String url, IconData icon) {
    final isSelected = _urlController.text == url;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _urlController.text = url;
          _connectionStatus = null; // Reset connection status
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: ServerConfigStyles.configOptionSpacing),
        padding: ServerConfigStyles.configOptionPadding,
        decoration: ServerConfigStyles.getConfigOptionDecoration(isSelected),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? ServerConfigStyles.primaryColor : ServerConfigStyles.secondaryTextColor,
              size: ServerConfigStyles.iconSize,
            ),
            const SizedBox(width: ServerConfigStyles.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ServerConfigStyles.getConfigOptionTitleStyle(isSelected),
                  ),
                  Text(
                    url,
                    style: ServerConfigStyles.getConfigOptionUrlStyle(isSelected),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: ServerConfigStyles.primaryColor,
                size: ServerConfigStyles.iconSize,
              ),
          ],
        ),
      ),
    );
  }
}
