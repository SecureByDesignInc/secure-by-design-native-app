import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/catalog.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/models.dart';
import 'package:secure_by_design_app/data/published_catalog.dart';
import 'package:secure_by_design_app/screens/course_screen.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';
import 'package:secure_by_design_app/screens/network_screen.dart';
import 'package:secure_by_design_app/screens/path_screen.dart';
import 'package:secure_by_design_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  LearningPath course(String id) =>
      publishedPaths.firstWhere((path) => path.id == id);

  test('the app carries every website course in site order with stable progress IDs', () {
    expect(publishedPaths.map((path) => path.id), [
      'dc01-dc02', 'dns-configuration', 'domain-time', 'stig-scap',
      'harden-baseline', 'two-tier-pki', 'dhcp', 'tiered-admin',
      'linux-repository', 'logging-pipeline', 'audit-repository',
      'splunk-analysis', 'workstation-fleet', 'patch-protect',
      'management-server', 'business-services',
      'prove-recovery', 'rmf-boe-ato', 'rmf-body-of-evidence',
      'rmf-authorization-to-operate',
    ]);
    expect(publishedPaths.map((path) => path.number), [
      // 1.16 and 1.17 are coming soon on the website and have no material yet.
      for (var i = 1; i <= 19; i++) if (i != 16 && i != 17) '1.$i',
      for (var i = 1; i <= 3; i++) '2.$i',
    ]);
    final build = publishedPaths.where((path) => path.category == 'Network build');
    expect(build.length, 17);
    expect(course('dns-configuration').lessons.length, 5);
    expect(course('domain-time').lessons.length, 5);
    expect(course('two-tier-pki').lessons.length, 10);
    final ids = publishedPaths.expand((path) => path.lessons).map((lesson) => lesson.id).toList();
    expect(ids.length, 105);
    expect(ids, contains('training:domain-time:time'));
    expect(ids, isNot(contains('training:dns-configuration:time')));
    expect(ids.where((id) => id.endsWith(':epo') || id.endsWith(':nessus')), isEmpty);
    expect(ids, contains('training:two-tier-pki:template-admin'));
    expect(ids.where((id) => id.contains('connect-segment') || id.contains('pki-services')), isEmpty);
    expect(ids.toSet().length, ids.length);
    expect(ids, contains('training:two-tier-pki:sign'));
    expect(ids, contains('training:prove-recovery:record'));
    expect(course('two-tier-pki').lessons[3].sourceUrl,
        'https://securebydesigninc.com/training/two-tier-pki#sign');
    for (final path in publishedPaths) {
      for (final lesson in path.lessons) {
        for (final question in lesson.questions) {
          expect(question.correctAnswer, inInclusiveRange(0, question.answers.length - 1));
        }
      }
    }
  });

  test('each authorization course has its own page and download over one set of module IDs', () {
    final parts = publishedPaths.where((path) => path.category == 'Network authorization').toList();
    expect(parts.map((path) => path.title),
        ['Risk Management Framework', 'Body of Evidence', 'Authorization to Operate']);
    expect(parts.expand((path) => path.lessons).map((lesson) => lesson.id), [
      for (var i = 1; i <= 12; i++) 'training:rmf-boe-ato:${'$i'.padLeft(2, '0')}',
    ]);
    expect(parts.map((path) => path.lessons.length), [4, 5, 3]);
    expect(parts.map((path) => path.topics).fold(0, (a, b) => a + b), 36);
    // Owner request, 15 October 2026: each course has its own page and training materials download,
    // and every module opens on its RMF step (NIST SP 800-37 Rev. 2 with the 2016 JSIG mapped in).
    const pages = ['rmf', 'rmf-body-of-evidence', 'rmf-authorization-to-operate'];
    for (var i = 0; i < parts.length; i++) {
      expect(parts[i].materials.take(2).map((material) => material.url), [
        'https://securebydesigninc.com/training/${pages[i]}/index.html',
        'https://securebydesigninc.com/training/${pages[i]}/SecureByDesign-${pages[i]}-Learning-Package.zip',
      ]);
      for (final lesson in parts[i].lessons) {
        expect(lesson.sourceUrl,
            startsWith('https://securebydesigninc.com/training/${pages[i]}/index.html#catalog/'));
        expect(lesson.sections.map((section) => section.heading), contains('What this module produces'),
            reason: lesson.id);
      }
    }
    expect(resources.where((resource) => resource.id == 'rmf-word'), isEmpty);
    expect(parts[1].materials.map((material) => material.id), contains('rmf-evidence'));
    expect(parts[2].materials.map((material) => material.id), contains('rmf-capstone'));
  });

  test('configuration courses offer their guide and one download, objectives, recaps, and every knowledge check', () {
    for (final path in publishedPaths.where((path) =>
        path.category == 'Network build' && path.id != 'dc01-dc02')) {
      final urls = path.materials.map((material) => material.url).toList();
      expect(urls, [
        'https://securebydesigninc.com/training/${path.id}',
        'https://securebydesigninc.com/training/${path.id}/SecureByDesign-${path.id}-Learning-Package.zip',
      ], reason: path.id);
      for (final lesson in path.lessons) {
        expect(lesson.objectives, isNotEmpty, reason: lesson.id);
        expect(lesson.recap, isNotEmpty, reason: lesson.id);
        expect(lesson.nextStep, isNotEmpty, reason: lesson.id);
        expect(lesson.questions.length, greaterThanOrEqualTo(3), reason: lesson.id);
      }
    }
    // The website lists every material the app offers, so every bookmark syncs.
    for (final id in ['dc-guide', 'dc-package', 'dns-configuration-guide', 'two-tier-pki-package',
        'rmf-guide', 'rmf-boe-ato-package', 'rmf-evidence', 'rmf-capstone', 'harden-guide',
        'harden-baseline-package']) {
      expect(resources.firstWhere((resource) => resource.id == id).syncable, isTrue, reason: id);
    }
    expect(resources.every((resource) => resource.syncable), isTrue);
  });

  testWidgets('a configuration lesson needs every check right and keeps XP once per lesson',
      (tester) async {
    final store = await LearningStore.load(clock: () => DateTime(2026, 10, 7));
    addTearDown(store.dispose);
    final path = course('dns-configuration'), lesson = path.lessons.first;
    await tester.pumpWidget(MaterialApp(theme: buildTheme(),
        home: LessonScreen(store: store, path: path, lesson: lesson)));
    await tester.pumpAndSettle();
    expect(find.text('IN THIS LESSON YOU WILL'), findsOneWidget);
    expect(find.text(lesson.objectives.first), findsOneWidget);
    expect(find.text('RECAP'), findsOneWidget);
    expect(find.text(lesson.nextStep), findsOneWidget);
    final complete = find.widgetWithText(FilledButton, 'Complete lesson');
    Future<void> choose(String answer) async {
      await tester.ensureVisible(find.text(answer).last);
      await tester.tap(find.text(answer).last);
      await tester.pumpAndSettle();
    }
    final questions = lesson.questions;
    expect(questions.length, greaterThanOrEqualTo(3));
    final first = questions.first;
    await choose(first.answers[(first.correctAnswer + 1) % first.answers.length]);
    for (var i = 0; i < questions.length; i++) {
      await choose(questions[i].answers[questions[i].correctAnswer]);
      expect(tester.widget<FilledButton>(complete).onPressed,
          i == questions.length - 1 ? isNotNull : isNull);
    }
    await tester.ensureVisible(complete);
    await tester.tap(complete);
    await tester.pumpAndSettle();
    expect(store.isCompleted(lesson.id), isTrue);
    expect(find.text('+30 XP'), findsOneWidget);
    expect(store.stats.quests.last.complete, isFalse);
  });

  testWidgets('library categories combine with search and show related courses', (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(),
        home: Scaffold(body: TrainingLibraryScreen(store: store))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Network Authorization'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Network Authorization'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingCard), findsNWidgets(3));
    expect(find.text('Configure DNS and time'), findsNothing);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Certificates & Trust'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Certificates & Trust'));
    await tester.enterText(find.byType(TextField), 'Root CA');
    await tester.pumpAndSettle();
    expect(find.byType(TrainingCard), findsOneWidget);
    expect(find.text('Configure the two-tier PKI'), findsOneWidget);
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
    await tester.tap(find.text('View materials (${publishedPaths.first.materials.length})'));
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
  testWidgets('offline network reference includes the web process, what-ifs, and policy decisions',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(theme: buildTheme(), home: const NetworkScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('7 traffic processes, 5 what-ifs, 22 systems'), findsOneWidget);
    expect(find.text('Use a web app'), findsOneWidget);
    await tester.ensureVisible(find.text('PC-to-PC remote desktop'));
    await tester.tap(find.text('PC-to-PC remote desktop'));
    await tester.pumpAndSettle();
    expect(find.text('D02 · Denied by policy'), findsOneWidget);
    await tester.ensureVisible(find.text('Use a web app'));
    await tester.tap(find.text('Use a web app'));
    await tester.pumpAndSettle();
    expect(find.text('F01 · Permitted by policy'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('POLICY REGISTER'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('F01 · DNS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

