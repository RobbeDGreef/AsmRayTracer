include "rt/object.inc"
include "rt/vec.inc"

struc Triangle
    obj Object ?
    p1 dd ? ;; PTR to Point
    p2 dd ? ;; PTR to Point
    p3 dd ? ;; PTR to Point
ends Triangle

GLOBAL triangle_set:PROC ;; triangle_set(Triangle* triangle, Point* p1, Point* p2, Point* p3, Material* mat)