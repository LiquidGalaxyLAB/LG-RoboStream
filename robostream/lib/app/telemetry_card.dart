import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/assets/styles/telemetry_card_styles.dart';

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

class _TelemetryCardState extends State<TelemetryCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  void _onHover(bool hover) {
    setState(() => _isHovered = hover);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: Transform.scale(
        scale: _isPressed 
            ? TelemetryCardStyles.pressedScale 
            : (_isHovered 
                ? TelemetryCardStyles.hoveredScale 
                : TelemetryCardStyles.normalScale),
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Container(
        decoration: TelemetryCardStyles.getContainerDecoration(widget.color, _isHovered),
        padding: TelemetryCardStyles.containerPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAnimatedIcon(),
            const SizedBox(height: TelemetryCardStyles.iconTextSpacing),
            _buildLabel(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0.0,
        end: _isHovered ? 1.0 : 0.0,
      ),
      duration: TelemetryCardStyles.hoverDuration,
      builder: (context, value, child) {
        return Container(
          padding: TelemetryCardStyles.iconContainerPadding,
          decoration: TelemetryCardStyles.getIconContainerDecoration(widget.color, value, _isHovered),
          child: Icon(
            widget.icon,
            size: TelemetryCardStyles.iconSize,
            color: widget.color,
          ),
        );
      },
    );
  }

  Widget _buildLabel() {
    return Column(
      children: [
        AnimatedDefaultTextStyle(
          duration: TelemetryCardStyles.scaleDuration,
          style: TelemetryCardStyles.getTextStyle(context, widget.color, _isHovered),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: TelemetryCardStyles.textIndicatorSpacing),
        AnimatedContainer(
          duration: TelemetryCardStyles.hoverDuration,
          width: _isHovered ? TelemetryCardStyles.hoveredIndicatorWidth : TelemetryCardStyles.normalIndicatorWidth,
          height: TelemetryCardStyles.indicatorHeight,
          decoration: TelemetryCardStyles.getIndicatorDecoration(widget.color, _isHovered),
        ),
      ],
    );
  }
}