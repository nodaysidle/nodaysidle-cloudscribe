# CloudScribe TRD

## Deepgram Streaming Contract
Endpoint: `wss://api.deepgram.com/v1/listen`

Query params:
- `model=nova-3`
- `language=en`
- `smart_format=true`
- `punctuate=true`
- `interim_results=true`
- `encoding=linear16`
- `sample_rate=16000`
- `channels=1`

Auth header: `Authorization: Token <DEEPGRAM_API_KEY>`.

Client sends little-endian 16-bit mono PCM as binary WebSocket frames. On stop, send `{"type":"Finalize"}` and then `{"type":"CloseStream"}` after final result handling.

## Deepgram File Contract
Endpoint: `POST https://api.deepgram.com/v1/listen`

Query params:
- `model=nova-3`
- `language=en`
- `smart_format=true`
- `punctuate=true`

Auth header: `Authorization: Token <DEEPGRAM_API_KEY>`. Body is original audio file data with content type inferred from extension.

## Keychain Contract
- Service: `com.nodaysidle.cloudscribe`
- Account: `DEEPGRAM_API_KEY`
- Optional text-polish account: `OPENROUTER_API_KEY`
- Secrets are never written to repo files, logs, plist, or git.

## Verification Commands
```bash
swift test
./Scripts/package_app.sh
codesign --verify --deep --strict .build/release/CloudScribe.app
git ls-files .build | wc -l
git status --short | wc -l
rg -i 'whisper|mlx|parakeet' Sources Tests Package.swift
```
