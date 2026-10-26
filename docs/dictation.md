# Dictation (AV-047)

The microphone button in the composer (beside the send button, in a
session's follow-up box and a new session's prompt) turns speech into
text with OpenAI's [Whisper](https://github.com/openai/whisper) model, run
on this device. The words appear in the box while you speak, as in
Cursor's and the Agents window's voice input, and the audio never leaves
the device.

![The composer with the microphone button beside send](images/desktop-dark.png)

## Using it

- Press the microphone. The first time, the app asks to download the
  model (Whisper base.en, 161 MB) into its support folder; the button
  shows the download's progress. The system asks once for microphone
  access.
- Speak. The utterance you are saying is re-transcribed several times a
  second and shown in the box; when you pause (0.6 s), it is
  transcribed once more, with punctuation, and kept.
- Text goes where the caret was, replacing a selection, with spaces
  added next to the words around it. The placeholder reads "Listening…"
  in an empty box.
- Press the button again (now a filled red microphone) to stop: what you
  were still saying is transcribed. Typing in the box, or sending it,
  also stops dictation and keeps the text as it is.

Dictation is in the desktop apps (macOS, Linux, Windows) and the mobile
apps; the web app has no button yet (see [GAPS.md](../GAPS.md)).

## How it works

Whisper only transcribes whole clips; it has no streaming mode. Live
text comes from re-transcribing the utterance in progress as it grows,
which a small model on a laptop CPU does in a fraction of a second.

```text
microphone (record, 16 kHz mono PCM)
  -> PumpedSession: queues audio while Whisper works or loads
  -> Whisper isolate (sherpa-onnx)
       Silero VAD: where speech starts and where a pause ends it
       LiveTranscriber: every 0.4 s of speech, transcribe the utterance
         so far (a guess); at a pause, transcribe it once more (final)
  -> Transcript (finished utterances + the guess)
  -> DictationAnchor.write: the box's text around the caret + transcript
```

- **sherpa-onnx** ([`sherpa_onnx`](https://pub.dev/packages/sherpa_onnx))
  runs Whisper's ONNX export and Silero VAD through FFI on every native
  platform, with prebuilt libraries in the plugin. The model is
  [`csukuangfj/sherpa-onnx-whisper-base.en`](https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base.en)
  (int8, pinned to a revision), and the VAD
  [`silero_vad.onnx`](https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models).
- **The isolate.** Decoding blocks for hundreds of milliseconds, so
  Whisper runs in an isolate of its own (`whisper_worker.dart`), which
  takes one request at a time. Audio that arrives meanwhile is sent in
  one batch next time, so the guesses keep up on a slow machine (they
  are just made less often), and nothing said while the model loads is
  lost.
- **Utterances.** The VAD ends an utterance after 0.6 s of silence, or
  after 15 s of speech (Whisper takes at most 30 s, and shorter clips
  keep each guess quick). 0.3 s of audio before the detected start is
  kept so the first syllable is not clipped.
- **Cleanup.** Whisper writes tags such as `[BLANK_AUDIO]` or
  `(wind blowing)` for sounds that are not speech; they are dropped
  (`cleanTranscript`).
- **Models.** `ModelStore` downloads each file to `<name>.part`, checks
  its size, then renames it, so a cut download is fetched again next
  time. The files are in the app support folder under
  `models/whisper-base.en/` (on macOS
  `~/Library/Application Support/dev.shireitou.shireitou/models/`); delete
  the folder to download them again.

The code is in `app/lib/src/dictation/` (see
[architecture.md](architecture.md)).

## Platforms

| Platform | Microphone                       | Setup                                                                               |
| -------- | -------------------------------- | ----------------------------------------------------------------------------------- |
| macOS    | AVFoundation                     | `com.apple.security.device.audio-input` entitlement, `NSMicrophoneUsageDescription` |
| Linux    | `parecord` (PulseAudio/PipeWire) | `pulseaudio-utils` (the `.deb` recommends it)                                       |
| Windows  | Media Foundation                 | none                                                                                |
| iOS      | AVFoundation                     | `NSMicrophoneUsageDescription`                                                      |
| Android  | `AudioRecord`                    | `RECORD_AUDIO`, asked for at first use                                              |

## Testing

- `just test` covers the pure parts and the button with fakes:
  `dictation_text_test.dart` (the transcript, writing at the caret, PCM),
  `live_transcriber_test.dart` (guesses and finals with a fake VAD),
  `dictation_session_test.dart` (queueing audio while the engine loads or
  works, stop and cancel), `model_store_test.dart` (downloads, progress,
  cut downloads) and `dictation_button_test.dart` (the button in the
  composer, the download prompt, typing to stop).
- `just test-whisper` runs the real model: it downloads Whisper base.en
  (into `SHIREITOU_SPEECH_MODELS`, or the temp folder), streams a
  recorded sentence through the worker isolate in 100 ms chunks and
  checks that guesses came before the final text. It needs macOS or
  Linux and is not run in CI (the download).
