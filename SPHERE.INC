include "object.inc"

struc Sphere
    obj Object ?
    radius dd ?      ;; float radius
ends Sphere

GLOBAL sphere_set:PROC ;; sphere_set(Sphere* sphere, Point* location, float radius)