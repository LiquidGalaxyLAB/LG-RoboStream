import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelemetryCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const TelemetryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<TelemetryCard> createState() => _TelemetryCardState();
}

class _TelemetryCardState extends State<TelemetryCard>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pulseController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pulseController.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pulseController.reverse();
  }

  void _onHover(bool hover) {
    setState(() => _isHovered = hover);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: _isHovered
                        ? Border.all(
                            color: widget.color.withOpacity(0.2),
                            width: 2,
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Animated icon container
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.0,
                          end: _isHovered ? 1.0 : 0.0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.color.withOpacity(0.1 + (0.1 * value)),
                                  widget.color.withOpacity(0.05 + (0.15 * value)),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isHovered
                                  ? [
                                      BoxShadow(
                                        color: widget.color.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              widget.icon,
                              size: 32,
                              color: widget.color,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Animated text
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _isHovered
                                  ? widget.color
                                  : const Color(0xFF1E293B),
                              fontSize: _isHovered ? 17 : 16,
                            ),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Subtle indicator
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isHovered ? 30 : 20,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color.withOpacity(_isHovered ? 0.8 : 0.3),
                              widget.color.withOpacity(_isHovered ? 0.4 : 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}