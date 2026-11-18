<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

A synchronous 8-bit Arithmetic Logic Unit that executes combinational logic/add/sub operations in one cycle and 8×8-bit multiplication (Shift-and-Add) or division (Restoring) over 8 clock cycles. Operands A and B are loaded sequentially through the shared 8-bit ui_in bus, while uio_in[4:2] selects the opcode and uio_in[5] multiplexes the 16-bit result (low/high byte or quotient/remainder) onto uo_out.

## How to test

Pulse rst_n low, load Operand A (ui_in + uio_in[1:0] = 01), load Operand B (ui_in + uio_in[1:0] = 10), set the desired opcode (uio_in[4:2]), and trigger execution with uio_in[1:0] = 11. Wait for busy (uio_out[7]) to go low and read both bytes of the output on uo_out by toggling uio_in[5].

## External hardware

None required for basic testing (can be driven directly via the Tiny Tapeout RP2040 microcontroller or DIP switches and LEDs on uo_out).
