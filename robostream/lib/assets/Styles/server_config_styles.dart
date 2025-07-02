import 'package:flutter/material.dart';

class ServerConfigStyles {
  // Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color primaryTextColor = Color(0xFF1E293B);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color successColor = Color(0xFF10B981);
  static const Color successLightColor = Color(0xFF059669);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color cyanColor = Color(0xFF06B6D4);
  static const Color fillColor = Color(0xFFF1F5F9);
  static const Color lightBackgroundColor = Color(0xFFF8FAFC);
  static const Color successBackgroundColor = Color(0xFFF0FDF4);
  static const Color errorBackgroundColor = Color(0xFFFEF2F2);
  
  // Font sizes
  static const double titleFontSize = 24;
  static const double sectionTitleFontSize = 18;
  static const double labelFontSize = 16;
  static const double fieldLabelFontSize = 14;
  static const double statusTextFontSize = 12;
  static const double buttonFontSize = 16;
  static const double configOptionTitleFontSize = 14;
  static const double configOptionUrlFontSize = 12;
  
  // Font weights
  static const FontWeight titleFontWeight = FontWeight.w700;
  static const FontWeight sectionTitleFontWeight = FontWeight.w600;
  static const FontWeight labelFontWeight = FontWeight.w600;
  static const FontWeight fieldLabelFontWeight = FontWeight.w500;
  static const FontWeight buttonFontWeight = FontWeight.w600;
  static const FontWeight configOptionTitleFontWeight = FontWeight.w500;
  
  // Border radius
  static const double containerBorderRadius = 16;
  static const double textFieldBorderRadius = 12;
  static const double buttonBorderRadius = 8;
  static const double configOptionBorderRadius = 8;
  static const double iconContainerBorderRadius = 8;
  static const double statusContainerBorderRadius = 8;
  
  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const EdgeInsets containerPadding = EdgeInsets.all(20);
  static const EdgeInsets iconContainerPadding = EdgeInsets.all(8);
  static const EdgeInsets statusContainerPadding = EdgeInsets.all(12);
  static const EdgeInsets configOptionPadding = EdgeInsets.all(12);
  static const EdgeInsets buttonVerticalPadding = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets saveButtonVerticalPadding = EdgeInsets.symmetric(vertical: 16);
  
  // Spacing
  static const double sectionSpacing = 24;
  static const double itemSpacing = 20;
  static const double smallSpacing = 12;
  static const double tinySpacing = 8;
  static const double fieldSpacing = 8;
  static const double configOptionSpacing = 12;
  
  // Icon sizes
  static const double iconSize = 20;
  static const double smallIconSize = 16;
  
  // Shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
  
  // Border widths
  static const double focusBorderWidth = 2;
  static const double selectedBorderWidth = 2;
  static const double normalBorderWidth = 1;
  
  // Opacity values
  static const double iconBackgroundOpacity = 0.1;
  static const double borderOpacity = 0.3;
  static const double statusBorderOpacity = 0.2;
  static const double greyBorderOpacity = 0.2;
  
  // AppBar style
  static TextStyle get appBarTitleStyle => const TextStyle(
    fontSize: titleFontSize,
    fontWeight: titleFontWeight,
    color: primaryTextColor,
  );
  
  // Container decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(containerBorderRadius),
    boxShadow: const [cardShadow],
  );
  
  // Section title style
  static TextStyle get sectionTitleStyle => const TextStyle(
    fontSize: sectionTitleFontSize,
    fontWeight: sectionTitleFontWeight,
    color: primaryTextColor,
  );
  
  // Label style
  static TextStyle get labelStyle => const TextStyle(
    fontSize: labelFontSize,
    fontWeight: labelFontWeight,
    color: primaryTextColor,
  );
  
  // Field label style
  static TextStyle get fieldLabelStyle => const TextStyle(
    fontSize: fieldLabelFontSize,
    fontWeight: fieldLabelFontWeight,
    color: secondaryTextColor,
  );
  
  // TextField decoration
  static InputDecoration get textFieldDecoration => InputDecoration(
    hintText: 'http://localhost:8000',
    filled: true,
    fillColor: fillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(textFieldBorderRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(textFieldBorderRadius),
      borderSide: const BorderSide(
        color: primaryColor,
        width: focusBorderWidth,
      ),
    ),
    prefixIcon: const Icon(
      Icons.link,
      color: secondaryTextColor,
    ),
  );
  
  // Button styles
  static ButtonStyle get saveButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: saveButtonVerticalPadding,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(textFieldBorderRadius),
    ),
    elevation: 0,
  );
  
  // Status container decoration
  static BoxDecoration getStatusDecoration(bool isSuccess) {
    return BoxDecoration(
      color: isSuccess ? successBackgroundColor : errorBackgroundColor,
      borderRadius: BorderRadius.circular(statusContainerBorderRadius),
      border: Border.all(
        color: isSuccess 
            ? successColor.withOpacity(statusBorderOpacity)
            : errorColor.withOpacity(statusBorderOpacity),
      ),
    );
  }
  
  // Status text style
  static TextStyle getStatusTextStyle(bool isSuccess) {
    return TextStyle(
      fontSize: statusTextFontSize,
      color: isSuccess ? successColor : errorColor,
    );
  }
  
  // Icon container decoration
  static BoxDecoration getIconContainerDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(iconBackgroundOpacity),
      borderRadius: BorderRadius.circular(iconContainerBorderRadius),
    );
  }
  
  // Config option decoration
  static BoxDecoration getConfigOptionDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected 
          ? primaryColor.withOpacity(iconBackgroundOpacity) 
          : lightBackgroundColor,
      borderRadius: BorderRadius.circular(configOptionBorderRadius),
      border: Border.all(
        color: isSelected
            ? primaryColor
            : Colors.grey.withOpacity(greyBorderOpacity),
        width: isSelected ? selectedBorderWidth : normalBorderWidth,
      ),
    );
  }
  
  // Config option title style
  static TextStyle getConfigOptionTitleStyle(bool isSelected) {
    return TextStyle(
      fontSize: configOptionTitleFontSize,
      fontWeight: configOptionTitleFontWeight,
      color: isSelected ? primaryColor : primaryTextColor,
    );
  }
  
  // Config option URL style
  static TextStyle getConfigOptionUrlStyle(bool isSelected) {
    return TextStyle(
      fontSize: configOptionUrlFontSize,
      color: isSelected ? primaryColor : secondaryTextColor,
    );
  }
  
  // Button text style
  static TextStyle get buttonTextStyle => const TextStyle(
    fontSize: buttonFontSize,
    fontWeight: buttonFontWeight,
  );
  
  // Custom server info decoration
  static BoxDecoration get customServerInfoDecoration => BoxDecoration(
    color: successColor.withOpacity(iconBackgroundOpacity),
    borderRadius: BorderRadius.circular(statusContainerBorderRadius),
    border: Border.all(color: successColor.withOpacity(borderOpacity)),
  );
  
  // Custom server info text style
  static TextStyle get customServerInfoTextStyle => const TextStyle(
    fontSize: fieldLabelFontSize,
    color: successLightColor,
    fontWeight: fieldLabelFontWeight,
  );
}
