import 'package:flutter/material.dart';
import 'package:robostream/config/server_config.dart';
import 'package:robostream/services/server.dart';

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
    // Usar la URL actual del servicio si está disponible
    _currentUrl = widget.serverService?.currentBaseUrl ?? ServerConfig.baseUrl;
    _urlController.text = _currentUrl;
  }
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Server Configuration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.settings_ethernet,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Server Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Server URL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'http://localhost:8000',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.link,
                        color: Color(0xFF64748B),
                      ),
                    ),                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestingConnection ? null : () {
                            _testConnection(_urlController.text);
                          },
                          icon: _isTestingConnection 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.wifi_find, size: 16),
                          label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_connectionStatus != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _connectionStatus!.contains('successfully') 
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _connectionStatus!.contains('successfully')
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFFEF4444).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _connectionStatus!.contains('successfully') 
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _connectionStatus!.contains('successfully')
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionStatus!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _connectionStatus!.contains('successfully')
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Common Configurations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
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
            ),
            const SizedBox(height: 24),
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
                            const SizedBox(width: 8),
                            Text('Server URL updated to: $newUrl'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    
                    // Devolver la nueva URL para que la pantalla principal se actualice
                    Navigator.pop(context, newUrl);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid URL'),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Add bottom padding for safe area
          ],
        ),
      ),
    );
  }
  Widget _buildConfigOption(String title, String url, IconData icon) {
    final isSelected = _urlController.text == url;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _urlController.text = url;
          _connectionStatus = null; // Reset connection status
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6366F1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
