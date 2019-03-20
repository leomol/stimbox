/**
 * @brief Send a train of pulses to the specified pin. Play noise or a tone.
 * @author Leonardo Molina (leonardomt@gmail.com).
 * @file StimBox.ino
 * @date 2019-02-25
 * @version: 0.1.190320
*/

#include "Noise.h"
#include "Oscillator.h"
using namespace bridge;

enum class Modes {
	Stop,
	Tone,
	Noise
};

Modes mode = Modes::Stop;

/// Pulse oscillator.
Noise noise = Noise();
Oscillator oscillator = Oscillator();

uint8_t speakerPin = 52;
uint32_t playDuration = 500000;
uint32_t toneFrequency = 2250;
uint32_t minFrequency = 2000;
uint32_t maxFrequency = 2500;

void setup() {
	Serial.begin(115200);
	oscillator.SetCallback(toggle);
	
	// // Demo.
	// uint8_t pin = 2;
	// bool state = 1;
	// uint32_t durationLow = 700000;
	// uint32_t durationHigh = 300000;
	// uint32_t repetitions = 999;
	// oscillator.Start(speakerPin, state, 0, durationLow, durationHigh, 2 * repetitions);
	// mode = Modes::Noise;
}

/// Arduino library loop: Update all steppers and read serial port.
void loop() {
	noise.Step();
	oscillator.Step();
	
	/// Read Serial port.
	while (Serial.available()) {
		mode = static_cast<Modes>(read1());
		switch (mode) {
			case Modes::Tone:
			{
				uint8_t buffer = read1();
				uint8_t pin = buffer & B01111111;
				bool state = (buffer & B10000000) == B10000000;
				uint32_t durationLow = read4();
				uint32_t durationHigh = read4();
				uint32_t repetitions = read4();
				speakerPin = read1();
				playDuration = read4();
				toneFrequency = read4();
				noTone(speakerPin);
				oscillator.Start(pin, state, 0, durationLow, durationHigh, 2 * repetitions);
				break;
			}
			case Modes::Noise:
			{
				uint8_t buffer = read1();
				uint8_t pin = buffer & B01111111;
				bool state = (buffer & B10000000) == B10000000;
				uint32_t durationLow = read4();
				uint32_t durationHigh = read4();
				uint32_t repetitions = read4();
				speakerPin = read1();
				playDuration = read4();
				minFrequency = read4();
				maxFrequency = read4();
				noTone(speakerPin);
				oscillator.Start(pin, state, 0, durationLow, durationHigh, 2 * repetitions);
				break;
			}
			case Modes::Stop:
			{
				noTone(speakerPin);
				oscillator.Stop();
				noise.Stop();
				break;
			}
		}
	}
}

/// Block-read 1 byte.
uint8_t read1() {
	while (Serial.available() == 0) {}
	return Serial.read();
}

/// Block-read 4 bytes.
uint32_t read4() {
	uint32_t buffer = 0;
	buffer |= (uint32_t) read1() << 24;
	buffer |= (uint32_t) read1() << 16;
	buffer |= (uint32_t) read1() <<  8;
	buffer |= (uint32_t) read1() <<  0;
	return buffer;
}

void toggle(Oscillator* oscillator, bool state) {
	if (state) {
		if (mode == Modes::Tone) {
			noTone(speakerPin);
			if (playDuration > 0 && toneFrequency > 0)
				tone(speakerPin, toneFrequency, playDuration / 1000);
		} else if (mode == Modes::Noise) {
			noise.Start(speakerPin, minFrequency, maxFrequency, playDuration);
		}
	}
	Serial.write(state);
}