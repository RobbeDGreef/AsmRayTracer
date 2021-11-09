import os
import font

fontfile = "FONT.BIN"

with open(fontfile, "wb+") as f:
    for i in range(32):
        f.write(bytearray([0 for x in range(16)]))
    f.write(bytearray(font.MonospaceFont16))
    f.close()
