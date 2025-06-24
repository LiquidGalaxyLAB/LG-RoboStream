import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:robostream/services/server_config_service.dart';

void main() {
  group('ServerConfigService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and retrieve server IP', () async {
      const testIp = '192.168.1.100:8080';
      
      // Guardar IP
      await ServerConfigService.saveServerIp(testIp);
      
      // Recuperar IP
      final retrievedIp = await ServerConfigService.getServerIp();
      
      expect(retrievedIp, equals(testIp));
    });

    test('should detect custom configuration when IP is saved', () async {
      const testIp = '10.0.2.15:3000';
      
      // Inicialmente no debe haber configuración personalizada
      expect(await ServerConfigService.hasCustomConfig(), isFalse);
      
      // Guardar IP
      await ServerConfigService.saveServerIp(testIp);
      
      // Ahora debe detectar configuración personalizada
      expect(await ServerConfigService.hasCustomConfig(), isTrue);
    });

    test('should return correct config type', () async {
      // Inicialmente debe ser Default
      expect(await ServerConfigService.getConfigType(), equals('Default'));
      
      // Después de guardar IP debe ser Custom IP
      await ServerConfigService.saveServerIp('192.168.1.1:8000');
      expect(await ServerConfigService.getConfigType(), equals('Custom IP'));
    });

    test('should clear custom configuration', () async {
      const testIp = '172.16.0.1:9000';
      
      // Guardar configuración
      await ServerConfigService.saveServerIp(testIp);
      expect(await ServerConfigService.hasCustomConfig(), isTrue);
      
      // Limpiar configuración
      await ServerConfigService.clearCustomConfig();
      
      // Verificar que se limpió
      expect(await ServerConfigService.hasCustomConfig(), isFalse);
      expect(await ServerConfigService.getServerIp(), equals(''));
      expect(await ServerConfigService.getConfigType(), equals('Default'));
    });

    test('should handle empty server IP correctly', () async {
      // Guardar IP vacía
      await ServerConfigService.saveServerIp('');
      
      // No debe marcar como configuración personalizada
      expect(await ServerConfigService.hasCustomConfig(), isFalse);
      expect(await ServerConfigService.getConfigType(), equals('Default'));
    });
  });
}
