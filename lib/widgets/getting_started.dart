import 'package:flutter/material.dart';

import '../data/getting_started.dart';
import '../data/learning_store.dart';
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
                'A small first step.',
                'Welcome to Secure By Design. Choose a learning path and try one lesson at your own pace. You do not need to learn everything at once.',
                'Explore learning paths'
              ),
            GettingStartedMessage.resources => (
                'Keep a useful reference close.',
                'Visit Resources and bookmark one guide for your next learning session. Your saved references stay together on this device.',
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
              if (context.mounted)
                showNotice(
                    context, 'Could not save this change. Please try again.');
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
                                } else {
                                  await dismiss();
                                  if (context.mounted)
                                    onTab(
                                        message == GettingStartedMessage.welcome
                                            ? 1
                                            : 2);
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
              'Welcome, learning tips, and feedback prompts on Home. Saved on this device; no emails or push notifications.'),
          value: store.enabled,
          onChanged: store.busy
              ? null
              : (value) async {
                  try {
                    await store.setEnabled(value);
                  } catch (_) {
                    if (context.mounted)
                      showNotice(context,
                          'Could not save this preference. Please try again.');
                  }
                },
        ),
      );
}
