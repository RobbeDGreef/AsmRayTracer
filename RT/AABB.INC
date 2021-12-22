include "rt/vec.inc"

struc Aabb
    min Point ?
    max Point ?
ends Aabb

GLOBAL aabb_surrounding:PROC ;; aabb_surrounding(Aabb* ret, Aabb* b1, Aabb* b2)
GLOBAL aabb_set:PROC         ;; aabb_set(Aabb* box, Point* min, Point* max)
GLOBAL aabb_hit:PROC         ;; aabb_hit(Aabb* box, Ray* r, float t_min, float t_max)
