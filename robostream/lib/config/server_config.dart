class ServerConfig {
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  static const Duration requestTimeout = Duration(seconds: 5);
  static const Duration updateInterval = Duration(seconds: 10);
}
