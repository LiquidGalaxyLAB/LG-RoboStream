import 'package:flutter/material.dart';

class AppTheme {
  // Enhanced color palette with more variants
  static const primaryColor = Color(0xFF6366F1);
  static const secondaryColor = Color(0xFF8B5CF6);
  static const accentColor = Color(0xFF06B6D4);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const surfaceColor = Colors.white;
  static const cardColor = Color(0xFFFFFBFF);
  static const errorColor = Color(0xFFEF4444);
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  
  // Gradient definitions with more variations
  static const primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFE2E8F0),
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
  );

  // Animation curves
  static const primaryCurve = Curves.easeOutCubic;
  static const bouncyCurve = Curves.elasticOut;
  static const smoothCurve = Curves.fastOutSlowIn;

  // Durations
  static const shortDuration = Duration(milliseconds: 200);
  static const mediumDuration = Duration(milliseconds: 400);
  static const longDuration = Duration(milliseconds: 600);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto', // Usar la fuente Roboto local
      
      // Tema de texto usando solo Regular (400) y Bold (700)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 40, 
          fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
          letterSpacing: -1.0,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 36, 
          fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
          letterSpacing: -0.8,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 32, 
          fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
          letterSpacing: -0.6,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 28, 
          fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
          letterSpacing: -0.4,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24, 
          fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 22, 
          fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
          letterSpacing: 0.0,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18, 
          fontWeight: FontWeight.normal, // Usa Roboto-Regular.ttf
          letterSpacing: 0.1,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16, 
          fontWeight: FontWeight.normal, // Usa Roboto-Regular.ttf
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14, 
          fontWeight: FontWeight.normal, // Usa Roboto-Regular.ttf
          letterSpacing: 0.3,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12, 
          fontWeight: FontWeight.normal, // Usa Roboto-Regular.ttf
          letterSpacing: 0.4,
          height: 1.6,
        ),
      ).apply(bodyColor: const Color(0xFF1E293B), displayColor: const Color(0xFF0F172A)),

      // Temas de componentes usando las fuentes locales
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: Color(0xFF0F172A),
          fontSize: 28,
          fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: primaryColor, size: 28),
      ),

      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.bold, // Usa Roboto-Bold.ttf
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.normal, // Usa Roboto-Regular.ttf
          letterSpacing: 0.2,
        ),
      ),

      // Enhanced page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      splashColor: primaryColor.withOpacity(0.1),
      highlightColor: primaryColor.withOpacity(0.05),
    );
  }

  // Custom box shadows for different elevations
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.2),
      blurRadius: 25,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}