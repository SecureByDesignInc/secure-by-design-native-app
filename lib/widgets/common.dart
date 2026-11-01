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

Future<void> openResource(BuildContext context, String url,
    {VoidCallback? onOpened}) async {
  try {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') {
      throw ArgumentError('Only secure resource links are supported.');
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) onOpened?.call();
    if (!opened && context.mounted) {
      showNotice(context, 'This link could not be opened. Please try again.');
    }
  } catch (_) {
    if (context.mounted) {
      showNotice(context, 'This link could not be opened. Please try again.');
    }
  }
}

/// The site header's branding (app/layout.tsx): the logo, the wordmark with
/// "Secure" in bold, and the tagline beneath it.
class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false, this.logoSize = 44});
  final bool compact;
  final double logoSize;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(logoSize * 0.27),
            child: Image.asset(
              'assets/brand/brand-mark.png',
              width: logoSize,
              height: logoSize,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'Secure',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: ' By Design'),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SbdColors.inkBright,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                if (!compact)
                  const Text(
                    'EDUCATE. EMPOWER. SECURE THE FUTURE.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFA4B9D1),
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

/// A kicker the way the site sets one: Geist Mono, small capitals, tracked.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color = SbdColors.cyan});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      );
}

/// A panel: a flat surface on a hairline (.th-tools-card, .th-empty).
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.gradient = false,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.radius = 18,
  });
  final Widget child;
  final bool gradient;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
        decoration: softSurface(featured: gradient, radius: radius),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// A small square icon tile, like the site's sidebar brand mark.
class TopicBadge extends StatelessWidget {
  const TopicBadge(this.icon, {super.key, this.size = 44});
  final String icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: SbdColors.surfaceSelected,
          borderRadius: BorderRadius.circular(size * 0.25),
          border: Border.all(color: SbdColors.borderInput),
        ),
        child: Icon(topicIcon(icon), color: SbdColors.cyan, size: size * 0.5),
      );
}

/// Phones get the site's 16px gutters; wider screens its 24px.
double pageGutter(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600 ? 16 : 28;

class PageContent extends StatelessWidget {
  const PageContent({
    super.key,
    required this.children,
    this.maxWidth = 1120,
    this.controller,
    this.footer,
    this.topPadding = 22,
  });
  final List<Widget> children;
  final double maxWidth;
  final ScrollController? controller;

  /// Shown beneath the content at full width, the way the site's footer
  /// follows every page.
  final Widget? footer;
  final double topPadding;
  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(context);
    return SingleChildScrollView(
      controller: controller,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, topPadding, gutter, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
        if (footer != null) footer!,
      ]),
    );
  }
}

/// A page's opening: the kicker, the title and a line of copy (.th-top).
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
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontSize: 15)),
          const SizedBox(height: 24),
        ],
      );
}

/// A row's heading with its count or its View all (.th-shelf-head).
class ShelfHeading extends StatelessWidget {
  const ShelfHeading(this.title, {super.key, this.note, this.action});
  final String title;

  /// A mono note at the right, like "12 courses · take them in order".
  final String? note;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge)),
          if (note != null) ...[
            const SizedBox(width: 12),
            Flexible(
                child: Text(note!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontFamily: sbdMono,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: SbdColors.muted))),
          ],
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      );
}

/// An inline text link with an arrow (.th-text-link).
class ArrowLink extends StatelessWidget {
  const ArrowLink(this.label, {super.key, required this.onTap, this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
        icon: Icon(icon ?? Icons.arrow_forward, size: 16),
        iconAlignment: IconAlignment.end,
        label: Text(label),
      );
}

/// The Training Hub's closing line (.th-footer): one network, one System Hub.
class HubFootnote extends StatelessWidget {
  const HubFootnote({super.key, required this.onSystemHub});
  final VoidCallback onSystemHub;
  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 12,
          children: [
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.hub_outlined, size: 20, color: SbdColors.cyan),
              SizedBox(width: 10),
              Text('Every build is part of a bigger network.',
                  style: TextStyle(color: SbdColors.ink, fontSize: 15)),
            ]),
            ArrowLink('Step inside the complete network in the System Hub',
                onTap: onSystemHub),
          ],
        ),
      );
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
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
