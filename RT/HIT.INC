include "rt/vec.inc"

struc Hit
    hit_point Point ?
    normal Vec ?
    t dd ?              ;; float
    hit_front dd ?      ;; boolean
    hit_mat dd ?        ;; pointer to the hit material
ends Hit