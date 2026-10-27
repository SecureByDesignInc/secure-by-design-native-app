import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/app_tabs.dart';
import 'package:secure_by_design_app/data/ato_builder.dart';
import 'package:secure_by_design_app/data/catalog.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/screens/lab_mode_screen.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';
import 'package:secure_by_design_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Past the first-run welcome, as the other app tests are, so the tab bar is on screen.
  setUp(() => SharedPreferences.setMockInitialValues({'sbd.guidance.enabled.v1': false}));
  setUpAll(() async {
    await (FontLoader('Geist')..addFont(rootBundle.load('assets/fonts/Geist.ttf'))).load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  Future<LearningStore> pumpApp(WidgetTester tester, Size size, double scale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = await LearningStore.load();
    await tester.pumpWidget(SecureByDesignApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  test('the tabs follow the website’s navigation, in its order', () {
    expect(AppTab.values.map((t) => t.title), [
      'Home',
      'System Hub',
      'Training Hub',
      'Community & Careers Hub',
      'Cyber Range',
      'My Account',
    ]);
  });

  for (final (size, scale) in [
    (const Size(320, 740), 2.0),
    (const Size(390, 844), 1.0),
    (const Size(1280, 900), 1.0),
  ]) {
    testWidgets('six tabs fit and open each hub (${size.width.toInt()}px, ${scale}x)',
        (tester) async {
      await pumpApp(tester, size, scale);
      for (final tab in AppTab.values) {
        expect(find.byKey(ValueKey('tab-${tab.name}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('tab-systemHub')));
      await tester.pumpAndSettle();
      expect(find.text('Open the System Hub'), findsOneWidget);
      // The ATO Package Builder lives in the Training tab's Tools (website, 27 October 2026).
      await tester.tap(find.byKey(const ValueKey('tab-training')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tool-ato-builder')), findsOneWidget);
      expect(find.text('Open the builder'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tab-community')));
      await tester.pumpAndSettle();
      expect(find.text('Join the Discord'), findsOneWidget);
      expect(find.text('Find your state'), findsOneWidget);
      // No WebView platform under test, so the Range tab shows its open-in-browser card.
      await tester.tap(find.byKey(const ValueKey('tab-range')));
      await tester.pumpAndSettle();
      expect(find.text('Open the Cyber Range'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  // The seven RMF steps sit in the Training tab's Tools since 27 October 2026, as on the website.
  testWidgets('the Training tab lists the seven RMF steps with their course 2.1 lessons',
      (tester) async {
    await pumpApp(tester, const Size(390, 844), 1);
    await tester.tap(find.byKey(const ValueKey('tab-training')));
    await tester.pumpAndSettle();
    for (final step in rmfSteps) {
      await tester.scrollUntilVisible(find.text(step.title), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(step.title), findsWidgets);
    }
    final course = learningPaths.firstWhere((p) => p.id == rmfCourseId);
    expect(rmfSteps.expand((s) => s.lessonIds).toList(),
        course.lessons.map((l) => l.id).toList());
  });

  testWidgets('the Training Hub shows the website’s coming-soon tiles in course order',
      (tester) async {
    // One column, so course order is top-to-bottom order.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: Scaffold(body: TrainingLibraryScreen(store: store))));
    await tester.pumpAndSettle();
    expect(find.byType(ComingSoonCard), findsNWidgets(currentCatalog.comingSoon.length));
    final y = {
      for (final number in ['1.8', '1.9', '1.10', '1.11'])
        number: tester.getTopLeft(find.textContaining('$number ·').first).dy,
    };
    expect(y['1.8']! < y['1.9']! && y['1.9']! < y['1.10']! && y['1.10']! < y['1.11']!, isTrue);
    expect(find.text('Foundation lessons'), findsNothing);
  });

  testWidgets('lab mode walks the steps and keeps checks and notes in the guide’s own records',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    final path = publishedPaths.first;
    final lesson = path.lessons.first;
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: LabModeScreen(store: store, path: path, lesson: lesson)));
    await tester.pumpAndSettle();
    expect(find.text(lesson.labSteps.first.title), findsOneWidget);
    for (var i = 0; i < lesson.labSteps.length; i++) {
      await tester.tap(find.byKey(const ValueKey('lab-next')));
      await tester.pumpAndSettle();
    }
    // Site, 22 October 2026: the console check leads, then the commands as the optional route.
    if (lesson.labConsole.trim().isNotEmpty) {
      expect(find.text('CHECK IT IN THE CONSOLE'), findsOneWidget); // Kicker shows its text in capitals
      expect(find.text('Check your work'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lab-next')));
      await tester.pumpAndSettle();
      expect(find.text('COMMAND-LINE ROUTE (OPTIONAL)'), findsOneWidget);
    } else {
      expect(find.text('Check your work'), findsOneWidget);
    }
    expect(find.byTooltip('Copy this command'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('lab-next')));
    await tester.pumpAndSettle();
    expect(find.text(lesson.guide!.checklist.first), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('lab-check-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lab-check-0')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('lab-observations')));
    await tester.enterText(find.byKey(const ValueKey('lab-observations')), 'One forest, sbd.test.');
    await tester.pumpAndSettle();
    final saved = jsonDecode((await SharedPreferences.getInstance())
        .getString('sbd.guide.v1.${lesson.guide!.id}')!) as Map<String, dynamic>;
    expect(saved['checks'], {lesson.guide!.checkKey(0): true});
    expect(saved['notes'], {lesson.guide!.chapter: 'One forest, sbd.test.'});
    expect(tester.takeException(), isNull);
  });

  test('completed lessons come due for review on a widening schedule', () async {
    var now = DateTime(2026, 10, 1, 9);
    final store = await LearningStore.load(clock: () => now);
    addTearDown(store.dispose);
    final lesson = publishedPaths.first.lessons.first;
    await store.finishLesson(lesson.id, perfect: true);
    expect(store.reviewsDue, 0);
    now = DateTime(2026, 10, 2, 9);
    expect(store.reviewsDue, 1);
    expect(store.practiceLesson?.id, lesson.id);
    await store.finishLesson(lesson.id);
    now = DateTime(2026, 10, 4, 9);
    expect(store.reviewsDue, 0, reason: 'after one review the next gap is 3 days');
    now = DateTime(2026, 10, 5, 9);
    expect(store.reviewsDue, 1);
  });
}
