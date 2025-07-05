import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/services/lg_service.dart';
import 'package:robostream/services/lg_config_service.dart';
import 'package:robostream/assets/styles/login_styles.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class LiquidGalaxyLoginForm extends StatefulWidget {
  final String serverIp;
  final VoidCallback onLoginSuccess;
  final Function(String) onError;
  
  const LiquidGalaxyLoginForm({
    super.key,
    required this.serverIp,
    required this.onLoginSuccess,
    required this.onError,
  });

  @override
  State<LiquidGalaxyLoginForm> createState() => _LiquidGalaxyLoginFormState();
}

class _LiquidGalaxyLoginFormState extends State<LiquidGalaxyLoginForm> {
  final _lgIpController = TextEditingController();
  final _lgUsernameController = TextEditingController();
  final _lgPasswordController = TextEditingController();
  final _totalScreensController = TextEditingController();
  
  final _lgIpFocus = FocusNode();
  final _lgUsernameFocus = FocusNode();
  final _lgPasswordFocus = FocusNode();
  final _totalScreensFocus = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _setupTextFieldListeners();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _lgIpController.dispose();
    _lgUsernameController.dispose();
    _lgPasswordController.dispose();
    _totalScreensController.dispose();
    _lgIpFocus.dispose();
    _lgUsernameFocus.dispose();
    _lgPasswordFocus.dispose();
    _totalScreensFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final config = await LGConfigService.getLGConfig();
    setState(() {
      _lgIpController.text = config['host'] ?? '';
      _lgUsernameController.text = config['username'] ?? '';
      _lgPasswordController.text = config['password'] ?? '';
      _totalScreensController.text = config['totalScreens'] ?? '';
    });
  }

  void _setupTextFieldListeners() {
    _lgIpController.addListener(() => setState(() {}));
    _lgUsernameController.addListener(() => setState(() {}));
    _lgPasswordController.addListener(() => setState(() {}));
    _totalScreensController.addListener(() => setState(() {}));
  }

  Future<void> _onLoginPressed() async {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check for missing fields
      List<String> missingFields = [];
      
      if (_lgIpController.text.isEmpty) {
        missingFields.add('LG IP Address');
      }
      if (_lgUsernameController.text.isEmpty) {
        missingFields.add('LG Username');
      }
      if (_lgPasswordController.text.isEmpty) {
        missingFields.add('LG Password');
      }
      if (_totalScreensController.text.isEmpty) {
        missingFields.add('Total Screens');
      }
      
      if (missingFields.isNotEmpty) {
        String errorMessage;
        if (missingFields.length == 4) {
          errorMessage = 'Please fill in all required fields';
        } else if (missingFields.length == 1) {
          errorMessage = 'Please enter the ${missingFields.first}';
        } else {
          errorMessage = 'Please enter the following fields: ${missingFields.join(', ')}';
        }
        
        widget.onError(errorMessage);
        return;
      }
      
      final totalScreens = int.tryParse(_totalScreensController.text);
      if (totalScreens == null || totalScreens <= 0 || totalScreens % 2 == 0) {
        widget.onError('Number of screens must be a positive odd number (e.g.: 3, 5, 7)');
        return;
      }
      
      final result = await LGService.login(
        lgIpAddress: _lgIpController.text,
        lgUsername: _lgUsernameController.text,
        lgPassword: _lgPasswordController.text,
        totalScreens: totalScreens,
      );
      
      if (mounted) {
        if (result.success) {
          widget.onLoginSuccess();
        } else {
          widget.onError(result.message);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Server connection info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppStyles.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppStyles.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_done,
                color: AppStyles.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected to: ${widget.serverIp}:8000',
                  style: TextStyle(
                    color: AppStyles.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // LG Form fields
        ..._buildAnimatedFields(),
        const SizedBox(height: 32),
        
        // Login button
        _buildLoginButton(),
      ],
    );
  }

  List<Widget> _buildAnimatedFields() {
    final fields = [
      _buildEnhancedTextField(
        controller: _lgIpController,
        focusNode: _lgIpFocus,
        label: 'LG IP Address',
        icon: Icons.lan,
        nextFocus: _lgUsernameFocus,
        hintText: 'e.g., 192.168.1.100',
      ),
      _buildEnhancedTextField(
        controller: _lgUsernameController,
        focusNode: _lgUsernameFocus,
        label: 'LG Username',
        icon: Icons.person_outline_rounded,
        nextFocus: _lgPasswordFocus,
        hintText: 'Enter your main LG username',
      ),
      _buildEnhancedTextField(
        controller: _lgPasswordController,
        focusNode: _lgPasswordFocus,
        label: 'LG Password',
        icon: Icons.lock_outline_rounded,
        obscureText: !_isPasswordVisible,
        nextFocus: _totalScreensFocus,
        hintText: 'Enter your main LG password',
        isPasswordField: true,
      ),
      _buildEnhancedTextField(
        controller: _totalScreensController,
        focusNode: _totalScreensFocus,
        label: 'Total Screens',
        icon: Icons.monitor,
        hintText: '3, 5, 7, etc.',
        keyboardType: TextInputType.number,
      ),
    ];

    return fields
        .asMap()
        .entries
        .map((entry) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + (entry.key * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: entry.value,
                  ),
                );
              },
            ))
        .toList();
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool obscureText = false,
    FocusNode? nextFocus,
    String? hintText,
    bool isPasswordField = false,
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
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: nextFocus != null 
                      ? TextInputAction.next 
                      : TextInputAction.done,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    letterSpacing: 0.3,
                    height: 1.4,
                  ),
                  onSubmitted: (_) {
                    if (nextFocus != null) {
                      nextFocus.requestFocus();
                    } else {
                      _onLoginPressed();
                    }
                  },
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
                    suffixIcon: _buildSuffixIcon(isPasswordField, hasContent, isFocused),
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

  Widget? _buildSuffixIcon(bool isPasswordField, bool hasContent, bool isFocused) {
    if (isPasswordField) {
      return AnimatedOpacity(
        opacity: hasContent ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isPasswordVisible 
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                key: ValueKey(_isPasswordVisible),
                color: isFocused 
                    ? AppStyles.primaryColor 
                    : Colors.grey[500],
                size: 22,
              ),
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
              HapticFeedback.lightImpact();
            },
            splashRadius: 20,
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildLoginButton() {
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
              boxShadow: _isLoading 
                  ? AppStyles.cardShadow 
                  : AppStyles.floatingShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isLoading ? null : _onLoginPressed,
                splashColor: Colors.white.withOpacity(0.25),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
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
                              Icons.rocket_launch,
                              color: Colors.white,
                              size: LoginStyles.buttonIconSize,
                            ),
                            SizedBox(width: LoginStyles.buttonIconSpacing),
                            Text(
                              'Connect to Liquid Galaxy',
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
