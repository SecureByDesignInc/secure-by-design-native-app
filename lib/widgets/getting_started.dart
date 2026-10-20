import 'package:flutter/material.dart';

import '../data/getting_started.dart';
import '../data/learning_store.dart';
import '../data/catalog.dart';
import '../screens/main_screens.dart' show openResources;
import '../screens/onboarding_screen.dart';
import '../screens/path_screen.dart';
import '../theme.dart';
import 'common.dart';

class GettingStartedCard extends StatelessWidget {
  const GettingStartedCard(
      {super.key, required this.store, required this.onTab});
  final LearningStore store;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store.gettingStarted,
        builder: (context, _) {
          final guidance = store.gettingStarted;
          final message = guidance.next;
          if (message == null) return const SizedBox.shrink();
          final (title, body, action) = switch (message) {
            GettingStartedMessage.welcome => (
                'A plan that starts with you.',
                'Choose your goals, find a useful first lesson, and read a personal welcome from Jon.',
                'Find my starting point'
              ),
            GettingStartedMessage.resources => (
                'Keep a useful reference close.',
                'Open Resources & references and bookmark one guide for your next learning session. Find what you saved in My Account.',
                'Explore resources'
              ),
            GettingStartedMessage.feedback => (
                'What would you like to learn next?',
                'Suggest a topic or vote on an idea on our UserJot board. It opens in your browser. Posts are public, so leave out personal or confidential details.',
                'Share an idea'
              ),
          };
          Future<void> dismiss() async {
            try {
              await guidance.dismiss(message);
            } catch (_) {
              if (context.mounted) {
                showNotice(
                    context, 'Could not save this change. Please try again.');
              }
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker('Getting started'),
                    const SizedBox(height: 12),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(body,
                        style: const TextStyle(
                            color: SbdColors.muted, height: 1.6)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton(
                        onPressed: guidance.busy
                            ? null
                            : () async {
                                if (message == GettingStartedMessage.feedback) {
                                  await openResource(context,
                                      'https://securebydesign.userjot.com/',
                                      onOpened: () {
                                    store.analytics.feedbackOpened();
                                    dismiss();
                                  });
                                } else if (message ==
                                    GettingStartedMessage.welcome) {
                                  await openOnboarding(context, store);
                                } else {
                                  await dismiss();
                                  if (context.mounted) {
                                    await openResources(context, store);
                                  }
                                }
                              },
                        child: Text(action),
                      ),
                      TextButton(
                          onPressed: guidance.busy ? null : dismiss,
                          child: const Text('Dismiss')),
                    ]),
                  ]),
            ),
          );
        },
      );
}

class GettingStartedSetting extends StatelessWidget {
  const GettingStartedSetting({super.key, required this.store});
  final GettingStartedStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => SwitchListTile.adaptive(
          key: const ValueKey('getting-started-setting'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Getting-started prompts'),
          subtitle: const Text(
              'Your starting checklist, learning tips, and feedback prompts on Home. Saved on this device; no emails or push notifications.'),
          value: store.enabled,
          onChanged: store.busy
              ? null
              : (value) async {
                  try {
                    await store.setEnabled(value);
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

class LearningPlanChecklist extends StatelessWidget {
  const LearningPlanChecklist(
      {super.key, required this.store, required this.onTab});
  final LearningStore store;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final profile = store.gettingStarted.profile;
    if (profile == null || !store.gettingStarted.enabled) {
      return const SizedBox.shrink();
    }
    final paths = profile.pathIds
        .map((id) => learningPaths.firstWhere((p) => p.id == id))
        .toList();
    final learned = paths.any((p) => store.completedIn(p) > 0);
    final saved = store.saved.isNotEmpty;
    if (learned && saved) return const SizedBox.shrink();
    final count = 1 + (learned ? 1 : 0) + (saved ? 1 : 0);
    return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker('Your first steps · $count of 3'),
            const SizedBox(height: 14),
            Text('Make a little progress today.',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _check('Choose your learning goals', true),
            _check('Complete a lesson in your plan', learned),
            _check('Save a useful reference', saved),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                onPressed: () => learned
                    ? openResources(context, store)
                    : openLearningPath(context, store, paths.first),
                child: Text(
                    learned ? 'Find a reference' : 'Open my learning path'),
              ),
              TextButton(
                  onPressed: () => openOnboarding(context, store),
                  child: const Text('Adjust my plan')),
            ]),
          ]),
        ));
  }

  Widget _check(String text, bool done) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          label: '$text, ${done ? 'complete' : 'next step'}',
          excludeSemantics: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(done ? Icons.check_circle_outline : Icons.circle_outlined,
                color: done ? SbdColors.success : SbdColors.muted, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ]),
        ),
      );
}
