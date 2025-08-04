import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/server_config_manager.dart';
import '../widgets/widgets.dart';
import '../widgets/common/custom_snackbar.dart';

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
  bool _isRelaunching = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.currentHost);
    _usernameController = TextEditingController(text: widget.currentUsername);
    _passwordController = TextEditingController(text: widget.currentPassword);
    _totalScreensController = TextEditingController(text: widget.currentTotalScreens.toString());
    _fetchConfigurationFromServer();
  }

  Future<void> _fetchConfigurationFromServer() async {
    try {
      final serverUrl = await ServerConfigManager.instance.getServerUrl();
      if (serverUrl == null) {
        // Server not configured, do nothing.
        return;
      }
      final response = await http.get(Uri.parse('$serverUrl/lg-config'));
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        if (mounted) {
          setState(() {
            _hostController.text = config['host'] ?? widget.currentHost;
            _usernameController.text = config['username'] ?? widget.currentUsername;
            _passwordController.text = config['password'] ?? widget.currentPassword;
            _totalScreensController.text = (config['total_screens'] ?? widget.currentTotalScreens).toString();
          });
        }
      }
    } catch (e) {
      // Silently fail if the server is not reachable or config doesn't exist
      print('Could not fetch LG config from server: $e');
    }
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
    CustomSnackBar.showError(context, message);
  }

  // Helper method for showing success messages
  void _showSuccessSnackBar(String message) {
    CustomSnackBar.showSuccess(context, message);
  }

  void _saveConfiguration() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      HapticFeedback.mediumImpact();

      final serverUrl = await ServerConfigManager.instance.getServerUrl();
      if (serverUrl == null) {
        _showErrorSnackBar('Server URL is not configured.');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('$serverUrl/lg-config'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'host': fields['host'],
          'username': fields['username'],
          'password': fields['password'],
          'total_screens': fields['totalScreens'],
        }),
      );

      if (response.statusCode == 200) {
        // Save configuration locally
        widget.onConfigSaved(
          fields['host'], 
          fields['username'], 
          fields['password'], 
          fields['totalScreens']
        );
        
        // Show logo on LG after saving configuration through server
        final serverIp = await ServerConfigManager.instance.getSavedServerIp();
        if (serverIp != null) {
          await http.post(
            Uri.parse('http://$serverIp:8000/lg/show-logo'),
            headers: {'Content-Type': 'application/json'},
          );
          // Logo request sent to server (no need to wait for response)
        }
        
        if(mounted) Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Failed to save configuration on server: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving configuration: ${e.toString()}');
    } finally {
      if(mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearAllKML() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    setState(() {
      _isClearing = true;
    });

    try {
      // Clear ALL KML through server
      final serverIp = await ServerConfigManager.instance.getSavedServerIp();
      if (serverIp != null) {
        final response = await http.post(
          Uri.parse('http://$serverIp:8000/lg/clear-all-kml'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            HapticFeedback.mediumImpact();
            _showSuccessSnackBar('All KML content cleared successfully from Liquid Galaxy');
          } else {
            _showErrorSnackBar('Failed to clear all KML: ${responseData['message']}');
          }
        } else {
          _showErrorSnackBar('Failed to clear all KML from Liquid Galaxy');
        }
      } else {
        _showErrorSnackBar('Server configuration not found');
      }
    } catch (e) {
      _showErrorSnackBar('Error clearing KML files: ${e.toString()}');
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  Future<bool> _showRelaunchConfirmationDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.restart_alt_rounded,
                color: Color(0xFF6366F1),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Confirm Relaunch',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to relaunch Liquid Galaxy?',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will restart all Liquid Galaxy services and may temporarily disconnect active connections.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(false);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt_rounded, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Relaunch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  void _relaunchLG() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    // Mostrar diálogo de confirmación
    final shouldRelaunch = await _showRelaunchConfirmationDialog();
    if (!shouldRelaunch) return;

    setState(() {
      _isRelaunching = true;
    });

    try {
      // Relaunch LG through server
      final serverIp = await ServerConfigManager.instance.getSavedServerIp();
      if (serverIp != null) {
        final response = await http.post(
          Uri.parse('http://$serverIp:8000/lg/relaunch'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            HapticFeedback.mediumImpact();
            _showSuccessSnackBar('Liquid Galaxy relaunched successfully');
          } else {
            _showErrorSnackBar('Failed to relaunch LG: ${responseData['message']}');
          }
        } else {
          _showErrorSnackBar('Failed to relaunch Liquid Galaxy');
        }
      } else {
        _showErrorSnackBar('Server configuration not found');
      }
    } catch (e) {
      _showErrorSnackBar('Error relaunching LG: ${e.toString()}');
    } finally {
      setState(() {
        _isRelaunching = false;
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
            // Relaunch LG Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRelaunching ? null : _relaunchLG,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isRelaunching ? 0 : 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRelaunching)
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
                        Icons.restart_alt_rounded,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isRelaunching ? 'Relaunching...' : 'Relaunch Liquid Galaxy',
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
