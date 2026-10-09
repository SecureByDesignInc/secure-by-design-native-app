import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/membership.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';

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
      SharedPreferences.setMockInitialValues({
        'sbd.guidance.started.v1': DateTime.now().toUtc().toIso8601String(),
      });
      final store = await LearningStore.load();
      await tester.pumpWidget(SecureByDesignApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Account').last);
      await tester.pump();
      await tester.runAsync(MembershipCatalog.load);
      await tester.pumpAndSettle();
      expect(find.byType(MyLearningScreen), findsOneWidget);
      expect(find.text('Community · Included'), findsOneWidget);
      await tester.ensureVisible(find.text('View membership options'));
      await tester.tap(find.text('View membership options'));
      await tester.pump();
      await tester.runAsync(MembershipCatalog.load);
      await tester.pumpAndSettle();
      expect(find.text('Membership options').hitTestable(), findsOneWidget);
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          3);
      expect(
          Navigator.of(tester.element(find.byType(MyLearningScreen))).canPop(),
          isFalse);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Coming soon · founding pricing for the first 100 members'),
          findsOneWidget);
      expect(find.text('Coming soon · limited seats'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
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
      expect(find.byType(TrainingLibraryScreen), findsOneWidget);
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1);
      expect(
          Navigator.of(tester.element(find.byType(TrainingLibraryScreen)))
              .canPop(),
          isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }

  testWidgets('first lesson invitation opens memberships in the My Account tab',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'sbd.guidance.started.v1': DateTime.now().toUtc().toIso8601String(),
    });
    final store = await LearningStore.load();
    await tester.pumpWidget(SecureByDesignApp(store: store));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start learning'));
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start the first lesson'));
    await tester.tap(find.text('Start the first lesson'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.text('Changing them on a domain controller later is a separate procedure'));
    await tester.tap(find.text('Changing them on a domain controller later is a separate procedure'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete lesson'));
    await tester.tap(find.text('Complete lesson'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explore plans in My Account'));
    await tester.tap(find.text('Explore plans in My Account'));
    await tester.pump();
    await tester.runAsync(MembershipCatalog.load);
    await tester.pumpAndSettle();
    expect(find.byType(MyLearningScreen), findsOneWidget);
    expect(find.text('Membership options').hitTestable(), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3);
    expect(Navigator.of(tester.element(find.byType(MyLearningScreen))).canPop(),
        isFalse);
    expect(store.completed, {'training:dc01-dc02:prepare'});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}

