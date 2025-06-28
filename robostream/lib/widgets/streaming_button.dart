import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StreamingButton extends StatefulWidget {
  final bool isStreaming;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const StreamingButton({
    Key? key,
    required this.isStreaming,
    required this.isEnabled,
    this.onPressed,
  }) : super(key: key);

  @override
  State<StreamingButton> createState() => _StreamingButtonState();
}

class _StreamingButtonState extends State<StreamingButton> {
  void _handlePress() {
    if (widget.isEnabled && widget.onPressed != null) {
      HapticFeedback.mediumImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isStreaming 
        ? const Color(0xFFEF4444) 
        : const Color(0xFF6366F1);
    
    final disabledColor = Colors.grey.shade400;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          // Sombra principal
          BoxShadow(
            color: (widget.isEnabled ? primaryColor : disabledColor)
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(25),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _handlePress,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: widget.isEnabled
                  ? LinearGradient(
                      colors: widget.isStreaming
                          ? [
                              const Color(0xFFEF4444),
                              const Color(0xFFDC2626),
                            ]
                          : [
                              const Color(0xFF6366F1),
                              const Color(0xFF4F46E5),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        disabledColor,
                        disabledColor.withOpacity(0.8),
                      ],
                    ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono con animación
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    widget.isStreaming ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(widget.isStreaming),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Texto con animación
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.isStreaming ? 'Stop Streaming' : 'Start Streaming',
                    key: ValueKey(widget.isStreaming),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
