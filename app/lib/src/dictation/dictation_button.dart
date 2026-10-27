/// The composer's microphone button (AV-047): dictates into the box,
/// writing the words as they are spoken.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'dictation.dart';
import 'dictation_text.dart';

enum _Phase { idle, downloading, starting, listening, finishing }

/// Starts and stops dictation into [controller]. The first press offers
/// to download the model. Speech is written at the caret (replacing a
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
    final dictation = widget.dictation;
    try {
      if (!await dictation.hasModel()) {
        if (!mounted || !await _confirmDownload()) return;
        _setPhase(_Phase.downloading);
        await dictation.downloadModel(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
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

  Future<bool> _confirmDownload() async {
    final model = widget.dictation.model;
    final megabytes = (model.bytes / 1e6).round();
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download the speech model?'),
            content: Text(
              'Dictation runs ${model.label} on this device, so your '
              'voice never leaves it. The model is $megabytes MB and is '
              'downloaded once.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Download ($megabytes MB)'),
              ),
            ],
          ),
        ) ??
        false;
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
        'Downloading ${widget.dictation.model.label}'
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
