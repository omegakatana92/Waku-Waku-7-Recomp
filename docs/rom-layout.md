# ROM layout - MAME set `wakuwak7` (NGH-225)

Validated against MAME's `src/mame/snk/neogeo.cpp`, `ROM_START( wakuwak7 )`.
All 12 game files and the 4 required system-ROM files were checked by size,
CRC32 and SHA1 with `python scripts/validate-roms.py roms`; every one matched.

## Game set

| File | Size | CRC32 | MAME load | Role |
|---|---:|---|---|---|
| `225-p1.p1` | 1,048,576 | `b14da766` | `ROM_LOAD16_WORD_SWAP` @ 0x000000 | 68000 fixed bank |
| `225-p2.sp2` | 2,097,152 | `fe190665` | `ROM_LOAD16_WORD_SWAP` @ 0x100000 | banked program |
| `225-s1.s1` | 131,072 | `71c4b4b5` | `NEO_SFIX_128K` | fixed layer |
| `225-m1.m1` | 131,072 | `0634bba6` | `NEO_BIOS_AUDIO_128K` | Z80 sound driver |
| `225-v1.v1` | 4,194,304 | `6195c6b4` | `ROM_LOAD` @ 0x000000 | ADPCM-A |
| `225-v2.v2` | 4,194,304 | `6159c5fe` | `ROM_LOAD` @ 0x400000 | ADPCM-A |
| `225-c1.c1` | 4,194,304 | `ee4fea54` | `ROM_LOAD16_BYTE` @ 0x0000000 | sprite planes 0,1 |
| `225-c2.c2` | 4,194,304 | `0c549e2d` | `ROM_LOAD16_BYTE` @ 0x0000001 | sprite planes 2,3 |
| `225-c3.c3` | 4,194,304 | `af0897c0` | `ROM_LOAD16_BYTE` @ 0x0800000 | sprite planes 0,1 |
| `225-c4.c4` | 4,194,304 | `4c66527a` | `ROM_LOAD16_BYTE` @ 0x0800001 | sprite planes 2,3 |
| `225-c5.c5` | 4,194,304 | `8ecea2b5` | `ROM_LOAD16_BYTE` @ 0x1000000 | sprite planes 0,1 |
| `225-c6.c6` | 4,194,304 | `0eb11a6d` | `ROM_LOAD16_BYTE` @ 0x1000001 | sprite planes 2,3 |

Totals: 3 MB program (1 MB fixed + 2 MB banked), 24 MB sprite data,
8 MB ADPCM-A, 128 KB fixed layer, 128 KB Z80 program.

## System set (`neogeo.zip`)

| File | Size | CRC32 | Role |
|---|---:|---|---|
| `sp-s2.sp1` | 131,072 | `9036d879` | MVS Asia/Europe v2 BIOS (default `--bios`) |
| `sfix.sfix` | 131,072 | `c2ea0cfd` | BIOS fixed-layer graphics |
| `sm1.sm1` | 131,072 | `94416d67` | BIOS Z80 sound driver |
| `000-lo.lo` | 131,072 | `5a86cff2` | sprite shrink table |

The supplied `wakuwak7.zip` also contains a copy of the `neogeo` sets; the
project only uses the four files above.

## How the dump maps into `ng_game_t`

* **P ROM.** Both files are stored 16-bit word-swapped, so `swap = 1`. After
  the swap the fixed bank carries `NEO-GEO` at `$100`; the cartridge header
  entry points at `$122`, `$128`, `$12E` and `$134` are what the BIOS calls.
  `prom_size = 0x300000`: the first 1 MB is the fixed bank at
  `$000000-$0FFFFF`, the remaining 2 MB are two 1 MB banks behind the
  `$200000` window, selected through `$2FFFF0-$2FFFFF`.
* **C ROMs.** MAME loads them as three `ROM_LOAD16_BYTE` pairs, 8 MB per pair
  at `0x0000000`, `0x0800000` and `0x1000000`. The runtime's `crom_pairs`
  interleaves each pair byte-for-byte into the same 24 MB layout, which the
  per-scanline sprite renderer indexes directly.
* **V ROMs.** Concatenated in MAME order into one 8 MB ADPCM-A space.
* **S ROM / M1.** Single 128 KB files, copied as-is.

## Hardware profile

| Item | Result |
|---|---|
| Board | standard MVS/AES PROGBK1 cart |
| Encryption | none |
| Protection / daughterboard | none (no NEO-SMA, CMC42/CMC50) |
| Banking | two 1 MB banks at `$200000`; selector byte at `$2FFFFF` |
| Raster / IRQ | standard LSPC, IRQ1 (VBlank) and IRQ2 (timer) |
| Sound | standard M1 driver + YM2610 (SSG, FM, ADPCM-A/B) |

No MAME code is copied. The layout was read from the public driver as a
hardware reference.
