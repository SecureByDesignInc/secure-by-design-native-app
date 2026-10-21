import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/guide_state.dart';
import '../data/keep_awake.dart';
import '../data/learning_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Lab mode: the phone as a second screen beside the keyboard. One build step
/// at a time, the inspection commands with copy buttons, then the lesson's
/// checklist and observations, the same ones the website's course guide keeps.
/// The screen stays on while it is open.
class LabModeScreen extends StatefulWidget {
  const LabModeScreen(
      {super.key, required this.store, required this.path, required this.lesson});
  final LearningStore store;
  final LearningPath path;
  final Lesson lesson;

  @override
  State<LabModeScreen> createState() => _LabModeScreenState();
}

enum _Page { step, commands, checks }

class _LabModeScreenState extends State<LabModeScreen> {
  late final List<LabStep> _steps = widget.lesson.labSteps;
  late final List<(_Page, int)> _pages = [
    for (var i = 0; i < _steps.length; i++) (_Page.step, i),
    if (widget.lesson.labCommands.trim().isNotEmpty) (_Page.commands, 0),
    (_Page.checks, 0),
  ];
  int _page = 0;
  LabNotes? _notes;
  final _note = TextEditingController();
  bool _typed = false;

  @override
  void initState() {
    super.initState();
    unawaited(KeepAwake.set(true));
    if (widget.lesson.guide != null) unawaited(_openNotes());
  }

  Future<void> _openNotes() async {
    try {
      final notes = await LabNotes.open(widget.lesson,
          chapterIndex: widget.path.lessons.indexOf(widget.lesson),
          account: widget.store.account);
      if (!mounted) {
        notes.dispose();
        return;
      }
      notes.addListener(_notesChanged);
      _note.text = notes.note;
      setState(() => _notes = notes);
    } catch (_) {
      if (mounted) showNotice(context, 'Your checks and notes could not be opened.');
    }
  }

  /// An account copy that arrives after opening fills the note, unless the
  /// learner has already started typing.
  void _notesChanged() {
    final notes = _notes;
    if (notes == null) return;
    if (!_typed && _note.text != notes.note) _note.text = notes.note;
    setState(() {});
  }

  @override
  void dispose() {
    unawaited(KeepAwake.set(false));
    final notes = _notes;
    if (notes != null) {
      notes.removeListener(_notesChanged);
      unawaited(notes.close());
      notes.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  void _go(int page) {
    widget.store.haptics.selectionChanged();
    setState(() => _page = page.clamp(0, _pages.length - 1));
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showNotice(context, '$what copied.');
  }

  static const _mono = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Courier'],
      fontSize: 13.5,
      height: 1.5,
      color: SbdColors.ink);

  Widget _stepPage(BuildContext context, int index) {
    final step = _steps[index];
    final done = _notes?.stepDone(index) ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Kicker('Step ${index + 1} of ${_steps.length}'),
      const SizedBox(height: 12),
      Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      SelectableText(step.body, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 22),
      if (_notes != null)
        Panel(
            padding: EdgeInsets.zero,
            child: CheckboxListTile(
                key: ValueKey('lab-step-$index'),
                value: done,
                onChanged: (value) =>
                    unawaited(_notes!.setStepDone(index, value ?? false)),
                title: const Text('I’ve done this step'),
                subtitle: const Text('Kept on this device'),
                controlAffinity: ListTileControlAffinity.leading)),
    ]);
  }

  Widget _commandsPage(BuildContext context) {
    final commands = widget.lesson.labCommands;
    final lines = commands.split('\n');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Kicker('Inspect your configuration'),
      const SizedBox(height: 12),
      Text('Check your work', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 10),
      const Text('Run these where the lesson says. Each command has its own copy button.',
          style: TextStyle(color: SbdColors.muted, height: 1.5)),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          color: SbdColors.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SbdColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final line in lines)
            if (line.trim().isEmpty)
              const SizedBox(height: 8)
            else if (line.trimLeft().startsWith('#'))
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(line.trim(),
                      style: _mono.copyWith(color: SbdColors.muted)))
            else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: SelectableText(line, style: _mono))),
                IconButton(
                    tooltip: 'Copy this command',
                    icon: const Icon(Icons.copy_rounded, size: 19, color: SbdColors.cyan),
                    onPressed: () => _copy(line.trim(), 'Command')),
              ]),
        ]),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
          onPressed: () => _copy(commands, 'All commands'),
          icon: const Icon(Icons.copy_all_rounded, size: 18),
          label: const Text('Copy all')),
      if (widget.lesson.labSuccess.isNotEmpty) ...[
        const SizedBox(height: 26),
        Text('What success looks like', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Text(widget.lesson.labSuccess, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ]);
  }

  Widget _checksPage(BuildContext context) {
    final guide = widget.lesson.guide;
    final notes = _notes;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Kicker('Checks & notes'),
      const SizedBox(height: 12),
      Text('Prove it, then write it down',
          style: Theme.of(context).textTheme.headlineSmall),
      if (guide != null && notes != null) ...[
        const SizedBox(height: 10),
        const Text(
            'These are the checks and observations from the website’s course guide for this lesson. Tick what you confirmed in your own environment.',
            style: TextStyle(color: SbdColors.muted, height: 1.5)),
        const SizedBox(height: 16),
        Panel(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < guide.checklist.length; i++)
                CheckboxListTile(
                    key: ValueKey('lab-check-$i'),
                    value: notes.checked(i),
                    onChanged: (value) => unawaited(notes.setChecked(i, value ?? false)),
                    title: Text(guide.checklist[i]),
                    controlAffinity: ListTileControlAffinity.leading),
            ])),
        const SizedBox(height: 20),
        Text('Your observations', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        if (widget.lesson.labEvidence.isNotEmpty)
          Text(widget.lesson.labEvidence,
              style: const TextStyle(color: SbdColors.muted, height: 1.5)),
        const SizedBox(height: 12),
        TextField(
            key: const ValueKey('lab-observations'),
            controller: _note,
            minLines: 4,
            maxLines: 12,
            maxLength: 30000,
            decoration: const InputDecoration(
                hintText:
                    'What did you observe? Which file holds the evidence? What still needs attention?'),
            onChanged: (value) {
              _typed = true;
              unawaited(notes.setNote(value));
            }),
        const SizedBox(height: 6),
        Text(notes.status, style: const TextStyle(color: SbdColors.muted, fontSize: 13)),
      ] else if (guide != null) ...[
        const SizedBox(height: 20),
        const Center(child: CircularProgressIndicator()),
      ] else ...[
        const SizedBox(height: 10),
        if (widget.lesson.labSuccess.isNotEmpty)
          Text(widget.lesson.labSuccess, style: Theme.of(context).textTheme.bodyLarge),
        if (widget.lesson.labEvidence.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(widget.lesson.labEvidence, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ],
      const SizedBox(height: 22),
      const Text(
          'Finish the knowledge checks in the lesson to complete it. Record your results in the workbook for your portfolio.',
          style: TextStyle(color: SbdColors.muted, fontSize: 13, height: 1.5)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final (kind, index) = _pages[_page];
    final last = _page == _pages.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab mode', style: TextStyle(fontSize: 16)),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 16),
              child: Tooltip(
                  message: 'The screen stays on while lab mode is open',
                  child: Icon(Icons.light_mode_outlined, color: SbdColors.muted))),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          LinearProgressIndicator(
              value: (_page + 1) / _pages.length,
              minHeight: 3,
              backgroundColor: SbdColors.border,
              color: SbdColors.cyan,
              // Screen readers need a number here; the label says where you are.
              semanticsLabel: 'Lab mode, page ${_page + 1} of ${_pages.length}',
              semanticsValue: '${((_page + 1) * 100 / _pages.length).round()}'),
          Expanded(
            child: PageContent(maxWidth: 760, children: [
              Text(widget.lesson.title,
                  style: const TextStyle(color: SbdColors.cyan, fontSize: 13)),
              const SizedBox(height: 14),
              switch (kind) {
                _Page.step => _stepPage(context, index),
                _Page.commands => _commandsPage(context),
                _Page.checks => _checksPage(context),
              },
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: _page == 0 ? null : () => _go(_page - 1),
                      child: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      key: const ValueKey('lab-next'),
                      onPressed: last ? () => Navigator.pop(context) : () => _go(_page + 1),
                      child: Text(last ? 'Finish' : 'Next'))),
            ]),
          ),
        ]),
      ),
    );
  }
}
