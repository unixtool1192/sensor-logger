#include <stdio.h>
#include "sensor.h"

/* Readings arrive as raw ADC counts. A disconnected probe reads negative,
   and electrical noise can push a reading past full scale. */
int clamp_reading(int reading)
{
    if (reading < MIN_VALID) reading = MIN_VALID;
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
