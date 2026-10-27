/*
 * game.c - Waku Waku 7 (MAME set "wakuwak7", NGH-225), the verified ROM
 * layout shared by the player and the recompiler.
 *
 * Layout and hashes were checked against MAME's src/mame/snk/neogeo.cpp,
 * ROM_START( wakuwak7 ):
 *
 *   225-p1.p1   1 MB  TC538200  fixed program bank, 16-bit word-swapped
 *   225-p2.sp2  2 MB  TC5316200 banked program image, word-swapped
 *   225-s1.s1 128 KB  TC531000  fixed layer
 *   225-m1.m1 128 KB  TC531001  Z80 sound program
 *   225-v1.v1   4 MB  TC5332204 ADPCM-A
 *   225-v2.v2   4 MB  TC5332204 ADPCM-A
 *   225-c1..c6  4 MB each, three odd/even bitplane pairs
 *
 * The cart is a normal MVS/AES PROGBK1 board: 1 MB fixed at $000000 and two
 * 1 MB banks behind the $200000 window, selected through $2FFFF0. There is no
 * encryption, no NEO-SMA/CMC protection and no S ROM banking, so the generic
 * toolkit path is used.
 */
#include "game.h"

const ng_game_t k_wakuwak7 = {
    .name = "wakuwak7",
    .title = "Waku Waku 7",
    .prom_size = 0x300000,          /* 1 MB fixed + 2 MB banked */
    .prom = {
        /* file          file offset  dest       length    swap */
        {"225-p1.p1",   0x000000,    0x000000,  0x100000, 1},
        {"225-p2.sp2",  0x000000,    0x100000,  0x200000, 1},
    },
    .crom_size = 0x1800000,         /* 24 MB after pairing */
    .crom_pairs = {
        {"225-c1.c1", "225-c2.c2"},
        {"225-c3.c3", "225-c4.c4"},
        {"225-c5.c5", "225-c6.c6"},
    },
    .srom = "225-s1.s1",
    .m1 = "225-m1.m1",
    .vrom = {"225-v1.v1", "225-v2.v2"},
};
