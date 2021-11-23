include "rt/mat/mat.inc"
include "rt/vec.inc"

struc Unlit
    mat Mat ?
    color Color ?
ends Unlit

GLOBAL unlit_init:PROC ;; void unlit_init(Unlit* lam, Color* col)