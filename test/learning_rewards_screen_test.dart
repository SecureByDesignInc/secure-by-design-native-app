import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/data/catalog.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/screens/path_screen.dart';
import 'package:secure_by_design_app/theme.dart';
import 'package:secure_by_design_app/widgets/learning_rewards.dart';

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('previews').createSync(recursive: true);
    await File('previews/streak-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader('Geist')
          ..addFont(rootBundle.load('assets/fonts/Geist.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final large in [false, true]) {
    testWidgets(
        'streak, quests, goal setting and real completion are accessible, large: $large',
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
      var now = DateTime(2026, 9, 29);
      final store = await LearningStore.load(clock: () => now);
      for (var i = 0; i < 6; i++) {
        await store.finishLesson('ad-1');
        now = now.add(const Duration(days: 1));
      }
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary, child: SecureByDesignApp(store: store)));
      await tester.pumpAndSettle();
      expect(find.text('6-day streak'), findsOneWidget);
      if (!large) await _capture(tester, boundary, 'home');
      await _tap(tester, 'Start learning');
      await _tap(tester, 'Start the first lesson');
      expect(find.text('Your lesson'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tap(tester, 'Daily goal');
      await _tap(tester, 'Focused · 40 XP');
      expect(store.dailyGoal, 40);
      await _tap(tester, 'Quests & rewards');
      await tester.ensureVisible(find.text('Daily quests'));
      await tester.pumpAndSettle();
      if (!large) await _capture(tester, boundary, 'quests');
      expect(tester.takeException(), isNull);
      await _tap(tester, 'Practice what you know');
      expect(find.text('Practice'), findsOneWidget);
      final lesson = foundationPaths.first.lessons.first;
      await _tap(tester, lesson.answers[lesson.correctAnswer]);
      await _tap(tester, 'Complete review');
      expect(store.stats.streak, 7);
      expect(find.text('A week of learning'), findsOneWidget);
      expect(find.text('+25 XP'), findsOneWidget);
      if (!large) await _capture(tester, boundary, 'celebration');
      await _tap(tester, 'Continue');
      await _tap(tester, 'Practice what you know');
      await _tap(tester, lesson.answers[lesson.correctAnswer]);
      await _tap(tester, 'Complete review');
      expect(find.text('Practice complete'), findsOneWidget);
      expect(store.stats.todayXp, 25);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }
  testWidgets(
      'an incorrect first answer earns learning XP without a perfect bonus',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LearningStore.load(clock: () => DateTime(2026, 10, 5));
    final path = foundationPaths.first,
        lesson = foundationPaths.first.lessons.first;
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: LessonScreen(store: store, path: path, lesson: lesson)));
    await _tap(tester,
        lesson.answers[(lesson.correctAnswer + 1) % lesson.answers.length]);
    await _tap(tester, lesson.answers[lesson.correctAnswer]);
    await _tap(tester, 'Complete lesson');
    expect(find.byType(LessonCelebration), findsOneWidget);
    expect(find.text('+30 XP'), findsOneWidget);
    expect(store.stats.quests.last.complete, false);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
