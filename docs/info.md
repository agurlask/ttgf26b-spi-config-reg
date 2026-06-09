## How it works

The 8-bit SPI configuration register consists of a 
shift register and an output latch. 

The SPI interface shifts in the next value of the register when chip select (CS) is low (shifting is done MSB-first). Once CS is high, the register outputs update to the current value of the shift register (even if less/more than 8 clocks were received).

The design also includes an asynchronous clear signal which is used to reset the state of the register to a default value. 

The 8-bit parallel output of the register is accessible from the output pins.

The IP is intended to be used to write configuration bits to future analog/mixed-signal designs with limited pin access.

## How to test

By default, the register should read the value 0xAA. 

TODO: add a script to test the design.
