/**
 * @file Noise.cpp
 * @author Leonardo Molina (leonardomt@gmail.com).
 * @date 2019-03-17
 * @version 1.1.190320
 * 
**/

#include <stdint.h>
#include "Noise.h"

namespace bridge {
	Noise::Noise() :
	lastClick(0),
	instantPeriod(0),
	instantFrequency(0),
	playing(false)
	{
	}
	
	void Noise::Start(int8_t pin, uint16_t minFrequency, uint16_t maxFrequency, uint32_t duration) {
		this->pin = pin;
		this->minFrequency = minFrequency;
		this->maxFrequency = maxFrequency;
		this->duration = duration;
		this->end = micros() + duration;
		this->playing = true;
		pinMode(pin, OUTPUT);
	}
	
	// Event receiver.
	void Noise::Step() {
		uint32_t time = micros();
		bool wasPlaying = playing;
		playing = wasPlaying && duration == 0 || time <= end;
		if (playing) {
			if (time - lastClick >= instantPeriod) {
				lastClick = micros();
				instantFrequency = random(minFrequency, maxFrequency);
				instantPeriod = 1000000UL / instantFrequency;
				noTone(pin);
				tone(pin, instantFrequency, instantPeriod / 1000);
			}
		} else if (wasPlaying) {
			noTone(pin);
		}
	}
	
	int8_t Noise::GetPin() {
		return pin;
	}
	
	void Noise::Stop() {
		playing = false;
		noTone(pin);
	}
}