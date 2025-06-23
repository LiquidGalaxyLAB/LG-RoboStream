class ServerConfig {
  // Configuración del servidor FastAPI
  // Cambia la IP por la de tu servidor Docker
  static const String baseUrl = 'http://localhost:8000';
  
  // Para usar con Docker en la misma máquina:
  // static const String baseUrl = 'http://localhost:8000';
  
  // Para usar con Docker en una máquina remota (cambia por la IP de tu servidor):
  // static const String baseUrl = 'http://192.168.1.100:8000';
  
  // Para usar con Docker Desktop en Windows/Mac:
  // static const String baseUrl = 'http://host.docker.internal:8000';
  
  static const Duration requestTimeout = Duration(seconds: 5);
  static const Duration updateInterval = Duration(seconds: 1);
}
