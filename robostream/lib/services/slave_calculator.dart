class SlaveCalculator {
  final int totalScreens;

  SlaveCalculator({required this.totalScreens});

  /// Calculates the leftmost screen number where the logo should be displayed
  /// Formula: totalScreens // 2 + 2
  int get leftmostScreen => totalScreens ~/ 2 + 2;

  /// Calculates the rightmost screen number where data and camera should be displayed
  /// Formula: totalScreens // 2 + 1
  int get rightmostScreen => totalScreens ~/ 2 + 1;

  /// Validates if the total screens number is valid
  bool get isValidScreenCount => totalScreens > 0 && totalScreens % 2 == 1;

  /// Gets all screen numbers from 1 to totalScreens
  List<int> get allScreens => List.generate(totalScreens, (index) => index + 1);

  /// Gets the middle screen number (master screen)
  int get masterScreen => (totalScreens ~/ 2) + 1;

  @override
  String toString() {
    return 'SlaveCalculator(totalScreens: $totalScreens, leftmost: $leftmostScreen, rightmost: $rightmostScreen, master: $masterScreen)';
  }
}
