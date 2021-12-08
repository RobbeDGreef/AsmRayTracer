include "rt/mat/mat.inc"
include "rt/texture/texture.inc"
include "rt/vec.inc"

struc Lambertian
    mat Mat ?
    texture dd ?    ;; texture pointer
ends Lambertian

GLOBAL lambertian_init:PROC ;; void lambertian_init(Lambertian* lam, Texture* col)