import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/membership.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Owner request, 13 October 2026: one "Coming soon" statement, no specifics.
  test('membership copy is a single coming-soon statement', () async {
    final catalog = await MembershipCatalog.load();
    expect(catalog.comingSoon, 'Coming soon');
    final raw = await rootBundle.loadString('assets/membership-plans.json');
    expect(RegExp(r'\$\d|Builder|Guided|founding|month|annual|quarter',
            caseSensitive: false).hasMatch(raw), isFalse);
  });
  for (final large in [false, true]) {
    testWidgets('membership options read coming soon, large: $large',
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
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.textContaining('\$'), findsNothing);
      expect(find.textContaining('Builder'), findsNothing);
      expect(find.textContaining('Guided'), findsNothing);
      expect(store.completed, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Keep learning in the Training Library'));
      await tester.tap(find.text('Keep learning in the Training Library'));
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
    await tester.ensureVisible(find.text('Membership options in My Account'));
    await tester.tap(find.text('Membership options in My Account'));
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

