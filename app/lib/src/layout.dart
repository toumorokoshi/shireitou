/// Responsive layout tiers (AV-003).
library;

/// The three layout tiers from `specs/agents-view.md`.
enum LayoutTier {
  /// Below 700dp: stacked navigation.
  compact,

  /// 700dp to 1200dp: list plus detail.
  medium,

  /// 1200dp and wider: list, timeline and review panes.
  wide,
}

/// The layout tier for a window [width] in logical pixels.
LayoutTier layoutTierFor(double width) => width >= 1200
    ? LayoutTier.wide
    : width >= 700
    ? LayoutTier.medium
    : LayoutTier.compact;

/// The narrowest a resizable pane (the sidebar, the review pane) gets.
const minPaneWidth = 240.0;

/// The widest a resizable pane gets.
const maxPaneWidth = 600.0;

/// The sidebar's width until the user drags its edge (AV-005).
const defaultSidebarWidth = 400.0;

/// [width] kept between [minPaneWidth] and [maxPaneWidth], and at most
/// [available] (the room left for the pane, so a narrow window keeps
/// space for the session) unless that is below [minPaneWidth].
double clampedPaneWidth(double width, {double available = double.infinity}) =>
    width.clamp(
      minPaneWidth,
      available < minPaneWidth
          ? minPaneWidth
          : available < maxPaneWidth
          ? available
          : maxPaneWidth,
    );
