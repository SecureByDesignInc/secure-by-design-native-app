// Temporary diagnostic (draft PR only, never merged): catches each layout error and reports a one-line summary.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/app_tabs.dart';
import 'package:secure_by_design_app/data/catalog.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/screens/lab_mode_screen.dart';
import 'package:secure_by_design_app/screens/path_screen.dart';
import 'package:secure_by_design_app/theme.dart';

final problems = <String>[];
String short(Object? e) => e
    .toString()
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty && !l.startsWith('═'))
    .take(3)
    .join(' | ');

void note(WidgetTester tester, String where) {
  final e = tester.takeException();
  if (e != null) problems.add('$where: ${short(e)}');
}

Future<void> size(WidgetTester tester, double w, double scale) async {
  tester.view.physicalSize = Size(w, w >= 860 ? 900 : 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    await (FontLoader('Geist')..addFont(rootBundle.load('assets/fonts/Geist.ttf'))).load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  for (final (w, scale) in [(320.0, 1.0), (320.0, 2.0), (390.0, 1.0), (390.0, 2.0), (768.0, 2.0), (1280.0, 1.0), (1280.0, 2.0)]) {
    testWidgets('a tabs $w $scale', (tester) async {
      await size(tester, w, scale);
      final store = await LearningStore.load();
      await tester.pumpWidget(SecureByDesignApp(store: store));
      await tester.pumpAndSettle();
      note(tester, '$w@$scale home');
      for (final tab in AppTab.values.skip(1)) {
        await tester.tap(find.byKey(ValueKey('tab-${tab.name}')));
        await tester.pumpAndSettle();
        note(tester, '$w@$scale ${tab.name}');
      }
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }

  for (final (w, scale) in [(320.0, 2.0), (390.0, 1.0)]) {
    testWidgets('b lesson and lab $w $scale', (tester) async {
      await size(tester, w, scale);
      final store = await LearningStore.load();
      final path = publishedPaths.first, lesson = path.lessons.first;
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(), home: LessonScreen(store: store, path: path, lesson: lesson)));
      await tester.pumpAndSettle();
      note(tester, '$w@$scale lesson');
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(), home: LabModeScreen(store: store, path: path, lesson: lesson)));
      await tester.pumpAndSettle();
      note(tester, '$w@$scale lab page 1');
      for (var i = 0; i < lesson.labSteps.length + 1; i++) {
        await tester.tap(find.byKey(const ValueKey('lab-next')));
        await tester.pumpAndSettle();
        note(tester, '$w@$scale lab page ${i + 2}');
      }
      await tester.pumpWidget(const SizedBox());
      note(tester, '$w@$scale lab disposed');
      store.dispose();
    });
  }

  test('z report', () => expect(problems, isEmpty));
}
