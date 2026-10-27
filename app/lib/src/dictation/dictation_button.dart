/// The composer's microphone button (AV-047): dictates into the box,
/// writing the words as they are spoken.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'dictation.dart';
import 'dictation_text.dart';
import 'speech_model.dart';

enum _Phase { idle, downloading, starting, listening, finishing }

/// Starts and stops dictation into [controller]. The first press offers
/// a choice of models to download ([ModelDownloadDialog]). Speech is written at the caret (replacing a
/// selection), each utterance's guess updated as it is spoken; typing in
/// the box, or sending it, stops dictation and keeps the text.
class DictationButton extends StatefulWidget {
  /// Creates a [DictationButton].
  const DictationButton({
    super.key,
    required this.dictation,
    required this.controller,
    this.focusNode,
    this.onListeningChanged,
  });

  /// The speech to text.
  final Dictation dictation;

  /// The box's text.
  final TextEditingController controller;

  /// The box, focused when dictation starts.
  final FocusNode? focusNode;

  /// Whether the microphone is on, each time that changes.
  final ValueChanged<bool>? onListeningChanged;

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<DictationButton> {
  var _phase = _Phase.idle;
  double? _progress;

  /// The model being downloaded.
  SpeechModel? _downloading;
  DictationSession? _session;
  StreamSubscription<Transcript>? _transcripts;
  DictationAnchor? _anchor;

  /// The text dictation last wrote; other text in the box is the user's.
  String? _written;

  @override
  void dispose() {
    _end(cancel: true, notify: false);
    super.dispose();
  }

  Future<void> _toggle() async {
    switch (_phase) {
      case _Phase.idle:
        await _start();
      case _Phase.listening:
        _setPhase(_Phase.finishing);
        await _session?.stop();
      case _Phase.downloading || _Phase.starting || _Phase.finishing:
        break;
    }
  }

  Future<void> _start() async {
    var dictation = widget.dictation;
    try {
      if (!await dictation.hasModel()) {
        final downloaded = {
          for (final model in speechModels)
            if (await dictation.withModel(model).hasModel()) model.id,
        };
        if (!mounted) return;
        final picked = await showDialog<SpeechModel>(
          context: context,
          builder: (context) => ModelDownloadDialog(
            initial: dictation.model,
            downloaded: downloaded,
          ),
        );
        if (picked == null || !mounted) return;
        dictation = dictation.withModel(picked);
        await dictation.choose(picked);
        if (!downloaded.contains(picked.id)) {
          _downloading = picked;
          _setPhase(_Phase.downloading);
          await dictation.downloadModel(
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
        }
      }
      if (!mounted) return;
      _setPhase(_Phase.starting);
      final session = await dictation.listen();
      if (!mounted) {
        unawaited(session.cancel());
        return;
      }
      _session = session;
      _anchor = DictationAnchor.at(widget.controller.value);
      _written = widget.controller.text;
      widget.controller.addListener(_onEdited);
      _transcripts = session.transcripts.listen(
        _write,
        onError: (Object e) {
          _end(cancel: true);
          _report(e);
        },
        onDone: _end,
      );
      _setPhase(_Phase.listening);
      widget.focusNode?.requestFocus();
    } catch (e) {
      _setPhase(_Phase.idle);
      _report(e);
    }
  }

  void _write(Transcript transcript) {
    final anchor = _anchor;
    if (anchor == null) return;
    final value = anchor.write(transcript.text);
    _written = value.text;
    widget.controller.value = value;
  }

  void _onEdited() {
    if (widget.controller.text != _written) _end(cancel: true);
  }

  /// Back to idle; [cancel] drops what is not transcribed yet.
  void _end({bool cancel = false, bool notify = true}) {
    widget.controller.removeListener(_onEdited);
    unawaited(_transcripts?.cancel());
    if (cancel) unawaited(_session?.cancel());
    _transcripts = null;
    _session = null;
    _anchor = null;
    _written = null;
    if (notify) _setPhase(_Phase.idle);
  }

  void _setPhase(_Phase phase) {
    if (!mounted || phase == _phase) return;
    final wasListening = _phase == _Phase.listening;
    setState(() {
      _phase = phase;
      _progress = null;
    });
    if (wasListening != (phase == _Phase.listening)) {
      widget.onListeningChanged?.call(phase == _Phase.listening);
    }
  }

  void _report(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          error is DictationException
              ? error.message
              : 'Dictation failed: $error',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).mutedText;
    final (tooltip, icon) = switch (_phase) {
      _Phase.idle => ('Dictate', const Icon(AppIcons.dictate)),
      _Phase.downloading => (
        'Downloading ${(_downloading ?? widget.dictation.model).label}'
            '${_progress == null ? '' : ' (${(_progress! * 100).round()}%)'}',
        _Spinner(value: _progress),
      ),
      _Phase.starting => ('Starting dictation', const _Spinner()),
      _Phase.listening => (
        'Stop dictation',
        Icon(AppIcons.dictating, color: Theme.of(context).colorScheme.error),
      ),
      _Phase.finishing => ('Transcribing', const _Spinner()),
    };
    return IconButton(
      tooltip: tooltip,
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      color: muted,
      isSelected: _phase == _Phase.listening,
      icon: icon,
      onPressed: _toggle,
    );
  }
}

/// Asks which of [speechModels] to download, [initial] picked first;
/// pops the picked model, or null when cancelled. Models in [downloaded]
/// (ids) are used without a download.
class ModelDownloadDialog extends StatefulWidget {
  /// Creates the dialog.
  const ModelDownloadDialog({
    super.key,
    required this.initial,
    this.downloaded = const {},
  });

  /// The model picked when it opens.
  final SpeechModel initial;

  /// The ids of the models already on disk.
  final Set<String> downloaded;

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog> {
  late var _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final onDisk = widget.downloaded.contains(_picked.id);
    return AlertDialog(
      title: const Text('Download a speech model?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dictation runs the model on this device, so your voice never '
            'leaves it. It is downloaded once; change it later under '
            '"Dictation model" in the sidebar\'s "…" menu.',
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _picked.id,
            onChanged: (id) {
              if (id != null) setState(() => _picked = speechModelById(id));
            },
            child: Column(
              children: [
                for (final model in speechModels)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: model.id,
                    title: Text(model.label),
                    subtitle: Text(
                      '${model.description} · '
                      '${widget.downloaded.contains(model.id) ? 'downloaded' : '${model.megabytes} MB'}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _picked),
          child: Text(
            onDisk
                ? 'Use ${_picked.label}'
                : 'Download (${_picked.megabytes} MB)',
          ),
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.value});

  final double? value;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 14,
    child: CircularProgressIndicator(
      value: value,
      strokeWidth: 2,
      color: AppColors.of(context).mutedText,
    ),
  );
}
