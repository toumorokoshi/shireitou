/// Relative timestamps for session rows (AV-020, AV-093).
library;

/// Formats [time] relative to [now] as the reference UI does: `just now`,
/// `5 mins ago`, `3 hrs ago`, `2 days ago`, `1 wk ago`. Times more than
/// 30 days old are shown as `YYYY-MM-DD`.
String formatRelativeTime(DateTime time, DateTime now) {
  final elapsed = now.difference(time);
  String ago(int n, String unit) => '$n $unit${n == 1 ? '' : 's'} ago';
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return ago(elapsed.inMinutes, 'min');
  if (elapsed.inDays < 1) return ago(elapsed.inHours, 'hr');
  if (elapsed.inDays < 7) return ago(elapsed.inDays, 'day');
  if (elapsed.inDays <= 30) return ago(elapsed.inDays ~/ 7, 'wk');
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
