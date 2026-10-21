/// The `/` and `@` completion popup of the composer and the follow-up box
/// (AV-044).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'completions.dart';

/// Answers the completions for [text] at [token] (the host's `completions`
/// or the session's skills), each answer replacing the one before, such as
/// local items first and the host's when it answers.
typedef CompletionSource = Stream<List<ComposerCompletion>> Function(
  String text,
  CompletionToken token,
);

/// Shows completions above the caret while the word before it starts with
/// one of [triggers] in [controller]'s text. A new word asks [source] at
/// once; typing in it asks again after [delay], and answers for older text
/// are dropped. The text field's key
/// handler must call [CompletionPopupState.handleKey] first, so that
/// ↑/↓, Enter, Tab and Esc go to the popup while it is open.
class CompletionPopup extends StatefulWidget {
  /// Creates a [CompletionPopup] around the text field [child].
  const CompletionPopup({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.triggers,
    required this.source,
    required this.child,
    this.onAccepted,
    this.delay = const Duration(milliseconds: 150),
  });

  /// The text field's controller.
  final TextEditingController controller;

  /// The text field's focus node; the popup shows only while it has focus.
  final FocusNode focusNode;

  /// Characters that start a completion, such as `/` and `@`.
  final List<String> triggers;

  /// Answers the completions.
  final CompletionSource source;

  /// The text field.
  final Widget child;

  /// Called with each accepted item.
  final ValueChanged<ComposerCompletion>? onAccepted;

  /// How long typing must pause before [source] is asked.
  final Duration delay;

  /// The most items shown at once; the window follows the selection.
  static const maxVisible = 8;

  @override
  State<CompletionPopup> createState() => CompletionPopupState();
}

/// The state of a [CompletionPopup].
class CompletionPopupState extends State<CompletionPopup> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  Timer? _timer;
  int _generation = 0;

  /// The word being completed; null when there is none.
  CompletionToken? _token;
  String _text = '';

  /// The last answer, the text it was for, and the items shown.
  List<ComposerCompletion> _items = const [];
  String? _itemsText;
  int? _itemsStart;
  List<ComposerCompletion> _shown = const [];
  int _selected = 0;

  /// The start of a word the user closed the popup on (Esc or accept).
  int? _dismissedStart;
  int? _announced;

  /// The popup's width and where its bottom-left corner goes, measured
  /// from the laid-out field when the popup changes (not during build).
  double _width = _maxWidth;
  Offset _anchor = Offset.zero;

  static const _maxWidth = 360.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.focusNode.addListener(_update);
  }

  @override
  void didUpdateWidget(CompletionPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_update);
      widget.focusNode.addListener(_update);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onChanged);
    widget.focusNode.removeListener(_update);
    super.dispose();
  }

  /// Whether the popup is showing.
  bool get isOpen =>
      _token != null && _shown.isNotEmpty && widget.focusNode.hasFocus;

  void _onChanged() {
    final value = widget.controller.value;
    final selection = value.selection;
    final token = selection.isValid && selection.isCollapsed
        ? completionToken(value.text, selection.baseOffset, widget.triggers)
        : null;
    if (token == null || token.start != _dismissedStart) _dismissedStart = null;
    if (token == null || _dismissedStart != null) {
      _close();
      return;
    }
    if (value.text == _text && token == _token) return;
    _text = value.text;
    _token = token;
    final newWord = _itemsStart != token.start;
    if (newWord) {
      _items = const [];
      _itemsStart = token.start;
    }
    _filter();
    _timer?.cancel();
    if (newWord) {
      unawaited(_request(value.text, token));
    } else {
      _timer = Timer(
        widget.delay,
        () => unawaited(_request(value.text, token)),
      );
    }
  }

  Future<void> _request(String text, CompletionToken token) async {
    final generation = ++_generation;
    // Answers for text that has changed since are dropped.
    bool current() =>
        mounted && generation == _generation && widget.controller.text == text;
    try {
      await for (final items in widget.source(text, token)) {
        if (!current()) return;
        _items = items;
        _itemsText = text;
        _itemsStart = token.start;
        _filter();
      }
    } on Object {
      if (!current() || _itemsText == text) return;
      _items = const [];
      _itemsText = text;
      _filter();
    }
  }

  /// Shows the last answer as is when it is for the current text, else
  /// filtered by what was typed since.
  void _filter() {
    final token = _token;
    _shown = token == null
        ? const []
        : _itemsText == _text
        ? _items
        : filterCompletions(_items, token.query);
    _selected = _selected.clamp(0, math.max(0, _shown.length - 1));
    _update();
  }

  void _close() {
    if (_token == null && _shown.isEmpty) return;
    _timer?.cancel();
    _generation++;
    _token = null;
    _text = '';
    _items = const [];
    _itemsText = null;
    _itemsStart = null;
    _shown = const [];
    _selected = 0;
    _update();
  }

  void _update() {
    if (!mounted) return;
    if (isOpen) _measure();
    setState(() {});
    if (isOpen) {
      _portal.show();
      if (_announced != _shown.length) {
        _announced = _shown.length;
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            _countLabel(_shown.length),
            Directionality.of(context),
          ),
        );
      }
    } else {
      _portal.hide();
      _announced = null;
    }
  }

  static String _countLabel(int count) =>
      count == 1 ? '1 completion' : '$count completions';

  /// Handles ↑/↓, Enter, Tab and Esc while the popup is open; ignores
  /// everything else.
  KeyEventResult handleKey(KeyEvent event) {
    if (!isOpen || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _select(_selected + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _select(_selected - 1);
    } else if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.tab)) {
      accept(_selected);
    } else if (event is KeyDownEvent && key == LogicalKeyboardKey.escape) {
      _dismissedStart = _token?.start;
      _close();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _select(int index) => setState(() => _selected = index % _shown.length);

  /// Accepts the item at [index] of the shown items.
  void accept(int index) {
    final item = _shown[index];
    _dismissedStart = _token?.start;
    widget.controller.value = applyCompletion(widget.controller.value, item);
    widget.onAccepted?.call(item);
    widget.focusNode.requestFocus();
  }

  /// Sets [_width] and [_anchor]: the top of the caret at the start of
  /// the word, relative to the field, kept on the field.
  void _measure() {
    final box = _fieldKey.currentContext?.findRenderObject();
    final token = _token;
    if (box is! RenderBox || !box.hasSize || token == null) return;
    _width = math.min(_maxWidth, box.size.width);
    RenderEditable? editable;
    void visit(RenderObject child) {
      if (editable != null) return;
      if (child is RenderEditable) {
        editable = child;
      } else {
        child.visitChildren(visit);
      }
    }

    box.visitChildren(visit);
    final found = editable;
    if (found == null || !found.hasSize) return;
    final start = math.min(token.start, found.plainText.length);
    final caret = found.getLocalRectForCaret(TextPosition(offset: start));
    final at = found.localToGlobal(caret.topLeft, ancestor: box);
    _anchor = Offset(
      at.dx.clamp(0, math.max(0, box.size.width - _width)),
      math.max(0, at.dy),
    );
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: _popup,
    child: CompositedTransformTarget(
      link: _link,
      child: KeyedSubtree(key: _fieldKey, child: widget.child),
    ),
  );

  Widget _popup(BuildContext context) {
    final first = math.max(
      0,
      math.min(
        _selected - CompletionPopup.maxVisible + 1,
        _shown.length - CompletionPopup.maxVisible,
      ),
    );
    final visible = _shown
        .skip(first)
        .take(CompletionPopup.maxVisible)
        .toList();
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        offset: _anchor,
        followerAnchor: Alignment.bottomLeft,
        child: TextFieldTapRegion(
          child: SizedBox(
            width: _width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: Semantics(
                role: SemanticsRole.list,
                container: true,
                explicitChildNodes: true,
                label: _countLabel(_shown.length),
                child: Column(
                  key: const ValueKey('completions'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, item) in visible.indexed)
                      Semantics(
                        role: SemanticsRole.listItem,
                        container: true,
                        child: ListTile(
                          dense: true,
                          selected: first + i == _selected,
                          title: Text(item.label),
                          subtitle: item.description == null
                              ? null
                              : Text(
                                  item.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => accept(first + i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
