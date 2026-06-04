#!/bin/sh
# Minimal test harness: no framework, just the binary and its output.
set -eu

BIN=build/sensor
fail=0

check() {  # check <description> <expected-substring>
    if "$BIN" | grep -q "$2"; then
        echo "  ok   $1"
    else
        echo "  FAIL $1 (expected output matching: $2)"
        fail=1
    fi
}

echo "test_sensor:"
check "negative readings are handled"   "raw=  -12"
check "full-scale readings are handled" "raw= 4096"

exit "$fail"
