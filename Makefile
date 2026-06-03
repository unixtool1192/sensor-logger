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
