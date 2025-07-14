import 'package:shared_preferences/shared_preferences.dart';

class LGConfigService {
  // Keys for SharedPreferences
  static const String _lgHostKey = 'lg_host';
  static const String _lgUsernameKey = 'lg_username';
  static const String _lgPasswordKey = 'lg_password';
  static const String _lgTotalScreensKey = 'lg_total_screens';
  
  // Default values
  static const String _defaultTotalScreens = '';

  /// Saves Liquid Galaxy configuration persistently
  static Future<void> saveLGConfig({
    required String host,
    required String username,
    required String password,
    required int totalScreens,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lgHostKey, host.trim());
      await prefs.setString(_lgUsernameKey, username.trim());
      await prefs.setString(_lgPasswordKey, password);
      await prefs.setInt(_lgTotalScreensKey, totalScreens);
    } catch (e) {
      // Error saving LG config - silent fail
    }
  }

  /// Gets all LG configuration
  static Future<Map<String, String>> getLGConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'host': prefs.getString(_lgHostKey) ?? '',
        'username': prefs.getString(_lgUsernameKey) ?? '',
        'password': prefs.getString(_lgPasswordKey) ?? '',
        'totalScreens': prefs.getInt(_lgTotalScreensKey)?.toString() ?? _defaultTotalScreens,
      };
    } catch (e) {
      return {
        'host': '',
        'username': '',
        'password': '',
        'totalScreens': _defaultTotalScreens,
      };
    }
  }

  /// Gets the total number of screens
  static Future<int> getTotalScreens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lgTotalScreensKey) ?? int.parse(_defaultTotalScreens);
    } catch (e) {
      return int.parse(_defaultTotalScreens);
    }
  }

  /// Clears all LG configuration
  static Future<void> clearLGConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lgHostKey);
      await prefs.remove(_lgUsernameKey);
      await prefs.remove(_lgPasswordKey);
      await prefs.remove(_lgTotalScreensKey);
    } catch (e) {
      // Error clearing LG config - silent fail
    }
  }
}
