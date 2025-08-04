import 'package:flutter/material.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class LoginStyles {
  LoginStyles._();
  
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: AppStyles.backgroundGradient,
  );

  static BoxDecoration errorSnackBarDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
  );
  static const Color errorSnackBarColor = AppStyles.errorColor;

  static const SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating;

  static TextStyle? titleTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: 36,
    );
  }

  static TextStyle? subtitleTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.grey[600],
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
  }

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
  static const EdgeInsets fieldPadding = EdgeInsets.only(bottom: 18);

  static const double logoSize = 150.0;
  static const double titleSpacing = 8.0;
  static const double sectionSpacing = 36.0;
  static const double buttonSpacing = 32.0;

  static BoxDecoration textFieldDecoration({required bool isFocused}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: isFocused ? AppStyles.elevatedShadow : AppStyles.cardShadow,
    );
  }

  static const Duration animationDuration = Duration(milliseconds: 1400);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration slideAnimationDuration = Duration(milliseconds: 1000);
  static const Duration fieldAnimationDuration = Duration(milliseconds: 700);
  static const Curve animationCurve = AppStyles.bouncyCurve;
  static const Curve primaryCurve = AppStyles.primaryCurve;

  static const List<double> particleSizes = [80.0, 60.0, 100.0, 70.0, 90.0, 110.0];
  static const List<double> particleDelays = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625];
  static const List<Offset> particlePositions = [
    Offset(-50, 100),
    Offset(300, 50),
    Offset(50, 600),
    Offset(250, 500),
    Offset(100, 300),
    Offset(200, 200),
  ];

  static const double baseParticleOpacity = 0.03;
  static const double variationParticleOpacity = 0.02;
  static const double backgroundCircleOpacity = 0.08;
  static const double backgroundCircleSecondaryOpacity = 0.04;

  static const double primaryBackgroundCircleSize = 200.0;
  static const double secondaryBackgroundCircleSize = 160.0;

  static const Offset primaryCircleOffset = Offset(-100, -100);
  static const Offset secondaryCircleOffset = Offset(-80, -80);

  static TextStyle getTextFieldLabelStyle(bool isFocused) {
    return TextStyle(
      color: isFocused ? AppStyles.primaryColor : Colors.grey[600],
      fontWeight: isFocused ? FontWeight.w600 : FontWeight.w500,
    );
  }

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const double buttonIconSize = 24;

  static const double buttonIconSpacing = 12;
}
