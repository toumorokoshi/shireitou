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

/// How sherpa-onnx runs a [SpeechModel].
enum SpeechModelKind {
  /// OpenAI Whisper: an encoder and a decoder.
  whisper,

  /// NVIDIA NeMo transducer (Parakeet): an encoder, a decoder and a
  /// joiner.
  nemoTransducer,
}

/// A speech-to-text model in sherpa-onnx's ONNX export, with the voice
/// activity detector that splits speech into utterances.
class SpeechModel {
  /// Creates a [SpeechModel].
  const SpeechModel({
    required this.id,
    required this.label,
    required this.description,
    required this.kind,
    required this.encoder,
    required this.decoder,
    this.joiner,
    required this.tokens,
    required this.vad,
  });

  /// The folder name, also a stable id.
  final String id;

  /// Its name for people: "Whisper base.en".
  final String label;

  /// How it compares with the others, for the model menu.
  final String description;

  /// How it is run.
  final SpeechModelKind kind;

  /// The encoder, decoder and token table.
  final ModelFile encoder, decoder, tokens;

  /// The transducer's joiner; null for Whisper.
  final ModelFile? joiner;

  /// Silero VAD.
  final ModelFile vad;

  /// Every file to download.
  List<ModelFile> get files => [encoder, decoder, ?joiner, tokens, vad];

  /// The download size.
  int get bytes => files.fold(0, (sum, f) => sum + f.bytes);

  /// The download size in megabytes, rounded.
  int get megabytes => (bytes / 1e6).round();
}

const _vad = ModelFile(
  'silero_vad.onnx',
  'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
      'silero_vad.onnx',
  643854,
);

const _whisperRepo =
    'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base.en/resolve/'
    '59eea950fc76df2453efb57e6c0fd334548e8ffe';

/// OpenAI's Whisper base.en (English, int8), about 160 MB: fast enough to
/// re-transcribe an utterance several times a second on a laptop CPU.
const whisperBaseEn = SpeechModel(
  id: 'whisper-base.en',
  label: 'Whisper base.en',
  description: 'Fastest, smallest download',
  kind: SpeechModelKind.whisper,
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
  vad: _vad,
);

const _parakeetRepo =
    'https://huggingface.co/csukuangfj/'
    'sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8/resolve/'
    '1ab9323565ddb038682214b292f588070a538ce2';

/// NVIDIA's Parakeet TDT 0.6B v2 (English, int8, CC-BY-4.0), about
/// 660 MB: about 40% fewer word errors than Whisper base.en on the Open
/// ASR Leaderboard, and slower on a CPU, so live guesses come less often.
const parakeetTdtV2 = SpeechModel(
  id: 'parakeet-tdt-0.6b-v2',
  label: 'Parakeet TDT 0.6B v2',
  description: 'More accurate, slower',
  kind: SpeechModelKind.nemoTransducer,
  encoder: ModelFile(
    'encoder.int8.onnx',
    '$_parakeetRepo/encoder.int8.onnx',
    652184296,
  ),
  decoder: ModelFile(
    'decoder.int8.onnx',
    '$_parakeetRepo/decoder.int8.onnx',
    7257753,
  ),
  joiner: ModelFile(
    'joiner.int8.onnx',
    '$_parakeetRepo/joiner.int8.onnx',
    1739080,
  ),
  tokens: ModelFile('tokens.txt', '$_parakeetRepo/tokens.txt', 9384),
  vad: _vad,
);

/// The models dictation can use, the default first.
const speechModels = [whisperBaseEn, parakeetTdtV2];

/// The model with [id], or the default when there is none.
SpeechModel speechModelById(String? id) =>
    speechModels.where((m) => m.id == id).firstOrNull ?? speechModels.first;

/// Reports download progress, from 0 to 1.
typedef DownloadProgress = void Function(double fraction);
