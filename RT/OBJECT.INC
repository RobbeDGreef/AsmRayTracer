include "rt/vec.inc"

struc Object
    ;; hit_function is a function pointer to the start of a function that has 
    ;; prototype: int hit_function(Object* this, Ray* r, float t_min, float t_max, Hit*)
    hit_function dd ?
    material dd ?
ends Object

GLOBAL object_set:PROC  ;; object_set(Object* obj, Point* location, function* hit_function, Mat* mat)