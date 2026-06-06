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
