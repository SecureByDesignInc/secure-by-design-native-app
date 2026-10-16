import 'package:flutter/material.dart';

/// Shared destinations remain available from lessons and other pushed routes.
class AccountNavigation extends InheritedWidget {
  const AccountNavigation({
    super.key,
    required this.onAccount,
    required this.onTraining,
    required super.child,
  });

  final VoidCallback onAccount;
  final VoidCallback onTraining;

  static AccountNavigation _of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AccountNavigation>()!;

  static void openAccount(BuildContext context) {
    final navigation = _of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    navigation.onAccount();
  }

  static void openTraining(BuildContext context) {
    final navigation = _of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    navigation.onTraining();
  }

  @override
  bool updateShouldNotify(AccountNavigation oldWidget) =>
      onAccount != oldWidget.onAccount || onTraining != oldWidget.onTraining;
}
