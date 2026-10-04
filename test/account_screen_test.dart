import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_by_design_app/data/account.dart';
import 'package:secure_by_design_app/screens/account_screen.dart';
import 'package:secure_by_design_app/theme.dart';
import 'account_test.dart' show FakeAccountTransport;

void main() {
  testWidgets('email consent starts unchecked on a narrow large-text screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final transport = FakeAccountTransport();
    final account = AccountStore(transport: transport);
    await account.signIn('reader@example.invalid', 'password');
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: AccountScreen(account: account)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(Checkbox), 250);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false);
    final button = find.widgetWithText(FilledButton, 'Send me the series');
    expect(tester.widget<FilledButton>(button).onPressed, null);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(account.enrollment, 'accepted');
    expect(
        transport.calls
            .where((call) =>
                call['path'] == '/api/native-onboarding' &&
                call['method'] == 'POST')
            .length,
        1);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    account.dispose();
  });

  testWidgets('sign-in form is optional and validates without network requests',
      (tester) async {
    final transport = FakeAccountTransport();
    final account = AccountStore(transport: transport);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: AccountScreen(account: account)));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(transport.calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
    account.dispose();
  });
}
