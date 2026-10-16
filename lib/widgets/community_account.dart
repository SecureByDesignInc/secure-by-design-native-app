import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Owner request, 16 October 2026: membership tiers are gone from the website
/// and the app. Every Secure By Design account is a free Community account.
/// The copy matches the website's My Account section (#community-account).
class CommunityAccountPanel extends StatelessWidget {
  const CommunityAccountPanel({super.key});

  @override
  Widget build(BuildContext context) => Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Free Community account',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text(
            'Every Secure By Design account is a free Community account. It saves your progress and materials on the website and in the Secure By Design app.',
            style: TextStyle(color: SbdColors.muted, height: 1.6)),
        const SizedBox(height: 22),
        const Kicker('A note from Secure By Design'),
        const SizedBox(height: 12),
        const Text(
            'Start learning with what’s here. If it helps you, pay us back by sharing our content.',
            style: TextStyle(height: 1.7)),
        const SizedBox(height: 14),
        const Text('Secure By Design',
            style: TextStyle(color: SbdColors.muted)),
      ]));
}
