include "rt/texture/texture.inc"
include "rt/vec.inc"

struc Image
    texture Texture ?
    buffer dd ?
    width dd ?
    height dd ?
ends Image

GLOBAL image_init:PROC ;; void image_init(Image* tex, const char* imagepath)