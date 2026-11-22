# Embedded Systems — STM32F407 Assembly Labs

Bare-metal ARM assembly exercises for the **STM32F407G-DISC1** (Cortex-M4) board, written for the Keil `armasm` toolchain. No HAL, no CMSIS — registers are set directly.

## Button–LED control (`ButtonLEDControl_f407.s`)

| Input | Action |
|---|---|
| Short press on user button (PA0) | Toggle all four LEDs (PD12–PD15) |
| Long press (> ~600 ms) | Blink all LEDs once |

What it shows:

- Enabling GPIO clocks through `RCC_AHB1ENR`
- Setting pin modes with `MODER` / `PUPDR`
- Reading the button from `IDR`, writing LEDs with `BSRR` / `ODR`
- Software debounce and press-length measurement with delay loops

## Files

| File | Content |
|---|---|
| `ButtonLEDControl_f407.s` | Main program |
| `constants.s` | Shared register addresses and constants |
| `startup_bare_minumum.s` | Minimal vector table / reset handler |
| `LAB3/` | Lab 3 work |

## Build

1. Create a Keil µVision project for **STM32F407VGTx**.
2. Add the `.s` files, set `startup_bare_minumum.s` as startup.
3. Build and flash with the on-board ST-LINK.
