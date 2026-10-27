# Generic changes in the vendored toolkit

`neogeorecomp/` is upstream **v0.2.0**, commit
`af96b2b4b39b42b392b17bcaa6a74a5f27088202` (`toolkit.ref`), plus the generic
changes below. None contains game addresses or ROM data; each is a hardware
model or host fix that any title can use. They are released under the
toolkit's MIT license.

## MVS watchdog

`src/neogeo.c`, `src/io.c`, `src/ng_internal.h`. The board resets after
3,244,030 master clocks without a write to `$300001`, preserving work and
backup RAM. Waku Waku 7 does not depend on it, but late carts do.

## Bank-aware native dispatch

`src/exec.c`, `src/bus.c`, `include/neogeorecomp/neogeo.h`. A native routine is
tied to the bytes of one bank, so the dispatcher interprets code in the
`$200000` window when `ng_bank_base != 0`. This prevents running bank 0's
translation against bank 1's bytes.

## Fixed-layer banking selectors

`NG_FIX_BANK_GAROU` and `NG_FIX_BANK_KOF2000` cover the two larger-S-ROM
layouts. Waku Waku 7 uses the plain 128 KB `NG_FIX_BANK_NONE` path.

## M1 bank mask from the M1 file size (`src/audio.c`)

MAME's `init_audio()` builds each Z80 bank entry as
`0x10000 + ((bank << (11 + window)) & address_mask)` in the audio region, and
`ROM_RELOAD` places the first byte of the M1 file at region offset `0x10000`.
The file offset is therefore the masked value alone:

```c
off = (bank & ((size - 1) & 0x3FFFF)) + (a & window_mask);
```

The old formula added a second `0x10000` and/or used
`(size - 0x10000 - 1)`, which rotated or truncated banks that drivers use for
music data. The generic fix is present here.

## Frame-boundary Z80 sync (`src/audio.c`)

`audio_take_samples()` calls `audio_sync()` before generating samples, so the
Z80 and YM2610 timers keep running even when the 68000 stops polling the sound
latches. This prevents a pull-based audio path from starving the music driver.

## Fullscreen with 4:3 pillarboxing

`src/window_sdl.c`, `src/neogeo.c`, `src/platform.c`. `--fullscreen` creates a
desktop-fullscreen window and scales the 320x224 image into a 4:3 rectangle
centred in the output with black bars. It is never stretched to 16:10. F11
toggles the mode. This is what the Steam Deck AppRun passes by default.

## Native instruction accounting

`src/exec.c` reports native instructions and a coverage percentage beside the
interpreted count, so coverage is measured rather than estimated.
