# CloudScribe

CloudScribe is a NODAYSIDLE macOS 14+ cloud-only speech-to-text utility. It sends live microphone audio and imported audio files to Deepgram nova-3, then shows the transcript and copies it to the clipboard.

## Privacy Boundary
CloudScribe does **not** run local transcription models. No Whisper, MLX, Parakeet, CoreML speech, bundled model downloads, or on-device STT are used. The app clearly displays:

> Audio sent to cloud for transcription

## Deepgram Setup
Slice 1 uses Deepgram only.

Required model and params:
- `model=nova-3`
- `language=en`
- `smart_format=true`
- `punctuate=true`
- streaming also: `interim_results=true`

The app stores the API key in macOS Keychain under `DEEPGRAM_API_KEY`. Do not put keys in repo files.

Development/live smoke setup:
1. Get a Deepgram API key from NDI.
2. Launch CloudScribe.
3. Open Settings.
4. Paste the key into the Deepgram key field and save.
5. Run a short mic or file transcription smoke.

## Build and Test
```bash
swift test
./Scripts/package_app.sh
codesign --verify --deep --strict .build/release/CloudScribe.app
./Scripts/smoke_test.sh
```

See [USERGUIDE.md](USERGUIDE.md) for the full user guide. [GUIDE.md](GUIDE.md) covers developer install and smoke commands.

## Slice 3 Features
- Floating draggable pill UI for always-on dictation.
- Configurable global hotkey with recorder UI.
- Auto-paste on completion (on by default).

## Slice 2 Features
- Global hotkey `⌥⇧Space` toggles recording.
- Opt-in local transcript history (text only, off by default).
- Optional OpenRouter text polish after transcription (off by default).
- Recording dot on menu bar icon.

## Slice 1 Features
- Menu bar macOS utility.
- Live mic transcription through Deepgram streaming WebSocket.
- Audio file import/drop through Deepgram prerecorded `/v1/listen`.
- Transcript UI, copy-to-clipboard, and low-risk paste attempt.
- Keychain-backed API key storage.
- Dark NODAYSIDLE UI with Volt accent `#C8FF00`.

## Out of Scope
App Store, notarization, accounts, telemetry, cloud storage of audio, meeting library, local model downloads, Android, OpenRouter primary STT.
