import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/services/server.dart';
import 'package:robostream/assets/styles/login_styles.dart';
import 'package:robostream/assets/styles/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConnectionForm extends StatefulWidget {
  final Function(String) onConnectionSuccess;
  final Function(String) onError;
  
  const ServerConnectionForm({
    super.key,
    required this.onConnectionSuccess,
    required this.onError,
  });

  @override
  State<ServerConnectionForm> createState() => _ServerConnectionFormState();
}

class _ServerConnectionFormState extends State<ServerConnectionForm> {
  final _serverIpController = TextEditingController();
  final _serverIpFocus = FocusNode();
  bool _isConnecting = false;
  RobotServerService? _serverService;

  @override
  void initState() {
    super.initState();
    _serverIpController.addListener(() => setState(() {}));
    // Removed _loadSavedServerIp() to prevent auto-filling
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _serverIpFocus.dispose();
    _serverService?.dispose();
    super.dispose();
  }

  Future<void> _onConnectPressed() async {
    HapticFeedback.mediumImpact();
    
    if (_serverIpController.text.isEmpty) {
      widget.onError('Please enter the server IP address');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // Save server IP to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', _serverIpController.text.trim());
      
      // Create server service with entered IP
      final serverUrl = 'http://${_serverIpController.text.trim()}:8000';
      _serverService = RobotServerService();
      _serverService!.updateServerUrl(serverUrl);
      
      // Test connection
      final isConnected = await _serverService!.checkConnection();
      
      if (mounted) {
        if (isConnected) {
          widget.onConnectionSuccess(_serverIpController.text.trim());
        } else {
          widget.onError('Unable to connect to server. Please check the IP address.');
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onError('Connection error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildEnhancedTextField(
                  controller: _serverIpController,
                  focusNode: _serverIpFocus,
                  label: 'Server IP Address',
                  icon: Icons.dns_rounded,
                  hintText: 'Enter server IP address',
                  keyboardType: TextInputType.url,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        _buildConnectButton(),
      ],
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        final hasContent = controller.text.isNotEmpty;
        final isActive = isFocused || hasContent;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // External floating label with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: isActive ? 24 : 0,
                padding: EdgeInsets.only(
                  left: 20,
                  bottom: isActive ? 6 : 0,
                ),
                child: AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFocused 
                          ? AppStyles.primaryColor
                          : Colors.grey[600],
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              
              // Modern input field
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: isFocused 
                          ? AppStyles.primaryColor.withOpacity(0.08)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: isFocused ? 16 : 4,
                      offset: Offset(0, isFocused ? 6 : 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    letterSpacing: 0.3,
                    height: 1.4,
                  ),
                  onSubmitted: (_) => _onConnectPressed(),
                  onTap: () => HapticFeedback.selectionClick(),
                  decoration: InputDecoration(
                    labelText: !isActive ? label : null,
                    hintText: isActive ? (hintText ?? 'Enter your ${label.toLowerCase()}') : null,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    labelStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isFocused 
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppStyles.primaryColor,
                                  AppStyles.secondaryColor,
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey[100]!,
                                  Colors.grey[200]!,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isFocused ? [
                          BoxShadow(
                            color: AppStyles.primaryColor.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedScale(
                        scale: isFocused ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          icon,
                          color: isFocused ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: isFocused 
                        ? Colors.white
                        : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: hasContent 
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: AppStyles.primaryColor,
                        width: 2.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: AppStyles.bouncyCurve,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: AnimatedContainer(
            duration: AppStyles.mediumDuration,
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppStyles.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isConnecting 
                  ? AppStyles.cardShadow 
                  : AppStyles.floatingShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isConnecting ? null : _onConnectPressed,
                splashColor: Colors.white.withOpacity(0.25),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  alignment: Alignment.center,
                  child: _isConnecting
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_find_rounded,
                              color: Colors.white,
                              size: LoginStyles.buttonIconSize,
                            ),
                            SizedBox(width: LoginStyles.buttonIconSpacing),
                            Text(
                              'Connect to Server',
                              style: LoginStyles.buttonTextStyle,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
