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

  test('the map is Radware’s, opened only over HTTPS', () {
    expect(ThreatMapScreen.url, 'https://livethreatmap.radware.com/');
    expect(Uri.parse(ThreatMapScreen.url).host, ThreatMapScreen.host);
  });

  testWidgets('Explore offers the Live Threat Map after Inside the Network',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await LearningStore.load();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: ExploreScreen(store: store))));
    await tester.pumpAndSettle();
    expect(find.text('Live Threat Map'), findsOneWidget);
    expect(find.text('Watch live attacks'), findsOneWidget);
    expect(
        tester.getTopLeft(find.text('Live Threat Map')).dy,
        greaterThan(tester.getTopLeft(find.text('Inside the Network')).dy));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('without a web view the map offers the browser ($width)',
        (tester) async {
      tester.view.physicalSize = Size(width, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(), home: const ThreatMapScreen(embedded: false)));
      await tester.pumpAndSettle();
      expect(find.text('Live Threat Map'), findsOneWidget);
      expect(find.textContaining('not affiliated with Radware'),
          findsOneWidget);
      expect(find.text('Open the live map'), findsOneWidget);
      expect(find.byTooltip('Open on Radware'), findsOneWidget);
      expect(find.byTooltip('Reload the map'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
