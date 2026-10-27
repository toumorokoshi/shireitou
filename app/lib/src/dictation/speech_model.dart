/// The speech models dictation downloads on first use (AV-047).
library;

/// One file of a [SpeechModel].
class ModelFile {
  /// Creates a [ModelFile].
  const ModelFile(this.name, this.url, this.bytes);

  /// The file name in the model's folder.
  final String name;

  /// Where it is downloaded from.
  final String url;

  /// Its size, which a download must match.
  final int bytes;
}

/// A Whisper model in sherpa-onnx's ONNX export, with the voice activity
/// detector that splits speech into utterances.
class SpeechModel {
  /// Creates a [SpeechModel].
  const SpeechModel({
    required this.id,
    required this.label,
    required this.encoder,
    required this.decoder,
    required this.tokens,
    required this.vad,
  });

  /// The folder name, also a stable id.
  final String id;

  /// Its name for people: "Whisper base.en".
  final String label;

  /// The Whisper encoder, decoder and token table.
  final ModelFile encoder, decoder, tokens;

  /// Silero VAD.
  final ModelFile vad;

  /// Every file to download.
  List<ModelFile> get files => [encoder, decoder, tokens, vad];

  /// The download size.
  int get bytes => files.fold(0, (sum, f) => sum + f.bytes);
}

const _whisperRepo =
    'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base.en/resolve/'
    '59eea950fc76df2453efb57e6c0fd334548e8ffe';

/// OpenAI's Whisper base.en (English, int8), about 160 MB: fast enough to
/// re-transcribe an utterance several times a second on a laptop CPU.
const whisperBaseEn = SpeechModel(
  id: 'whisper-base.en',
  label: 'Whisper base.en',
  encoder: ModelFile(
    'base.en-encoder.int8.onnx',
    '$_whisperRepo/base.en-encoder.int8.onnx',
    29120534,
  ),
  decoder: ModelFile(
    'base.en-decoder.int8.onnx',
    '$_whisperRepo/base.en-decoder.int8.onnx',
    130669978,
  ),
  tokens: ModelFile(
    'base.en-tokens.txt',
    '$_whisperRepo/base.en-tokens.txt',
    835554,
  ),
  vad: ModelFile(
    'silero_vad.onnx',
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
        'silero_vad.onnx',
    643854,
  ),
);

/// Reports download progress, from 0 to 1.
typedef DownloadProgress = void Function(double fraction);
