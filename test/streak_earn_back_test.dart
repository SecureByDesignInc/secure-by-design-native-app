import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/screens/path_screen.dart';
import 'package:secure_by_design_app/widgets/learning_rewards.dart';

void main() {
  for (final large in [false, true]) {
    testWidgets('Home offers a free restore after a missed day, large: $large',
        (tester) async {
      tester.view.physicalSize =
          large ? const Size(320, 740) : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'sbd.guidance.started.v1': '2026-09-01T00:00:00Z',
        'sbd.guidance.enabled.v1': false
      });
      var now = DateTime(2026, 10, 1);
      final store = await LearningStore.load(clock: () => now);
      for (var i = 0; i < 5; i++) {
        await store.finishLesson('ad-1');
        now = now.add(const Duration(days: 1));
      }
      // Oct 6 and 7 use both freezes; Oct 8 is missed; Oct 9 is today.
      now = DateTime(2026, 10, 9);
      expect(store.stats.earnBack?.streak, 5);

      await tester.pumpWidget(SecureByDesignApp(store: store));
      await tester.pumpAndSettle();
      expect(find.byType(EarnBackCard), findsOneWidget);
      expect(find.text('Your 5-day streak is still in reach.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final start = find.descendant(
          of: find.byType(EarnBackCard), matching: find.text('Start a lesson'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);

      // Two lessons today restore the streak and the offer disappears.
      await store.finishLesson('ad-1');
      await store.finishLesson('ad-2');
      expect(store.stats.streak, 6);
      expect(store.stats.earnBack, isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }

  testWidgets('a milestone celebration skips its motion when asked to',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
            textDirection: TextDirection.ltr,
            child: MilestoneEmblem(days: 30))));
    expect(find.text('30'), findsOneWidget);
    expect(find.bySemanticsLabel('30-day streak milestone'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    semantics.dispose();
  });
}
