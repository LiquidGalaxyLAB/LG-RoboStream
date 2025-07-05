import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:robostream/services/lg_service.dart';
import 'package:robostream/services/lg_config_service.dart';
import 'package:robostream/assets/styles/login_styles.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppStyles.backgroundGradient,
        ),
        child: const _LoginView(),
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with TickerProviderStateMixin {
  final _lgIpController = TextEditingController();
  final _lgUsernameController = TextEditingController();
  final _lgPasswordController = TextEditingController();
  final _totalScreensController = TextEditingController(); // Remove default value
  
  bool _isLoading = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _lgIpFocus = FocusNode();
  final _lgUsernameFocus = FocusNode();
  final _lgPasswordFocus = FocusNode();
  final _totalScreensFocus = FocusNode();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTextFieldListeners();
    _loadSavedConfig();
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
    // Listeners for real-time UI updates
    _lgIpController.addListener(() => setState(() {}));
    _lgUsernameController.addListener(() => setState(() {}));
    _lgPasswordController.addListener(() => setState(() {}));
    _totalScreensController.addListener(() => setState(() {}));
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppStyles.bouncyCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: AppStyles.smoothCurve,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _lgIpController.dispose();
    _lgUsernameController.dispose();
    _lgPasswordController.dispose();
    _totalScreensController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _lgIpFocus.dispose();
    _lgUsernameFocus.dispose();
    _lgPasswordFocus.dispose();
    _totalScreensFocus.dispose();
    super.dispose();
  }
  void _onLoginPressed() async {
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppStyles.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      
      final totalScreens = int.tryParse(_totalScreensController.text);
      if (totalScreens == null || totalScreens <= 0 || totalScreens % 2 == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Number of screens must be a positive odd number (e.g.: 3, 5, 7)'),
            backgroundColor: AppStyles.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
          _showSuccessAnimation();
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              context.go('/');
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppStyles.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
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

  void _showSuccessAnimation() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14b981).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFF14b981).withOpacity(0.1),
                        blurRadius: 60,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF14b981),
                          const Color(0xFF10a674),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        onEnd: () => HapticFeedback.selectionClick(),
                        builder: (context, tickValue, child) {
                          return Transform.scale(
                            scale: tickValue,
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 70,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    // Auto-close the dialog
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppStyles.primaryColor.withOpacity(0.08),
                    AppStyles.primaryColor.withOpacity(0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppStyles.secondaryColor.withOpacity(0.08),
                    AppStyles.secondaryColor.withOpacity(0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with scale animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1400),
                        curve: AppStyles.bouncyCurve,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Image.asset(
                                'lib/assets/Images/ROBOSTREAM_FINAL_LOGO.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                      // App title with gradient
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, _) {
                          return ShaderMask(
                            shaderCallback: (bounds) => AppStyles.titleGradient.createShader(bounds),
                            child: Text(
                              'RoboStream',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 36,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Subtitle with fade animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, _) {
                          return Opacity(
                            opacity: value,
                            child: Text(
                              'Connect to your robot and start streaming',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                      
                      ..._buildEnhancedAnimatedFields(),
                      
                      const SizedBox(height: 32),
                      
                      _buildEnhancedButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEnhancedAnimatedFields() {
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
                    // Use labelText when NOT active, hintText when active
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

  Widget _buildEnhancedButton() {
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
                onTap: _isLoading ? null : () {
                  HapticFeedback.mediumImpact();
                  _onLoginPressed();
                },
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.rocket_launch,
                              color: Colors.white,
                              size: LoginStyles.buttonIconSize,
                            ),
                            SizedBox(width: LoginStyles.buttonIconSpacing),
                            Text(
                              'Connect',
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
