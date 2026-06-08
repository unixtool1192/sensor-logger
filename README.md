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
| TMP-2 | 0–1023 | 10-bit probe, scale before comparing |
| TMP-3 | 0–4095 | Same as TMP-1, different connector |
