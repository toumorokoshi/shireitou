/// The chime played when it is the user's turn (AV-121), beside the
/// notification.
library;

import 'package:flutter/foundation.dart';

/// Plays the chime.
abstract interface class Chime {
  /// Plays the chime once; failures are logged, never thrown.
  Future<void> play();
}

/// The chime's sound: Kenney's "confirmation_003" (CC0, see
/// `assets/sounds/LICENSE-kenney.txt`), as WAV so that every platform
/// and browser decodes it.
const chimeAsset = 'assets/sounds/chime.wav';

/// Whether the chime can only play while the app is in the foreground
/// on [platform]: a suspended mobile app plays no audio, so there the
/// notification keeps its own sound instead.
bool chimeNeedsForeground(TargetPlatform platform) =>
    platform == TargetPlatform.android || platform == TargetPlatform.iOS;
