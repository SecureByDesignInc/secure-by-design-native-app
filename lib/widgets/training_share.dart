import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import 'common.dart';

const homepageShareUrl = 'https://securebydesigninc.com/';

class TrainingShare extends StatelessWidget {
  const TrainingShare({super.key});
  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      final result = await SharePlus.instance.share(ShareParams(
        text: 'Learn it. Share it. Pay it forward. $homepageShareUrl',
        subject: 'Secure By Design',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        await Clipboard.setData(const ClipboardData(text: homepageShareUrl));
        if (context.mounted) {
          showNotice(context, 'Homepage link copied. Ready to pass it on.');
        }
      }
    } catch (_) {
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
          context: context,
          builder: (context) => SafeArea(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Pass it on'),
                  const SizedBox(height: 16),
                  const SelectableText(homepageShareUrl),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: () async {
                        await Clipboard.setData(
                            const ClipboardData(text: homepageShareUrl));
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Copy homepage link')),
                ]),
              )));
    }
  }

  @override
  Widget build(BuildContext context) => Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Kicker('Learn it. Share it. Pay it forward.'),
        const SizedBox(height: 12),
        Text('If this helped you, help someone else find it.',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text('Pass it on to someone who could use it.',
            style: TextStyle(color: SbdColors.muted)),
        const SizedBox(height: 16),
        Builder(
            builder: (buttonContext) => OutlinedButton.icon(
                onPressed: () => _share(buttonContext),
                icon: const Icon(Icons.ios_share),
                label: const Text('Pass it on'))),
      ]));
}
