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
