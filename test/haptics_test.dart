import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/data/haptics.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/published_catalog.dart';
import 'package:secure_by_design_app/screens/course_screen.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final pulses = <String>[];
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'sbd.guidance.started.v1': DateTime.now().toUtc().toIso8601String()});
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    pulses.clear();
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        pulses.add(call.arguments as String);
      }
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('navigation taps once, and the accessible setting persists off',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    await tester.pumpWidget(SecureByDesignApp(store: store));
    await tester.pumpAndSettle();
    expect(pulses, isEmpty);
    await tester.tap(find.text('Training').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training').last);
    await tester.pumpAndSettle();
    expect(pulses, ['HapticFeedbackType.selectionClick']);

    await tester.tap(find.byTooltip('About this preview'));
    await tester.pumpAndSettle();
    final setting = find.byKey(const ValueKey('haptics-setting'));
    await tester.ensureVisible(setting);
    await tester
        .tap(find.descendant(of: setting, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(store.haptics.enabled, isFalse);
    final reloaded = await LearningStore.load();
    addTearDown(reloaded.dispose);
    expect(reloaded.haptics.enabled, isFalse);
    await tester.ensureVisible(find.text('Keep exploring'));
    await tester.tap(find.text('Keep exploring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    expect(pulses, ['HapticFeedbackType.selectionClick']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved material confirms only the user action, not store reloads',
      (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    final course = publishedPaths.first;
    await tester.pumpWidget(MaterialApp(
        home: CourseScreen(store: store, path: course, initialTab: 2)));
    await tester.pumpAndSettle();
    expect(pulses, isEmpty);
    await tester.scrollUntilVisible(find.byTooltip('Save material').first, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byTooltip('Save material').first);
    await tester.pumpAndSettle();
    expect(store.isSaved(course.materials.first.id), isTrue);
    expect(pulses, ['HapticFeedbackType.lightImpact']);
    final reloaded = await LearningStore.load();
    addTearDown(reloaded.dispose);
    expect(reloaded.isSaved(course.materials.first.id), isTrue);
    expect(pulses, hasLength(1));
    await tester.tap(find.byTooltip('Remove saved material').first);
    await tester.pumpAndSettle();
    expect(store.isSaved(course.materials.first.id), isFalse);
    expect(pulses, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });

  testWidgets('disabled, background, and desktop contexts stay silent',
      (tester) async {
    final haptics = AppHaptics(await SharedPreferences.getInstance());
    addTearDown(haptics.dispose);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    haptics.lessonCompleted();
    await tester.pump();
    expect(pulses, ['HapticFeedbackType.successNotification']);
    pulses.clear();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    haptics.bookmarkChanged();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await haptics.setEnabled(false);
    haptics.selectionChanged();
    await haptics.setEnabled(true);
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      haptics.lessonCompleted();
    }
    debugDefaultTargetPlatformOverride = null;
    await tester.pump();
    expect(pulses, isEmpty);
  });

  testWidgets('unsupported device feedback never interrupts an action',
      (tester) async {
    final haptics = AppHaptics(await SharedPreferences.getInstance());
    addTearDown(haptics.dispose);
    for (final failure in [
      MissingPluginException(),
      PlatformException(code: 'unavailable'),
    ]) {
      binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') throw failure;
        return null;
      });
      haptics.selectionChanged();
      haptics.bookmarkChanged();
      haptics.lessonCompleted();
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
