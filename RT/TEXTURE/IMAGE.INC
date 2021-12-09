include "rt/texture/texture.inc"
include "rt/vec.inc"

struc Image
    texture Texture ?
    buffer dd ?
    width dd ?
    height dd ?
ends Image

GLOBAL image_get_color:PROC ;; void image_get_color(Image* tex, float u, float v, Color* dest_color)
GLOBAL image_init:PROC ;; void image_init(Image* tex, const char* imagepath)