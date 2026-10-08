import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_by_design_app/data/account.dart';
import 'package:secure_by_design_app/screens/account_screen.dart';
import 'package:secure_by_design_app/theme.dart';
import 'account_test.dart' show FakeAccountTransport;

void main() {
  testWidgets('account screen has no marketing enrollment on large text',
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
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Send me the series'), findsNothing);
    expect(transport.calls.length, 1);
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
    final signIn = find.widgetWithText(OutlinedButton, 'Sign in');
    await tester.ensureVisible(signIn);
    await tester.pumpAndSettle();
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(transport.calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
    account.dispose();
  });

  testWidgets('browser sign-in button opens the sign-in page', (tester) async {
    final transport = FakeAccountTransport();
    Uri? opened;
    final account = AccountStore(
      transport: transport,
      browser: (url, _) async {
        opened = url;
        return 'securebydesign://auth?code=one-time-code';
      },
    );
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: AccountScreen(account: account)));
    final button = find.byKey(const ValueKey('browser-sign-in'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(opened?.path, '/app-sign-in');
    expect(account.signedIn, true);
    expect(transport.calls.single['path'], '/api/native-auth/exchange');
    await tester.pumpWidget(const SizedBox());
    account.dispose();
  });
}
