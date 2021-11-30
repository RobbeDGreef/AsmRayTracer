include "rt/vec.inc"

struc Hit
    hit_point Point ?
    normal Vec ?
    t dd ?              ;; float, holds the t value of our ray_at function. 
    hit_front dd ?      ;; boolean
    hit_mat dd ?        ;; pointer to the hit material
    u dd ?              ;; UV coordinate (u)
    v dd ?              ;; UV coordinate (v)
ends Hit

GLOBAL hit_cpy:PROC     ;; void hit_cpy(Hit* dest, Hit* src)