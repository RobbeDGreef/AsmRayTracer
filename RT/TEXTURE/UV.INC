include "rt/texture/texture.inc"
include "rt/vec.inc"

struc Uv
    texture Texture ?
ends Uv

GLOBAL uv_init:PROC ;; void uv_init(Uv* tex)
GLOBAL uv_get_color:PROC ;; usefull for debugging