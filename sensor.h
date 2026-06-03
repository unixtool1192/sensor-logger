#ifndef SENSOR_H
#define SENSOR_H

/* Raw ADC counts from a 12-bit probe. */
#define MIN_VALID      0
#define MAX_VALID   4095

#define SENSOR_OK          0
#define SENSOR_ERR_RANGE (-1)

int clamp_reading(int reading);

#endif /* SENSOR_H */
