/// The interface the notifications post through (AV-121), so the
/// desktop, mobile and browser implementations and the tests' recorder
/// are interchangeable.
library;

/// Posts notifications.
abstract interface class OsNotifier {
  /// Asks the user for permission if they have not decided yet, and
  /// returns whether notifications can be shown. Called at start and
  /// from the notifications menu; asking again after a refusal returns
  /// false without a prompt on most platforms.
  Future<bool> requestPermission();

  /// Shows a notification with [payload], which comes back when it is
  /// clicked; [silent] ones make no sound (the app's chime played).
  /// Dropped when permission is not granted.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool silent = false,
  });
}
