import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/assets/styles/app_styles.dart';

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
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  
  late FocusNode _focusNode;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onSubmitted: widget.onSubmitted,        style: _textStyle,
        decoration: _getInputDecoration(isFocused),
      ),
    );
  }

  BoxDecoration _getContainerDecoration(bool isFocused) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16.0),
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
      fillColor: _fillColor,
      border: _getBorder(),
      focusedBorder: _getFocusedBorder(),
      errorBorder: _getErrorBorder(),
      focusedErrorBorder: _getErrorBorder(),
      labelStyle: _getLabelStyle(isFocused),
      hintStyle: _hintStyle,
      helperStyle: _helperStyle,
      errorStyle: _errorStyle,
      contentPadding: _contentPadding,
    );
  }

  Widget? _buildPrefixIcon(bool isFocused) {
    if (widget.icon == null) return null;
    
    const activePrefixGradient = LinearGradient(
      colors: [AppStyles.primaryColor, Color(0xFF5B61F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return AnimatedContainer(
      duration: AppStyles.mediumDuration,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: isFocused ? activePrefixGradient : _inactivePrefixGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isFocused ? [
          BoxShadow(
            color: AppStyles.primaryColor.withOpacity(0.25),
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

  Color get _fillColor => widget.isEnabled ? Colors.white : Colors.grey[100]!;

  OutlineInputBorder _getBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide.none,
    );
  }

  OutlineInputBorder _getFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide(
        color: AppStyles.primaryColor,
        width: 2,
      ),
    );
  }

  OutlineInputBorder _getErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: const BorderSide(
        color: AppStyles.errorColor,
        width: 2,
      ),
    );
  }

  TextStyle get _textStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      );

  TextStyle _getLabelStyle(bool isFocused) {
    return TextStyle(
      fontSize: isFocused ? 14 : 16,
      fontWeight: FontWeight.w500,
      color: isFocused ? AppStyles.primaryColor : Colors.grey[600],
    );
  }

  TextStyle get _hintStyle => TextStyle(
        fontSize: 14,
        color: Colors.grey[500],
      );

  TextStyle get _helperStyle => TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      );

  TextStyle get _errorStyle => const TextStyle(
        fontSize: 12,
        color: AppStyles.errorColor,
        fontWeight: FontWeight.w500,
      );

  EdgeInsets get _contentPadding => const EdgeInsets.symmetric(horizontal: 16, vertical: 20);

  LinearGradient get _inactivePrefixGradient => const LinearGradient(
        colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
