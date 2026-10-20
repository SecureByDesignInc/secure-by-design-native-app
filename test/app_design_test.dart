import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/account.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/published_catalog.dart';
import 'package:secure_by_design_app/data/training_categories.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';
import 'package:secure_by_design_app/theme.dart';

Future<void> capture(WidgetTester tester, GlobalKey boundary, String name) async {
  await tester.runAsync(() async {
    final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('previews').createSync(recursive: true);
    await File('previews/app-$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    await (FontLoader('Geist')..addFont(rootBundle.load('assets/fonts/Geist.ttf'))).load();
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test('every published course has one app category without changing server groups', () {
    for (final path in publishedPaths) {
      expect(trainingCategories.where((category) => category.contains(path)).length, 1);
    }
    String titleFor(String id) =>
        categoryFor(publishedPaths.firstWhere((path) => path.id == id)).title;
    // 20 October 2026: the PKI is part of course 1.1, so Certificates & Trust folded into Network Foundations.
    for (final id in ['identity-foundation', 'linux-repository', 'prove-recovery']) {
      expect(titleFor(id), 'Network Foundations');
    }
    for (final id in ['rmf-boe-ato']) {
      expect(titleFor(id), 'Network Authorization');
    }
    // Categories list courses in the website's order.
    for (final category in trainingCategories) {
      final order = publishedPaths.where(category.contains).map((path) => path.id).toList();
      expect(category.pathIds, order);
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('category filter, tile expansion and lesson navigation at ${scale}x text',
        (tester) async {
      tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await LearningStore.load();
      addTearDown(store.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(
          debugShowCheckedModeBanner: false, theme: buildTheme(), home: Scaffold(body: TrainingLibraryScreen(store: store)))));
      await tester.pumpAndSettle();
      if (scale == 1) await capture(tester, boundary, 'training-categories');
      await tester.enterText(find.byType(TextField), 'DNS');
      await tester.pumpAndSettle();
      final card = find.byWidgetPredicate((widget) => widget is TrainingCard &&
          widget.path.id == 'identity-foundation');
      await tester.ensureVisible(card);
      final toggle = find.byKey(const ValueKey('expand-identity-foundation'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.descendant(of: card, matching: find.text('Hide lessons')), findsOneWidget);
      final lesson = publishedPaths.firstWhere((path) => path.id == 'identity-foundation').lessons.first;
      await tester.ensureVisible(find.text(lesson.title));
      await tester.pumpAndSettle();
      if (scale == 1) await capture(tester, boundary, 'expanded-training');
      await tester.tap(find.text(lesson.title));
      await tester.pumpAndSettle();
      expect(store.currentPath.id, 'identity-foundation');
      expect(store.completed, isEmpty);
      expect(find.text('Your lesson'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('account hub opens saved materials and learning preferences at ${scale}x text',
        (tester) async {
      tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await LearningStore.load();
      final account = AccountStore();
      addTearDown(store.dispose);
      addTearDown(account.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(
          debugShowCheckedModeBanner: false, theme: buildTheme(), home: Scaffold(body: MyLearningScreen(store: store, account: account)))));
      await tester.pumpAndSettle();
      expect(find.text('Free Community account'), findsOneWidget);
      expect(find.text('View membership options'), findsNothing);
      if (scale == 1) await capture(tester, boundary, 'my-account');
      await tester.ensureVisible(find.text('Saved materials'));
      await tester.tap(find.text('Saved materials'));
      await tester.pumpAndSettle();
      expect(find.text('Save a material from any course to find it here.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Learning preferences'));
      await tester.tap(find.text('Learning preferences'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Personalize my learning'));
      await tester.tap(find.text('Personalize my learning'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(store.analytics.enabled, isFalse);
      expect(store.completed, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
