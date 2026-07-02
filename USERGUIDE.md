# CloudScribe User Guide

CloudScribe is a NODAYSIDLE macOS menu bar dictation utility. It turns your voice — or an audio file — into text using **Deepgram nova-3** in the cloud. There are no local Whisper, MLX, or on-device speech models. Your Mac captures audio; Deepgram returns the transcript.

**Version:** 0.3.0
**Requires:** macOS 14 or later

---

## Quick start (about 60 seconds)

1. Open CloudScribe:
   ```bash
   open -n /Applications/CloudScribe.app
   ```
   Or launch from the **menu bar mic icon** if already running.

2. Open **Settings** (gear icon in the menu bar popover).

3. Paste your **Deepgram API key** and press **Save**. The key is stored in macOS Keychain — never in project files or git.

4. In Settings, open the **Microphone** section and tap **Request Access**. macOS only lists CloudScribe under System Settings → Privacy & Security → Microphone **after** this first request — you cannot add it manually with the **+** button.

5. Grant **Microphone** access when macOS prompts you (CloudScribe briefly comes to the front so the dialog is visible).

6. Dictate using any of the three surfaces below. When transcription finishes, the text is copied automatically and pasted into the frontmost app (if auto-paste is on).

You should always see this privacy line in the UI:

> **Audio sent to cloud for transcription**

---

## Three ways to dictate

### 1. Floating pill (recommended)

The pill is a small capsule that stays above your other windows. Drag it anywhere — CloudScribe remembers the position.

| Action | How |
|--------|-----|
| Start / stop recording | Tap the **mic** button on the pill |
| See live progress | Watch the preview line (interim text while you speak) |
| Hide the pill | Settings → turn off **Floating pill** |

The pill shows recording state with a red border and stop icon while active.

### 2. Global hotkey

Press your hotkey from **any app** while CloudScribe is running:

| State | Hotkey action |
|-------|----------------|
| Idle / done | Starts recording |
| Recording | Stops recording |

**Default hotkey:** `⌥⇧Space` (Option + Shift + Space)

**Change it:** Settings → **Global hotkey** → **Change** → press your new combo. You must include at least one modifier: `⌘`, `⌥`, `⌃`, or `⇧`.

### 3. Menu bar popover

Click the **menu bar mic icon** for the full panel:

- Record / stop, import file, copy, paste
- Transcript history (when enabled)
- Settings and Quit

---

## After transcription

When a session completes, CloudScribe:

1. Runs optional **text polish** (if you enabled OpenRouter — see Settings)
2. Shows the final transcript in the pill and popover
3. Saves to **history** (if enabled)
4. **Auto-pastes** (if enabled): copies to clipboard, then sends `⌘V` to the frontmost app

You can always use the **Copy** and **Paste** buttons in the menu bar popover instead.

---

## Importing audio files

Transcribe a recording without using the mic:

- Tap the **document import** button in the popover, or
- **Drag and drop** a file onto the transcript area

**Supported formats:** WAV, MP3, M4A, OGG, FLAC, AAC, WebM

File transcription uses Deepgram’s prerecorded API — same nova-3 model, same cloud boundary.

---

## Settings reference

Open Settings from the gear icon in the menu bar popover (or via the system Settings window).

### API keys

| Key | Purpose | Required |
|-----|---------|----------|
| **Deepgram API key** | Speech-to-text (live + files) | Yes |
| **OpenRouter API key** | Optional grammar polish on finished text | No |

Both keys live in **Keychain only**.

### Workflow

| Setting | Default | What it does |
|---------|---------|--------------|
| **Floating pill** | On | Always-visible dictation surface |
| **Auto-paste on completion** | On | Copy + paste when transcription finishes |
| **Global hotkey** | On | Keyboard toggle for record/stop |
| **Hotkey binding** | `⌥⇧Space` | Customizable via **Change** |
| **Local transcript history** | Off | Saves last 20 transcript texts on this Mac |
| **OpenRouter text polish** | Off | Text-only cleanup after Deepgram; never receives audio |

**History note:** Enabling history stores text only — no audio files. Turning history **off** clears all saved transcripts.

---

## Permissions

CloudScribe may need macOS permissions depending on how you use it:

| Permission | Why | Where to enable |
|------------|-----|-----------------|
| **Microphone** | Live dictation | System Settings → Privacy & Security → Microphone |
| **Accessibility** | Simulated paste (`⌘V`) into other apps | System Settings → Privacy & Security → Accessibility |

If auto-paste does not land in your target app, enable Accessibility for CloudScribe, or use **Copy** and paste manually.

---

## Privacy boundary

CloudScribe is **cloud-only** for speech recognition:

- No local STT models, no MLX, no Whisper, no bundled inference
- Audio is sent to Deepgram **only during an active transcription request**
- Optional OpenRouter polish receives **finished text only** — never audio
- Transcript history (if enabled) stays **on your Mac** as plain text

The UI always shows that audio goes to the cloud. That is intentional and non-negotiable for this app.

---

## Tips for best results

- **Speak in short bursts** for live dictation — pause clearly when you finish a thought.
- **Check your Deepgram balance** if transcripts come back empty.
- **Use a quiet room**; CloudScribe does not run local noise models.
- **Place the pill** where it does not cover your cursor or text field.
- **Test auto-paste** in Notes or TextEdit first before relying on it in complex apps (IDEs, browsers, etc.).
- **Disable auto-paste** when you only want the transcript in CloudScribe, not injected elsewhere.

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| “Please set your Deepgram API key” | Settings → paste key → Save |
| CloudScribe missing from Microphone list | Quit CloudScribe, relaunch from `/Applications/CloudScribe.app`, then Settings → **Microphone** → **Request Access** → **Continue** → **Allow** in the macOS dialog. macOS cannot add apps manually with **+**. |
| Mic will not start / “operation couldn’t be completed” | Settings → **Request Access**, or System Settings → Privacy & Security → **Microphone** → enable CloudScribe, then quit and relaunch (`pkill CloudScribe; open -n /Applications/CloudScribe.app`) |
| Empty or partial transcript | Speak longer (1–2 s minimum); check network and API credits |
| Hotkey does nothing | Confirm **Global hotkey** is on; CloudScribe must be running |
| Paste does not appear | Enable Accessibility; or Copy manually from the popover |
| Pill missing | Settings → enable **Floating pill**; relaunch if needed |
| Polish has no effect | Enable polish **and** save an OpenRouter key |
| History empty | Enable **Local transcript history** first — it is off by default |

---

## Install and update

**Installed app (recommended for daily use):**

```text
/Applications/CloudScribe.app
```

**Build from source:**

```bash
cd /Volumes/omarchyuser/projekti/nodaysidle-cloudscribe
./Scripts/package_app.sh
./Scripts/install_app.sh
open -n /Applications/CloudScribe.app
```

**Verify a build:**

```bash
./Scripts/smoke_test.sh
```

---

## What is not in this release

The current build is meant for **local testing** before notarization:

- No App Store distribution
- No notarization yet (planned after a few days of real-world use)
- No accounts, telemetry, or cloud storage of your audio
- No meeting library or long-term cloud archive
- No Android or Windows client

---

## Support checklist

Before reporting an issue, confirm:

- [ ] Deepgram API key saved and valid
- [ ] Microphone permission granted
- [ ] `./Scripts/smoke_test.sh` passes on your machine
- [ ] You tested in a simple target app (Notes) with auto-paste on
- [ ] CloudScribe version is **0.3.0** or newer (Settings → About, or check `Info.plist` in the app bundle)

---

*NODAYSIDLE · CloudScribe · cloud Deepgram nova-3 SST*