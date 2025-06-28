// Test script para verificar la funcionalidad RGB Camera
// Este archivo puede ser eliminado después de las pruebas

import 'package:flutter_test/flutter_test.dart';
import 'package:robostream/services/server.dart';

void main() {
  group('RGB Camera Tests', () {
    late RobotServerService service;
    
    setUp(() {
      service = RobotServerService();
    });
    
    test('RGB Camera data should be available', () async {
      final cameraData = await service.getRGBCameraData();
      expect(cameraData, isNotNull);
      expect(cameraData!.cameraId, equals('RGB_CAM_01'));
      expect(cameraData.resolution, equals('1920x1080'));
      expect(cameraData.fps, equals(30));
      expect(cameraData.rotationInterval, equals(180)); // 3 minutes
    });
    
    test('RGB Camera image data should be available', () async {
      final imageData = await service.getRGBCameraImageData();
      expect(imageData, isNotNull);
      expect(imageData!['camera_info'], isNotNull);
      expect(imageData['timing'], isNotNull);
      expect(imageData['image_metadata'], isNotNull);
    });
    
    test('RGB Camera image URL should be correct', () {
      final imageUrl = service.getRGBCameraImageUrl();
      expect(imageUrl, contains('/rgb-camera/image'));
    });
  });
}
