import 'package:flutter/material.dart';

import '../data/analytics.dart';
import '../data/learning_store.dart';
import '../data/haptics.dart';
import '../theme.dart';
import 'common.dart';

class HapticsSetting extends StatelessWidget {
  const HapticsSetting({super.key, required this.haptics});
  final AppHaptics haptics;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: haptics,
        builder: (context, _) => SwitchListTile.adaptive(
          key: const ValueKey('haptics-setting'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Haptic feedback'),
          subtitle: const Text(
              'Feel a subtle tap when you navigate, save, or complete a lesson.'),
          value: haptics.enabled,
          onChanged: haptics.changing
              ? null
              : (value) async {
                  try {
                    await haptics.setEnabled(value);
                    if (value && context.mounted) haptics.selectionChanged();
                  } catch (_) {
                    if (context.mounted) {
                      showNotice(context,
                          'Could not save this preference. Please try again.');
                    }
                  }
                },
        ),
      );
}

class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({super.key, required this.store});
  final LearningStore store;

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Help shape what comes next'),
            const SizedBox(height: 12),
            Text('Your ideas belong here.',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              'Suggest learning topics, vote on ideas, or share an app improvement. '
              'Opens our public UserJot board in your browser. Posts are public; '
              'please keep personal or confidential details out.',
              style: TextStyle(color: SbdColors.muted, height: 1.6),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => openResource(
                context,
                'https://securebydesign.userjot.com/',
                onOpened: store.analytics.feedbackOpened,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Share an idea'),
            ),
          ],
        ),
      );
}

class AnalyticsSetting extends StatelessWidget {
  const AnalyticsSetting({super.key, required this.analytics});
  final LearningAnalytics analytics;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: analytics,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              key: const ValueKey('analytics-setting'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Share learning analytics'),
              subtitle: const Text('Optional · off by default'),
              value: analytics.enabled,
              onChanged: analytics.changing
                  ? null
                  : (value) async {
                      try {
                        await analytics.setEnabled(value);
                      } catch (_) {
                        if (context.mounted) {
                          showNotice(context,
                              'Could not save this preference. Please try again before closing the app.');
                        }
                      }
                    },
            ),
            const Text(
              'Help us improve lessons by sending app opens, lesson and resource '
              'actions, answer correctness, and feedback-board opens to PostHog '
              'in the US. Events use a random device ID and include your platform. '
              'No name, email, answer text, or session recordings are sent. '
              'Your IP address is used to deliver requests and anonymized in PostHog. '
              'Turn this off anytime to stop future events and remove the ID from '
              'this device. Previously sent events remain in PostHog. '
              'Lessons and saved progress work with this setting off.',
              style:
                  TextStyle(color: SbdColors.muted, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      );
}
