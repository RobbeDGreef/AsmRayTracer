include "rt/mat/mat.inc"
include "rt/vec.inc"
include "rt/texture/texture.inc"

struc Glass
    mat Mat ?
    texture dd ?    ;; texture pointer
    refraction_index dd ?
ends Glass

GLOBAL glass_init:PROC ;; void glass_init(Glass* lam, Texture* tex)