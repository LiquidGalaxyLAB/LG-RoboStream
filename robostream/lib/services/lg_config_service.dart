class LGConfigService {
  // Almacenamiento en memoria para la configuración
  static Map<String, String>? _lgConfig;
  
  // Valores por defecto
  static const String _defaultHost = '192.168.1.100';
  static const String _defaultUsername = 'lg';
  static const String _defaultPassword = 'lg';

  /// Guarda la configuración de Liquid Galaxy en memoria
  static Future<void> saveLGConfig({
    required String host,
    required String username,
    required String password,
  }) async {
    _lgConfig = {
      'host': host,
      'username': username,
      'password': password,
    };
  }

  /// Obtiene toda la configuración de LG
  static Future<Map<String, String>> getLGConfig() async {
    return _lgConfig ?? {
      'host': _defaultHost,
      'username': _defaultUsername,
      'password': _defaultPassword,
    };
  }


}
