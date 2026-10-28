# Waku Waku 7 v0.1.1 - corrected Steam Deck AppImage

This release fixes the mispackaged Linux AppImage that actually contained
**Fatal Fury 3**. The corrected build is a genuine Waku Waku 7 recompilation.

## Root cause

The bad AppImage was assembled from a Fatal Fury 3 AppDir: its executable,
AppRun, desktop entry, icon and documentation all belonged to `fatfury3`, and
it looked for `~/.local/share/fatfury3/roms`. It was not a rename issue.

## Fixed

* Rebuilt from the Waku Waku 7 source and MAME `wakuwak7` ROM layout.
* Correct internal executable: `usr/bin/wakuwak7`.
* Correct metadata: `Name=Waku Waku 7`, `Exec=wakuwak7`, `Icon=wakuwak7`.
* AppRun searches `~/.local/share/wakuwak7/roms`, `WAKUWAKU7_ROM_DIR`,
  beside-AppImage `roms`, EmulationStation folders and `$PWD/roms`.
* Supports `--rom-path DIR` and `--rom-path=DIR`.
* Preflights the twelve `225-*` files and names missing ones.
* Falls back to `~/.local/share/blazingstar/roms` or
  `~/.local/share/breakers/roms` for BIOS files when needed.
* Added an SDL software-renderer fallback for systems without a usable GPU
  driver.
* Rebuilt the Windows x64 package with the same corrected source.
* Removed all Fatal Fury 3 references.

## Assets

### Linux / Steam Deck

`Waku-Waku-7-Fixed-SteamDeck-x86_64.AppImage`

* Size: 9,652,728 bytes
* SHA-256: `83dc16cd8e8a7fb06dba8658aabcea67e4652a7c83b54e57359cf203f8bd12c3`

### Windows x64

`Waku-Waku-7-Fixed-Windows-x64.zip`

* Size: 9,007,372 bytes
* SHA-256: `0cc6e56db22239f16a41ed1bbc8c430b4e8bfaac1ff5d6c040428eaeb84999f6`
* Contains `Waku Waku 7.exe`, SDL2.dll, VC runtime, documentation and
  licences. No ROMs, BIOS files or CMake build files.

## Verified

* Direct AppImage execution and Dolphin-style double-click launch.
* Auto ROM discovery and explicit `--rom-path`.
* Missing-ROM error and BIOS fallback.
* 3,000-frame headless run: 52,086,539 native instructions, 0 interpreted.
* `--verify`, 2,000 frames: 898,367 blocks, 0 mismatches.
* Fullscreen 1280x800: 4:3 pillarbox at 107,0 1066x800.
* Forced software renderer: passed.
* Gameplay screenshot at frame 2500: Waku Waku 7 match (Rai vs Mauro).
* 12,000-frame audio capture: 202.8 s, 55,555 Hz stereo, peak 26,940.
* Windows package: headless, windowed and fullscreen launches exit 0;
  `--verify` 2,000 frames reports 0 mismatches; 3,000-frame WAV capture
  (50.7 s, 55,555 Hz, peak 27,652).

## Not tested

Physical Steam Deck hardware, Steam Input, physical gamepads and real audio
output were not available. Virtual gamepad test skipped because WSL SDL2 is
2.0.20. No ROMs or BIOS files are included in the AppImage.
