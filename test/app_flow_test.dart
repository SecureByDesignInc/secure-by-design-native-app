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
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
      await tester.tap(find.text('Start the first lesson'));
      await tester.pumpAndSettle();
      final complete = find.widgetWithText(FilledButton, 'Complete lesson');
      expect(tester.widget<FilledButton>(complete).onPressed, isNull);
      await tester.scrollUntilVisible(
        find.text('Only internet browsing history'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Only internet browsing history'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(complete).onPressed, isNull);
      await tester.tap(find.text('User, computer, and resource information'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(complete);
      await tester.tap(complete);
      await tester.pumpAndSettle();
      expect(store.completed, {'ad-1'});
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress').last);
      await tester.pumpAndSettle();
      expect(find.text('1 of 3 lessons completed'), findsOneWidget);
      final reloaded = await LearningStore.load();
      expect(reloaded.completed, {'ad-1'});
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
    await tester.tap(find.text('Resources').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save Active Directory fundamentals'));
    await tester.pumpAndSettle();
    expect(store.isSaved('ms-ad'), isTrue);
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
          for (final tab in ['Learn', 'Resources', 'Progress']) {
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
      'Learn': 'learn',
      'Resources': 'resources',
      'Progress': 'progress',
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
