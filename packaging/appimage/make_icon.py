#!/usr/bin/env python3
"""Draw an original 256x256 icon for the Waku Waku 7 recompilation.

No SNK artwork is used: a colourful field, a bubble, and block letters drawn
from a tiny bitmap font.
"""
import os
import struct
import zlib

W = H = 256
px = bytearray(W * H * 3)


def put(x, y, r, g, b):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 3
        px[i] = r
        px[i + 1] = g
        px[i + 2] = b


def rect(x0, y0, x1, y1, r, g, b):
    for y in range(max(0, y0), min(H, y1)):
        for x in range(max(0, x0), min(W, x1)):
            put(x, y, r, g, b)


# Background: bright arcade gradient.
for y in range(H):
    for x in range(W):
        put(x, y, 20 + y // 3, 30 + y // 5, 110 + y // 4)

# Radiating wedges.
for y in range(H):
    for x in range(W):
        if 20 <= (x + y) % 160 <= 52:
            put(x, y, 250, 120 + (y % 60), 30)

# Bubble.
cx, cy, rad = 128, 112, 58
for y in range(cy - rad, cy + rad):
    for x in range(cx - rad, cx + rad):
        if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad:
            put(x, y, 246, 72, 166)
        elif (x - cx) ** 2 + (y - cy) ** 2 <= (rad + 3) ** 2:
            put(x, y, 255, 230, 250)
for y in range(cy - 36, cy - 18):
    for x in range(cx - 30, cx - 8):
        if (x - (cx - 19)) ** 2 + (y - (cy - 27)) ** 2 <= 100:
            put(x, y, 255, 220, 245)

# Dark panel behind the lettering.
rect(10, 178, 246, 240, 8, 8, 18)
rect(12, 180, 244, 238, 20, 12, 32)

FONT = {
    "W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
}


def draw_text(text, x, y, scale, r, g, b):
    cx = x
    for ch in text:
        glyph = FONT.get(ch)
        if glyph:
            for gy, row in enumerate(glyph):
                for gx, bit in enumerate(row):
                    if bit == "1":
                        rect(cx + gx * scale, y + gy * scale,
                             cx + (gx + 1) * scale, y + (gy + 1) * scale, r, g, b)
        cx += 6 * scale


draw_text("WAKU", 18, 188, 4, 255, 226, 60)
draw_text("WAKU 7", 150, 198, 2, 250, 250, 250)

raw = bytearray()
for y in range(H):
    raw.append(0)
    raw += px[y * W * 3:(y + 1) * W * 3]


def chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data +
            struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))


out = b"\x89PNG\r\n\x1a\n"
out += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
out += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
out += chunk(b"IEND", b"")

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wakuwak7.png")
with open(path, "wb") as f:
    f.write(out)
print("wrote", path, len(out), "bytes")
