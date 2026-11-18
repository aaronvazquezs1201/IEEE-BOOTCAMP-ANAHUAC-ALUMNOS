
## How it works

A finite-state-machine (FSM) security lock that captures four 4-bit hexadecimal digits into a 16-bit shift register and compares them against a stored master passcode. It tracks remaining attempts (up to 3), allows updating the passcode when unlocked, and outputs single-character status codes (C, O, E, L) to a 7-segment display via uio_out[6:0]

## How to test

Reset the chip (rst_n = 0) to load the default factory passcode, enter four digits sequentially on ui_in[3:0] while pulsing ui_in[4], and pulse ui_in[5] to verify. When unlocked (uo_out[0] = 1), enter four new digits and pulse ui_in[6] to save a new password, or pulse ui_in[7] to re-lock; three wrong attempts trigger alarm_lockout (uo_out[1]).

## External hardware

A 4-bit DIP switch or hex keypad (ui_in[3:0]), pushbuttons for control lines (ui_in[7:4]), a single 7-segment display on uio_out[6:0], and LEDs on uo_out[3:0] to monitor lock status and remaining attempts.
