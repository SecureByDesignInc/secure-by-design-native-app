// Render the real Flutter screens for visual review in Codemagic.
// Run with: flutter test tool/render_previews.dart
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
  testWidgets('Render mobile screens for design review', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final font = FontLoader('Geist')
      ..addFont(rootBundle.load('assets/fonts/Geist.ttf'));
    await font.load();
    final store = await LearningStore.load();
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey,
      child: SecureByDesignApp(store: store),
    ));
    await tester.pumpAndSettle();
    await tester.runAsync(() => precacheImage(
      const AssetImage('assets/brand/brand-mark.png'),
      tester.element(find.byType(AppShell)),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Learn', 'Resources', 'Progress']) {
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File('build/previews/${label.toLowerCase()}.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
