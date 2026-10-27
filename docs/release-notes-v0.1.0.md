# Waku Waku 7 v0.1.0 - native recompilation

First public build of the Waku Waku 7 static recompilation on NeoGeoRecomp
v0.2.0.

## Downloads

* `Waku Waku 7-Windows-x64.zip` - Windows 10/11 x64, SDL2 and VC runtime
  included.
* `Waku Waku 7-SteamDeck-x86_64.AppImage` - Linux x86_64 / Steam Deck.
* `SHA256SUMS.txt` - hashes for both packages.

No game ROMs or BIOS files are included. Unzip your own legally obtained MAME
`wakuwak7` and `neogeo` sets into a `roms` folder next to the executable or
AppImage, or pass `--rom-path`.

## Verified

* ROM layout and hashes match MAME `ROM_START( wakuwak7 )`.
* 12,106 recompiled entry points after one profile pass (+986 runtime-only).
* 19,000-frame soak: 321,326,444 native instructions, 0 interpreted,
  0 uncovered entry points (100.000% native).
* `--verify`, 8,000 frames: 4,597,521 blocks, 0 mismatches.
* Native and interpreter frames byte-identical at frames 1500, 2500, 3500,
  3999.
* Audio: 202.8 s capture, 55,555 Hz stereo, peak 26,940; native and
  interpreter silent windows identical (boot and game transitions).
* Windows windowed and fullscreen launches passed.
* AppImage headless, `--verify` and fullscreen launches passed under Xvfb
  1280x800; 4:3 pillarbox measured at 1066x800 (destination x=107).

## Notes

* Steam Deck hardware, Steam Input and physical gamepads were not available;
  those paths remain untested.
* Audio was measured, not auditioned.
* The measured 100% coverage covers the scripted sessions. Code in the second
  program bank is interpreted by design if reached.
* Original project code: PolyForm Noncommercial 1.0.0. Vendored toolkit and
  dependencies keep their MIT/BSD/zlib licences.
