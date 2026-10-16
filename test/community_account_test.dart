import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/app.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/screens/training_screens.dart';
import 'package:secure_by_design_app/widgets/learning_rewards.dart';

// The old membership prompts. Course text can say "group membership", so the
// checks look for these exact phrases rather than the word.
const _oldPrompts = [
  'Memberships are coming soon.',
  'View membership options',
  'Membership options',
  'Membership options in My Account',
];

void _expectNoMembershipPrompts() {
  for (final text in _oldPrompts) {
    expect(find.text(text), findsNothing, reason: '"$text" should be gone');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Owner request, 16 October 2026: no membership tiers. Every account is a
  // free Community account. This replaces membership_screen_test.dart.
  test('the membership plan copy is gone', () {
    for (final path in [
      'assets/membership-plans.json',
      'lib/data/membership.dart',
      'lib/screens/membership_screen.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: '$path should be deleted');
    }
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('membership')));
  });

  for (final large in [false, true]) {
    testWidgets('My Account shows the free Community account, large: $large',
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
      await tester.pumpAndSettle();
      expect(find.byType(MyLearningScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Free Community account'));
      await tester.pumpAndSettle();
      expect(find.text('Free Community account').hitTestable(), findsOneWidget);
      expect(find.textContaining('is a free Community account'), findsOneWidget);
      _expectNoMembershipPrompts();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }

  testWidgets('finishing the first lesson shows no membership prompts',
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
    await tester.ensureVisible(find.text(
        'Changing them on a domain controller later is a separate procedure'));
    await tester.tap(find.text(
        'Changing them on a domain controller later is a separate procedure'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete lesson'));
    await tester.tap(find.text('Complete lesson'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonCelebration), findsOneWidget);
    _expectNoMembershipPrompts();
    expect(store.completed, {'training:dc01-dc02:prepare'});

    // Home used to show "Memberships are coming soon." after a first lesson.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(SecureByDesignApp(store: store));
    await tester.pumpAndSettle();
    _expectNoMembershipPrompts();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
