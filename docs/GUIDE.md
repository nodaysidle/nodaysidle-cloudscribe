# CloudScribe Guide

CloudScribe is a NODAYSIDLE macOS 14+ menu bar speech-to-text utility. It sends microphone audio and imported files to **Deepgram nova-3** in the cloud. No local Whisper, MLX, or on-device STT models are used.

## Installed app path

After packaging:

```text
.build/release/CloudScribe.app
```

Install to Applications (optional):

```bash
./Scripts/install_app.sh
open -n /Applications/CloudScribe.app
```

## First run

1. Launch CloudScribe from the menu bar mic icon.
2. Open **Settings** (gear icon).
3. Paste your Deepgram API key and press **Save**.
4. The key is stored in macOS Keychain as `DEEPGRAM_API_KEY`.

## Slice 3 features

### Floating pill

A compact pill stays on screen above other apps. Drag it anywhere (position is remembered). Tap the mic to record; live transcript preview appears in the pill.

Toggle in Settings → **Floating pill**.

### Configurable hotkey

Settings → **Global hotkey** → **Change**, then press your desired combo (must include ⌘, ⌥, ⌃, or ⇧). Default remains **⌥⇧Space**.

### Auto-paste

When enabled (default on), CloudScribe copies the finished transcript and sends paste to the frontmost app. Disable in Settings if you prefer manual copy/paste.

**Note:** Simulated paste is best-effort. Some apps may require Accessibility permission for CloudScribe under System Settings → Privacy & Security → Accessibility.

## Slice 2 features

### Global hotkey

While CloudScribe is running, press **⌥⇧Space** (Option+Shift+Space) to start or stop recording from any app. Toggle in Settings → Global hotkey.

### Transcript history

Enable **Local transcript history** in Settings to keep the last 20 transcript texts on this Mac. History is text-only — no audio is stored. Disabling history clears saved entries.

### Optional text polish

Enable **OpenRouter text polish** and save an OpenRouter API key to run grammar cleanup on finished transcripts. Polish is text-only and off by default. Deepgram remains the only STT route.

## Basic usage

### Live microphone

1. Click the menu bar icon to open the popover.
2. Confirm the strip reads: **Audio sent to cloud for transcription**.
3. Tap the mic button to record.
4. Speak clearly.
5. Tap stop when finished.
6. Copy or paste the transcript with the action buttons.

### Audio file import

- Tap the document import button, or
- Drag and drop a supported audio file onto the transcript area.

Supported formats: WAV, MP3, M4A, OGG, FLAC, AAC, WebM.

## Privacy boundary

CloudScribe does **not** run local transcription models. Audio leaves the machine only for Deepgram processing during the active request. The UI always shows the cloud indicator strip.

## Build, test, and smoke

```bash
swift test
./Scripts/package_app.sh
codesign --verify --deep --strict .build/release/CloudScribe.app
./Scripts/smoke_test.sh
```

`smoke_test.sh` runs unit tests, packages the app, verifies codesign, checks cloud-only source grep, and optionally runs a live Deepgram file smoke when `DEEPGRAM_API_KEY` is set in the environment.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Please set your Deepgram API key` | Open Settings and save a valid key |
| Mic does not start | Grant microphone permission in System Settings → Privacy & Security → Microphone |
| Empty transcript | Check network, API key balance, and speak for at least 1–2 seconds |
| Paste does not land | Use Copy, then paste manually; simulated Cmd+V is best-effort |

## Out of scope (Slice 1)

Notarization, App Store distribution, accounts, telemetry, cloud audio storage, meeting library, local model downloads, Android, and OpenRouter-primary STT.