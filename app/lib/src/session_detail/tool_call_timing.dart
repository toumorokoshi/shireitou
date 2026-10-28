/// Client-observed tool call timings in the timeline (AV-077): the scope
/// that hands the open chat's timings to its tool call cards, and a
/// builder that redraws every second while a call runs.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

/// Gives the tool call cards below the open chat's [timings], by
/// `toolCallId` (see `toolCallTimingsProvider`). Cards without a scope
/// show no time.
class ToolCallTimingScope extends InheritedWidget {
  /// Creates a [ToolCallTimingScope].
  const ToolCallTimingScope({
    super.key,
    required this.timings,
    required super.child,
  });

  /// The chat's timings by `toolCallId`.
  final Map<String, ToolCallTiming> timings;

  /// The timings of the nearest scope; empty without one.
  static Map<String, ToolCallTiming> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ToolCallTimingScope>()
          ?.timings ??
      const {};

  @override
  bool updateShouldNotify(ToolCallTimingScope oldWidget) =>
      !identical(timings, oldWidget.timings);
}

/// Builds with the current time, again every second while [ticking].
class ClockBuilder extends StatefulWidget {
  /// Creates a [ClockBuilder].
  const ClockBuilder({super.key, required this.ticking, required this.builder});

  /// Whether to rebuild every second.
  final bool ticking;

  /// Builds the child for the time `now`.
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<ClockBuilder> createState() => _ClockBuilderState();
}

class _ClockBuilderState extends State<ClockBuilder> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ClockBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!widget.ticking) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, clock.now());
}
