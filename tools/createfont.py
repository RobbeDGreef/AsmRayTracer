import os
import cursor
#import font

#fontfile = "FONT.BIN"
cursorfile = "CURSOR.BIN"

with open(cursorfile, "wb+") as f:
    #for i in range(32):
    #    f.write(bytearray([0 for x in range(16)]))
    f.write(bytearray(cursor.cursor))
    f.close()
