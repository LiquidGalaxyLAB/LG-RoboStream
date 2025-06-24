import 'package:flutter/material.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class HomeStyles {
  // Duraciones de animación
  static const Duration mediumAnimationDuration = AppStyles.mediumDuration;
  static const Duration parallaxDuration = Duration(milliseconds: 3000);
  static const Duration headerDuration = Duration(milliseconds: 800);
  static const Duration statsDuration = Duration(milliseconds: 1200);
  static const Duration pulseDuration = Duration(milliseconds: 2000);
  static const Duration cardAnimationDuration = Duration(milliseconds: 600);

  // Padding y espaciado
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(24, 0, 24, 24);
  static const EdgeInsets headerPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: 24);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16);

  // Tamaños
  static const double headerHeight = 240.0;
  static const double cardBorderRadius = 24.0;
  static const double buttonBorderRadius = 16.0;
  static const double iconSize = 28.0;
  static const double avatarRadius = 28.0;

  // Colores para estados de conexión
  static const Color connectedColor = AppStyles.successColor;
  static const Color disconnectedColor = Color(0xFFEF4444);
  static const Color streamingColor = AppStyles.primaryColor;
  static const Color stoppedColor = Color(0xFFEF4444);

  // Gradientes
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667EEA),
      Color(0xFF764BA2),
      Color(0xFFF093FB),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fabGradient = LinearGradient(
    colors: [AppStyles.primaryColor, AppStyles.secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Estilos de texto
  static const TextStyle headerTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headerSubtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B),
  );

  static const TextStyle statLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF64748B),
  );

  static const TextStyle statValueStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1E293B),
  );

  static const TextStyle detailLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF64748B),
  );

  static const TextStyle detailValueStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B),
  );

  // Decoraciones
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    boxShadow: AppStyles.cardShadow,
  );

  static BoxDecoration get headerDecoration => const BoxDecoration(
    gradient: headerGradient,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    ),
  );

  static BoxDecoration get fabDecoration => BoxDecoration(
    gradient: fabGradient,
    borderRadius: BorderRadius.circular(buttonBorderRadius),
    boxShadow: AppStyles.elevatedShadow,
  );

  // Configuraciones de botones
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    padding: buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
  );

  // Efectos visuales
  static const double parallaxFactor = 0.3;
  static const double pulseScaleMin = 0.95;
  static const double pulseScaleMax = 1.05;

  // Configuraciones de dividers
  static Container get verticalDivider => Container(
    width: 1,
    height: 40,
    color: Colors.grey.shade200,
  );

  // Espaciado estándar
  static const SizedBox smallSpacing = SizedBox(height: 8);
  static const SizedBox mediumSpacing = SizedBox(height: 16);
  static const SizedBox largeSpacing = SizedBox(height: 24);
  static const SizedBox extraLargeSpacing = SizedBox(height: 32);

  // Iconos por defecto para diferentes tipos
  static const IconData connectedIcon = Icons.wifi;
  static const IconData disconnectedIcon = Icons.wifi_off;
  static const IconData streamingIcon = Icons.play_circle_fill;
  static const IconData stoppedIcon = Icons.pause_circle_filled;
  static const IconData settingsIcon = Icons.settings;
}
