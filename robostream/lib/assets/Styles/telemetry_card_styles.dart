import 'package:flutter/material.dart';

class TelemetryCardStyles {
  // Animation durations
  static const Duration scaleDuration = Duration(milliseconds: 200);
  static const Duration hoverDuration = Duration(milliseconds: 300);
  
  // Animation curves
  static const Curve scaleOutCurve = Curves.easeOutCubic;
  
  // Scale factors
  static const double pressedScale = 0.95;
  static const double hoveredScale = 1.02;
  static const double normalScale = 1.0;
  
  // Border radius
  static const double containerBorderRadius = 24;
  static const double iconContainerBorderRadius = 16;
  static const double indicatorBorderRadius = 2;
  
  // Padding
  static const EdgeInsets containerPadding = EdgeInsets.all(24.0);
  static const EdgeInsets iconContainerPadding = EdgeInsets.all(16);
  
  // Spacing
  static const double iconTextSpacing = 16;
  static const double textIndicatorSpacing = 8;
  
  // Icon size
  static const double iconSize = 32;
  
  // Font sizes
  static const double normalFontSize = 16;
  static const double hoveredFontSize = 17;
  
  // Font weight
  static const FontWeight textFontWeight = FontWeight.w600;
  
  // Colors
  static const Color textColor = Color(0xFF1E293B);
  
  // Indicator dimensions
  static const double normalIndicatorWidth = 20;
  static const double hoveredIndicatorWidth = 30;
  static const double indicatorHeight = 3;
  
  // Opacity values
  static const double shadowOpacity = 0.1;
  static const double blackShadowOpacity = 0.04;
  static const double borderOpacity = 0.2;
  static const double iconGradientNormalOpacity1 = 0.1;
  static const double iconGradientNormalOpacity2 = 0.05;
  static const double iconGradientHoverOpacity1 = 0.15;
  static const double iconGradientHoverOpacity2 = 0.15;
  static const double iconShadowOpacity = 0.3;
  static const double indicatorGradientHoveredOpacity1 = 0.8;
  static const double indicatorGradientHoveredOpacity2 = 0.4;
  static const double indicatorGradientNormalOpacity1 = 0.3;
  static const double indicatorGradientNormalOpacity2 = 0.1;
  static const double whiteContainerOpacity = 0.9;
  
  // Shadow offsets
  static const Offset primaryShadowOffset = Offset(0, 8);
  static const Offset secondaryShadowOffset = Offset(0, 4);
  static const Offset iconShadowOffset = Offset(0, 5);
  
  // Shadow blur radius
  static const double primaryShadowBlur = 20;
  static const double secondaryShadowBlur = 10;
  static const double iconShadowBlur = 15;
  
  // Border width
  static const double borderWidth = 2;
  
  // Container decoration method
  static BoxDecoration getContainerDecoration(Color color, bool isHovered) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(whiteContainerOpacity),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(containerBorderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(shadowOpacity),
          blurRadius: primaryShadowBlur,
          offset: primaryShadowOffset,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(blackShadowOpacity),
          blurRadius: secondaryShadowBlur,
          offset: secondaryShadowOffset,
        ),
      ],
      border: isHovered
          ? Border.all(
              color: color.withOpacity(borderOpacity),
              width: borderWidth,
            )
          : null,
    );
  }
  
  // Icon container decoration method
  static BoxDecoration getIconContainerDecoration(Color color, double hoverValue, bool isHovered) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(iconGradientNormalOpacity1 + (iconGradientHoverOpacity1 * hoverValue)),
          color.withOpacity(iconGradientNormalOpacity2 + (iconGradientHoverOpacity2 * hoverValue)),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(iconContainerBorderRadius),
      boxShadow: isHovered
          ? [
              BoxShadow(
                color: color.withOpacity(iconShadowOpacity),
                blurRadius: iconShadowBlur,
                offset: iconShadowOffset,
              ),
            ]
          : [],
    );
  }
  
  // Text style method
  static TextStyle getTextStyle(BuildContext context, Color color, bool isHovered) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: textFontWeight,
      color: isHovered ? color : textColor,
      fontSize: isHovered ? hoveredFontSize : normalFontSize,
    );
  }
  
  // Indicator decoration method
  static BoxDecoration getIndicatorDecoration(Color color, bool isHovered) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(isHovered ? indicatorGradientHoveredOpacity1 : indicatorGradientNormalOpacity1),
          color.withOpacity(isHovered ? indicatorGradientHoveredOpacity2 : indicatorGradientNormalOpacity2),
        ],
      ),
      borderRadius: BorderRadius.circular(indicatorBorderRadius),
    );
  }
}
