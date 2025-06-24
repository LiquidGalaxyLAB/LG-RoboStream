import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/assets/styles/app_styles.dart';

/// Widget de campo de texto reutilizable con estilos predefinidos
/// Solo necesitas pasar el label, controller y configuraciones - todo el estilo está incluido
class CustomTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isEnabled;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final CustomTextFieldStyle fieldStyle;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isEnabled = true,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.fieldStyle = CustomTextFieldStyle.standard,
    this.textInputAction,
    this.onSubmitted,
  });

  /// Campo para direcciones IP
  const CustomTextField.ip({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isEnabled = true,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.textInputAction,
    this.onSubmitted,
  })  : icon = Icons.lan,
        obscureText = false,
        keyboardType = TextInputType.url,
        fieldStyle = CustomTextFieldStyle.ip;

  /// Campo para contraseñas
  const CustomTextField.password({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isEnabled = true,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.textInputAction,
    this.onSubmitted,
  })  : icon = Icons.lock_outline,
        obscureText = true,
        keyboardType = TextInputType.visiblePassword,
        fieldStyle = CustomTextFieldStyle.password;

  /// Campo para nombres de usuario
  const CustomTextField.username({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isEnabled = true,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.textInputAction,
    this.onSubmitted,
  })  : icon = Icons.person_outline,
        obscureText = false,
        keyboardType = TextInputType.text,
        fieldStyle = CustomTextFieldStyle.username;

  /// Campo para URLs/Servidores
  const CustomTextField.url({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isEnabled = true,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.textInputAction,
    this.onSubmitted,
  })  : icon = Icons.settings_ethernet,
        obscureText = false,
        keyboardType = TextInputType.url,
        fieldStyle = CustomTextFieldStyle.url;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _obscureText = false;
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    
    _animationController = AnimationController(
      duration: AppStyles.mediumDuration,
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppStyles.primaryCurve,
    ));
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        final isFocused = _focusNode.hasFocus;
        
        return AnimatedContainer(
          duration: AppStyles.mediumDuration,
          decoration: _getContainerDecoration(isFocused),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            enabled: widget.isEnabled,
            textInputAction: widget.textInputAction,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            onSubmitted: widget.onSubmitted,
            style: _getTextStyle(),
            decoration: _getInputDecoration(isFocused),
          ),
        );
      },
    );
  }

  BoxDecoration _getContainerDecoration(bool isFocused) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      boxShadow: isFocused ? AppStyles.elevatedShadow : AppStyles.cardShadow,
    );
  }

  InputDecoration _getInputDecoration(bool isFocused) {
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      prefixIcon: _buildPrefixIcon(isFocused),
      suffixIcon: _buildSuffixIcon(),
      filled: true,
      fillColor: _getFillColor(),
      border: _getBorder(),
      enabledBorder: _getBorder(),
      focusedBorder: _getFocusedBorder(),
      errorBorder: _getErrorBorder(),
      focusedErrorBorder: _getErrorBorder(),
      labelStyle: _getLabelStyle(isFocused),
      hintStyle: _getHintStyle(),
      helperStyle: _getHelperStyle(),
      errorStyle: _getErrorStyle(),
      contentPadding: _getContentPadding(),
    );
  }

  Widget? _buildPrefixIcon(bool isFocused) {
    if (widget.icon == null) return null;
    
    return AnimatedContainer(
      duration: AppStyles.mediumDuration,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: isFocused ? _getPrefixGradient() : _getInactivePrefixGradient(),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isFocused ? [
          BoxShadow(
            color: _getPrefixColor().withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : [],
      ),
      child: Icon(
        widget.icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (!widget.obscureText) return null;
    
    return IconButton(
      icon: Icon(
        _obscureText ? Icons.visibility : Icons.visibility_off,
        color: _focusNode.hasFocus ? AppStyles.primaryColor : Colors.grey,
      ),
      onPressed: _toggleObscureText,
    );
  }

  // Métodos de estilo basados en el tipo de campo
  double _getBorderRadius() {
    switch (widget.fieldStyle) {
      case CustomTextFieldStyle.standard:
      case CustomTextFieldStyle.ip:
      case CustomTextFieldStyle.password:
      case CustomTextFieldStyle.username:
      case CustomTextFieldStyle.url:
        return 16.0;
    }
  }

  Color _getFillColor() {
    return widget.isEnabled ? Colors.white : Colors.grey[100]!;
  }

  OutlineInputBorder _getBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: BorderSide.none,
    );
  }

  OutlineInputBorder _getFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: BorderSide(
        color: _getPrefixColor(),
        width: 2,
      ),
    );
  }

  OutlineInputBorder _getErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: const BorderSide(
        color: AppStyles.errorColor,
        width: 2,
      ),
    );
  }

  TextStyle _getTextStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );
  }

  TextStyle _getLabelStyle(bool isFocused) {
    return TextStyle(
      fontSize: isFocused ? 14 : 16,
      fontWeight: FontWeight.w500,
      color: isFocused ? _getPrefixColor() : Colors.grey[600],
    );
  }

  TextStyle _getHintStyle() {
    return TextStyle(
      fontSize: 14,
      color: Colors.grey[500],
    );
  }

  TextStyle _getHelperStyle() {
    return TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    );
  }

  TextStyle _getErrorStyle() {
    return const TextStyle(
      fontSize: 12,
      color: AppStyles.errorColor,
      fontWeight: FontWeight.w500,
    );
  }

  EdgeInsets _getContentPadding() {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  }

  Color _getPrefixColor() {
    switch (widget.fieldStyle) {
      case CustomTextFieldStyle.standard:
        return AppStyles.primaryColor;
      case CustomTextFieldStyle.ip:
        return AppStyles.accentColor;
      case CustomTextFieldStyle.password:
        return AppStyles.warningColor;
      case CustomTextFieldStyle.username:
        return AppStyles.secondaryColor;
      case CustomTextFieldStyle.url:
        return AppStyles.primaryColor;
    }
  }

  LinearGradient _getPrefixGradient() {
    final color = _getPrefixColor();
    return LinearGradient(
      colors: [color, color.withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient _getInactivePrefixGradient() {
    return LinearGradient(
      colors: [Colors.grey[400]!, Colors.grey[500]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

enum CustomTextFieldStyle {
  standard,
  ip,
  password,
  username,
  url,
}
