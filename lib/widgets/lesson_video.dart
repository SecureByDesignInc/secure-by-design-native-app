import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// A lesson or trailer video hosted on YouTube.
///
/// Shows the video's artwork with a play button first, so screens stay fast
/// and work offline; the official privacy-enhanced YouTube embed loads only
/// when the learner taps play.
class LessonVideo extends StatefulWidget {
  const LessonVideo({
    super.key,
    required this.youtubeId,
    required this.title,
    this.kicker = '',
  });

  final String youtubeId;
  final String title;

  /// Small uppercase label drawn on the artwork, e.g. 'Course trailer'.
  final String kicker;

  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  WebViewController? _player;

  void _play() {
    final embed = Uri.https('www.youtube-nocookie.com',
        '/embed/${widget.youtubeId}', {
      'autoplay': '1',
      'playsinline': '1',
      'rel': '0',
      'modestbranding': '1',
    });
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(SbdColors.background)
      ..loadRequest(embed);
    setState(() => _player = controller);
  }

  Widget _artwork() => Stack(fit: StackFit.expand, children: [
        Image.network(
          'https://img.youtube.com/vi/${widget.youtubeId}/hqdefault.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const DecoratedBox(
            decoration: BoxDecoration(gradient: SbdColors.gradient),
          ),
        ),
        // Keeps the play button and label legible over bright artwork.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SbdColors.background.withValues(alpha: 0.10),
                SbdColors.background.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
        if (widget.kicker.isNotEmpty)
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: SbdColors.background.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: SbdColors.cyan.withValues(alpha: 0.35)),
              ),
              child: Text(
                widget.kicker.toUpperCase(),
                style: const TextStyle(
                  color: SbdColors.cyan,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SbdColors.buttonGradient,
              boxShadow: [
                BoxShadow(
                  color: SbdColors.background.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: SbdColors.background, size: 34),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _player != null
              ? WebViewWidget(controller: _player!)
              : Semantics(
                  button: true,
                  label: 'Play video: ${widget.title}',
                  child: Material(
                    color: SbdColors.surface,
                    child: InkWell(
                      key: ValueKey('play-${widget.youtubeId}'),
                      onTap: _play,
                      child: _artwork(),
                    ),
                  ),
                ),
        ),
      );
}
