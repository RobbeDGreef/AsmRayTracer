include "rt/object.inc"

struc SceneElement
    object dd ?
    next dd ?
ends SceneElement

struc Scene
    head dd ?
ends Scene

GLOBAL scene_init:PROC  ;; void scene_init(Scene* scene)
GLOBAL scene_add:PROC   ;; void scene_add(Scene* scene, Object* object)
GLOBAL scene_hit:PROC   ;; bool scene_hit(Scene* scene, Ray* r, float t_min, float t_max, Hit* hit);
