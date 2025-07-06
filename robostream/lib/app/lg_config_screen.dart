import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/widgets.dart';
import '../services/lg_connection_manager.dart';
import '../services/lg_service.dart';

class LGConfigScreen extends StatefulWidget {
  final String currentHost;
  final String currentUsername;
  final String currentPassword;
  final int currentTotalScreens;
  final Function(String host, String username, String password, int totalScreens) onConfigSaved;

  const LGConfigScreen({
    super.key,
    required this.currentHost,
    required this.currentUsername,
    required this.currentPassword,
    required this.currentTotalScreens,
    required this.onConfigSaved,
  });

  @override
  State<LGConfigScreen> createState() => _LGConfigScreenState();
}

class _LGConfigScreenState extends State<LGConfigScreen> {
  late TextEditingController _hostController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _totalScreensController;
  bool _isSaving = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.currentHost);
    _usernameController = TextEditingController(text: widget.currentUsername);
    _passwordController = TextEditingController(text: widget.currentPassword);
    _totalScreensController = TextEditingController(text: widget.currentTotalScreens.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _totalScreensController.dispose();
    super.dispose();
  }

  // Helper method for validation and getting values
  Map<String, dynamic>? _getValidatedFields() {
    final host = _hostController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final totalScreensText = _totalScreensController.text.trim();

    if (host.isEmpty || username.isEmpty || password.isEmpty || totalScreensText.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return null;
    }

    final totalScreens = int.tryParse(totalScreensText);
    if (totalScreens == null || totalScreens <= 0 || totalScreens % 2 == 0) {
      _showErrorSnackBar('Total screens must be an odd positive number (e.g., 3, 5, 7)');
      return null;
    }

    return {
      'host': host,
      'username': username,
      'password': password,
      'totalScreens': totalScreens,
    };
  }

  // Helper method for showing error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Helper method for showing success messages
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveConfiguration() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      HapticFeedback.mediumImpact();
      
      // Save configuration
      widget.onConfigSaved(
        fields['host'], 
        fields['username'], 
        fields['password'], 
        fields['totalScreens']
      );
      
      // Show logo on LG after saving configuration
      final lgService = LGService(
        host: fields['host'],
        username: fields['username'],
        password: fields['password'],
        totalScreens: fields['totalScreens'],
      );
      
      final connected = await lgService.connect();
      if (connected) {
        await lgService.showLogoUsingKML();
        lgService.disconnect();
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Error saving configuration: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _clearAllKML() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    setState(() {
      _isClearing = true;
    });

    try {
      final connectionManager = LGConnectionManager(
        host: fields['host'],
        username: fields['username'],
        password: fields['password'],
        totalScreens: fields['totalScreens'],
      );

      final connected = await connectionManager.connect();
      if (!connected) {
        _showErrorSnackBar('Failed to connect to Liquid Galaxy');
        setState(() {
          _isClearing = false;
        });
        return;
      }

      final success = await connectionManager.kmlSender?.clearAllSlaves() ?? false;
      connectionManager.disconnect();

      if (success) {
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar('All KML files cleared successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear some KML files'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error clearing KML files: ${e.toString()}');
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildConfigForm(),
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
                  color: const Color(0xFF6366F1).withOpacity(0.1),
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
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF6366F1),
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
                  'Liquid Galaxy Config',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure connection to LG system',
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
              color: const Color(0xFF10B981),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigForm() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          width: 1,
        ),
      ),
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
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.settings_ethernet_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Enter your Liquid Galaxy system details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            CustomTextField(
              label: 'Host/IP Address',
              controller: _hostController,
              hintText: 'e.g., 192.168.1.100',
              icon: Icons.computer,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              label: 'Username',
              controller: _usernameController,
              hintText: 'e.g., lg',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              label: 'Password',
              controller: _passwordController,
              hintText: 'Password',
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              label: 'Total Screens',
              controller: _totalScreensController,
              hintText: 'Odd number: 3, 5, 7, etc.',
              icon: Icons.monitor,
              keyboardType: TextInputType.number,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clear ALL KML Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isClearing ? null : _clearAllKML,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isClearing ? 0 : 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isClearing)
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
                        Icons.clear_all_rounded,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isClearing ? 'Clearing...' : 'Clear ALL KML',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Save Configuration Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfiguration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isSaving ? 0 : 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSaving)
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
                        Icons.save_rounded,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isSaving ? 'Saving...' : 'Save Configuration',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
