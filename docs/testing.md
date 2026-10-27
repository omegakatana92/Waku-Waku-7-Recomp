# Testing and measured results

All numbers below are from the Windows Release build unless stated otherwise.
Commands are shown for PowerShell; on Linux replace `Waku Waku 7.exe` with
`build-linux/wakuwak7` and use forward slashes.

## Environment

| Item | Version |
|---|---|
| Windows | Windows 11 x64 |
| Compiler | MSVC 19.51.36257 (Visual Studio 18 2026) |
| CMake | 4.3.3 |
| SDL2 | 2.32.10 |
| Linux build host | Ubuntu 22.04.5 under WSL2 |
| Linux compiler | gcc (WSL2 Ubuntu) |

## 1. ROM validation

The archive is the MAME `wakuwak7` MVS set. Every file's CRC-32 and SHA-1 was
computed from the zip and compared with `ROM_START( wakuwak7 )` in MAME's
`src/mame/snk/neogeo.cpp`; all 12 game files match, as do the four required
`neogeo` files. The `NEO-GEO` signature is at `$100` of the byte-swapped fixed
bank.

No decryption or patching is performed. The build reads the user's files
directly from `WAKUWAKU7_ROM_DIR`.

## 2. Interpreted boot

```
"Waku Waku 7.exe" --headless --interp --rom-path roms --frames 6000 ^
    --screenshot 600:shots/ip-600.png --screenshot 1200:shots/ip-1200.png ^
    --screenshot 3000:shots/ip-3000.png --screenshot 5000:shots/ip-5000.png
```

Result: real BIOS eyecatcher at frame 600, character artwork and title in the
attract loop, INSERT COIN prompts. This validates the board model independently
of the recompiler.

## 3. Native build and boot

```
cmake -S . -B build-windows -G "Visual Studio 18 2026" -A x64 ^
      -DSDL2_DIR=...\deps\sdl2\SDL2-2.32.10\cmake ^
      -DWAKUWAKU7_ROM_DIR=C:/.../roms
cmake --build build-windows --config Release --parallel 8
```

Recompiler output (static discovery only):

```
[m68krecomp] pointer scan: 5284 seeds
[m68krecomp] wakuwak7: 292532 instructions emitted across routines
[m68krecomp] 6332 routines, 11120 dispatch entries
```

Boot and attract, 6,000 frames:

```
[exec] native blocks 2835784, native instructions 100265580,
       interpreted instructions 1819156 (98.22% native), 778 uncovered entry points
```

Screens checked: NEO-GEO eyecatcher (600), character artwork (1200, 2400,
3000, 4000), title/INSERT COIN (5000).

## 4. Coin, menus and a match

```
"Waku Waku 7.exe" --headless --rom-path roms --frames 4000 ^
    --input tests/probe.txt ^
    --screenshot 1200:shots/p1200.png --screenshot 1500:shots/p1500.png ^
    --screenshot 1800:shots/p1800.png --screenshot 2400:shots/p2400.png ^
    --screenshot 3999:shots/p3999.png
```

Frames checked: HOW TO PLAY (1200), CHARACTER SELECT (1500), opening stage
(1800), match with health bars and timer (2400-3600), ROUND 2 (3999).

## 5. Correctness: `--verify`

```
"Waku Waku 7.exe" --headless --verify --rom-path roms --frames 8000 ^
    --input tests/play_long.txt
[verify] 4597307 blocks checked, 0 mismatches
[exec] native blocks 4597307, native instructions 136648890,
       interpreted instructions 0 (100.00% native), 0 uncovered entry points
```

## 6. Coverage and the profile pass

Before profiling:

```
[attract, 6000 frames] interpreted 1819156 (98.22% native), 780 uncovered
[play_long, 19000 frames] interpreted 6774745 (97.89% native), 963 uncovered
```

Profile pass:

```
cmake --build build-windows --config Release --target profile
[exec] 780 new entry points ... entries.txt now lists 780
[exec] 963 new entry points ... entries.txt now lists 986
cmake --build build-windows --config Release
```

After profiling:

```
[play_long, 19000 frames]
[exec] native blocks 10226480, native instructions 321326444,
       interpreted instructions 0 (100.00% native), 0 uncovered entry points
```

Final table: 12,106 dispatch entries, 440,210 instructions emitted.

## 7. Native vs interpreter screenshots

| Frame | Screen | Result |
|---|---|---|
| 1500 | CHARACTER SELECT | byte-identical |
| 2500 | match | byte-identical |
| 3500 | match | byte-identical |
| 3999 | ROUND 2 | byte-identical |

## 8. Audio

```
"Waku Waku 7.exe" --headless --rom-path roms --frames 12000 ^
    --input tests/play_long.txt --wav shots/audio.wav
```

Result: 202.8 s, 55,555 Hz stereo, peak 26,940. The interpreter capture has the
same silent windows, which are game transitions:

```
native: (11-14), (16), (104-109), (153-156), (188-192), (201)
interp: (11-14), (16), (104-109), (153-156), (188-192), (201)
```

`tests/check_audio.py` fails on a music-sized gap; the known transitions are
wider than its 3 s threshold, so the report records them rather than claiming a
clean pass. No driver stall was observed: the Z80 keeps running and the same
timeline appears in interpreter mode.

## 9. Windows window

```
"Waku Waku 7.exe" --rom-path roms --frames 240 --scale 2
"Waku Waku 7.exe" --rom-path roms --fullscreen --frames 120
```

Both launched the SDL2 window, rendered frames and exited 0.

## 10. Linux and AppImage

The AppImage was built with gcc 11.4 on Ubuntu 22.04 under WSL2. It was run
headless (3,000 frames, 100.000% native), with `--verify` (2,000 frames,
0 mismatches, 100.000% native) and fullscreen under Xvfb at 1280x800, and
inspected with `ldd`:

```
[window] output 1280x800 dst 107,0 1066x800 fullscreen=1
```

That is a 4:3 pillarboxed image, not a stretch to 16:10. The bundled
`libSDL2-2.0.so.0` resolves from `usr/lib` when `LD_LIBRARY_PATH` is set by
AppRun; glibc, libstdc++ and libgcc are not bundled. Physical Steam Deck
LCD/OLED, Steam Input and Gaming Mode are **not tested**.
