/// The slim bar at the top of the sessions screen on medium and wide
/// layouts (AV-091): the sidebar toggle, back and forward, a centred box
/// naming the open session's workspace (it focuses search), and icon
/// actions on the right. On macOS it is drawn in the window's title bar.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../prefs.dart';
import '../session_list/folder_grouping.dart';
import '../theme/app_theme.dart';

/// The bar's height. On macOS it matches the window's compact toolbar
/// (`macos/Runner/MainFlutterWindow.swift`), so the traffic lights sit
/// centred in it.
const titleBarHeight = 38.0;

/// The app's name, in the centre box when no session is open.
const appName = 'shireitou';

/// The width the macOS traffic lights take at the bar's left.
const trafficLightsWidth = 76.0;

/// Whether the sidebar is collapsed on medium and wide layouts, kept on
/// this device under its own key: `sidebar_collapsed` holds the collapsed
/// sections (`collapsedNodesProvider`), and sharing it erased one with
/// the other.
final sidebarCollapsedProvider = NotifierProvider<StoredFlag, bool>(
  () => StoredFlag('sidebar_hidden'),
);

/// The workspace of [summary] as "folder [repo]" (only "folder" when the
/// host names no project), or null when it has no working directory.
String? workspaceTitle(SessionSummary? summary) {
  final key = summary == null ? null : folderKeyOf(summary);
  return key == null
      ? null
      : workspaceLabel(folderLabelOf(key), projectNameOf(summary!));
}

/// The title bar. Callbacks that are null hide or disable their button.
class TitleBar extends StatelessWidget {
  /// Creates the bar.
  const TitleBar({
    super.key,
    required this.title,
    required this.isWorkspace,
    required this.searchTooltip,
    required this.onSearch,
    this.sidebarCollapsed = false,
    this.onToggleSidebar,
    this.onBack,
    this.onForward,
    this.actions = const [],
    this.leadingInset = 0,
    this.draggable = false,
  });

  /// The text in the centre box: the open session's workspace, or the
  /// app's name.
  final String title;

  /// Whether [title] is a workspace (it gets a folder icon).
  final bool isWorkspace;

  /// The centre box's tooltip, naming the search shortcut.
  final String searchTooltip;

  /// Focuses the session search; called by a click on the centre box.
  final VoidCallback onSearch;

  /// Whether the sidebar is collapsed, for the toggle's icon and tooltip.
  final bool sidebarCollapsed;

  /// Collapses or expands the sidebar; null hides the toggle.
  final VoidCallback? onToggleSidebar;

  /// Opens the previous session in the history; null disables Back.
  final VoidCallback? onBack;

  /// Opens the next session in the history; null disables Forward.
  final VoidCallback? onForward;

  /// Icon actions at the right.
  final List<Widget> actions;

  /// Space left free at the left, for the macOS traffic lights.
  final double leadingInset;

  /// Whether dragging the bar moves the window and a double-click zooms
  /// it (macOS, where the bar replaces the native title bar).
  final bool draggable;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bar = Row(
      children: [
        SizedBox(width: leadingInset + 4),
        if (onToggleSidebar case final toggle?)
          IconButton(
            tooltip: sidebarCollapsed ? 'Show sidebar' : 'Hide sidebar',
            icon: const Icon(Icons.view_sidebar_outlined),
            onPressed: toggle,
          ),
        IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        IconButton(
          tooltip: 'Forward',
          icon: const Icon(Icons.arrow_forward),
          onPressed: onForward,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _CentreBox(
                title: title,
                isWorkspace: isWorkspace,
                tooltip: searchTooltip,
                onTap: onSearch,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ...actions,
        const SizedBox(width: 4),
      ],
    );
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          iconSize: 18,
          minimumSize: const Size(30, 30),
          padding: const EdgeInsets.all(6),
          visualDensity: VisualDensity.compact,
          foregroundColor: colors.mutedText,
        ),
      ),
      child: Container(
        height: titleBarHeight,
        decoration: BoxDecoration(
          color: colors.titleBarBackground,
          border: Border(bottom: BorderSide(color: colors.hairline)),
        ),
        child: draggable
            ? Stack(
                children: [
                  // Under the row, so its buttons get clicks without
                  // waiting for the double-click to time out.
                  const Positioned.fill(
                    child: DragToMoveArea(child: SizedBox.expand()),
                  ),
                  bar,
                ],
              )
            : bar,
      ),
    );
  }
}

/// The centre box: the workspace (or app name) in a bordered box; a click
/// focuses search.
class _CentreBox extends StatelessWidget {
  const _CentreBox({
    required this.title,
    required this.isWorkspace,
    required this.tooltip,
    required this.onTap,
  });

  final String title;
  final bool isWorkspace;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(appRadius);
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.mutedText);
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('title-bar-search'),
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: colors.hairline),
            ),
            child: Row(
              children: [
                Icon(
                  isWorkspace ? Icons.folder_outlined : Icons.search,
                  size: 14,
                  color: colors.mutedText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
