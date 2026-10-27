# Hardware notes - Waku Waku 7

Waku Waku 7 is a plain PROGBK1 MVS/AES cart. Bringing it up needed no
title-specific hardware work beyond the generic toolkit model.

## Program layout

```
$000000-$0FFFFF   fixed bank      225-p1.p1
$200000-$2FFFFF   banked window   225-p2.sp2, two 1 MB banks
$C00000-$C1FFFF   system ROM
```

The bank selector is the standard write to `$2FFFF0-$2FFFFF`. `ng_bank_base`
is the offset inside the 2 MB banked image, so selector 0 maps to
`prom + 0x100000`, the same as hardware. There is no NEO-SMA, CMC42/CMC50,
protection read or S ROM banking.

## Fixed layer

The S ROM is 128 KB, so `ng_game_t.fix_bank_type` stays at
`NG_FIX_BANK_NONE`. The fix layer draws menus, HUD, INSERT COIN and the
HOW TO PLAY text from the game's own S ROM after the BIOS hands over.

## Sound

The M1 is a plain 128 KB Z80 driver. The runtime models the four bank windows
at `$8000/$C000/$E000/$F000`, NMI/reply latches and the YM2610's FM, SSG and
ADPCM-A/B. The generic M1 mask fix (file size `(size - 1) & 0x3FFFF`, no
second `0x10000` base) is present in the vendored `audio.c`, and
`audio_take_samples()` syncs the Z80 once per frame so a 68000 that stops
polling the latches cannot starve the sequencer.

## Timing

The measured build runs at the MVS refresh rate (59.1856 Hz). The 19,000-frame
soak completes with 0 interpreted instructions after one profile pass.

## Untested hardware

* Physical MVS/AES board, memory card and link-up.
* AES BIOS variants and the Korean MVS set.
* PAL timing (the toolkit is NTSC/MVS only).
