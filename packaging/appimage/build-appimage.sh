#!/usr/bin/env bash
# Build the Linux x86_64 player and package it as a Steam Deck AppImage.
#
# Prerequisites: gcc, g++, cmake 3.21+, make, libsdl2-dev, wget.
# The user's ROMs are never bundled: the AppImage contains only the recompiled
# player and its runtime libraries.
#
# Usage: ./packaging/appimage/build-appimage.sh [ROM_DIR]
# Default ROM_DIR=$ROOT/roms, output
# dist/steamdeck/Waku Waku 7-SteamDeck-x86_64.AppImage
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROMS="${1:-$ROOT/roms}"
BUILD="$ROOT/build-linux"
APPDIR="$BUILD/AppDir"
OUT="$ROOT/dist/steamdeck/Waku Waku 7-SteamDeck-x86_64.AppImage"

echo "== configure/build (Release) =="
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DWAKUWAKU7_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$(nproc)"

echo "== assemble AppDir =="
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$APPDIR/usr/share/doc/wakuwak7"
cp "$BUILD/wakuwak7" "$APPDIR/usr/bin/wakuwak7"
strip --strip-unneeded "$APPDIR/usr/bin/wakuwak7" 2>/dev/null || true

# Bundle the SDL2 the build linked against; SteamOS's system copy may differ.
SDL=$(ldd "$BUILD/wakuwak7" | awk '/libSDL2-2\.0\.so\.0/{print $3; exit}')
if [ -n "$SDL" ]; then cp "$SDL" "$APPDIR/usr/lib/"; fi

cp "$ROOT/packaging/appimage/wakuwak7.png" "$APPDIR/wakuwak7.png"
cp "$ROOT/packaging/appimage/wakuwak7.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/wakuwak7.png"
cp "$ROOT/packaging/appimage/wakuwak7.desktop" "$APPDIR/wakuwak7.desktop"
cp "$ROOT/packaging/appimage/wakuwak7.desktop" "$APPDIR/usr/share/applications/wakuwak7.desktop"
cp "$ROOT/packaging/appimage/README.txt" "$APPDIR/usr/share/doc/wakuwak7/README.txt"
cp "$ROOT/LICENSE" "$APPDIR/usr/share/doc/wakuwak7/LICENSE.txt"
cp "$ROOT/LICENSE-STATUS.md" "$APPDIR/usr/share/doc/wakuwak7/LICENSE-STATUS.txt" 2>/dev/null || true
cp "$ROOT/THIRD_PARTY_NOTICES.md" "$APPDIR/usr/share/doc/wakuwak7/THIRD_PARTY_NOTICES.txt"
mkdir -p "$APPDIR/usr/share/doc/wakuwak7/LICENSES"
cp "$ROOT/neogeorecomp/LICENSE" "$APPDIR/usr/share/doc/wakuwak7/LICENSES/neogeorecomp.txt"
cp "$ROOT/neogeorecomp/NOTICE" "$APPDIR/usr/share/doc/wakuwak7/LICENSES/neogeorecomp-NOTICE.txt"
cp "$ROOT/neogeorecomp/LICENSES/"*.txt "$APPDIR/usr/share/doc/wakuwak7/LICENSES/"
cp "$ROOT/packaging/windows/SDL2.txt" "$APPDIR/usr/share/doc/wakuwak7/LICENSES/SDL2.txt"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
set -u
HERE=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Parse both "--rom-path DIR" and "--rom-path=DIR" forms. An explicit path
# always wins; otherwise search the standard locations, including the Deck
# per-user folder used by this project.
ROMDIR=""
BIOSDIR=""
explicit_rom=0
explicit_bios=0
prev=""
for a in "$@"; do
    case "$prev" in
        --rom-path)  ROMDIR="$a"; explicit_rom=1 ;;
        --bios-path) BIOSDIR="$a"; explicit_bios=1 ;;
    esac
    case "$a" in
        --rom-path=*)  ROMDIR="${a#--rom-path=}"; explicit_rom=1 ;;
        --bios-path=*) BIOSDIR="${a#--bios-path=}"; explicit_bios=1 ;;
    esac
    prev="$a"
done

if [ "$explicit_rom" = 0 ]; then
    for d in "${WAKUWAKU7_ROM_DIR:-}" \
             "${APPIMAGE:+$(dirname "$APPIMAGE")/roms}" \
             "${APPIMAGE:+$(dirname "$APPIMAGE")/roms/wakuwak7}" \
             "$HOME/.local/share/wakuwak7/roms" \
             "$HOME/Emulation/roms/wakuwak7" \
             "$HOME/roms/wakuwak7" \
             "$HOME/roms" \
             "$PWD/roms"; do
        if [ -n "$d" ] && [ -d "$d" ]; then ROMDIR="$d"; break; fi
    done
fi

if [ -z "$ROMDIR" ]; then
    echo "error: no Waku Waku 7 ROM folder found." >&2
    echo "Put the unzipped MAME wakuwak7 and neogeo sets in:" >&2
    echo "  $HOME/.local/share/wakuwak7/roms" >&2
    echo "or pass: --rom-path /path/to/roms" >&2
    exit 1
fi

missing=""
for f in 225-p1.p1 225-p2.sp2 225-s1.s1 225-m1.m1 225-v1.v1 225-v2.v2 \
         225-c1.c1 225-c2.c2 225-c3.c3 225-c4.c4 225-c5.c5 225-c6.c6; do
    [ -f "$ROMDIR/$f" ] || missing="$missing $f"
done
if [ -n "$missing" ]; then
    echo "error: missing Waku Waku 7 ROM files in $ROMDIR:" >&2
    for f in $missing; do echo "  $f" >&2; done
    echo "Unzip your legally obtained wakuwak7 set into that folder." >&2
    exit 1
fi

[ "$explicit_rom" = 0 ] && set -- --rom-path "$ROMDIR" "$@"

# The prepared ROM folder normally contains the neogeo system files. If it
# does not, use a known working BIOS folder read-only.
if [ "$explicit_bios" = 0 ] && [ ! -f "$ROMDIR/sp-s2.sp1" ]; then
    for d in "$HOME/.local/share/blazingstar/roms" \
             "$HOME/.local/share/breakers/roms"; do
        if [ -f "$d/sp-s2.sp1" ] && [ -f "$d/sfix.sfix" ] && \
           [ -f "$d/sm1.sm1" ] && [ -f "$d/000-lo.lo" ]; then
            BIOSDIR="$d"; break
        fi
    done
    [ -n "$BIOSDIR" ] && set -- --bios-path "$BIOSDIR" "$@"
fi

# Steam Deck / Gaming Mode wants a fullscreen game. Keep --headless and an
# explicit --scale or --fullscreen from being overridden.
add_fs=1
for a in "$@"; do
    case "$a" in --headless|--fullscreen|--scale) add_fs=0;; esac
done
[ "$add_fs" = 1 ] && set -- --fullscreen "$@"

exec "$HERE/usr/bin/wakuwak7" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "== appimagetool =="
mkdir -p "$ROOT/dist/steamdeck"
TOOL="${APPIMAGETOOL:-$HOME/appimagetool-x86_64.AppImage}"
if [ ! -x "$TOOL" ]; then
    TOOL="$BUILD/appimagetool.AppImage"
    wget -q -O "$TOOL" \
      https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$TOOL"
fi
ARCH=x86_64 "$TOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$OUT"
chmod +x "$OUT"

# Release-folder companions: README and the license set.
DIST="$ROOT/dist/steamdeck"
mkdir -p "$DIST/LICENSES"
cp "$ROOT/packaging/appimage/README.txt" "$DIST/README.txt"
cp "$ROOT/LICENSE" "$DIST/LICENSES/LICENSE.txt"
cp "$ROOT/LICENSE-STATUS.md" "$DIST/LICENSES/LICENSE-STATUS.txt" 2>/dev/null || true
cp "$ROOT/THIRD_PARTY_NOTICES.md" "$DIST/LICENSES/THIRD_PARTY_NOTICES.txt"
cp "$ROOT/packaging/windows/SDL2.txt" "$DIST/LICENSES/SDL2.txt"
cp "$ROOT/neogeorecomp/LICENSE" "$DIST/LICENSES/neogeorecomp.txt"
cp "$ROOT/neogeorecomp/NOTICE" "$DIST/LICENSES/neogeorecomp-NOTICE.txt"
cp "$ROOT/neogeorecomp/LICENSES/"*.txt "$DIST/LICENSES/"

echo "wrote $OUT"
