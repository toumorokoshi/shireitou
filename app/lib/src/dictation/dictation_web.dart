/// The web app has no dictation yet: Whisper would have to run in
/// WebAssembly (see GAPS.md).
library;

import 'dictation.dart';

/// None on the web.
Dictation? platformDictation() => null;
