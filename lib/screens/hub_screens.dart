import 'package:flutter/material.dart';

import '../data/ato_builder.dart';
import '../data/booking.dart';
import '../data/catalog.dart';
import '../data/learning_store.dart';
import '../data/models.dart';
import '../data/published_catalog.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'network_screen.dart';
import 'path_screen.dart';

const discordUrl = 'https://discord.gg/MDrGbP4cAY';
const linkedInUrl = 'https://www.linkedin.com/company/secure-by-design-inc/';
const communityHubUrl = 'https://securebydesigninc.com/community';

/// A row that opens something: an icon, a title and a line of detail.
class HubLink extends StatelessWidget {
  const HubLink(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.external = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  /// Opens the browser rather than another screen of the app.
  final bool external;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
          padding: const EdgeInsets.all(18),
          onTap: onTap,
          child: Row(children: [
            Icon(icon, color: SbdColors.cyan),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(color: SbdColors.muted, height: 1.5)),
                ])),
            const SizedBox(width: 8),
            Icon(external ? Icons.open_in_new : Icons.chevron_right,
                size: external ? 18 : 24, color: SbdColors.muted),
          ])));
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: SbdColors.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SbdColors.cyan.withValues(alpha: 0.35)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: SbdColors.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

/// The website's System Hub: Inside the Network, the system this training
/// builds. The app's reference works offline; the 3D view needs a connection.
class SystemHubScreen extends StatelessWidget {
  const SystemHubScreen({super.key, required this.store});
  final LearningStore store;

  void _open(BuildContext context) => Navigator.push(
      context, MaterialPageRoute<void>(builder: (_) => const NetworkScreen()));

  @override
  Widget build(BuildContext context) => PageContent(children: [
        const PageTitle('Inside the Network',
            'Every system you build, the segments they live on, and the paths the network permits between them.',
            kicker: 'System Hub'),
        Panel(
            gradient: true,
            onTap: () => _open(context),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: Kicker('The network you build')),
                    Icon(Icons.hub_outlined,
                        color: SbdColors.cyan.withValues(alpha: 0.7), size: 34),
                  ]),
                  const SizedBox(height: 10),
                  Text('Walk the systems behind every lesson',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Follow each traffic process step by step, test the what-ifs, and read every rule in the policy register. Works offline; the 3D view opens with a connection.',
                      style: TextStyle(color: SbdColors.muted, height: 1.6)),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                      onPressed: () => _open(context),
                      icon: const Icon(Icons.explore_outlined, size: 19),
                      label: const Text('Open the System Hub')),
                ])),
        const SizedBox(height: 24),
        Text('What’s inside', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final (icon, title, text) in const [
          (Icons.alt_route, 'Traffic processes',
              'How a sign-in, a log event or an update crosses the network, one hop at a time.'),
          (Icons.help_outline, 'What-ifs',
              'What changes when a system is down or a rule is removed.'),
          (Icons.dns_outlined, 'Systems', 'Every host, its VLAN, its role and the course that builds it.'),
          (Icons.rule, 'Policy register', 'Each permitted path, its owner and why it exists.'),
        ])
          HubLink(icon: icon, title: title, subtitle: text, onTap: () => _open(context)),
      ]);
}

/// The ATO Package Builder in the Training Hub (website, 27 October 2026): the
/// Tools (the builder, no account needed, and the System Hub) and the seven RMF
/// steps, each with its course 2.1 lessons, its builder task and its templates.
/// The separate ATO Package Builder Hub tab is retired, as the website's page is.
class AtoBuilderSection extends StatelessWidget {
  const AtoBuilderSection({super.key, required this.store, this.onSystemHub});
  final LearningStore store;
  final VoidCallback? onSystemHub;

  LearningPath? get _course =>
      learningPaths.where((path) => path.id == rmfCourseId).firstOrNull;

  void _openLesson(BuildContext context, String id) {
    final course = _course;
    final lesson = course?.lessons.where((l) => l.id == id).firstOrNull;
    if (course == null || lesson == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
            store: store,
            path: course,
            lesson: lesson,
            practice: store.isCompleted(lesson.id))));
  }

  Widget _step(BuildContext context, int index, RmfStep step) {
    final course = _course;
    final lessons = [
      for (final id in step.lessonIds)
        if (course?.lessons.where((l) => l.id == id).firstOrNull case final Lesson lesson)
          lesson,
    ];
    final done = lessons.where((l) => store.isCompleted(l.id)).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Kicker('Step ${index + 1} · ${step.moduleRange}')),
          if (lessons.isNotEmpty && done == lessons.length)
            const Icon(Icons.check_circle_rounded, color: SbdColors.success, size: 20),
        ]),
        const SizedBox(height: 10),
        Text(step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(step.task, style: const TextStyle(color: SbdColors.muted, height: 1.6)),
        const SizedBox(height: 14),
        for (final lesson in lessons)
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                  store.isCompleted(lesson.id)
                      ? Icons.check_circle_rounded
                      : Icons.play_circle_outline,
                  color: store.isCompleted(lesson.id)
                      ? SbdColors.success
                      : SbdColors.cyan),
              title: Text(lesson.title),
              subtitle: Text('${lesson.minutes} min · course 2.1'),
              onTap: () => _openLesson(context, lesson.id)),
        Wrap(spacing: 8, runSpacing: 4, children: [
          TextButton.icon(
              onPressed: () => openResource(context, atoBuilderUrl),
              icon: const Icon(Icons.open_in_new, size: 17),
              label: Text('Do the ${step.title} step in the builder')),
          if (step.hasTemplates)
            TextButton.icon(
                onPressed: () => openResource(context, step.templatesUrl),
                icon: const Icon(Icons.description_outlined, size: 17),
                label: Text('${step.title} templates')),
        ]),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        final course = _course;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Tools', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Panel(
              key: const ValueKey('tool-ato-builder'),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Kicker('Tool · No account needed'),
                const SizedBox(height: 10),
                Text('ATO Package Builder', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                    'Take the Secure By Design enclave through all seven RMF steps, from naming its roles to the authorization decision. Sign in to save your work, or use it without an account for one visit.',
                    style: TextStyle(color: SbdColors.muted, height: 1.6)),
                const SizedBox(height: 14),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  FilledButton.icon(
                      onPressed: () => openResource(context, atoBuilderUrl),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open the builder')),
                  if (course != null)
                    OutlinedButton.icon(
                        onPressed: () => openLearningPath(context, store, course),
                        icon: const Icon(Icons.auto_stories_outlined, size: 18),
                        label: const Text('Course 2.1')),
                ]),
              ])),
          if (onSystemHub != null) ...[
            const SizedBox(height: 12),
            Panel(
                key: const ValueKey('tool-system-hub'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Kicker('Tool'),
                  const SizedBox(height: 10),
                  Text('System Hub', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Explore every system in the lab network and follow the traffic between them.',
                      style: TextStyle(color: SbdColors.muted, height: 1.6)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                      onPressed: onSystemHub,
                      icon: const Icon(Icons.arrow_forward, size: 17),
                      label: const Text('Open the System Hub')),
                ])),
          ],
          const SizedBox(height: 28),
          const Kicker('Network Authorization · Course 2.1 RMF to ATO'),
          const SizedBox(height: 8),
          Text('Seven RMF steps: learn it, do it, use its templates',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (var i = 0; i < rmfSteps.length; i++) _step(context, i, rmfSteps[i]),
          const Text(
              'The reviews and the decision are automated practice rules and carry no authority. Enter practice data only.',
              style: TextStyle(color: SbdColors.muted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
        ]);
      });
}

/// The website's Community & Careers Hub: people, programs and jobs, by state.
class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key, required this.store});
  final LearningStore store;

  static const _onEveryPage = [
    ('Jobs',
        'The state’s own government job portal and public job board, plus current federal IT and cybersecurity openings.'),
    ('Paying for training',
        'The state workforce agency that runs WIOA training funds and American Job Centers, plus apprenticeships and SkillBridge.'),
    ('People near you',
        'Where to find ISSA, ISC2, ISACA, OWASP, InfraGard, DEF CON groups and BSides events in your state.'),
    ('The job market',
        'Where to see openings, workforce size and in-demand certifications for your state.'),
  ];

  static const _inTheWorks = [
    ('Role pathways',
        'Sysadmin, SOC analyst, ISSO and more, mapped to the courses that build each skill.'),
    ('Certification roadmap',
        'Which certifications each role asks for, in what order, and where DoD 8140 applies.'),
    ('Portfolio and resume guide',
        'Turning your lab work into proof a hiring manager can see.'),
    ('Interview prep',
        'Common technical and behavioral questions, and how to talk through your lab work.'),
  ];

  @override
  Widget build(BuildContext context) {
    final booking = validBookingUrl(bookingPageUrl);
    return PageContent(children: [
      const PageTitle('Find your people. Find your next role.',
          'Job openings, programs that can pay for your training, and places to meet people in the field, organized by state. Built for everyone learning with Secure By Design.',
          kicker: 'Community & Careers Hub'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.icon(
            onPressed: () => openResource(context, discordUrl),
            icon: const Icon(Icons.forum_outlined, size: 18),
            label: const Text('Join the Discord')),
        OutlinedButton.icon(
            onPressed: () => openResource(context, linkedInUrl),
            icon: const Icon(Icons.work_outline, size: 18),
            label: const Text('Follow on LinkedIn')),
        if (booking != null)
          OutlinedButton.icon(
              onPressed: () => openResource(context, booking,
                  onOpened: store.analytics.bookingOpened),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: const Text(bookingLabel)),
      ]),
      const SizedBox(height: 28),
      Panel(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
              key: const ValueKey('community-states'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.map_outlined, color: SbdColors.cyan),
              title: const Text('Find your state'),
              subtitle: const Text('50 states · Washington, DC'),
              children: [
                for (final state in bundledCommunityStates)
                  ListTile(
                      dense: true,
                      title: Text(state.name),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () => openResource(context, state.url)),
              ])),
      const SizedBox(height: 28),
      Text('On every state page', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final (title, text) in _onEveryPage)
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline, color: SbdColors.cyan),
            title: Text(title),
            subtitle: Text(text)),
      const SizedBox(height: 22),
      Text('Coming soon to the hub', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final (title, text) in _inTheWorks)
        Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Badge('Coming soon'),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(color: SbdColors.muted, height: 1.5)),
            ])),
      const SizedBox(height: 18),
      Text('Plan your next step', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      HubLink(
          icon: Icons.flag_outlined,
          title: 'Career goals worksheet',
          subtitle: 'Write down where you’re headed and what gets you there.',
          external: true,
          onTap: () => openResource(context, 'https://securebydesigninc.com/career-goals')),
      HubLink(
          icon: Icons.terminal_outlined,
          title: 'Cyber Range',
          subtitle: 'Battle the computer in seven rounds of multiple choice.',
          external: true,
          onTap: () => openResource(context, 'https://securebydesigninc.com/cyber-range')),
      HubLink(
          icon: Icons.public,
          title: 'The full hub on the website',
          subtitle: 'State pages, federal jobs and ways to suggest a resource we missed.',
          external: true,
          onTap: () => openResource(context, communityHubUrl)),
    ]);
  }
}
