class LGConfigService {
  // In-memory storage for configuration
  static Map<String, String>? _lgConfig;
  
  // Default value for screens
  static const String _defaultTotalScreens = '3';

  /// Saves Liquid Galaxy configuration in memory
  static Future<void> saveLGConfig({
    required String host,
    required String username,
    required String password,
    int totalScreens = 3,
  }) async {
    _lgConfig = {
      'host': host,
      'username': username,
      'password': password,
      'totalScreens': totalScreens.toString(),
    };
  }

  /// Gets all LG configuration
  static Future<Map<String, String>> getLGConfig() async {
    return _lgConfig ?? {
      'host': '',
      'username': '',
      'password': '',
      'totalScreens': '',
    };
  }

  /// Gets the total number of screens
  static Future<int> getTotalScreens() async {
    final config = await getLGConfig();
    return int.tryParse(config['totalScreens'] ?? _defaultTotalScreens) ?? 3;
  }

}
