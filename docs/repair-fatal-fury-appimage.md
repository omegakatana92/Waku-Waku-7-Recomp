# Repair report: Waku Waku 7 AppImage was packaged as Fatal Fury 3

Date: 2026-10-28

## Root cause

The file supplied as `Waku-Waku-7-SteamDeck-x86_64.AppImage` was not a Waku
Waku 7 build at all. The extracted AppDir was a complete Fatal Fury 3 package:

| AppDir item | Actual content |
|---|---|
| `usr/bin/fatfury3` | Fatal Fury 3 player, 24,729,952 bytes |
| `AppRun` | executed `usr/bin/fatfury3`; searched `~/.local/share/fatfury3/roms` |
| `fatfury3.desktop` | `Name=Fatal Fury 3` |
| `fatfury3.png` | Fatal Fury 3 icon |
| `usr/share/doc/fatfury3/` | Fatal Fury 3 README and notices |

Running the extracted binary with a nonexistent ROM path printed:

```
error: cannot open /tmp/does-not-exist/069-p1.p1
error: cannot open /tmp/does-not-exist/069-c1.c1
...
error: missing ROM files
```

`069-*` is the Fatal Fury 3 ROM set. So the defect was **incorrect packaging
of the wrong build artifact**, not a missing executable name. The Waku Waku 7
filename had been attached to a Fatal Fury 3 AppDir; renaming the executable
would not have fixed it.

The original bad `.AppImage` file was not present in the accessible workspace;
the extracted AppDir above was left from the earlier inspection and is the
audit evidence.

## Repair

1. Used the existing genuine Waku Waku 7 recompilation project:
   `releases/waku waku 7/` (also published at
   <https://github.com/omegakatana92/Waku-Waku-7-Recomp>).
2. Verified the project's ROM layout is MAME set `wakuwak7` (NGH-225):
   `225-p1.p1`, `225-p2.sp2`, `225-s1.s1`, `225-m1.m1`, `225-v1.v1`,
   `225-v2.v2`, six C ROMs.
3. Rebuilt the Linux x86-64 player from that source.
4. Added a software-renderer fallback in `neogeorecomp/src/window_sdl.c`:
   accelerated renderer first, SDL software renderer second, default renderer
   last, with error checks for window, renderer and texture creation.
5. Replaced the AppRun launcher with one that:
   * accepts `--rom-path DIR` and `--rom-path=DIR`;
   * searches `~/.local/share/wakuwak7/roms`, `WAKUWAKU7_ROM_DIR`, folders
     beside the AppImage, EmulationStation folders and `$PWD/roms`;
   * preflights the twelve `225-*` game files and prints the missing names;
   * falls back to `~/.local/share/blazingstar/roms` or
     `~/.local/share/breakers/roms` for BIOS files when the game folder has no
     `sp-s2.sp1`;
   * still adds `--fullscreen` for a normal Deck launch and respects
     `--headless`, `--fullscreen` and `--scale`.
6. Packaged a fresh AppImage with Waku Waku 7 metadata, icon, docs and
   licences. No Fatal Fury 3 strings remain.

## ROM preparation

The supplied archive was copied to the expected location and validated:

```
/home/deck/Downloads/neo geo appimagesd/wakuwak7.zip
```

Originals were extracted to:

```
/home/deck/.local/share/wakuwak7/roms-original
```

Runtime-ready files (no transformation required for this plain PROGBK1 cart)
were copied to:

```
/home/deck/.local/share/wakuwak7/roms
```

`python3 scripts/validate-roms.py /home/deck/.local/share/wakuwak7/roms`
reported **all files verified**: 12 game files + `sp-s2.sp1`, `sfix.sfix`,
`sm1.sm1` and `000-lo.lo`.

## Fixed AppImage

```
/home/deck/Downloads/neo geo appimagesd/Waku-Waku-7-Fixed-SteamDeck-x86_64.AppImage
```

* Size: 9,652,728 bytes
* SHA-256: `83dc16cd8e8a7fb06dba8658aabcea67e4652a7c83b54e57359cf203f8bd12c3`
* ELF 64-bit LSB PIE, x86-64
* Internal executable: `usr/bin/wakuwak7`
* Desktop: `Name=Waku Waku 7`, `Exec=wakuwak7`, `Icon=wakuwak7`
* AppRun: launches `usr/bin/wakuwak7`
* No `fatfury3` / Fatal Fury references
* No ROM or BIOS files inside the AppImage

## Verification

| Test | Result |
|---|---|
| Direct AppImage execution | Passed (FUSE available) |
| `--headless --rom-path ...`, 3,000 frames | 52,086,539 native, 0 interpreted, 0 uncovered |
| No `--rom-path`, auto-discovery, 300 frames | Passed; used `~/.local/share/wakuwak7/roms` |
| Missing ROM folder | Useful error, exit 1 |
| Missing one ROM (`225-v2.v2`) | Names the file, exit 1 |
| Game ROMs only, BIOS fallback | Passed using `~/.local/share/blazingstar/roms` |
| `--verify`, 2,000 frames | 898,367 blocks, 0 mismatches, 100.000% native |
| Fullscreen 1280x800 | Passed; output 1280x800, destination 107,0 1066x800 (4:3 pillarbox) |
| Forced software renderer | Passed, same fullscreen geometry |
| Double-click-style direct launch | Passed, fullscreen and auto ROM discovery |
| Gameplay screenshot | Waku Waku 7 match captured at frame 2500 (Rai vs Mauro) |
| Audio capture, 12,000 frames | 202.8 s, 55,555 Hz stereo, peak 26,940; same game-transition gaps as the native build |
| `ldd` | No missing libraries; SDL2 resolves from bundled `usr/lib` when AppRun runs |
| Virtual gamepad test | Skipped: WSL SDL2 2.0.20 lacks the 2.24 virtual-joystick API; no physical pad/Deck available |

## Remaining issues

* Physical Steam Deck controller/Steam Input and real audio output were not
  available in this environment.
* The WSL test used SDL2 2.0.20. SteamOS ships a newer SDL2; the bundled copy is
  used first. Controller mapping code is the toolkit's existing SDL2
  GameController path.
* The AppImage was tested under Xvfb, not on physical Deck hardware.
