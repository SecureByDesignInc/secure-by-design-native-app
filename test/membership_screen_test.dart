import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/membership.dart';
import 'package:secure_by_design_app/screens/membership_screen.dart';
import 'package:secure_by_design_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('paid plans stay unavailable and Builder annual saving is accurate',
      () async {
    final catalog = await MembershipCatalog.load();
    final builder = catalog.plans.firstWhere((p) => p.id == 'builder');
    expect(catalog.plans.where((p) => p.available).map((p) => p.id),
        ['community']);
    expect(builder.monthlyPrice, 20);
    expect(builder.annualPrice, 180);
    expect(1 - builder.annualPrice! / (12 * builder.monthlyPrice), .25);
    expect(
        catalog.plans.firstWhere((p) => p.id == 'guided').annualPrice, isNull);
  });
  for (final large in [false, true]) {
    testWidgets('plans preserve access and readable billing, large: $large',
        (tester) async {
      tester.view.physicalSize =
          large ? const Size(320, 740) : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({});
      final store = await LearningStore.load();
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(),
          home: Builder(
              builder: (context) => Scaffold(
                  body: Center(
                      child: FilledButton(
                          onPressed: () => openMemberships(context, store),
                          child: const Text('Open plans')))))));
      await tester.tap(find.text('Open plans'));
      await tester.pump();
      await tester.runAsync(MembershipCatalog.load);
      await tester.pumpAndSettle();
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Coming soon · planned benefits'), findsNWidgets(2));
      await tester.ensureVisible(find.text('Annual · save 25%'));
      await tester.tap(find.text('Annual · save 25%'));
      await tester.pumpAndSettle();
      expect(find.text('\$180 / year'), findsOneWidget);
      expect(find.text('\$99 / month'), findsOneWidget);
      await tester.ensureVisible(find.text('Explore Builder'));
      await tester.tap(find.text('Explore Builder'));
      await tester.pumpAndSettle();
      expect(find.text('Builder · \$180/year · coming soon'), findsOneWidget);
      expect(store.completed, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Continue with Community').first);
      await tester.tap(find.text('Continue with Community').first);
      await tester.pumpAndSettle();
      expect(find.text('Open plans'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }
}
