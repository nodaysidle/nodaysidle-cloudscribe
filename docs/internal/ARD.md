# CloudScribe ARD

## Architecture Decision
Build CloudScribe as a native SwiftPM macOS menu bar utility using AppKit lifecycle plus SwiftUI popover/settings views.

## Why Menu Bar
Menu bar fits a lightweight dictation tool: always available, low visual footprint, no primary document window, and simpler than a floating pill for Slice 1. Floating pill/global hotkey can be added later after the cloud STT path is proven.

## System Shape
- `AudioCaptureActor`: `AVAudioEngine` capture, 16 kHz mono PCM conversion, async sample stream.
- `DeepgramStreamingClient`: `URLSessionWebSocketTask` to Deepgram nova-3.
- `DeepgramPrerecordedClient`: `URLSession.upload` to Deepgram `/v1/listen`.
- `KeychainStore`: Security.framework generic password storage for `DEEPGRAM_API_KEY` and optional `OPENROUTER_API_KEY`.
- `AppState`: main-actor state for recording, import, transcript, errors, and clipboard actions.
- `MenuBarController`: status item and popover host.

## Enforcement
`Package.swift` must have no ML dependencies. Source must not import or depend on WhisperKit, MLX, Parakeet, CoreML speech, whisper-rs, ggml, local model files, or bundled inference. Deepgram is the only STT route.

## Tradeoffs
- Raw Foundation WebSocket avoids third-party dependencies.
- `linear16` PCM is preferred over `linear32` for Deepgram compatibility and bandwidth.
- OpenRouter polish is architecture-only/off by default in Slice 1 and never receives audio.
