#!/bin/bash
# smoke_test.sh — Slice 1 release gates for CloudScribe
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== CloudScribe smoke_test ==="

echo "--- swift test ---"
swift test

echo "--- package_app ---"
./Scripts/package_app.sh

APP=".build/release/CloudScribe.app"
echo "--- codesign verify ---"
codesign --verify --deep --strict "$APP"

echo "--- git hygiene ---"
BUILD_TRACKED="$(git ls-files .build | wc -l | tr -d ' ')"
echo ".build tracked count: $BUILD_TRACKED"
if [ "$BUILD_TRACKED" != "0" ]; then
    echo "ERROR: .build artifacts are tracked"
    exit 1
fi

echo "--- cloud-only grep ---"
if rg -i 'whisper|mlx|parakeet|faster-whisper|onnx' Sources Tests Package.swift >/dev/null 2>&1; then
    echo "ERROR: local STT references found"
    exit 1
fi
echo "LOCAL_STT_GREP_MATCHES_FOUND=NO"

if [ -z "${DEEPGRAM_API_KEY:-}" ] && [ -f "$HOME/.hermes/profiles/eldio/.env" ]; then
    DEEPGRAM_API_KEY="$(rg '^DEEPGRAM_API_KEY=' "$HOME/.hermes/profiles/eldio/.env" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
    export DEEPGRAM_API_KEY
fi

if [ -n "${DEEPGRAM_API_KEY:-}" ]; then
    echo "--- live Deepgram file smoke ---"
    SMOKE_DIR=".build/smoke"
    mkdir -p "$SMOKE_DIR"
    SMOKE_WAV="$SMOKE_DIR/cloudscribe-smoke.wav"
    if [ ! -f "$SMOKE_WAV" ]; then
        say -o "$SMOKE_DIR/cloudscribe-smoke.aiff" "Cloud scrub smooth test"
        afconvert -f WAVE -d LEI16@16000 "$SMOKE_DIR/cloudscribe-smoke.aiff" "$SMOKE_WAV"
    fi
    RESPONSE="$(curl -sS -X POST "https://api.deepgram.com/v1/listen?model=nova-3&language=en&smart_format=true&punctuate=true" \
        -H "Authorization: Token ${DEEPGRAM_API_KEY}" \
        -H "Content-Type: audio/wav" \
        --data-binary @"$SMOKE_WAV")"
    echo "$RESPONSE" | rg -q 'transcript' || { echo "ERROR: Deepgram smoke missing transcript"; echo "$RESPONSE"; exit 1; }
    SNIPPET="$(printf '%s' "$RESPONSE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["results"]["channels"][0]["alternatives"][0]["transcript"])')"
    echo "LIVE_DEEPGRAM_FILE_SMOKE=PASS"
    echo "Transcript snippet: $SNIPPET"
else
    echo "LIVE_DEEPGRAM_FILE_SMOKE=SKIPPED (no DEEPGRAM_API_KEY)"
fi

echo ""
echo "=== smoke_test PASS ==="