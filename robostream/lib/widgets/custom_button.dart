import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonStyle buttonStyle;
  final bool isEnabled;

  const CustomButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.buttonStyle = CustomButtonStyle.primary,
    this.isEnabled = true,
  });

  const CustomButton.launch({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  })  : icon = Icons.rocket_launch,
        buttonStyle = CustomButtonStyle.launch;

  const CustomButton.save({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  })  : icon = Icons.save,
        buttonStyle = CustomButtonStyle.save;

  const CustomButton.config({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  })  : icon = Icons.settings,
        buttonStyle = CustomButtonStyle.config;

  const CustomButton.streaming({
    super.key,
    required this.text,
    required this.onPressed,
    required IconData streamIcon,
    this.isLoading = false,
    this.isEnabled = true,
  })  : icon = streamIcon,
        buttonStyle = CustomButtonStyle.streaming;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  // Animation constants
  static const Duration _animationDuration = Duration(milliseconds: 100);
  static const double _pressedScale = 0.95;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _pressedScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.mediumImpact();
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.isEnabled && !widget.isLoading && widget.onPressed != null;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: AppStyles.mediumDuration,
          width: double.infinity,
          height: _getButtonHeight(),
          transform: Matrix4.identity()..scale(_scaleAnimation.value),
          decoration: _getButtonDecoration(),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          onTap: isInteractive ? widget.onPressed : null,
          onTapDown: isInteractive ? _onTapDown : null,
          onTapUp: isInteractive ? _onTapUp : null,
          onTapCancel: isInteractive ? _onTapCancel : null,
          splashColor: Colors.white.withOpacity(0.25),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            alignment: Alignment.center,
            child: widget.isLoading
                ? _buildLoadingWidget()
                : _buildButtonContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: _getTextColor(),
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            color: _getTextColor(),
            size: _getIconSize(),
          ),
          SizedBox(width: 12.0),
          Text(
            widget.text,
            style: _getTextStyle(),
          ),
        ],
      );
    } else {
      return Text(
        widget.text,
        style: _getTextStyle(),
      );
    }
  }

  double _getButtonHeight() {
    switch (widget.buttonStyle) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.launch:
        return 64.0;
      case CustomButtonStyle.streaming:
        return 48.0;
      case CustomButtonStyle.save:
      case CustomButtonStyle.config:
        return 56.0;
    }
  }
  
  double _getBorderRadius() {
    switch (widget.buttonStyle) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.launch:
        return 20.0;
      case CustomButtonStyle.streaming:
        return 32.0;
      case CustomButtonStyle.save:
      case CustomButtonStyle.config:
        return 16.0;
    }
  }

  BoxDecoration _getButtonDecoration() {
    if (!widget.isEnabled) {
      return BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        boxShadow: AppStyles.cardShadow,
      );
    }

    switch (widget.buttonStyle) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.launch:
        return BoxDecoration(
          gradient: AppStyles.primaryGradient,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: widget.isLoading ? AppStyles.cardShadow : AppStyles.floatingShadow,
        );
      case CustomButtonStyle.streaming:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [AppStyles.primaryColor, AppStyles.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: AppStyles.elevatedShadow,
        );
      case CustomButtonStyle.save:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [AppStyles.successColor, AppStyles.successColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: AppStyles.elevatedShadow,
        );
      case CustomButtonStyle.config:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [AppStyles.secondaryColor, AppStyles.secondaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: AppStyles.elevatedShadow,
        );
    }
  }

  Color _getTextColor() {
    return widget.isEnabled ? Colors.white : Colors.grey[600]!;
  }
  double _getIconSize() {
    switch (widget.buttonStyle) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.launch:
        return 24.0;
      case CustomButtonStyle.streaming:
        return 28.0;
      case CustomButtonStyle.save:
      case CustomButtonStyle.config:
        return 20.0;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.buttonStyle) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.launch:
      case CustomButtonStyle.streaming:
        return const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );
      case CustomButtonStyle.save:
      case CustomButtonStyle.config:
        return const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        );
    }
  }
}

enum CustomButtonStyle {
  primary,
  launch,
  save,
  config,
  streaming,
}
