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
  bool _isClearingLogos = false;
  bool _isClearingKmlLogos = false;
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      CustomSnackBar.showError(context, message);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      CustomSnackBar.showSuccess(context, message);
    }
  }

  void _saveConfiguration() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      HapticFeedback.mediumImpact();

      final serverUrl = await ServerConfigManager.instance.getServerUrl();
      if (serverUrl == null) {
        if (mounted) {
          _showErrorSnackBar('Server URL is not configured.');
          setState(() {
            _isSaving = false;
          });
        }
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
        widget.onConfigSaved(
          fields['host'], 
          fields['username'], 
          fields['password'], 
          fields['totalScreens']
        );
        
        final serverIp = await ServerConfigManager.instance.getSavedServerIp();
        if (serverIp != null) {
          await http.post(
            Uri.parse('http://$serverIp:8000/lg/show-logo'),
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        if(mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          _showErrorSnackBar('Failed to save configuration on server: ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving configuration: ${e.toString()}');
      }
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

    final confirmed = await _showGenericConfirmationDialog(
      title: 'Confirm Clear KML',
      message: 'This will remove the current KML overlays from the rightmost screen.',
      icon: Icons.clear_all_rounded,
      color: const Color(0xFF9333EA),
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;

    if (mounted) {
      setState(() {
        _isClearing = true;
      });
    }

    try {
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
            if (mounted) {
              _showSuccessSnackBar('All KML content cleared successfully from Liquid Galaxy');
            }
          } else {
            if (mounted) {
              _showErrorSnackBar('Failed to clear all KML: ${responseData['message']}');
            }
          }
        } else {
          if (mounted) {
            _showErrorSnackBar('Failed to clear all KML from Liquid Galaxy');
          }
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Server configuration not found');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error clearing KML files: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  void _clearLogos() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    final confirmed = await _showGenericConfirmationDialog(
      title: 'Confirm Clear Logos',
      message: 'This will remove the logos from the leftmost screen.',
      icon: Icons.image_not_supported_outlined,
      color: const Color(0xFF0EA5E9),
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;

    if (mounted) {
      setState(() { _isClearingLogos = true; });
    }

    try {
      final serverIp = await ServerConfigManager.instance.getSavedServerIp();
      if (serverIp != null) {
        final response = await http.post(
          Uri.parse('http://$serverIp:8000/lg/clear-logos'),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
            if (data['success'] == true) {
              HapticFeedback.mediumImpact();
              if (mounted) _showSuccessSnackBar('Leftmost screen cleared');
            } else {
              if (mounted) _showErrorSnackBar('Failed to clear logos: ${data['message']}');
            }
        } else {
          if (mounted) _showErrorSnackBar('Failed to clear logos');
        }
      } else {
        if (mounted) _showErrorSnackBar('Server configuration not found');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error clearing logos: $e');
    } finally {
      if (mounted) setState(() { _isClearingLogos = false; });
    }
  }

  void _clearKmlAndLogos() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    final confirmed = await _showGenericConfirmationDialog(
      title: 'Confirm Clear KML + Logos',
      message: 'This will clear both the rightmost screen KML overlays and the leftmost screen logos.',
      icon: Icons.layers_clear_outlined,
      color: const Color(0xFFEF4444),
      confirmLabel: 'Clear All',
    );
    if (!confirmed) return;

    if (mounted) {
      setState(() { _isClearingKmlLogos = true; });
    }

    try {
      final serverIp = await ServerConfigManager.instance.getSavedServerIp();
      if (serverIp != null) {
        final response = await http.post(
          Uri.parse('http://$serverIp:8000/lg/clear-kml-logos'),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
            if (data['success'] == true) {
              HapticFeedback.mediumImpact();
              if (mounted) _showSuccessSnackBar('Leftmost & rightmost screens cleared');
            } else {
              if (mounted) _showErrorSnackBar('Failed to clear KML + logos: ${data['message']}');
            }
        } else {
          if (mounted) _showErrorSnackBar('Failed to clear KML + logos');
        }
      } else {
        if (mounted) _showErrorSnackBar('Server configuration not found');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error clearing KML + logos: $e');
    } finally {
      if (mounted) setState(() { _isClearingKmlLogos = false; });
    }
  }

  Future<bool> _showRelaunchConfirmationDialog() async {
    if (!mounted) return false;
    
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

  Future<bool> _showGenericConfirmationDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String confirmLabel = 'Confirm',
  }) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This action cannot be undone.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                )
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
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 6),
                        Text(confirmLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              )
            ],
        );
      }
    );
    return result ?? false;
  }

  void _relaunchLG() async {
    final fields = _getValidatedFields();
    if (fields == null) return;

    final shouldRelaunch = await _showRelaunchConfirmationDialog();
    if (!shouldRelaunch) return;

    if (mounted) {
      setState(() {
        _isRelaunching = true;
      });
    }

    try {
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
            if (mounted) {
              _showSuccessSnackBar('Liquid Galaxy relaunched successfully');
            }
          } else {
            if (mounted) {
              _showErrorSnackBar('Failed to relaunch LG: ${responseData['message']}');
            }
          }
        } else {
          if (mounted) {
            _showErrorSnackBar('Failed to relaunch Liquid Galaxy');
          }
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Server configuration not found');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error relaunching LG: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRelaunching = false;
        });
      }
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildConfigForm(),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // All buttons always visible (compact spacing)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    isLoading: _isClearingLogos,
                    onPressed: _clearLogos,
                    color: const Color(0xFF0EA5E9),
                    icon: Icons.image_not_supported_outlined,
                    text: 'Clear Logos',
                    loadingText: 'Clearing...'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    isLoading: _isClearing,
                    onPressed: _clearAllKML,
                    color: const Color(0xFF9333EA),
                    icon: Icons.clear_all_rounded,
                    text: 'Clear KML',
                    loadingText: 'Clearing...'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              isLoading: _isClearingKmlLogos,
              onPressed: _clearKmlAndLogos,
              color: const Color(0xFFEF4444),
              icon: Icons.layers_clear_outlined,
              text: 'Clear KML + Logos',
              loadingText: 'Clearing...'),
            const SizedBox(height: 8),
            _buildActionButton(
              isLoading: _isRelaunching,
              onPressed: _relaunchLG,
              color: const Color(0xFF6366F1),
              icon: Icons.restart_alt_rounded,
              text: 'Relaunch Liquid Galaxy',
              loadingText: 'Relaunching...'),
            const SizedBox(height: 10),
            _buildActionButton(
              isLoading: _isSaving,
              onPressed: _saveConfiguration,
              color: const Color(0xFF10B981),
              icon: Icons.save_rounded,
              text: 'Save Configuration',
              loadingText: 'Saving...'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
    required String text,
    required String loadingText,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () { HapticFeedback.mediumImpact(); onPressed(); },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: isLoading ? 0 : 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              isLoading ? loadingText : text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
