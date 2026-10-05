import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/published_catalog.dart';
import 'package:secure_by_design_app/screens/course_screen.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';
import 'package:secure_by_design_app/screens/network_screen.dart';
import 'package:secure_by_design_app/widgets/training_share.dart';
import 'package:secure_by_design_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('DNS and two-tier PKI belong to the build category with stable progress IDs', () {
    expect(publishedPaths.map((path) => path.id),
        ['dc01-dc02', 'dns-configuration', 'two-tier-pki', 'rmf-boe-ato']);
    final build = publishedPaths.where((path) => path.category == 'Network build');
    expect(build.length, 3);
    expect(publishedPaths[1].lessons.length, 5);
    expect(publishedPaths[2].lessons.length, 6);
    final ids = publishedPaths.expand((path) => path.lessons).map((lesson) => lesson.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, contains('training:two-tier-pki:sign'));
    expect(publishedPaths[2].lessons[3].sourceUrl,
        'https://securebydesigninc.com/training/two-tier-pki#sign');
  });
  testWidgets('library categories combine with search and show related courses', (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(),
        home: Scaffold(body: TrainingLibraryScreen(store: store))));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Authorize the Network'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingCard), findsOneWidget);
    expect(find.text('Configure DNS'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Build the Network'));
    await tester.enterText(find.byType(TextField), 'Root CA');
    await tester.pumpAndSettle();
    expect(find.byType(TrainingCard), findsOneWidget);
    expect(find.text('Configure a Root CA & issuing CA'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no matching topic');
    await tester.pumpAndSettle();
    expect(find.byType(TrainingCard), findsNothing);
    expect(find.text('No matching training. Try another topic.'), findsOneWidget);
  });
  testWidgets('View materials opens the material collection directly',
      (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
            body: TrainingCard(path: publishedPaths.first, store: store))));
    await tester.tap(find.text('View materials'));
    await tester.pumpAndSettle();
    expect(find.text('Interactive build guide'), findsOneWidget);
    expect(find.text('Start the first lesson'), findsNothing);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('published course panels fit a narrow phone at ${scale}x text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await LearningStore.load();
      addTearDown(store.dispose);
      for (final path in publishedPaths) {
        await tester.pumpWidget(MaterialApp(
            theme: buildTheme(),
            home: CourseScreen(
                key: ValueKey(path.id), store: store, path: path)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final tab in ['Lessons', 'Materials']) {
          await tester.ensureVisible(find.text(tab));
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.scrollUntilVisible(
            find.byTooltip('Save material').first, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.byTooltip('Save material').first);
        await tester.pumpAndSettle();
        expect(store.isSaved(path.materials.first.id), true);
      }
    });
  }
  testWidgets(
      'offline network flows expose system details and manual trust transfer',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(theme: buildTheme(), home: const NetworkScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Offline trust'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Offline trust'));
    await tester.tap(find.text('Offline trust'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Next step'));
    await tester.tap(find.byTooltip('Next step'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('SBD-ROOTCA01').first, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('SBD-ROOTCA01').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('sharing passes the fixed homepage and an iPad anchor',
      (tester) async {
    MethodCall? sent;
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      sent = call;
      return 'dismissed';
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: const Scaffold(body: TrainingShare())));
    await tester.tap(find.text('Pass it on'));
    await tester.pumpAndSettle();
    expect(sent, isNotNull);
    expect(sent!.arguments['text'],
        'Learn it. Share it. Pay it forward. https://securebydesigninc.com/');
    expect(sent!.arguments['originWidth'], greaterThan(0));
    expect(find.text('Copy homepage link'), findsNothing);
  });
}
