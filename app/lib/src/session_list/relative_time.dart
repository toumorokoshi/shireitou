/// Relative timestamps for session rows (AV-020).
library;

/// Formats [time] relative to [now], e.g. `just now`, `5m`, `3h`, `2d`.
/// Times more than 30 days old are shown as `YYYY-MM-DD`.
String formatRelativeTime(DateTime time, DateTime now) {
  final elapsed = now.difference(time);
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}m';
  if (elapsed.inDays < 1) return '${elapsed.inHours}h';
  if (elapsed.inDays <= 30) return '${elapsed.inDays}d';
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
