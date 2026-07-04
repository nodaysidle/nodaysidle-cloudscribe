# CloudScribe

**Cloud-only macOS dictation powered by Deepgram nova-3.**

CloudScribe gives NODAYSIDLE a fast menu-bar dictation surface for live microphone capture and audio-file transcription. It is explicit about the trust boundary: audio goes to Deepgram for speech-to-text, optional polish can touch finished text only, and API keys stay in macOS Keychain.

**Release v0.1.0** *(bundle version 0.3.0)* · macOS 14+ · Swift 6 · SwiftUI

---

## Install

Download the latest release from [GitHub Releases](https://github.com/nodaysidle/nodaysidle-cloudscribe/releases).

### 1. Verify the download

```bash
# After downloading CloudScribe-v0.1.0-macos.zip, verify its checksum:
shasum -a 256 ~/Downloads/CloudScribe-v0.1.0-macos.zip
```

| Asset | SHA256 |
|-------|--------|
| `CloudScribe-v0.1.0-macos.zip` | `b4900ef216fb5a8f44d354ba31b9c9a545133fe9145bf13ec38bdacf30d07d33` |

### 2. Unzip and launch

```bash
unzip ~/Downloads/CloudScribe-v0.1.0-macos.zip -d /Applications/
open /Applications/CloudScribe.app
```

> **Note:** The app is ad-hoc signed and not notarized. macOS Gatekeeper will block it on first launch. To open it, right-click the app in Finder and select **Open**, then click **Open** in the dialog. Alternatively, run `xattr -cr /Applications/CloudScribe.app` in Terminal. This is expected for a direct-download release.

### 3. Configure

Launch CloudScribe, open **Settings**, and save a Deepgram API key. Then grant microphone access when prompted.

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

1. Launch CloudScribe from your menu bar — look for the microphone icon.
2. Open **Settings** (gear icon), save a Deepgram API key, and grant microphone access.
3. Start dictating from the floating pill, global hotkey (`⌥⇧Space`), or menu-bar popover.
4. The transcript appears live. Use **Copy** or **Paste** to send text to your frontmost app.

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

---

## Status

CloudScribe is a NODAYSIDLE macOS utility distributed as a direct-download release. The app is ad-hoc signed; notarization is not yet included.

## License

Proprietary — NODAYSIDLE.
