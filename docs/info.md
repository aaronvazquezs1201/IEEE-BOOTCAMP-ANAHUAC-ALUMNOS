<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

A digital clock and calendar (HH:MM and DD:MM) built from cascaded synchronous counters driven by a configurable clock prescaler (ui_in[7:6]). It continuously compares the current time against a user-programmable alarm register and drives a 4-digit multiplexed 7-segment display directly via uo_out (segments) and uio_out[3:0] (digit select).

## How to test

Reset the chip (rst_n = 0), keep ui_in[1:0] = 00 for normal clock operation, and toggle ui_in[4] to switch between time and date views. Set ui_in[1:0] to 01 (time), 10 (date), or 11 (alarm), using ui_in[3] to select fields and ui_in[2] to increment values; set ui_in[7:6] = 11 to fast-forward time during verification.

## External hardware

A 4-digit 7-segment display (connected to uo_out[7:0] and uio_out[3:0]), pushbuttons/switches for setting inputs, and an optional active buzzer or LED on uio_out[4] for the alarm output.
