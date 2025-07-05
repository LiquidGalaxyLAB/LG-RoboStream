import 'package:flutter_test/flutter_test.dart';
import 'package:robostream/services/slave_calculator.dart';

void main() {
  group('SlaveCalculator', () {
    test('should calculate correct screens for 3 screens', () {
      final calculator = SlaveCalculator(totalScreens: 3);
      
      expect(calculator.leftmostScreen, 3); // 3 // 2 + 2 = 1 + 2 = 3
      expect(calculator.rightmostScreen, 2); // 3 // 2 + 1 = 1 + 1 = 2
      expect(calculator.masterScreen, 2); // (3 // 2) + 1 = 1 + 1 = 2
      expect(calculator.isValidScreenCount, true);
    });

    test('should calculate correct screens for 5 screens', () {
      final calculator = SlaveCalculator(totalScreens: 5);
      
      expect(calculator.leftmostScreen, 4); // 5 // 2 + 2 = 2 + 2 = 4
      expect(calculator.rightmostScreen, 3); // 5 // 2 + 1 = 2 + 1 = 3
      expect(calculator.masterScreen, 3); // (5 // 2) + 1 = 2 + 1 = 3
      expect(calculator.isValidScreenCount, true);
    });

    test('should calculate correct screens for 7 screens', () {
      final calculator = SlaveCalculator(totalScreens: 7);
      
      expect(calculator.leftmostScreen, 5); // 7 // 2 + 2 = 3 + 2 = 5
      expect(calculator.rightmostScreen, 4); // 7 // 2 + 1 = 3 + 1 = 4
      expect(calculator.masterScreen, 4); // (7 // 2) + 1 = 3 + 1 = 4
      expect(calculator.isValidScreenCount, true);
    });

    test('should return false for even number of screens', () {
      final calculator = SlaveCalculator(totalScreens: 4);
      
      expect(calculator.isValidScreenCount, false);
    });

    test('should return false for zero or negative screens', () {
      final calculator1 = SlaveCalculator(totalScreens: 0);
      final calculator2 = SlaveCalculator(totalScreens: -1);
      
      expect(calculator1.isValidScreenCount, false);
      expect(calculator2.isValidScreenCount, false);
    });

    test('should generate correct all screens list', () {
      final calculator = SlaveCalculator(totalScreens: 5);
      
      expect(calculator.allScreens, [1, 2, 3, 4, 5]);
    });

    test('should return correct toString', () {
      final calculator = SlaveCalculator(totalScreens: 3);
      
      expect(calculator.toString(), 
        'SlaveCalculator(totalScreens: 3, leftmost: 3, rightmost: 2, master: 2)');
    });
  });
}
