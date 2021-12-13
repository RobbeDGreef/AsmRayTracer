include "rt/mat.inc"
include "rt/vec.inc"

struc Lambertian
    mat Mat ?
    color Color ?
ends Lambertian

GLOBAL lambertian_init:PROC ;; void lambertian_init(Lambertian* lam, Color* col)