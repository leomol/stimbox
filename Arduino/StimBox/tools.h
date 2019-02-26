/**
 * @file tools.h
 * @author Leonardo Molina (leonardomt@gmail.com).
 * @date 2016-12-01
 * @version 0.1.181218
 * 
 * @brief Tools for direct port manipulation.
 * Macros provided are faster analogous to pinMode, digitalRead, and digitalWrite.
**/
 
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

#ifndef BRIDGE_TOOLS_H
	#define BRIDGE_TOOLS_H
	
	#include <Arduino.h>
	
	
	#if defined(__AVR__)
		#define BRIDGE_IO_REG_TYPE	uint8_t
		/// Get hardware address containing pin.
		#define BRIDGE_BASEREG(pin)		 		 (portInputRegister(digitalPinToPort(pin)))
		/// Get mask isolating a pin from its port.
		#define BRIDGE_BITMASK(pin)		 		 (digitalPinToBitMask(pin))
		/// Change pin mode to binary input (direct port manipulation).
		#define BRIDGE_MAKE_INPUT(base, mask)	 ((*((base) +  1)) &= ~(mask), (*((base) + 2)) &= ~(mask))
		/// Change pin mode to binary output (direct port manipulation).
		#define BRIDGE_MAKE_OUTPUT(base, mask)	 ((*((base) +  1)) |=  (mask))
		/// Set pin state to low (direct port manipulation).
		#define BRIDGE_WRITE_LOW(base, mask)	 ((*((base) +  2)) &= ~(mask))
		/// Set pin state to high (direct port manipulation).
		#define BRIDGE_WRITE_HIGH(base, mask)	 ((*((base) +  2)) |=  (mask))
		/// Read pin binary state (direct port manipulation).
		#define BRIDGE_READ(base, mask)			(((*((base) +  0))  &  (mask)) ? 1 : 0)
	#elif defined(__SAM3X8E__)
		#define BRIDGE_IO_REG_TYPE	uint32_t
		#define BRIDGE_BASEREG(pin)				 (&(digitalPinToPort(pin)->PIO_PER))
		#define BRIDGE_BITMASK(pin)				 (digitalPinToBitMask(pin))
		#define BRIDGE_READ(base, mask)			(((*((base) + 15))  &  (mask)) ? 1 : 0)
		#define BRIDGE_MAKE_INPUT(base, mask)	 ((*((base) +  5))  =  (mask))
		#define BRIDGE_MAKE_OUTPUT(base, mask)	 ((*((base) +  4))  =  (mask))
		#define BRIDGE_WRITE_LOW(base, mask)	 ((*((base) + 13))  =  (mask))
		#define BRIDGE_WRITE_HIGH(base, mask)	 ((*((base) + 12))  =  (mask))
	#endif
	
#endif