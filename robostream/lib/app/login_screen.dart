import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:robostream/app/login_cubit.dart';
import 'package:robostream/app/login_state.dart';
import 'package:robostream/assets/styles/login_styles.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppStyles.backgroundGradient,
          ),
          child: BlocListener<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccess) {
                // Mostrar mensaje de éxito si está disponible
                if (state.message != null && state.message!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message!),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                // Navegar después de un breve delay para que se vea el mensaje
                Future.delayed(const Duration(milliseconds: 800), () {
                  context.go('/');
                });
              }
              if (state is LoginFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppStyles.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const _LoginView(),
          ),
        ),
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

  // Removidas las variables estáticas para guardar configuración - no las necesitamos

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;

  // Focus nodes for better interaction feedback
  final _lgIpFocus = FocusNode();
  final _lgUsernameFocus = FocusNode();
  final _lgPasswordFocus = FocusNode();

  // Secret functionality variables
  int _secretTapCount = 0;
  static const int _requiredTaps = 7;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startContinuousAnimations();
    // Removido: _loadSavedConfiguration(); - No queremos cargar datos guardados
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
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 8000),
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

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _startContinuousAnimations() {
    _particleController.repeat();
  }
  @override
  void dispose() {
    _lgIpController.dispose();
    _lgUsernameController.dispose();
    _lgPasswordController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _lgIpFocus.dispose();
    _lgUsernameFocus.dispose();
    _lgPasswordFocus.dispose();
    super.dispose();
  }
  void _onLoginPressed() {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // La configuración se guardará automáticamente cuando el login sea exitoso
    
    context.read<LoginCubit>().login(
          lgIpAddress: _lgIpController.text,
          lgUsername: _lgUsernameController.text,
          lgPassword: _lgPasswordController.text,
        );
  }

  // Secret functionality method
  void _handleSecretTap() {
    _secretTapCount++;
    if (_secretTapCount >= _requiredTaps) {
      // Navigate directly to home screen without any message
      _secretTapCount = 0; // Reset counter
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fixed animated background elements
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
        // Enhanced animated background with floating particles
        ...List.generate(6, (index) => _buildFloatingParticle(index)),
        
        // Main content with enhanced animations
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
                      // Enhanced logo without breathing animation
                      GestureDetector(
                        onTap: _handleSecretTap,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1400),
                          curve: AppStyles.bouncyCurve,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
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
                      ),
                      
                      // Enhanced title with shimmer effect
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) => AppStyles.primaryGradient.createShader(bounds),
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
                      
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
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
                      
                      // Enhanced form fields with better animations
                      ..._buildEnhancedAnimatedFields(),
                      
                      const SizedBox(height: 32),
                      
                      // Enhanced button with better feedback
                      BlocBuilder<LoginCubit, LoginState>(
                        builder: (context, state) {
                          return _buildEnhancedButton(state);
                        },
                      ),
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

  Widget _buildFloatingParticle(int index) {
    final delays = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625];
    final sizes = [80.0, 60.0, 100.0, 70.0, 90.0, 110.0];
    final positions = [
      const Offset(-50, 100),
      const Offset(300, 50),
      const Offset(50, 600),
      const Offset(250, 500),
      const Offset(100, 300),
      const Offset(200, 200),
    ];

    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        final animatedValue = (_particleAnimation.value + delays[index]) % 1.0;
        
        // Safe opacity calculation
        final baseOpacity = 0.03;
        final variationOpacity = 0.02 * (0.5 + 0.5 * math.sin(animatedValue * 2 * math.pi));
        final finalOpacity = (baseOpacity + variationOpacity);
        
        return Positioned(
          left: positions[index].dx + (20 * math.sin(animatedValue * 2 * math.pi)),
          top: positions[index].dy + (15 * math.cos(animatedValue * 2 * math.pi)),
          child: Opacity(
            opacity: finalOpacity.clamp(0.0, 1.0), // Clamping here for safety
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppStyles.primaryColor.withOpacity(0.06),
                    AppStyles.secondaryColor.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      ),
      _buildEnhancedTextField(
        controller: _lgUsernameController,
        focusNode: _lgUsernameFocus,
        label: 'LG Username',
        icon: Icons.person_outline,
        nextFocus: _lgPasswordFocus,
      ),
      _buildEnhancedTextField(
        controller: _lgPasswordController,
        focusNode: _lgPasswordFocus,
        label: 'LG Password',
        icon: Icons.lock_outline,
        obscureText: true,
      ),
    ];

    return fields
        .asMap()
        .entries
        .map((entry) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 700 + (entry.key * 150)),
              curve: AppStyles.bouncyCurve,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: entry.value,
                    ),
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
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        
        return AnimatedContainer(
          duration: AppStyles.mediumDuration,
          curve: AppStyles.primaryCurve,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: isFocused ? AppStyles.elevatedShadow : AppStyles.cardShadow,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (_) {
              if (nextFocus != null) {
                nextFocus.requestFocus();
              } else {
                _onLoginPressed();
              }
            },
            onTap: () => HapticFeedback.selectionClick(),
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              prefixIcon: AnimatedContainer(
                duration: AppStyles.mediumDuration,
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isFocused ? AppStyles.primaryGradient : AppStyles.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isFocused ? [
                    BoxShadow(
                      color: AppStyles.primaryColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : [],
                ),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: 22,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              labelStyle: LoginStyles.getTextFieldLabelStyle(isFocused),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedButton(LoginState state) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: AppStyles.bouncyCurve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedContainer(
            duration: AppStyles.mediumDuration,
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppStyles.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: state is LoginInProgress 
                  ? AppStyles.cardShadow 
                  : AppStyles.floatingShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: state is LoginInProgress ? null : () {
                  HapticFeedback.mediumImpact();
                  _onLoginPressed();
                },
                splashColor: Colors.white.withOpacity(0.25),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  alignment: Alignment.center,
                  child: state is LoginInProgress
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
