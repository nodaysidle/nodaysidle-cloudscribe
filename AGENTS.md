# Agent Execution Contract — CloudScribe

## Read Order
- README.md
- USERGUIDE.md
- docs/GUIDE.md
- AGENTS.md

## Hard Stack Contract
- Preset id: native-macos-swiftpm
- Preset label: Native macOS Menu Bar App
- Swift 6
- SwiftUI
- Swift Package Manager (Package.swift)
- macOS 14+
- Cloud API: Deepgram nova-3 for speech-to-text
- Optional: OpenRouter for text polish (text only, never audio)
- API keys stored in macOS Keychain only

## Must Use
- Swift 6
- SwiftUI
- SwiftPM (swift build / swift test)
- macOS Keychain for API key storage
- Deepgram nova-3 for transcription
- Menu bar app architecture with floating pill
- Global hotkeys via Carbon/CGEvent or AppKit bridge

## Must Not Use
- Local Whisper/MLX/CoreML/Parakeet speech models — this is cloud-only by design
- Xcode project format (.xcodeproj) — use Package.swift
- Electron, React, Tauri, WebView shell
- Storing API keys in source files, UserDefaults, or environment variables
- Telemetry, analytics, or any network call outside Deepgram/OpenRouter transcription

## Architecture Rules
- Agent must enforce SwiftPM build system.
- Agent must keep API keys exclusively in macOS Keychain.
- Agent must preserve the privacy boundary: audio → Deepgram only during active transcription; polish receives finished text only.
- Agent must verify menu bar app lifecycle works without a dock icon when running in background mode.
- Agent must keep the floating pill window independent of the menu bar popover.

## File Rules
- Source in `Sources/CloudScribe/`.
- Tests in `Tests/CloudScribeTests/`.
- Scripts in `Scripts/` (package_app.sh, smoke_test.sh).
- End-user docs in `USERGUIDE.md`.
- Developer docs in `docs/GUIDE.md`.

## Validation Rules
- Run `swift test` before marking any task complete.
- Run `./Scripts/package_app.sh` to verify the app builds to a bundle.
- Run `codesign --verify --deep --strict .build/release/CloudScribe.app` to verify signing.
- Treat missing Keychain integration, broken hotkeys, or silent Deepgram auth failures as blockers.

## Stop Conditions
- Stop if a task introduces local speech models (Whisper, MLX, etc.) — this product is cloud-only.
- Stop if a task stores API keys outside Keychain.
- Stop if a task adds telemetry, analytics, or non-Deepgram/OpenRouter network calls.
- Stop if validation fails and the failure is not documented with a concrete fix.
