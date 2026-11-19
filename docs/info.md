## How it works

This project implements a 4-bit hexadecimal digital safe using a finite state machine (`LOCKED`, `UNLOCKED`, `LOCKOUT`), an 8-entry circular access log, and two common-cathode 7-segment display drivers.

- The default 4-bit hexadecimal passcode is `A` (`4'hA`), entered via `ui_in[3:0]` and submitted with a rising edge on `enter_btn` (`ui_in[4]`).
- Up to **3 consecutive failed attempts** are allowed before entering `LOCKOUT`, which locks the safe and activates the alarm decimal point (`uio_out[7]`) until `rst_n` is asserted.
- **Display 1 (`uo_out`)**: shows the current hex digit (`0`–`F`), `U.` when unlocked, or `L` during lockout.
- **Display 2 (`uio_out`)**: shows remaining attempts (`3` down to `0`, with decimal point lit on lockout).
- Setting `log_mode` (`ui_in[6] = 1`) inspects the 8-entry access log selected by `ui_in[2:0]`: Display 1 shows the attempted hex code (or `-`) and Display 2 shows the result (`A` = accepted, `d` = denied, `E` = lockout, `-` = empty).

## How to test

1. Reset the chip (`rst_n = 0`, then `rst_n = 1`). Display 1 shows `0` and Display 2 shows `3`.
2. Set a 4-bit hex code on `ui_in[3:0]` and pulse `ui_in[4]` (`enter_btn`).
3. Entering `A` unlocks the safe (`U.` on Display 1); pulse `ui_in[5]` (`lock_btn`) to re-lock.
4. Three wrong codes trigger `LOCKOUT` (`L` on Display 1 and `0.` on Display 2).
5. Set `ui_in[6] = 1` and cycle `ui_in[2:0]` from `0` to `7` to read logged access attempts on both displays.

## External hardware

Two common-cathode 7-segment displays (onboard display on `uo_out` plus an external 7-segment display on `uio_out`), 4-bit DIP switches/keypad, and push buttons.

