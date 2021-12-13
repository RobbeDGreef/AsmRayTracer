include "rt/object.inc"

struc Sphere
    obj Object ?
    radius dd ?      ;; float radius
ends Sphere

GLOBAL sphere_calc_coords:PROC
GLOBAL sphere_set:PROC ;; sphere_set(Sphere* sphere, Point* location, float radius, Mat* mat)