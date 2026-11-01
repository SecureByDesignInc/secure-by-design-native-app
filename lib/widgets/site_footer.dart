import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/analytics.dart';
import '../data/booking.dart';
import '../theme.dart';
import 'common.dart';

const youtubeUrl = 'https://www.youtube.com/channel/UCItxo3KJms-IuQKdFzFXqRg';
const tiktokUrl = 'https://www.tiktok.com/@jon_sbd';
const instagramUrl = 'https://www.instagram.com/securebydesigninc/';
const linkedInUrl = 'https://www.linkedin.com/company/secure-by-design-inc/';
const discordUrl = 'https://discord.gg/MDrGbP4cAY';
const siteUrl = 'https://securebydesigninc.com';
const privacyUrl = 'https://securebydesigninc.com/privacy';

/// The website's "Follow along" channels (content/videos.json platforms), in
/// its order, each with the owner's icon art in assets/social.
const followAlong = <(String id, String name, String url)>[
  ('youtube', 'YouTube', youtubeUrl),
  ('tiktok', 'TikTok', tiktokUrl),
  ('instagram', 'Instagram', instagramUrl),
  ('linkedin', 'LinkedIn', linkedInUrl),
  ('discord', 'Discord', discordUrl),
];

/// The site's logo pill (.logo-pill): the channel's icon on a blue gradient
/// with its name, opening the channel in the browser.
class LogoPill extends StatelessWidget {
  const LogoPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticsHint,
  });
  final String icon;
  final String label;
  final VoidCallback onTap;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        link: true,
        label: label,
        hint: semanticsHint ?? 'Opens in your browser',
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.fromLTRB(7, 5, 12, 5),
              decoration: BoxDecoration(
                gradient: SbdColors.pill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SbdColors.pillBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/social/$icon.png',
                    width: 22, height: 22, fit: BoxFit.contain),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(label,
                        style: const TextStyle(
                            color: SbdColors.pillInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2))),
              ]),
            ),
          ),
        ),
      );
}

/// The "Follow along" row: YouTube, TikTok, Instagram, LinkedIn, Discord,
/// then Book a call (lib/follow-along.mjs on the website).
class FollowAlongRow extends StatelessWidget {
  const FollowAlongRow({super.key, this.analytics});
  final LearningAnalytics? analytics;

  @override
  Widget build(BuildContext context) {
    final booking = validBookingUrl(bookingPageUrl);
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final (id, name, url) in followAlong)
        LogoPill(icon: id, label: name, onTap: () => openResource(context, url)),
      if (booking != null)
        LogoPill(
            key: const ValueKey('follow-book-a-call'),
            icon: 'book-a-call',
            label: bookingLabel,
            onTap: () =>
                openResource(context, booking, onOpened: analytics?.bookingOpened)),
    ]);
  }
}

Future<void> passItOn(BuildContext context) async {
  try {
    await SharePlus.instance.share(ShareParams(
        text: 'Secure By Design: build a small enterprise network, step by step, and keep the proof. $siteUrl',
        subject: 'Secure By Design'));
  } catch (_) {
    if (context.mounted) showNotice(context, 'Sharing is not available on this device.');
  }
}

/// The site's footer, beneath every page (app/layout.tsx, 26–27 October 2026):
/// Follow along, then the partner programs with Secure By Design © 2026,
/// Privacy and Pass it on. App availability is left out; this is the app.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, this.analytics});
  final LearningAnalytics? analytics;

  static const _partners = <(String id, String label, double width, double height)>[
    ('tenable', 'Tenable Partner', 154, 53),
    ('red-hat', 'Red Hat Partner', 613, 145),
  ];

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    const label = Text('Follow along',
        style: TextStyle(
            color: SbdColors.inkBright, fontSize: 14, fontWeight: FontWeight.w700, height: 1.5));
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(gutter, 26, gutter, 26),
      decoration: const BoxDecoration(
          color: SbdColors.stage,
          border: Border(top: BorderSide(color: SbdColors.borderHeader))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (narrow) ...[
          label,
          const SizedBox(height: 8),
          FollowAlongRow(analytics: analytics),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(width: 120, child: label),
            Expanded(child: FollowAlongRow(analytics: analytics)),
          ]),
        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFF1B2D42)),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 16,
          children: [
            Wrap(spacing: 20, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              for (final (id, name, width, height) in _partners)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 108,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8FCFF),
                          borderRadius: BorderRadius.circular(5)),
                      child: Image.asset('assets/partners/$id.png',
                          width: width, height: height, fit: BoxFit.contain, semanticLabel: name)),
                  const SizedBox(width: 10),
                  Flexible(
                      child: Text(name,
                          style: const TextStyle(
                              color: Color(0xFFD1E1F2), fontSize: 14, fontWeight: FontWeight.w600))),
                ]),
            ]),
            Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              TextButton(
                  onPressed: () => openResource(context, siteUrl),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFDCECFF)),
                  child: const Text('Secure By Design © 2026')),
              TextButton(
                  onPressed: () => openResource(context, privacyUrl),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFDCECFF)),
                  child: const Text('Privacy')),
              TextButton.icon(
                  key: const ValueKey('pass-it-on'),
                  onPressed: () => passItOn(context),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFDCECFF)),
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('Pass it on')),
            ]),
          ],
        ),
      ]),
    );
  }
}
