/// The AHP `SessionStatus` bitset (protocol 1.0.0, AHP-026).
///
/// The activity bits and the orthogonal `IsRead` / `IsArchived` flags are
/// combined in one integer, so checks must be bitwise, never equality.
/// `InputNeeded` (24) includes the `InProgress` bit (8).
extension type const SessionStatus(int bits) {
  /// The session is idle.
  static const idle = SessionStatus(1);

  /// The session (or its last turn) failed.
  static const error = SessionStatus(1 << 1);

  /// A turn is running.
  static const inProgress = SessionStatus(1 << 3);

  /// A turn is running and is waiting on the user (approval or input).
  static const inputNeeded = SessionStatus((1 << 3) | (1 << 4));

  /// The user has read the latest changes.
  static const isRead = SessionStatus(1 << 5);

  /// The session is archived.
  static const isArchived = SessionStatus(1 << 6);

  /// Whether every bit of [flag] is set.
  bool has(SessionStatus flag) => bits & flag.bits == flag.bits;

  /// Whether the `Idle` bit is set.
  bool get isIdle => has(idle);

  /// Whether the `Error` bit is set.
  bool get isError => has(error);

  /// Whether the `InProgress` bit is set (also true when input is needed).
  bool get isInProgress => has(inProgress);

  /// Whether both bits of `InputNeeded` are set.
  bool get isInputNeeded => has(inputNeeded);

  /// Whether the `IsRead` flag is set.
  bool get isReadFlag => has(isRead);

  /// Whether the `IsArchived` flag is set.
  bool get isArchivedFlag => has(isArchived);

  /// Returns this status with [flag] set or cleared.
  SessionStatus withFlag(SessionStatus flag, {required bool enabled}) =>
      SessionStatus(enabled ? bits | flag.bits : bits & ~flag.bits);
}
