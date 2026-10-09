import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/data/learning_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(
      {'sbd.guidance.started.v1': DateTime.now().toUtc().toIso8601String()}));

  setUpAll(() async {
    final font = FontLoader('Geist')
      ..addFont(rootBundle.load('assets/fonts/Geist.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets(
    'a learner opens a path, answers, completes, and sees saved progress',
    (tester) async {
      final pulses = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          pulses.add(call.arguments as String);
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await LearningStore.load();
      await tester.pumpWidget(SecureByDesignApp(store: store));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start learning'));
      await tester.tap(find.text('Start learning'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start the first lesson'));
      await tester.tap(find.text('Start the first lesson'));
      await tester.pumpAndSettle();
      final complete = find.widgetWithText(FilledButton, 'Complete lesson');
      expect(tester.widget<FilledButton>(complete).onPressed, isNull);
      await tester.scrollUntilVisible(
        find.text('Promotion assigns a name and address automatically'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Promotion assigns a name and address automatically'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(complete).onPressed, isNull);
      await tester.tap(find.text('Promotion assigns a name and address automatically'));
      await tester.pumpAndSettle();
      expect(pulses, ['HapticFeedbackType.selectionClick']);
      await tester.tap(find.text('Changing them on a domain controller later is a separate procedure'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(complete);
      await tester.tap(complete);
      await tester.pumpAndSettle();
      expect(store.completed, {'training:dc01-dc02:prepare'});
      expect(pulses, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.successNotification',
      ]);
      expect(find.text('1-day streak'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('1 of 5 chapters complete'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Account').last);
      await tester.pumpAndSettle();
      expect(find.text('1 of 5 lessons complete'), findsOneWidget);
      final reloaded = await LearningStore.load();
      expect(reloaded.completed, {'training:dc01-dc02:prepare'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saving and filtering a resource updates the collection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await LearningStore.load();
    await tester.pumpWidget(SecureByDesignApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved resources & materials'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byTooltip('Save Active Directory fundamentals'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save Active Directory fundamentals'));
    await tester.pumpAndSettle();
    expect(store.isSaved('ms-ad'), isTrue);
    await tester.ensureVisible(find.text('Saved (1)'));
    await tester.tap(find.text('Saved (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Active Directory fundamentals'), findsOneWidget);
    expect(find.text('The Risk Management Framework'), findsNothing);
    await tester.tap(
      find.byTooltip('Remove Active Directory fundamentals from saved'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Make this your collection.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1280, 900),
  ]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'all tabs fit ${size.width.toInt()}px at ${textScale}x text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final store = await LearningStore.load();
          await tester.pumpWidget(SecureByDesignApp(store: store));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final tab in ['Training', 'Explore', 'My Account']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('feedback and analytics settings fit narrow large-text screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = await LearningStore.load();
    await tester.pumpWidget(SecureByDesignApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About this preview'));
    await tester.pumpAndSettle();
    expect(find.text('Share an idea'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('analytics-setting')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const ValueKey('analytics-setting')))
            .value,
        false);
    await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('analytics-setting')),
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(store.analytics.enabled, true);
    await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('analytics-setting')),
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(store.analytics.enabled, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export actual app screen previews', (tester) async {
    final boundary = GlobalKey();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await LearningStore.load();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: SecureByDesignApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    for (final entry in {
      'Home': 'home',
      'Training': 'training',
      'Explore': 'explore',
      'My Account': 'progress',
    }.entries) {
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('previews')..createSync(recursive: true);
        await File('${dir.path}/${entry.value}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
  });
}

