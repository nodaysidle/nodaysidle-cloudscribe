# CloudScribe Agent Contract

## Scope
This repo is `/Volumes/omarchyuser/projekti/nodaysidle-cloudscribe`. Write only inside this repo unless NDI explicitly approves otherwise.

## Product Boundary
CloudScribe is cloud-only STT for macOS. Deepgram nova-3 is the primary and only Slice 1 transcription provider.

## Hard Constraints
- No local STT/ML: no Whisper, MLX, Parakeet, CoreML speech, on-device inference, bundled model files, whisper-rs, ggml, or model downloads.
- Do not route primary transcription or audio through OpenRouter.
- Store `DEEPGRAM_API_KEY` in Keychain only.
- Never commit secrets, `.env`, generated `.app`, `.build`, `.swiftpm`, `dist`, or `Secrets/`.
- Never use `git add .` or `git add -A`.
- Use explicit paths for staging.

## Deepgram Required Params
Streaming and file transcription must use:
- `model=nova-3`
- `language=en`
- `smart_format=true`
- `punctuate=true`
- streaming: `interim_results=true`

Do not use `flux-general-en`, `nova-2`, or OpenRouter as primary STT.

## Visual System
Dark NODAYSIDLE utility UI. Volt accent `#C8FF00`. Clear label: `Audio sent to cloud for transcription`.

## Gates
Before done:
- `swift test`
- `Scripts/package_app.sh`
- `codesign --verify --deep --strict .build/release/CloudScribe.app`
- `git ls-files .build | wc -l` is `0`
- `git status --short | wc -l` is `< 60`
- grep proof for no local STT dependencies
