include "rt/vec.inc"

struc Hit
    hit_point Point ?
    normal Vec ?
    t dd ?              ;; float
    hit_front dd ?      ;; boolean
ends Hit