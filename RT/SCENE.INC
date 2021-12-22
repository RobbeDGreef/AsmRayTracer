include "rt/object.inc"

struc BvhNode
    obj Object ?
    left dd ?       ;; Left pointer (hitable pointer)
    right dd ?      ;; right pointer (hitable pointer)
ends BvhNode

struc Scene
    head dd ?
ends Scene

GLOBAL scene_init:PROC  ;; void scene_init(Scene* scene)
GLOBAL scene_add:PROC   ;; void scene_add(Scene* scene, Object* object)
GLOBAL scene_hit:PROC   ;; bool scene_hit(Scene* scene, Ray* r, float t_min, float t_max, Hit* hit);
GLOBAL scene_build_bvh:PROC ;; void scene_build_bvh(Scene *scene)