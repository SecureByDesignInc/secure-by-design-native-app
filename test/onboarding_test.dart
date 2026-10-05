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
import 'package:secure_by_design_app/data/onboarding.dart';
import 'package:secure_by_design_app/screens/onboarding_screen.dart';

Future<void> tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('previews').createSync(recursive: true);
    await File('previews/onboarding-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    await (FontLoader('Geist')
          ..addFont(rootBundle.load('assets/fonts/Geist.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  test(
      'every goal and starting level recommends real lessons in a stable order',
      () {
    for (final start in LearningStart.values) {
      for (final goal in LearningGoal.values) {
        final profile = OnboardingProfile(goals: {goal}, start: start);
        final path =
            learningPaths.singleWhere((p) => p.id == profile.pathIds.single);
        expect(path.lessons, isNotEmpty);
        expect(path.lessons.first.minutes, greaterThan(0));
      }
    }
    final multiple = OnboardingProfile(
        goals: {LearningGoal.monitor, LearningGoal.authorize},
        start: LearningStart.practical);
    expect(multiple.pathIds, ['rmf-boe-ato', 'monitoring']);
    expect(OnboardingProfile.fromJson(multiple.toJson())!.pathIds,
        multiple.pathIds);
    expect(
        OnboardingProfile.fromJson({
          'goals': ['removed'],
          'start': 'practical'
        }),
        isNull);
  });

  test(
      'upgrades preserve progress, disabled prompts, and the last learning path',
      () async {
    SharedPreferences.setMockInitialValues({
      'sbd.guidance.started.v1': '2026-10-04T00:00:00Z',
      'sbd.guidance.enabled.v1': false,
      'sbd.guidance.dismissed.v1': ['welcome'],
      'sbd.completed.v1': ['ad-1'],
      'sbd.lastPath.v1': 'ad',
      'sbd.haptics.enabled.v1': false,
    });
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    expect(store.gettingStarted.shouldPresentWelcome, false);
    await store.gettingStarted.finishWelcome(
        profile: OnboardingProfile(
            goals: {LearningGoal.authorize}, start: LearningStart.practical));
    final restored = await LearningStore.load();
    addTearDown(restored.dispose);
    expect(restored.gettingStarted.profile!.pathIds, ['rmf-boe-ato']);
    expect(restored.completed, {'ad-1'});
    expect(restored.currentPath.id, 'ad');
    expect(restored.gettingStarted.enabled, false);
    expect(restored.gettingStarted.next, isNull);
    expect(restored.haptics.enabled, false);
    expect(restored.analytics.enabled, false);
  });

  for (final largeText in [false, true]) {
    testWidgets(
        'personalized welcome leads to a real first win, large text: $largeText',
        (tester) async {
      tester.view.physicalSize =
          largeText ? const Size(320, 740) : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = largeText ? 2 : 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await LearningStore.load();
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary, child: SecureByDesignApp(store: store)));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 5'), findsOneWidget);
      if (!largeText) await capture(tester, boundary, 'welcome');
      await tap(tester, 'Find my starting point');
      expect(
          tester
              .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Continue'))
              .onPressed,
          isNull);
      await tap(tester, 'Understand RMF & authorization');
      if (!largeText) await capture(tester, boundary, 'goals');
      await tap(tester, 'Continue');
      expect(
          tester
              .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Show my plan'))
              .onPressed,
          isNull);
      await tap(tester, 'Start with the foundations');
      await tap(tester, 'Show my plan');
      expect(find.text('Make sense of RMF'), findsOneWidget);
      expect(find.text('START HERE · 3 MIN'), findsOneWidget);
      if (!largeText) await capture(tester, boundary, 'plan');
      await tap(tester, 'A note before you begin');
      expect(find.text('Hi, I’m Jon.'), findsOneWidget);
      if (!largeText) await capture(tester, boundary, 'creator');
      expect(tester.takeException(), isNull);
      await tap(tester, 'Start my first lesson');
      expect(find.text('Your lesson'), findsOneWidget);
      await tap(tester, 'Prepare');
      await tap(tester, 'Complete lesson');
      expect(store.completed, {'rmf-1'});
      expect(find.text('+45 XP'), findsOneWidget);
      await tap(tester, 'Continue');
      expect(find.text('YOUR FIRST STEPS · 2 OF 3'), findsOneWidget);
      await store.toggleSaved('nist-rmf');
      await tester.pumpAndSettle();
      expect(find.text('YOUR FIRST STEPS · 2 OF 3'), findsNothing);
      final restored = await LearningStore.load();
      expect(restored.gettingStarted.shouldPresentWelcome, false);
      expect(restored.gettingStarted.profile!.pathIds, ['rmf']);
      expect(restored.currentPath.id, 'rmf');
      expect(restored.haptics.enabled, true);
      expect(restored.analytics.enabled, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      restored.dispose();
    });
  }

  testWidgets(
      'skip persists and reopening then closing preserves the saved plan',
      (tester) async {
    final store = await LearningStore.load();
    await tester.pumpWidget(SecureByDesignApp(store: store));
    await tester.pumpAndSettle();
    await tap(tester, 'Skip');
    expect(find.byType(OnboardingScreen), findsNothing);
    final restored = await LearningStore.load();
    expect(restored.gettingStarted.welcomeFinished, true);
    expect(restored.gettingStarted.shouldPresentWelcome, false);
    await store.gettingStarted.finishWelcome(
        profile: OnboardingProfile(
            goals: {LearningGoal.build}, start: LearningStart.practical));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About this preview'));
    await tester.pumpAndSettle();
    await tap(tester, 'Personalize my learning');
    await tap(tester, 'Find my starting point');
    await tap(tester, 'Understand security monitoring');
    await tester.tap(find.byTooltip('Previous step'));
    await tester.pumpAndSettle();
    await tap(tester, 'Close');
    expect(store.gettingStarted.profile!.pathIds, ['dc01-dc02']);
    expect(store.completed, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    restored.dispose();
  });
}
