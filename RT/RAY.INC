include "rt/vec.inc"

struc Ray
    origin Point ?
    direction Vec ?
ends Ray

GLOBAL ray_set:PROC         ;; void ray_set(Ray* r, Point* origin, Vec* dir)
GLOBAL ray_at:PROC          ;; void ray_at(Ray* r, Point* result, float t)
