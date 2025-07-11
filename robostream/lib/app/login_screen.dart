import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:robostream/assets/styles/app_styles.dart';
import 'package:robostream/widgets/login_widgets/login_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:robostream/services/lg_service_manager.dart';
import 'package:robostream/services/server_config_manager.dart';

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
  // Server connection state
  bool _isServerConnected = false;
  String _serverIp = '';
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _screenFadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    _screenFadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _screenFadeController.dispose();
    super.dispose();
  }

  void _onLoginSuccess() {
    _showSuccessAnimation();
    // Start fade out animation
    _screenFadeController.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        context.go('/?fromLogin=true');
      }
    });
  }

  void _onError(String message) {
    _showErrorMessage(message);
  }

  Future<void> _fetchAndSaveLGConfigFromServer(String serverIp) async {
    try {
      // We assume the default port, as it's not available in the login screen.
      // The server config screen should be used for non-default ports.
      final port = await ServerConfigManager.instance.getSavedServerPort();
      final serverUrl = 'http://$serverIp:$port';
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
      // Silently fail, the user can still input the data manually.
      print('Could not fetch LG config from server on login: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyles.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyles.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessAnimation() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Center(
          child: AnimatedBuilder(
            animation: _screenFadeController,
            builder: (context, child) {
              return Transform.scale(
                scale: _screenFadeController.value,
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
                      child: AnimatedBuilder(
                        animation: _screenFadeController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _screenFadeController.value,
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

  // Helper method for simplified decorative circles
  Widget _buildDecorativeCircle(double size, Color color) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _screenFadeController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value * (1.0 - _screenFadeController.value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.08),
                  color.withOpacity(0.04),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _screenFadeController,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _screenFadeController.value,
          child: Stack(
            children: [
              // Simplified background decorative elements
              Positioned(
                top: -100,
                right: -100,
                child: _buildDecorativeCircle(200, AppStyles.primaryColor),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: _buildDecorativeCircle(160, AppStyles.secondaryColor),
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
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _fadeAnimation.value,
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
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => AppStyles.titleGradient.createShader(bounds),
                                    child: Text(
                                      'RoboStream',
                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 36,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // Subtitle with fade animation
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Text(
                                    _isServerConnected
                                        ? 'Configure Liquid Galaxy connection'
                                        : 'Connect to your robot server to begin',
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
                            
                            // Show different forms based on server connection state with fade transition
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.3),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    )),
                                    child: child,
                                  ),
                                );
                              },
                              child: !_isServerConnected
                                  ? ServerConnectionForm(
                                      key: const ValueKey('server-form'),
                                      onConnectionSuccess: (serverIp) async {
                                        _showSuccessMessage('Server connected successfully! Please configure Liquid Galaxy.');
                                        await _fetchAndSaveLGConfigFromServer(serverIp);
                                        setState(() {
                                          _isServerConnected = true;
                                          _serverIp = serverIp;
                                        });
                                      },
                                      onError: _onError,
                                    )
                                  : LiquidGalaxyLoginForm(
                                      key: const ValueKey('lg-form'),
                                      serverIp: _serverIp,
                                      onLoginSuccess: _onLoginSuccess,
                                      onError: _onError,
                                    ),
                            ),
                          ],
                        ),
                      ),
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

}
