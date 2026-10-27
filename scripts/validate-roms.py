#!/usr/bin/env python3
"""Validate the Waku Waku 7 (MAME set `wakuwak7`) ROM files.

Checks every file the runtime loads against MAME's neogeo.cpp: size, CRC32
and SHA1. The game set and the required `neogeo` system ROMs may live in one
directory or be passed as two.

Usage:
    python scripts/validate-roms.py ROM_DIR [BIOS_DIR]

Exit code 0 means every file matched; 1 means a problem was found.
No ROM data is read from or written anywhere except the paths given.
"""
import hashlib
import os
import sys
import zlib

# MAME src/mame/snk/neogeo.cpp, ROM_START( wakuwak7 ).
GAME = {
    "225-p1.p1":  (0x100000, "b14da766", "bdffd72ff705fc6b085a4026217bac1c4bc93163"),
    "225-p2.sp2": (0x200000, "fe190665", "739d9a8fc2da34381654d9e291141eacc210ae5c"),
    "225-s1.s1":  (0x020000, "71c4b4b5", "9410f13807f01082dc86f2d84051be4bed8e9f7c"),
    "225-m1.m1":  (0x020000, "0634bba6", "153aaf016440500df7a4454f3f2f2911219cb7d8"),
    "225-v1.v1":  (0x400000, "6195c6b4", "66c06b5904aedb256e3997bbec60f8ab50c6ff0c"),
    "225-v2.v2":  (0x400000, "6159c5fe", "9015e93416497f1ef877c717afed40f7ecfa42e4"),
    "225-c1.c1":  (0x400000, "ee4fea54", "314b513a52b2cc88cbf2409d1934c357269a8bb2"),
    "225-c2.c2":  (0x400000, "0c549e2d", "d8c4626231c92e43d9bf183202553ee2b5c532e6"),
    "225-c3.c3":  (0x400000, "af0897c0", "2b8ec19b9dd0bd1f1171fb01b915e9d25ec8c421"),
    "225-c4.c4":  (0x400000, "4c66527a", "6c8c9342fad70b456e282b0d52e7ad890e4673d3"),
    "225-c5.c5":  (0x400000, "8ecea2b5", "cad51e6e76d8258a78becb6f4096dd061f537494"),
    "225-c6.c6":  (0x400000, "0eb11a6d", "c6d4f978ff3ca190a3060ac52bd7347189194f76"),
}

BIOS = {
    "sp-s2.sp1": (0x020000, "9036d879", "4f5ed7105b7128794654ce82b51723e16e389543"),
    "sfix.sfix": (0x020000, "c2ea0cfd", "fd4a618cdcdbf849374f0a50dd8efe9dbab706c3"),
    "sm1.sm1":   (0x020000, "94416d67", "42f9d7ddd6c0931fd64226a60dc73602b2819dcf"),
    "000-lo.lo": (0x020000, "5a86cff2", "5992277debadeb64d1c1c64b0a92d9293eaf7e4a"),
}


def check(name, expected, search):
    size, crc, sha1 = expected
    for d in search:
        p = os.path.join(d, name)
        if os.path.isfile(p):
            break
    else:
        print("MISSING   %-12s (looked in %s)" % (name, ", ".join(search)))
        return False
    data = open(p, "rb").read()
    got_crc = "%08x" % (zlib.crc32(data) & 0xFFFFFFFF)
    got_sha1 = hashlib.sha1(data).hexdigest()
    ok = len(data) == size and got_crc == crc and got_sha1 == sha1
    if ok:
        print("OK        %-12s %9d bytes  crc32 %s" % (name, len(data), got_crc))
    else:
        print("MISMATCH  %-12s size %d (want %d) crc32 %s (want %s)"
              % (name, len(data), size, got_crc, crc))
    return ok


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    game_dir = sys.argv[1]
    bios_dir = sys.argv[2] if len(sys.argv) > 2 else game_dir
    ok = True
    print("== game set wakuwak7 ==")
    for n, e in GAME.items():
        ok &= check(n, e, [game_dir])
    print("== system set neogeo ==")
    for n, e in BIOS.items():
        ok &= check(n, e, [bios_dir, game_dir])
    print("result:", "all files verified" if ok else "PROBLEMS FOUND")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
