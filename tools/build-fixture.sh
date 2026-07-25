#!/usr/bin/env bash
# Build the sensor-logger teaching fixture for the git course.
#
#   usage: tools/build-fixture.sh [target-directory]    (default: ./sensor-logger)
#
# WARNING: the target directory is deleted and rebuilt from scratch.
set -euo pipefail

REPO="${1:-./sensor-logger}"

case "$(cd "$(dirname "$REPO")" 2>/dev/null && pwd)/$(basename "$REPO")" in
  "/"|"$HOME"|"$HOME/") echo "refusing to wipe $REPO" >&2; exit 1 ;;
esac

rm -rf "$REPO"
mkdir -p "$REPO"
cd "$REPO"

git init -q -b main
git config user.name  "A. Developer"
git config user.email "adev@example.com"
git config core.autocrlf false

D=0
commit() {  # commit <subject> [body]
  D=$((D + 1))
  local when="2026-06-0$(( (D % 9) + 1 ))T09:0${D}:00-04:00"
  if [ -n "${2:-}" ]; then
    GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" git commit -q -m "$1" -m "$2"
  else
    GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" git commit -q -m "$1"
  fi
}

# --- 1: skeleton ------------------------------------------------------------
cat > sensor.c <<'EOF'
#include <stdio.h>

int main(void)
{
    printf("sensor-logger: no probe configured\n");
    return 0;
}
EOF
git add sensor.c
commit "feat: initial sensor skeleton"

# --- 2: validation ----------------------------------------------------------
cat > sensor.h <<'EOF'
#ifndef SENSOR_H
#define SENSOR_H

/* Raw ADC counts from a 12-bit probe. */
#define MIN_VALID      0
#define MAX_VALID   4095

#define SENSOR_OK          0
#define SENSOR_ERR_RANGE (-1)

int clamp_reading(int reading);

#endif /* SENSOR_H */
EOF

cat > sensor.c <<'EOF'
#include <stdio.h>
#include "sensor.h"

/* Readings arrive as raw ADC counts. A disconnected probe reads negative,
   and electrical noise can push a reading past full scale. */
int clamp_reading(int reading)
{
    if (reading < 0) reading = 0;
    if (reading > MAX_VALID) reading = MAX_VALID;
    return reading;
}

int main(void)
{
    int samples[] = { -12, 0, 512, 4096 };
    size_t i;

    for (i = 0; i < sizeof(samples) / sizeof(samples[0]); i++)
        printf("raw=%5d clamped=%5d\n", samples[i], clamp_reading(samples[i]));

    return 0;
}
EOF

cat > Makefile <<'EOF'
CC     ?= cc
CFLAGS ?= -Wall -Wextra -std=c99

build/sensor: sensor.c sensor.h
	@mkdir -p build
	$(CC) $(CFLAGS) -o $@ sensor.c

.PHONY: test clean
test: build/sensor
	@sh tests/test_sensor.sh

clean:
	rm -rf build
EOF
git add sensor.c sensor.h Makefile
commit "feat: validate readings against the configured range"

# --- 3: tests ---------------------------------------------------------------
mkdir -p tests
cat > tests/test_sensor.sh <<'EOF'
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
EOF
git add tests/test_sensor.sh
commit "test: add range checks for the clamp helper"

# --- 4: ignore rules --------------------------------------------------------
cat > .gitignore <<'EOF'
# Build output
build/

# Runtime logs
*.log

# Local configuration — copy config.env.example and fill it in
config.env
EOF

cat > config.env.example <<'EOF'
# Copy to config.env and fill in. config.env is ignored and must never be committed.
SENSOR_PROBE_PORT=/dev/ttyUSB0
SENSOR_UPLOAD_URL=https://example.invalid/ingest
SENSOR_API_TOKEN=replace-me-this-is-not-a-real-token
EOF
git add .gitignore config.env.example
commit "chore: ignore build output and local config"

# --- 5: README --------------------------------------------------------------
cat > README.md <<'EOF'
# sensor-logger

A small C program that reads a 12-bit probe and clamps out-of-range values.

## Build

    make          # produces build/sensor
    make test     # runs tests/test_sensor.sh
    make clean

## Calibration

| Probe | Range (counts) | Notes |
|---|---|---|
| TMP-1 | 0–4095 | Default 12-bit ADC |
EOF
git add README.md
commit "docs: add README with build instructions"

# --- 6: release (this commit is the merge base for every exercise) ----------
cat > sensor.h <<'EOF'
#ifndef SENSOR_H
#define SENSOR_H

#define SENSOR_VERSION "1.2"

/* Raw ADC counts from a 12-bit probe. */
#define MIN_VALID      0
#define MAX_VALID   4095

#define SENSOR_OK          0
#define SENSOR_ERR_RANGE (-1)

int clamp_reading(int reading);

#endif /* SENSOR_H */
EOF
git add sensor.h
commit "chore: release v1.2"
GIT_COMMITTER_DATE="2026-06-07T09:07:00-04:00" git tag -a v1.2 -m "Release 1.2"

BASE=$(git rev-parse HEAD)

# --- main moves on ----------------------------------------------------------
cat >> README.md <<'EOF'
| TMP-2 | 0–1023 | 10-bit probe, scale before comparing |
| TMP-3 | 0–4095 | Same as TMP-1, different connector |
EOF
git add README.md
commit "docs: update calibration table"

sed -i 's/    if (reading < 0) reading = 0;/    if (reading < MIN_VALID) reading = MIN_VALID;/' sensor.c
git add sensor.c
commit "refactor: clamp against the configured minimum" \
       "Use the header constant instead of a bare 0 so a future probe with a
non-zero floor only needs the #define changed."

# --- fix-42: conflicts with main on purpose ---------------------------------
git switch -q -c fix-42 "$BASE"
sed -i 's/    if (reading < 0) reading = 0;/    if (reading < 0) return SENSOR_ERR_RANGE;/' sensor.c
git add sensor.c
commit "fix: clamp negative sensor readings" \
       "A disconnected probe reads negative. Silently clamping to 0 logged a
plausible-looking reading; report the range error to the caller instead."

# --- issue-17: merges cleanly ----------------------------------------------
git switch -q -c issue-17 "$BASE"
cat > logging.c <<'EOF'
#include <stdio.h>
#include <time.h>
#include "sensor.h"

/* Append one rejected reading to sensor.log (ignored by .gitignore). */
void log_rejected(int reading)
{
    FILE *f = fopen("sensor.log", "a");
    if (f == NULL) return;
    fprintf(f, "%ld rejected raw=%d\n", (long) time(NULL), reading);
    fclose(f);
}
EOF
git add logging.c
commit "feat: log rejected readings to sensor.log"

# --- tracked-config-oops: the .gitignore gotcha, pre-made -------------------
git switch -q -c tracked-config-oops "$BASE"
cat > config.env <<'EOF'
SENSOR_PROBE_PORT=/dev/ttyUSB0
SENSOR_UPLOAD_URL=https://example.invalid/ingest
SENSOR_API_TOKEN=replace-me-this-is-not-a-real-token
EOF
git add -f config.env
commit "chore: add local config" \
       "Committed by mistake: config.env is listed in .gitignore, but adding a
pattern never untracks a file that is already in the index."

git switch -q main
echo "built: $REPO"
