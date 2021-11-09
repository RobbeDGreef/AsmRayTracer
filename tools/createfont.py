import os
import font

fontfile = "FONT"

empty_cell = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
]

full_cell = [
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
]

with open(fontfile, "wb+") as f:
    for i in range(32):
        f.write(bytearray(empty_cell))
    f.write(bytearray(font.MonospaceFont_16_bitmap))
    f.close()
