import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/screens/threat_map_screen.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';
import 'package:secure_by_design_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Owner decision, 20 October 2026: the map opens on Radware's own site,
  // never embedded or with parts of Radware's page covered.
  test('the map is Radware’s own page, opened over HTTPS', () {
    expect(threatMapUrl, 'https://livethreatmap.radware.com/');
    expect(Uri.parse(threatMapUrl).scheme, 'https');
  });

  for (final (width, scale) in [(320.0, 2.0), (390.0, 1.0)]) {
    testWidgets('Home offers the Live Threat Map as a link out ($width, ${scale}x)',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await LearningStore.load();
      addTearDown(store.dispose);
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: TrainingHome(store: store, onTab: (_) {}))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Live Threat Map'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Live Threat Map'), findsOneWidget);
      expect(find.textContaining('Radware’s live map'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
