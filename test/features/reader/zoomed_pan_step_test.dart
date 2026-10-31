import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('zoomedPanStep', () {
    test('a pan scrolls by its own step', () {
      final step = zoomedPanStep(y: -30, pinY: -10);
      expect(step.down, 20);
      expect(step.flingY, isNull);
    });

    test('a fling scrolls by the step since the last frame', () {
      // The viewer's fling sets the offset from its start each frame: -10
      // (the pin) to -40, -60, -70. The list goes 60 in all, not 30+50+60.
      const pinY = -10.0;
      double? flingY = pinY;
      var down = 0.0;
      for (final y in [-40.0, -60.0, -70.0]) {
        final step = zoomedPanStep(y: y, pinY: pinY, flingY: flingY);
        down += step.down;
        flingY = step.flingY;
      }
      expect(down, 60);
    });
  });
}
