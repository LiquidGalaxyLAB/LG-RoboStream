import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:robostream/assets/styles/app_styles.dart';
import 'package:robostream/widgets/login_widgets/login_widgets.dart';

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
  late AnimationController _stateTransitionController;
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
    _stateTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    _stateTransitionController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _stateTransitionController.dispose();
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

  void _animateStateTransition() {
    _stateTransitionController.reset();
    _stateTransitionController.forward();
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
    return AnimatedBuilder(
      animation: _screenFadeController,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _screenFadeController.value,
          child: Stack(
            children: [
              // Background decorative elements with enhanced fade
              Positioned(
                top: -100,
                right: -100,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fadeAnimation, _screenFadeController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * (1.0 - _screenFadeController.value),
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
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fadeAnimation, _screenFadeController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * (1.0 - _screenFadeController.value),
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
                    );
                  },
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
                                return FadeTransition(
                                  opacity: AlwaysStoppedAnimation(value),
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
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1000),
                              builder: (context, value, _) {
                                return FadeTransition(
                                  opacity: AlwaysStoppedAnimation(value),
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
                                      onConnectionSuccess: (serverIp) {
                                        _animateStateTransition();
                                        setState(() {
                                          _isServerConnected = true;
                                          _serverIp = serverIp;
                                        });
                                        _showSuccessMessage('Server connected successfully! Please configure Liquid Galaxy.');
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
