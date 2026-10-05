import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/theme.dart';
import 'package:secure_by_design_app/widgets/getting_started.dart';

void main() {
  testWidgets('returning learner can reopen welcome and dismiss the invitation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LearningStore.load();
    int? selectedTab;
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
              child: GettingStartedCard(
                  store: store, onTab: (tab) => selectedTab = tab)),
        )));
    expect(find.text('A plan that starts with you.'), findsOneWidget);
    await tester.tap(find.text('Find my starting point'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 5'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(selectedTab, isNull);
    expect(find.text('A plan that starts with you.'), findsNothing);
    final reloaded = await LearningStore.load();
    expect(reloaded.gettingStarted.next, null);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    reloaded.dispose();
  });

  testWidgets(
      'prompt switch works on narrow large-text screens without analytics',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = await LearningStore.load();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
              child: Column(children: [
            GettingStartedSetting(store: store.gettingStarted),
            GettingStartedCard(store: store, onTab: (_) {}),
          ])),
        )));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(store.gettingStarted.enabled, false);
    expect(store.analytics.enabled, false);
    expect(find.text('A plan that starts with you.'), findsNothing);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
