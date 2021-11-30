include "rt/texture/texture.inc"
include "rt/vec.inc"

struc Tiles
    texture Texture ?
    primary_color Color ?
    secondary_color Color ?
    scale dword ?
ends Tiles

GLOBAL tiles_init:PROC ;; void tiles_init(Tiles* tex, Color* primary, Color* secondary, float scale)