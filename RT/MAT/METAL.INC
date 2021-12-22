include "rt/mat/mat.inc"
include "rt/vec.inc"
include "rt/texture/texture.inc"

struc Metal
    mat Mat ?
    texture dd ?    ;; texture pointer
ends Metal

GLOBAL metal_init:PROC ;; void metal_init(Metal* lam, Texture* tex)
GLOBAL reflect:PROC