<img src=".github/social-preview.png" alt="CloudScribe — NODAYSIDLE" width="100%">

# CloudScribe

> Cloud-only macOS dictation powered by Deepgram nova-3.

CloudScribe provides a fast menu-bar dictation surface for live microphone capture and audio-file transcription. Audio goes to Deepgram for speech-to-text, optional polish can touch finished text only, and API keys stay in macOS Keychain.

**Release v0.1.0** · macOS 14+ · Swift 6 · SwiftUI

## Overview

CloudScribe is a NODAYSIDLE macOS dictation utility built for speed. It is intentionally cloud-only for speech recognition — no local Whisper, no MLX, no bundled models. The trust boundary is explicit: audio is sent to Deepgram only during active transcription, and API keys never touch the repository.

## Features

| Area | Capability |
|------|------------|
| Live dictation | Record from the menu bar or floating pill and stream interim text |
| Audio import | Transcribe WAV, MP3, M4A, OGG, FLAC, AAC, and WebM files |
| Floating pill | Draggable always-on-top dictation control with live status |
| Global hotkey | Default `⌥⇧Space`, configurable in Settings |
| Auto-paste | Copies the final transcript and can paste into the frontmost app |
| History | Optional local text-only transcript history, off by default |
| Text polish | Optional OpenRouter polish receives text only — never audio |
| Privacy label | UI states `Audio sent to cloud for transcription` |

## Privacy

CloudScribe is intentionally **cloud-only** for speech recognition.

- Audio is sent to **Deepgram nova-3** only during an active transcription request
- No Whisper, MLX, CoreML, Parakeet, bundled models, or local STT inference
- Deepgram and OpenRouter keys are stored in **macOS Keychain**, not repo files
- Optional OpenRouter polish receives finished transcript text only, never audio
- Transcript history, when enabled, is local text storage on your Mac

If you need fully local/offline transcription, this is not that product.

## Installation

Download from [GitHub Releases](https://github.com/nodaysidle/nodaysidle-cloudscribe/releases).

Verify the download:

| Asset | SHA256 |
|-------|--------|
| `CloudScribe-v0.1.0-macos.zip` | `b4900ef216fb5a8f44d354ba31b9c9a545133fe9145bf13ec38bdacf30d07d33` |

```bash
shasum -a 256 ~/Downloads/CloudScribe-v0.1.0-macos.zip
unzip ~/Downloads/CloudScribe-v0.1.0-macos.zip -d /Applications/
open /Applications/CloudScribe.app
```

The app is ad-hoc signed and not notarized. On first launch, right-click the app in Finder → **Open**, or run `xattr -cr /Applications/CloudScribe.app`.

After launching, open **Settings** and save a Deepgram API key. Grant microphone access when prompted.

## Usage

1. Launch CloudScribe from the menu bar.
2. Open **Settings**, save a Deepgram API key, and grant microphone access.
3. Start dictating from the floating pill, global hotkey (`⌥⇧Space`), or menu-bar popover.
4. The transcript appears live. Use **Copy** or **Paste** to send text to your frontmost app.

Full operator guide: [USERGUIDE.md](USERGUIDE.md)

## Configuration

CloudScribe uses Deepgram nova-3 with these settings:

| Setting | Value |
|---------|-------|
| `model` | `nova-3` |
| `language` | `en` |
| `smart_format` | `true` |
| `punctuate` | `true` |
| `interim_results` | `true` for streaming |

The API key is stored under `DEEPGRAM_API_KEY` in Keychain.

## Development

```bash
git clone https://github.com/nodaysidle/nodaysidle-cloudscribe.git
cd nodaysidle-cloudscribe
swift test
./Scripts/package_app.sh
codesign --verify --deep --strict .build/release/CloudScribe.app
./Scripts/smoke_test.sh
```

Developer guide: [docs/GUIDE.md](docs/GUIDE.md)

## Project Structure

| Path | Purpose |
|------|---------|
| `Sources/CloudScribe/` | Swift app source |
| `Tests/CloudScribeTests/` | XCTest coverage |
| `Scripts/` | Package, install, and smoke scripts |
| `USERGUIDE.md` | End-user operation guide |
| `docs/GUIDE.md` | Developer install and verification notes |

## Status

Active — macOS utility. Ad-hoc signed, notarization not yet included.

## Contributing

This repository is not currently accepting external contributions.

## License

Proprietary — NODAYSIDLE.
