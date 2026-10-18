import 'package:flutter/material.dart';

import '../data/account.dart';
import '../data/catalog.dart';
import '../data/learning_store.dart';
import '../theme.dart';
import '../widgets/app_support.dart';
import '../widgets/common.dart';
import '../widgets/community_account.dart';
import '../widgets/getting_started.dart';
import '../widgets/learning_rewards.dart';
import 'account_screen.dart';
import 'onboarding_screen.dart';
import 'path_screen.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key, required this.store, required this.account});
  final LearningStore store;
  final AccountStore account;

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  LearningStore get store => widget.store;
  AccountStore get account => widget.account;

  Future<void> _detail(String title, Widget Function(BuildContext) content) =>
      Navigator.of(context).push<void>(MaterialPageRoute(builder: (context) =>
          Scaffold(appBar: AppBar(title: Text(title)),
              body: SafeArea(child: AnimatedBuilder(
                  animation: Listenable.merge([store, account]),
                  builder: (context, _) => PageContent(
                      maxWidth: 760, children: [content(context)]))))));

  Future<void> _connect() async {
    try {
      if (store.cloudConnected) {
        await store.sync();
      } else {
        await store.connectAccount(account);
      }
    } catch (_) {
      if (mounted) showNotice(context, 'Sign in again to connect your progress.');
    }
  }

  Future<void> _importProgress() async {
    final approved = await showDialog<bool>(context: context,
        builder: (context) => AlertDialog(
            title: const Text('Add device progress?'),
            content: Text('Add this device’s offline lessons, learning activity, '
                'and bookmarks to ${account.email}. Existing account records will be kept.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add my progress')),
            ]));
    if (approved == true) await store.importDeviceProgress();
  }

  Widget _courseProgress(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    for (final path in learningPaths)
      Padding(padding: const EdgeInsets.only(bottom: 16), child: Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(path.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        ProgressLine(value: store.progressIn(path)),
        const SizedBox(height: 10),
        Text('${store.completedIn(path)} of ${path.lessons.length} complete'),
        TextButton(onPressed: () => openLearningPath(context, store, path),
            child: Text(store.completedIn(path) == path.lessons.length
                ? 'Review course' : 'Continue learning')),
      ]))),
  ]);

  Widget _savedMaterials(BuildContext context) {
    final saved = {for (final item in [...resources, ...foundationResources])
      if (store.isSaved(item.id)) item.id: item}.values.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (saved.isEmpty)
        const Panel(child: Text('Save a material from any course to find it here.')),
      for (final item in saved)
        ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: const Icon(Icons.bookmark, color: SbdColors.cyan),
            title: Text(item.title), subtitle: Text(item.publisher),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openResource(context, item.url)),
    ]);
  }

  Widget _preferences(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    _AccountRow(icon: Icons.route_outlined, title: 'Personalize my learning',
        subtitle: 'Change your goals and starting level',
        onTap: () => openOnboarding(context, store)),
    const Divider(height: 32),
    _AccountRow(icon: Icons.bolt_outlined, title: 'Daily learning goal',
        subtitle: '${store.dailyGoal} XP per day',
        onTap: () => chooseDailyGoal(context, store)),
    const Divider(height: 32),
    GettingStartedSetting(store: store.gettingStarted),
    const SizedBox(height: 12),
    const Text('Learning tips and reminders appear inside the app.'),
    if (store.haptics.supported) ...[
      const Divider(height: 32), HapticsSetting(haptics: store.haptics),
    ],
  ]);

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'This permanently deletes your Secure By Design account, sign-in methods, saved progress, saved materials, learning activity, Community record, and email preferences on the website and in the app. It can’t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              key: const ValueKey('confirm-delete-account'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete account')),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await account.deleteAccount();
    if (deleted && store.cloudConnected) await store.disconnectAccount();
    if (context.mounted) {
      showNotice(context, deleted
          ? 'Your account was deleted. Learning on this device is still here.'
          : account.error ?? 'Your account could not be deleted. Try again.');
    }
  }

  Widget _accountAndSecurity(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (account.signedIn) ...[
      const Kicker('Signed in as'),
      const SizedBox(height: 10),
      Text(account.email!, style: Theme.of(context).textTheme.titleMedium),
    ] else ...[
      const Text('Sign in with your Secure By Design account to connect progress.'),
      const SizedBox(height: 12),
      FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => AccountScreen(account: account))),
          child: const Text('Sign in')),
    ],
    const SizedBox(height: 20),
    _AccountRow(icon: Icons.lock_outline, title: 'Password & account help',
        subtitle: 'Open secure account recovery',
        onTap: () => openResource(context, 'https://securebydesigninc.com/my-progress')),
    _AccountRow(icon: Icons.privacy_tip_outlined, title: 'Privacy policy',
        subtitle: 'What we collect and how to control it',
        onTap: () => openResource(context, 'https://securebydesigninc.com/privacy')),
    _AccountRow(icon: Icons.delete_outline, title: 'Delete your account',
        subtitle: account.signedIn
            ? 'Permanently delete your account and its data'
            : 'Sign in first, or see how to request deletion',
        onTap: () => account.signedIn
            ? _confirmDelete(context)
            : openResource(context, 'https://securebydesigninc.com/privacy#delete-account')),
    const Divider(height: 32),
    AnalyticsSetting(analytics: store.analytics),
    const SizedBox(height: 24),
    const Text('Your session ends when you close the app or after 12 hours. '
        'Signing out keeps device-only learning separate from account progress.'),
    if (account.signedIn) ...[
      const SizedBox(height: 20),
      OutlinedButton.icon(onPressed: account.busy ? null : () async {
        await account.signOut();
        if (store.cloudConnected) await store.disconnectAccount();
      }, icon: const Icon(Icons.logout), label: const Text('Sign out')),
    ],
    if (account.error != null) ...[
      const SizedBox(height: 16),
      Semantics(liveRegion: true, child: Text(account.error!,
          style: const TextStyle(color: SbdColors.cyan))),
    ],
  ]);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([store, account]),
      builder: (context, _) {
        final path = store.currentPath;
        final stats = store.stats;
        return PageContent(children: [
          Text('My Account', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Panel(gradient: true, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(radius: 26, backgroundColor: SbdColors.surface,
                  child: Icon(Icons.person_outline, size: 30, color: SbdColors.cyan)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(account.signedIn
                        ? 'Welcome back.'
                        : 'Save your progress everywhere',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(account.signedIn ? account.email! : 'Learning on this device'),
              ])),
            ]),
            const SizedBox(height: 20),
            Text(store.storageLabel, style: const TextStyle(fontSize: 13)),
            // Sell sign-in on what it does for the learner, not on the form.
            if (!account.signedIn) ...[
              const SizedBox(height: 16),
              for (final benefit in const [
                'Your lessons and bookmarks sync across devices',
                'Your streak and XP follow you',
                'Pick up on the web right where you stopped',
              ])
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_rounded,
                              size: 18, color: SbdColors.cyan),
                          const SizedBox(width: 10),
                          Expanded(child: Text(benefit, style: const TextStyle(
                              color: SbdColors.muted, height: 1.4))),
                        ])),
              const SizedBox(height: 4),
            ] else
              const SizedBox(height: 14),
            if (!account.signedIn) ...[
              FilledButton.icon(onPressed: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) => AccountScreen(account: account))),
                  icon: const Icon(Icons.login), label: const Text('Sign in')),
              const SizedBox(height: 12),
              const Text('You can keep learning on this device either way.',
                  style: TextStyle(fontSize: 12, color: SbdColors.muted)),
            ],
          ])),
          const SizedBox(height: 20),
          // Zeros demotivate: the stat row appears once there is something
          // real to show.
          if (store.completed.isNotEmpty ||
              stats.streak > 0 ||
              stats.totalXp > 0) ...[
            LayoutBuilder(builder: (context, constraints) {
              final oneColumn = constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(16) > 21;
              final width = oneColumn ? constraints.maxWidth : (constraints.maxWidth - 20) / 3;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                _AccountStat(width: width, value: '${store.completed.length}', label: 'Lessons'),
                _AccountStat(width: width, value: '${stats.streak}', label: 'Day streak'),
                _AccountStat(width: width, value: '${stats.totalXp}', label: 'Total XP'),
              ]);
            }),
            const SizedBox(height: 24),
          ],
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Kicker('Continue learning'),
            const SizedBox(height: 12),
            Text(path.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ProgressLine(value: store.progressIn(path)),
            const SizedBox(height: 10),
            Text('${store.completedIn(path)} of ${path.lessons.length} lessons complete'),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: () => openLearningPath(context, store, path),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(store.completedIn(path) == path.lessons.length
                    ? 'Review course' : 'Continue learning')),
          ])),
          const SizedBox(height: 26),
          _AccountGroup(title: 'My learning', children: [
            _AccountRow(icon: Icons.auto_stories_outlined, title: 'My courses',
                subtitle: 'Progress across every training path',
                onTap: () => _detail('My courses', _courseProgress)),
            _AccountRow(icon: Icons.bookmarks_outlined, title: 'Saved materials',
                subtitle: '${store.saved.length} saved for later',
                onTap: () => _detail('Saved materials', _savedMaterials)),
            _AccountRow(icon: Icons.emoji_events_outlined, title: 'Quests & rewards',
                subtitle: 'Streaks, achievements, and your daily goal',
                onTap: () => _detail('Quests & rewards', (context) => LearningDashboard(
                    store: store, onPractice: () => openPractice(context, store)))),
          ]),
          const SizedBox(height: 24),
          _AccountGroup(title: 'Preferences & support', children: [
            _AccountRow(icon: Icons.tune, title: 'Learning preferences',
                subtitle: 'Goals, starting level, and in-app reminders',
                onTap: () => _detail('Learning preferences', _preferences)),
            _AccountRow(icon: Icons.manage_accounts_outlined, title: 'Account & security',
                subtitle: 'Sign-in, password help, and privacy',
                onTap: () => _detail('Account & security', _accountAndSecurity)),
            _AccountRow(icon: Icons.chat_bubble_outline, title: 'Help & feedback',
                subtitle: 'Share an idea or request an improvement',
                onTap: () => _detail('Help & feedback', (_) => FeedbackPanel(store: store))),
            _AccountRow(icon: Icons.info_outline, title: 'About Secure By Design',
                subtitle: 'Learn it. Share it. Pay it forward.',
                onTap: () => _detail('About Secure By Design', (_) => const CreatorNote())),
          ]),
          const SizedBox(height: 24),
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Progress across devices', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(account.signedIn
                ? store.cloudConnected
                    ? 'Your account progress is connected.'
                    : 'Connect when you are ready. Device-only progress stays separate.'
                : 'Sign in to connect your lessons and bookmarks. You can keep learning on this device.'),
            if (account.signedIn) ...[
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: store.syncing ? null : _connect,
                  icon: const Icon(Icons.sync), label: Text(store.syncing ? 'Syncing…'
                      : store.cloudConnected ? 'Sync now' : 'Connect progress')),
            ],
            if (store.syncError != null) ...[
              const SizedBox(height: 12),
              Semantics(liveRegion: true, child: Text(store.syncError!,
                  style: const TextStyle(color: SbdColors.cyan))),
            ],
            if (store.lastSynced != null && !store.syncing && store.syncError == null) ...[
              const SizedBox(height: 12),
              const Text('Progress synced.', style: TextStyle(color: SbdColors.success)),
            ],
            if (store.cloudConnected)
              TextButton(onPressed: store.syncing ? null : _importProgress,
                  child: const Text('Add my device-only progress')),
          ])),
          const SizedBox(height: 24),
          // Owner request, 16 October 2026: no membership tiers. Every account
          // is a free Community account, as on the website's My Account.
          CommunityAccountPanel(analytics: store.analytics),
        ]);
      });
}

class _AccountStat extends StatelessWidget {
  const _AccountStat({required this.width, required this.value, required this.label});
  final double width;
  final String value, label;
  @override
  Widget build(BuildContext context) => SizedBox(width: width,
      child: Panel(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Column(children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: SbdColors.cyan)),
            const SizedBox(height: 6), Text(label, textAlign: TextAlign.center),
          ])));
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 12),
    Panel(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1), children[i],
          ],
        ])),
  ]);
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.title,
      required this.subtitle, required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon, color: SbdColors.cyan),
      title: Text(title), subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20), onTap: onTap);
}
