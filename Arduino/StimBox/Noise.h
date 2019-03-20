/**
 * @file Noise.h
 * @author Leonardo Molina (leonardomt@gmail.com).
 * @date 2019-03-17
 * @version 1.1.190320
 * 
**/

#ifndef BRIDGE_Noise_H
#define BRIDGE_Noise_H

#include <stdint.h>
#include "Stepper.h"

namespace bridge {
	class Noise : public Stepper {
		public:
			Noise();
			void Start(int8_t pin, uint16_t minFrequency, uint16_t maxFrequency, uint32_t duration);
			void Stop();
			int8_t GetPin();
			void Step() override;
		private:
			uint8_t pin;
			uint16_t minFrequency;
			uint16_t maxFrequency;
			uint32_t duration;
			uint32_t end;
			uint32_t lastClick;
			uint16_t instantPeriod;
			uint16_t instantFrequency;
			bool playing;
	};
}

#endif