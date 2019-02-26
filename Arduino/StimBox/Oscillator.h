#ifndef BRIDGE_Oscillator_H
#define BRIDGE_Oscillator_H

#include <stdint.h>
#include "Stepper.h"
#include "tools.h"

namespace bridge {
	class Oscillator : public Stepper {
		public:
			Oscillator() {};
			void Start(int8_t pin, uint32_t duration);
			void Start(int8_t pin, bool state, uint32_t delay, uint32_t durationLow, uint32_t durationHigh, uint32_t phases);
			void Stop();
			bool IsIdle();
			int8_t GetPin();
			void Step() override;
		private:
			enum Epochs {
				Idle,
				Setup,
				Running
			};
			Epochs epoch;
			volatile BRIDGE_IO_REG_TYPE* port;	///< Hardware address of the pin.
			BRIDGE_IO_REG_TYPE mask;			///< Mask to single out in the hardware address.
			int8_t pin;							///< Pin id in hardware.
			bool finite;						///< Whether the number of repetitions is finite.
			bool state;							///< Last known state.
			bool stateStart;					///< Make this the first state.
			uint32_t next;						///< 
			uint32_t delay;						///<
			uint32_t durationLow;				///< Duration of low phase.
			uint32_t durationHigh;				///< Duration of high phase.
			uint32_t phases;					///< Phase control.
			void Write(bool state);
			
	};
}

#endif