/**
 * @brief Send a train of pulses to the specified pin.
 * @author Leonardo Molina (leonardomt@gmail.com).
 * @file StimBox.ino
 * @date 2019-02-25
 * @version: 0.1.190225
*/

#include "Oscillator.h"
using namespace bridge;

/// Pulse oscillator.
Oscillator oscillator = Oscillator();

void setup() {
	Serial.begin(115200);
}

/// Arduino library loop: Update all steppers and read serial port.
void loop() {
	oscillator.Step();
	
	/// Read Serial port.
	while (Serial.available()) {
		uint8_t buffer = read1();
		uint8_t pin = buffer & B01111111;
		bool state = (buffer & B10000000) == B10000000;
		uint32_t durationLow = read3();
		uint32_t durationHigh = read3();
		uint32_t repetitions = read3();
		oscillator.Start(pin, state, 0, durationLow, durationHigh, 2 * repetitions);
	}
}

/// Block-read 1 byte.
uint8_t read1() {
	while (Serial.available() == 0) {}
	return Serial.read();
}

/// Block-read 3 bytes.
uint32_t read3() {
	uint32_t buffer = 0;
	buffer |= (uint32_t) read1() << 16;
	buffer |= (uint32_t) read1() <<  8;
	buffer |= (uint32_t) read1() <<  0;
	return buffer;
}