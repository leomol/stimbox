#include <Arduino.h>
#include "tools.h"
#include "Oscillator.h"

namespace bridge {
	void Oscillator::Start(int8_t pin, bool state, uint32_t delay, uint32_t durationLow, uint32_t durationHigh, uint32_t phases) {
		/*
			Set a square wave. Start with !state for a given delay, then toggle between state and !state for a given number of repetitions, using durationLow and durationHigh for low and high states, respectively. When delay equals zero, pin is never set to !state.
			Infinite repetitions is accomplished by setting phases to zero.
			The final state is forced when the oscillator is stopped.
		*/
		this->pin = pin;
		this->stateStart = state;
		this->state = state,
		this->delay = delay;
		this->durationLow = durationLow;
		this->durationHigh = durationHigh;
		this->phases = phases;
		this->finite = phases > 0;
		this->epoch = Epochs::Setup;
		this->port = BRIDGE_BASEREG(pin);
		this->mask = BRIDGE_BITMASK(pin);
		pinMode(pin, OUTPUT);
	}
	
	void Oscillator::Start(int8_t pin, uint32_t duration) {
		Start(pin, HIGH, 0, duration, duration, 2);
	}

	// Event receiver.
	void Oscillator::Step() {
		// Check phase of the square wave.
		uint32_t tic = micros();
		if (epoch == Epochs::Setup) {
			// Delay occurs at oposite state.
			state = !stateStart;
			epoch = Epochs::Running;
			if (delay == 0) {
				next = 0;
			} else {
				Write(state);
				next = tic + delay;
			}
		}
		if (epoch == Epochs::Running) {
			if (tic >= next) {
				if (finite)
					phases -= 1;
				if (phases == 0)
					epoch = Epochs::Idle;				
				state = !state;
				Write(state);
				next = tic + (state ? durationHigh : durationLow);
			}
		}
	}
	
	int8_t Oscillator::GetPin() {
		return pin;
	}
	
	bool Oscillator::IsIdle() {
		return epoch == Epochs::Idle;
	}
	
	void Oscillator::Write(bool state) {
		if (state)
			BRIDGE_WRITE_HIGH(port, mask);
		else
			BRIDGE_WRITE_LOW(port, mask);
	}
	
	void Oscillator::Stop() {
		bool finalState = (phases % 2 == 0) ? !stateStart : stateStart;
		if (state != finalState)
			Write(finalState);
		epoch = Epochs::Idle;
	}
}