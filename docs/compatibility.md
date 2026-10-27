# Compatibility and verification report

Game: **Waku Waku 7** (SNK, MVS/AES), MAME set `wakuwak7`, NGH-225.

Toolkit: **NeoGeoRecomp v0.2.0**, commit
`af96b2b4b39b42b392b17bcaa6a74a5f27088202`, plus the generic fixes in
`docs/runtime-changes.md` (watchdog, bank guard, 4:3 fullscreen, M1 bank mask).

Everything below was run in this workspace. Anything not run is marked
**untested**, not assumed.

## Hardware profile

| Area | Result |
|---|---|
| 68000 program | 3 MB P ROM: 1 MB fixed + two 1 MB banks |
| Encryption / protection | none (normal PROGBK1 MVS/AES cart) |
| C ROMs | 24 MB, three odd/even pairs, no CMC decryption |
| S ROM | 128 KB fixed layer |
| M ROM | 128 KB Z80 driver |
| V ROMs | 8 MB ADPCM-A/B |
| BIOS | real `sp-s2.sp1` (MVS Asia/Europe v2), no BIOS HLE |
| Banking | standard `$2FFFF0-$2FFFFF` 1 MB window |

## ROM validation - passed

All 12 game files and the 4 required system-ROM files match MAME
`ROM_START( wakuwak7 )` by size, CRC32 and SHA1
(`python scripts/validate-roms.py roms`). Table in `docs/rom-layout.md`.

## Boot and hardware

| Test | Environment / run | Result |
|---|---|---|
| Interpreter boot, 6,000 frames | Windows x64, headless | **Passed**; BIOS self-test, eyecatcher, intro, attract |
| Native boot, 6,000 frames | Windows x64, headless | **Passed**; 100.3M instructions, 98.22% native before profiling |
| Native frames vs interpreter | frames 1500, 2500, 3500, 3999 | **Byte-identical** PNGs (SHA-256 match) |
| Window launch | Windows x64, SDL2 2.32.10 | **Passed**, exit 0 |
| Fullscreen launch | Windows x64, `--fullscreen` | **Passed**, exit 0 |
| Audio | 12,000-frame `--wav`, native | **202.8 s**, 55,555 Hz stereo, peak 26,940 |
| Audio, interpreter | same script, `--interp` | **202.8 s**, peak 26,527, same silent windows |

The silent windows in the 202.8 s capture are the game's own round/continue
transitions: the native and interpreter captures have the same windows
(11-14 s, 16 s, 104-109 s, 153-156 s, 188-192 s, 201 s). They are not a stalled
driver.

## Recompilation and correctness

| Metric | Result |
|---|---|
| Static discovery | 292,532 instructions, 6,332 routines, 11,120 entries |
| After one profile pass (6,000 + 19,000 frames) | **12,106** entries (+986) |
| `--verify`, 8,000 frames | **4,597,307 blocks, 0 mismatches** |
| Native instructions, 19,000-frame soak | **321,326,444** |
| Interpreted instructions after profiling | **0** |
| Uncovered entry points after profiling | **0** |
| Native coverage | **100.000%** of the executed instructions in these sessions |

The 100% figure is measured over the scripted sessions (boot, intro, attract,
HOW TO PLAY, character select, VS screens, repeated rounds, continue/round
transitions). It is not a proof that every reachable path in the 3 MB program
is native; code in bank 1 would still interpret by design, and no measured
execution reached it.

## Gameplay

| Item | Result |
|---|---|
| BIOS warning / eyecatcher | Yes (frame 600) |
| Intro / attract | Yes (character artwork, title, INSERT COIN) |
| Coin insertion | Yes (credit counter increments) |
| Start | Yes |
| HOW TO PLAY | Yes (frame 1200) |
| Character select | Yes (full roster, cursor, P1 marker at frame 1500) |
| VS / story screen | Yes ("Play with MAURO!") |
| Match: movement, A/B/C/D, hits, health bars, timer | Yes (frames 1800-3999) |
| ROUND 2 / continue transitions | Observed during the soak |
| Two-player versus | **Untested** |
| Test / service menu | **Untested** |
| Memory card | Not implemented by the toolkit |
| Audio device playback | **Untested** (WAV output verified) |
| Physical gamepad / Steam Input | **Untested** (toolkit mapping only) |

Screenshots collected during these runs are not shipped because they contain
SNK artwork.

## Windows deliverable

| Item | Result |
|---|---|
| Toolchain | MSVC 19.51.36257 (Visual Studio 18 2026), CMake 4.3.3, Release x64 |
| Build | **built**; 16 generated C files |
| Package | `dist/windows/Waku Waku 7-Windows-x64/` - exe + SDL2.dll + VC runtime + docs + licences |
| Headless smoke test | **Passed** (1,200 frames) |
| Full soak, native | **Passed** (19,000 frames, 100.000% native) |
| `--verify` | **Passed**, 4,597,307 blocks, 0 mismatches |
| ROMs in package | none |

## Steam Deck AppImage

| Item | Result |
|---|---|
| Build host | Windows 11 + WSL2, Ubuntu 22.04 x86_64 |
| Output | `dist/steamdeck/Waku Waku 7-SteamDeck-x86_64.AppImage` (about 9.6 MB) |
| Headless run | **Passed**, 3,000 frames, 100.000% native, 0 interpreted |
| `--verify` on AppImage | **Passed**, 2,000 frames, 0 mismatches, 100.000% native |
| Windowed/fullscreen launch | **Passed** under Xvfb 1280x800 |
| Aspect at 1280x800 | renderer output 1280x800, destination **107,0 1066x800**, 4:3 pillarboxed, not stretched (`NG_WINDOW_TRACE=1`) |
| `ldd` | no missing libraries; glibc/libstdc++/libgcc not bundled; SDL2 bundled in `usr/lib` |
| ROMs inside AppImage | none |
| Steam Deck hardware | **Not available**: Gaming Mode, Steam Input, LCD/OLED panels **untested** |

## Known limitations

* Native coverage is 100% for the scripted sessions only; bank 1 interprets by
  design if execution ever reaches it.
* No Steam Deck hardware, no physical gamepad, no keyboard-by-hand test, no
  two-player or service-menu test, no listening test on a real audio device.
* The toolkit's controller layout is fixed (no remapping).
* PolyForm Noncommercial 1.0.0 does not permit commercial distribution of the
  original code. The variant was confirmed by the owner on 2026-10-27.
* No ROMs or BIOS files are bundled; a legally obtained `neogeo` set is
  required.
* The Korean MVS variant and bootleg/hack sets are not configured.
