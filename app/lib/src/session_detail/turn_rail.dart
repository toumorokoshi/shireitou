/// The turn rail beside the timeline (AV-074): a column of dots, one per
/// user turn, that jump to the turn.
library;

import 'package:flutter/material.dart';

import 'turn_markers.dart';

/// A slim column of dots, oldest turn at the top, beside the timeline.
/// Tapping a dot, or dragging along the rail (scrubbing), calls
/// [onSelect] with the marker's index; hovering shows the message's first
/// line. The [current] turn's dot is highlighted, failed turns are red,
/// running ones hollow and cancelled ones faint. When [onLoadOlder] is
/// set (the host holds older turns back), a button above the dots pages
/// them in. [compact] makes the rail thinner still (phones), where
/// dragging along it scrubs.
class TurnRail extends StatefulWidget {
  /// Creates a [TurnRail].
  const TurnRail({
    super.key,
    required this.markers,
    required this.current,
    required this.onSelect,
    this.onLoadOlder,
    this.compact = false,
  });

  /// The turns, oldest first.
  final List<TurnMarker> markers;

  /// The index of the turn in view, or null.
  final int? current;

  /// Called with the index of the marker to jump to.
  final ValueChanged<int> onSelect;

  /// Pages older turns in and jumps to them; null when all are loaded.
  final VoidCallback? onLoadOlder;

  /// Whether to draw the thin rail of compact layouts.
  final bool compact;

  @override
  State<TurnRail> createState() => _TurnRailState();
}

class _TurnRailState extends State<TurnRail> {
  final _scroll = ScrollController();

  /// The last dot scrubbed to, so a drag selects each dot once.
  int? _scrubbed;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Selects the dot at [dy] (in the dots' coordinates, so also on a rail
  /// that scrolls).
  void _scrub(double dy, double spacing) {
    final index = turnAtOffset(dy, spacing, widget.markers.length);
    if (index == _scrubbed) return;
    _scrubbed = index;
    widget.onSelect(index);
  }

  /// Keeps the current dot in view on a rail that scrolls.
  void _follow(double spacing, double height) {
    final current = widget.current;
    if (current == null || !_scroll.hasClients) return;
    final offset = turnRailScrollOffset(
      current,
      widget.markers.length,
      spacing,
      height,
    );
    if ((offset - _scroll.offset).abs() > spacing) _scroll.jumpTo(offset);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 14.0 : 16.0;
    return SizedBox(
      width: width,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Turns',
        child: Column(
          children: [
            if (widget.onLoadOlder case final load?)
              SizedBox(
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: widget.compact ? 12 : 16,
                  tooltip: 'Load older turns',
                  onPressed: load,
                  icon: const Icon(Icons.more_horiz),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final layout = turnRailLayout(widget.markers.length, height);
                  if (layout.scrolls) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _follow(layout.spacing, height),
                    );
                  }
                  final dots = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (d) =>
                        _scrub(d.localPosition.dy, layout.spacing),
                    onVerticalDragUpdate: (d) =>
                        _scrub(d.localPosition.dy, layout.spacing),
                    onVerticalDragEnd: (_) => _scrubbed = null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (index, marker) in widget.markers.indexed)
                          _Dot(
                            marker: marker,
                            label: turnMarkerLabel(widget.markers, index),
                            current: index == widget.current,
                            extent: layout.spacing,
                            width: width,
                            onTap: () => widget.onSelect(index),
                          ),
                      ],
                    ),
                  );
                  return layout.scrolls
                      ? SingleChildScrollView(
                          controller: _scroll,
                          physics: const NeverScrollableScrollPhysics(),
                          child: dots,
                        )
                      : Center(child: dots);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One dot of the rail, [extent] high: a button labelled "Turn N: …".
class _Dot extends StatelessWidget {
  const _Dot({
    required this.marker,
    required this.label,
    required this.current,
    required this.extent,
    required this.width,
    required this.onTap,
  });

  /// The turn.
  final TurnMarker marker;

  /// The screen reader label.
  final String label;

  /// Whether this is the turn in view.
  final bool current;

  /// The dot's cell height (the spacing between dots).
  final double extent;

  /// The rail's width.
  final double width;

  /// Jumps to the turn.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (marker.state) {
      TurnMarkerState.error => scheme.error,
      _ when current => scheme.primary,
      TurnMarkerState.cancelled => scheme.outlineVariant,
      _ => scheme.outline,
    };
    final size = (current ? 8.0 : 5.0).clamp(2.0, extent);
    final hollow = marker.state == TurnMarkerState.running;
    return Semantics(
      button: true,
      selected: current,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: marker.text.isEmpty ? label : marker.text,
        excludeFromSemantics: true,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 200),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: width,
              height: extent,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hollow ? null : color,
                    border: hollow
                        ? Border.all(color: scheme.primary, width: 1.5)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
