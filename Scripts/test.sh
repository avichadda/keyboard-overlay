#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_BINARY="$(mktemp "${TMPDIR:-/tmp}/keyviz-tests.XXXXXX")"
trap 'rm -f "$TEST_BINARY"' EXIT

cd "$ROOT"
swift build
swiftc \
    -parse-as-library \
    "Sources/Keyviz/OverlayPreferences.swift" \
    "Sources/Keyviz/KeyFormatter.swift" \
    "Tests/KeyvizTests/KeyFormatterTests.swift" \
    -o "$TEST_BINARY"
"$TEST_BINARY"
