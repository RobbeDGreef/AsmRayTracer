include "rt/mat.inc"
include "rt/vec.inc"

struc Emissive
    mat Mat ?
    color Color ?
ends Emissive

GLOBAL emissive_init:PROC ;; void emissive_init(Emissive* em, Color* col, float strength)