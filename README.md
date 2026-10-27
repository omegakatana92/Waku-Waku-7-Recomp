# Waku Waku 7 - native recompilation

A native port of **Waku Waku 7** (SNK, MVS/AES, MAME set `wakuwak7`, NGH-225)
built on [NeoGeoRecomp](https://github.com/sp00nznet/neogeorecomp) v0.2.0.

The game's Motorola 68000 program is translated ahead of time into C: one C
function per routine, with the original address and disassembly above every
instruction, running against a model of the MVS board. It is **not** an
emulator wrapper. A Musashi interpreter stays linked as the correctness
oracle and as the fallback for addresses that have no native entry; on the
measured sessions below **nothing** executed in it.

| Deliverable | Path | State |
|---|---|---|
| Windows x64 | `dist/windows/Waku Waku 7-Windows-x64/` | built and tested |
| Steam Deck / Linux x86_64 AppImage | `dist/steamdeck/Waku Waku 7-SteamDeck-x86_64.AppImage` | built and tested under Xvfb 1280x800; **not** run on Deck hardware |

No game ROMs or BIOS files are included. Both builds compile the recompiled C
from *your* dump at build time; the distribution contains no ROM-derived code.

## Download

Prebuilt packages are attached to the GitHub releases:

<https://github.com/omegakatana92/Waku-Waku-7-Recomp/releases>

The source repository contains no game ROMs, BIOS images, CMake caches or
build trees. `CMakeLists.txt` files are source build definitions only.

## Status at a glance

| Area | Result |
|---|---|
| ROM validation | 12 game files + 4 BIOS files match MAME by size, CRC32 and SHA1 |
| Boot | Real MVS BIOS (`sp-s2.sp1`), no BIOS HLE; eyecatcher, intro, attract |
| Recompiled entry points | **12,106** (11,120 static + 986 from one profile pass) |
| `--verify` (8,000 frames) | **4,597,307 blocks, 0 mismatches** |
| Native coverage (19,000-frame soak) | **100.000%**, 0 interpreted instructions, 0 uncovered entries |
| Native vs interpreter frames | byte-identical PNGs at frames 1500, 2500, 3500, 3999 |
| Graphics | sprites, fix layer, palettes, raster effects and zoom checked in play |
| Audio | Z80 driver + YM2610 synthesize to WAV; 202.8 s, 55,555 Hz, peak 26,940 |
| Windows | Release x64, windowed/fullscreen tested, SDL2 + VC runtime shipped |
| Linux AppImage | built and launched under Xvfb 1280x800; see limitations |
| Steam Deck hardware | **untested** (no Deck available) |

Full measurements and the test log index: [docs/compatibility.md](docs/compatibility.md).

## Requirements

* **Windows**: Windows 10/11 x64. Visual Studio 2022/2026 with *Desktop
  development with C++*, CMake 3.21+, and the SDL2 VC development package
  under `deps/sdl2/` (2.32.10 is included here).
* **Linux**: gcc/g++, CMake 3.21+, make/ninja, `libsdl2-dev`, `pkg-config`,
  `python3`, `wget` (for appimagetool).
* **Your ROMs**: the MAME `wakuwak7` and `neogeo` sets, unzipped into one
  folder. See [docs/rom-layout.md](docs/rom-layout.md).

## Getting started - Windows

```powershell
# ROMs first: unzip both sets into .\roms, or use the helper
powershell -ExecutionPolicy Bypass -File packaging\windows\Prepare-ROMs.ps1
python scripts\validate-roms.py roms
powershell -ExecutionPolicy Bypass -File scripts\build-windows.ps1 -RomDir .\roms -Test
.\build-windows\Release\"Waku Waku 7.exe" --rom-path .\roms
```

`scripts\build-windows.ps1` configures with the Visual Studio generator,
builds Release, runs a headless smoke test with `-Test`, and stages
`dist\windows\Waku Waku 7-Windows-x64\` with the executable, SDL2, the VC
runtime, README, ROM layout and all licences.

## Getting started - Steam Deck / Linux

```bash
# ROMs first: unzip wakuwak7.zip and neogeo.zip into ./roms
python3 scripts/validate-roms.py roms
./packaging/appimage/build-appimage.sh ./roms
"./dist/steamdeck/Waku Waku 7-SteamDeck-x86_64.AppImage"
```

The AppImage auto-detects `roms/` beside itself (and the usual EmulationStation
folders), starts fullscreen on a 1280x800 panel with a uniform scale and black
pillarboxes, and uses SDL2 for video, audio and controllers. Copy the AppImage
plus `roms/` to the Deck, add it as a non-Steam game, and launch in Gaming Mode.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | arrows | D-pad / left stick |
| A B C D | Z X C V | A B X Y (Xbox positions) |
| Coin | 5 (6 = P2) | Back / View |
| Start | 1 (2 = P2) | Start |
| Select | 3 | left shoulder |
| Service / test | 9 / F2 | - |
| Fullscreen | F11 or Alt+Enter | - |
| Quit | Esc | - |

Two SDL GameControllers work: first connected is player 1, second player 2.
Steam Input's default gamepad template presents the Deck as an Xbox pad, which
is exactly the layout above. On MVS you must insert a coin before Start works.

## How the recompilation works

```
225-p1.p1 + 225-p2.sp2 --> wakuwak7_recomp (m68krecomp) --> build/generated/*.c
     + sp-s2.sp1           decode, discover, emit C             |
                                                                v
                    neogeorecomp runtime <-----> Waku Waku 7.exe/.AppImage
   dispatcher | Musashi fallback | LSPC video | palette | I/O | Z80/YM2610 | SDL2
```

* Static discovery starts from the BIOS and cartridge vectors, the four
  cartridge-header entry points (`USER`, `PLAYER_START`, `DEMO_END`,
  `COIN_SOUND`), call targets, jump tables and code pointers. It found
  11,120 dispatch entries across 6,332 routines.
* One profile pass over a 6,000-frame boot and a 19,000-frame scripted soak
  added 986 runtime-only addresses; the rebuilt table has 12,106 entries and
  440,210 emitted instructions.
* Control flow is flat: calls and returns travel through a dispatcher, return
  addresses live on the emulated stack, and interrupts are real 68000
  exceptions. The C stack does not grow with 68000 call depth.
* Banking: the cart has two 1 MB banks behind `$200000`. Measured execution
  stayed in the fixed bank and bank 0 after profiling, so the measured sessions
  are fully native.

## Correctness and coverage

`--verify` replays every native block in Musashi against the same memory and
I/O values and compares registers, flags and the write sequence. On an
8,000-frame coin/start/play session it checks **4,597,307 blocks with 0
mismatches**. The 19,000-frame soak reports **100.000% native instructions**,
0 interpreted and 0 uncovered entry points.

Frames rendered by the recompiled build are byte-identical to the interpreter's
at several points across the menus and the first match (SHA-256 match).

## Repository layout

```
waku waku 7/
  CMakeLists.txt           two stages: generator, then player
  src/                     game.c (ROM layout), main.c, recomp_main.c
  neogeorecomp/            vendored toolkit v0.2.0 + generic fixes (MIT)
  deps/sdl2/               SDL2 VC development package (Windows)
  scripts/                 Windows/Linux build, ROM validator
  packaging/               Windows README, AppImage recipe, icon, .desktop
  tests/                   scripted input, audio regression
  docs/                    rom-layout, compatibility, testing, hardware notes
  build-windows/           Windows build tree (generated C lives here)
  build-linux/             Linux build tree
  dist/windows/            Windows package
  dist/steamdeck/          AppImage + README
```

ROMs, BIOS files, generated C and entry lists are never committed
(`.gitignore`), and none of them ship in `dist/`.

## Licensing

* Original project code (ROM layout, player glue, scripts, packaging, docs):
  **PolyForm Noncommercial 1.0.0** - free for noncommercial use; commercial
  use requires a separate licence. Confirmed by the owner on 2026-10-27; see
  `LICENSE` and `LICENSE-STATUS.md`.
* Vendored NeoGeoRecomp: **MIT** (c) 2026 sp00nznet, with the generic fixes
  described in `docs/runtime-changes.md`. Musashi **MIT**, z80 **MIT**,
  ymfm **BSD-3**, SDL2 **zlib**. All notices ship in
  `THIRD_PARTY_NOTICES.md` and in `LICENSES/` in each release.
* The PolyForm licence covers only the original code. It grants no rights in
  SNK's game data, and it does not make distribution of ROM-derived material
  lawful where it otherwise would not be. Distribute source, or a binary built
  from your own dump, only where you have the rights to do so.

## Known limitations

* **Steam Deck hardware is untested.** The AppImage was built and validated on
  Linux x86_64 under Xvfb at 1280x800; Gaming Mode, Steam Input and LCD/OLED
  panels were not exercised on a physical Deck.
* No physical gamepad was available. The SDL GameController mapping is the
  toolkit's existing one; a real pad and Steam Input were not tested.
* Keyboard handlers were not exercised by a human; the scripted input path and
  the game logic behind it were.
* Two-player versus, the test/service menu and the memory-card paths were not
  tested. The toolkit does not implement memory cards.
* Audio was verified by waveform analysis; playback on a real audio device was
  not listened to. The native and interpreter captures have identical silent
  windows, which correspond to the game's own transitions.
* The controller layout is fixed by the toolkit; remapping is not implemented.
* The measured 100% figure is for the scripted sessions. Code in the second
  program bank is interpreted by design if execution ever reaches it.

## Credits

Toolkit: [NeoGeoRecomp](https://github.com/sp00nznet/neogeorecomp) by
sp00nznet and contributors. Header reference: MAME's Neo Geo driver and the
NeoGeo Development Wiki (no code copied). Musashi by Karl Stenerud, z80 by
Nicolas Allemand, ymfm by Aaron Giles, SDL2 by Sam Lantinga.

Waku Waku 7, Neo Geo, MVS and AES are trademarks of SNK Corporation. This
project is unaffiliated with and not endorsed by SNK.
