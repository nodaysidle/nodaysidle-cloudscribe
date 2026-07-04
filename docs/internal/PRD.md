# CloudScribe PRD

## Product
CloudScribe is a NODAYSIDLE macOS 14+ utility for lightweight cloud-only speech-to-text. It records live microphone audio or imports audio files, sends audio to Deepgram nova-3, displays the transcript, copies it to the clipboard, and may paste into the focused field when macOS permissions make that low-risk.

## Slice 1 Scope
- Native SwiftPM macOS app.
- Menu bar utility UI with dark NODAYSIDLE styling and Volt accent `#C8FF00`.
- Live mic dictation through Deepgram streaming WebSocket.
- Audio file import/drop for wav, m4a, mp3, ogg, flac through Deepgram prerecorded POST.
- API key stored in macOS Keychain under `DEEPGRAM_API_KEY`.
- Visible privacy indicator: `Audio sent to cloud for transcription`.
- Transcript display, copy-to-clipboard, optional paste attempt.
- Mocked tests and installable `.app` via `Scripts/package_app.sh`.

## Non-Goals
- No local STT, Whisper, MLX, Parakeet, CoreML speech, bundled models, or on-device inference.
- No App Store, notarization, accounts, telemetry, cloud audio storage, meeting library, model downloads, Android, or OpenRouter primary transcription.
- OpenRouter polish is optional, off by default, and text-only.

## Slice 3 Scope
- Floating pill UI — always-visible draggable dictation surface.
- Configurable global hotkey with in-app recorder.
- Auto-paste on completion (on by default; copies + ⌘V to frontmost app).

## Slice 2 Scope
- Global hotkey `⌥⇧Space` toggles recording while CloudScribe is running.
- Opt-in local transcript history (text only, off by default, clears on disable).
- Optional OpenRouter text polish after transcription (off by default, text only).
- Recording indicator on menu bar icon.

## Success Criteria
- `swift test` passes.
- `Scripts/package_app.sh` produces `.build/release/CloudScribe.app`.
- The bundle verifies with `codesign --verify --deep --strict`.
- Grep proof shows no local STT dependencies.
- Live Deepgram smoke is run when NDI supplies a key; otherwise marked `UNKNOWN`.
