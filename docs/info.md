## How it works

This project implements a 4-hex-digit (16-bit) digital safe using a finite state machine (`LOCKED`, `UNLOCKED`, `LOCKOUT`), live custom PIN programming, a 4-entry circular access log, and a 4-digit multiplexed common-cathode 7-segment display driver.

- The default 4-digit hexadecimal PIN is `1234`. Each hex digit is entered on `ui_in[3:0]` and shifted into the 16-bit buffer on a rising edge of `load_btn` (`ui_in[4]`).
- Pulsing `enter_lock_btn` (`ui_in[5]`) validates the 4-digit PIN and logs `{event_type[1:0], pin[15:0]}` into a 4-entry circular buffer.
- **3 consecutive failed attempts** trigger `LOCKOUT` (displays spell `LoCd` and `alarm` on `uio_out[7]` goes high) until `rst_n` is asserted.
- When unlocked (displays spell `0PEn`), pulsing `ui_in[5]` re-locks the safe. Setting `prog_mode` (`ui_in[7] = 1`) allows loading 4 new hex digits with `ui_in[4]` and saving them as the new PIN with `ui_in[5]`.
- Setting `log_mode` (`ui_in[6] = 1`) displays the 4 logged hex digits of the entry selected by `ui_in[1:0]` (or `----` if empty), while `uio_out[5:4]` outputs the event code (`00` empty, `01` granted, `10` denied, `11` lockout).
- `uo_out[7:0]` drives the shared 7-segment bus (`dp` marks the leftmost digit), and `uio_out[3:0]` drives the one-hot digit enables (`digit_sel[3:0]`).

## How to test

1. Reset the design (`rst_n = 0`, then `rst_n = 1`). The 4 multiplexed displays cycle `0. 0 0 0` and `uio_out[5:4]` indicates `3` attempts remaining.
2. Enter `1`, `2`, `3`, `4` via `ui_in[3:0]` pulsing `ui_in[4]` for each digit, then pulse `ui_in[5]` to unlock (`0. P E n`, `uio_out[6] = 1`).
3. Optionally set `ui_in[7] = 1`, shift 4 new hex digits with `ui_in[4]`, and pulse `ui_in[5]` to update the PIN. Clear `ui_in[7]` and pulse `ui_in[5]` to lock.
4. Submit 3 incorrect 4-digit codes to verify `LOCKOUT` (`L. o C d`, `uio_out[7] = 1`).
5. Set `ui_in[6] = 1` and cycle `ui_in[1:0]` from `0` to `3` to inspect the 4 most recent logged PINs and event codes.

## External hardware

A 4-digit multiplexed common-cathode 7-segment display connected to `uo_out[7:0]` (segments) and `uio_out[3:0]` (digit enables), plus status LEDs on `uio_out[7:4]` and 4-bit switches/push buttons on `ui_in[7:0]`.
