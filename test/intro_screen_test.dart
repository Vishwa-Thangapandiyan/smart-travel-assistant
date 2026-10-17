import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_assistant/widgets/intro_screen.dart';

void main() {
  Widget app(VoidCallback onDone, {bool lessMotion = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: lessMotion),
          child: IntroScreen(onDone: onDone),
        ),
      );

  testWidgets('the intro plays for its length, then hands over once', (tester) async {
    var done = 0;
    await tester.pumpWidget(app(() => done++));

    await tester.pump(const Duration(seconds: 3));
    expect(done, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(done, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(done, 1);
  });

  testWidgets('a tap skips the intro', (tester) async {
    var done = 0;
    await tester.pumpWidget(app(() => done++));

    await tester.tap(find.byType(IntroScreen));
    expect(done, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(done, 1);
  });

  testWidgets('with less motion asked for, the intro is skipped', (tester) async {
    var done = 0;
    await tester.pumpWidget(app(() => done++, lessMotion: true));
    await tester.pump();

    expect(done, 1);
  });
}
