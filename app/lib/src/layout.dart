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
