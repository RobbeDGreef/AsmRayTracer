include "rt/texture/texture.inc"
include "rt/vec.inc"

struc Solid
    texture Texture ?
    color Color ?
ends Solid

GLOBAL solid_init:PROC ;; void solid_init(Solid* tex, Color* color)