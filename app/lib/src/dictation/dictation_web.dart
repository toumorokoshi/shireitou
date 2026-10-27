/// The web app has no dictation yet: the model would have to run in
/// WebAssembly (see GAPS.md).
library;

import 'dictation.dart';
import 'speech_model.dart';

/// None on the web.
Dictation? platformDictation(
  SpeechModel model, {
  required Future<void> Function(SpeechModel) choose,
}) => null;
