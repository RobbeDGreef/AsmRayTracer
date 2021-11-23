include "rt/mat/mat.inc"
include "rt/vec.inc"

struc Metal
    mat Mat ?
    color Color ?
ends Metal

GLOBAL metal_init:PROC ;; void metal_init(Metal* lam, Color* col)