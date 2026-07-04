# CloudScribe

**Cloud-only macOS dictation powered by Deepgram nova-3.**

CloudScribe gives NODAYSIDLE a fast menu-bar dictation surface for live microphone capture and audio-file transcription. It is explicit about the trust boundary: audio goes to Deepgram for speech-to-text, optional polish can touch finished text only, and API keys stay in macOS Keychain.

**Version 0.3.0** · macOS 14+ · Swift 6 · SwiftUI

---

## What You Get

| Area | Capability |
|------|------------|
| **Live dictation** | Record from the menu bar or floating pill and stream interim text |
| **Audio import** | Transcribe WAV, MP3, M4A, OGG, FLAC, AAC, and WebM files |
| **Floating pill** | Draggable always-on-top dictation control with live status |
| **Global hotkey** | Default `⌥⇧Space`, configurable in Settings |
| **Auto-paste** | Copies the final transcript and can paste into the frontmost app |
| **History** | Optional local text-only transcript history, off by default |
| **Text polish** | Optional OpenRouter polish receives text only — never audio |
| **Privacy label** | UI states `Audio sent to cloud for transcription` clearly |

---

## Privacy Boundary

CloudScribe is intentionally **cloud-only** for speech recognition.

- Audio is sent to **Deepgram nova-3** only during an active transcription request.
- No Whisper, MLX, CoreML speech, Parakeet, bundled model files, or local STT inference.
- Deepgram and OpenRouter keys are stored in **macOS Keychain**, not repo files.
- Optional OpenRouter polish receives the finished transcript text only, never audio.
- Transcript history, when enabled, is local text storage on your Mac.

If you need fully local/offline transcription, this is not that product.

---

## Quick Start

1. Build and package the app:

   ```bash
   swift test
   ./Scripts/package_app.sh
   ```

2. Install and launch:

   ```bash
   ./Scripts/install_app.sh
   open -n /Applications/CloudScribe.app
   ```

3. Open **Settings**, save a Deepgram API key, then request microphone access.
4. Start dictating from the floating pill, global hotkey, or menu-bar popover.

Full operator guide: [USERGUIDE.md](USERGUIDE.md)

---

## Deepgram Configuration

CloudScribe uses Deepgram nova-3 with these required settings:

| Setting | Value |
|---------|-------|
| `model` | `nova-3` |
| `language` | `en` |
| `smart_format` | `true` |
| `punctuate` | `true` |
| `interim_results` | `true` for streaming |

The app stores the key under `DEEPGRAM_API_KEY` in Keychain.

---

## Build From Source

```bash
git clone https://github.com/nodaysidle/nodaysidle-cloudscribe.git
cd nodaysidle-cloudscribe

swift test
./Scripts/package_app.sh
codesign --verify --deep --strict .build/release/CloudScribe.app
./Scripts/smoke_test.sh
```

Developer install and smoke details: [docs/GUIDE.md](docs/GUIDE.md)

---

## Repository Map

| Path | Purpose |
|------|---------|
| `Sources/CloudScribe/` | Swift app source |
| `Tests/CloudScribeTests/` | XCTest coverage |
| `Scripts/` | Package, install, and smoke scripts |
| `USERGUIDE.md` | End-user operation guide |
| `docs/GUIDE.md` | Developer install and verification notes |
| `docs/internal/` | Planning/spec/agent notes retained for maintainers |

---

## Status

CloudScribe is an internal NODAYSIDLE macOS utility. Current distribution is source/build oriented; signing and notarization depend on the active release slice.

## License

Proprietary — NODAYSIDLE.
