import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

IconData topicIcon(String key) => switch (key) {
      'directory' => Icons.hub_outlined,
      'monitoring' => Icons.insights_outlined,
      'risk' => Icons.verified_user_outlined,
      'journal' => Icons.menu_book_outlined,
      'career' => Icons.explore_outlined,
      'video' => Icons.play_circle_outline,
      _ => Icons.school_outlined,
    };

void showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> openResource(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') {
      throw ArgumentError('Only secure resource links are supported.');
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showNotice(context, 'This link could not be opened. Please try again.');
    }
  } catch (_) {
    if (context.mounted) {
      showNotice(context, 'This link could not be opened. Please try again.');
    }
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/brand/brand-mark.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 11),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Secure By Design',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 17),
                ),
                if (!compact)
                  const Text(
                    'LEARNING COMPANION',
                    style: TextStyle(
                      color: SbdColors.muted,
                      fontSize: 10,
                      letterSpacing: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: SbdColors.cyan),
      );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.gradient = false,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final bool gradient;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: gradient ? null : SbdColors.surfaceLow,
          gradient: gradient ? SbdColors.gradient : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SbdColors.border),
        ),
        child: child,
      );
}

class TopicBadge extends StatelessWidget {
  const TopicBadge(this.icon, {super.key, this.size = 48});
  final String icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: SbdColors.cyan.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SbdColors.cyan.withValues(alpha: 0.14)),
        ),
        child: Icon(topicIcon(icon), color: SbdColors.cyan, size: size * 0.48),
      );
}

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children, this.maxWidth = 1120});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 600 ? 22 : 36,
          24,
          MediaQuery.sizeOf(context).width < 600 ? 22 : 36,
          32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      );
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, this.subtitle, {super.key, required this.kicker});
  final String title;
  final String subtitle;
  final String kicker;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker(kicker),
          const SizedBox(height: 13),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 26),
        ],
      );
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 5,
          backgroundColor: SbdColors.border,
          color: SbdColors.cyan,
          semanticsLabel: 'Learning path progress',
          semanticsValue: '${(value * 100).round()}',
        ),
      );
}

class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({
    super.key,
    required this.children,
    this.minWidth = 290,
  });
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.maxWidth / minWidth).floor().clamp(1, 3);
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children:
                children.map((w) => SizedBox(width: width, child: w)).toList(),
          );
        },
      );
}
