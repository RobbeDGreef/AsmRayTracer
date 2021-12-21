IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat/mat.inc"
include "rt/mat/lmbrtian.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc lambertian_scatter
    arg @@mat:PTR Lambertian, @@in:PTR Ray, @@hit:PTR Hit, @@color:PTR Color,\
        @@out:PTR Ray
    local @@target:Vec
    uses ebx, ecx

    ;; Lambertian (diffuse) materials always scatter a new ray in a random 
    ;; direction. This gives the diffuse or 'mat' effect. 

    ;; target = random_in_unit_vector(normal)
    mov ecx, [@@hit]
    lea ecx, [ecx+Hit.normal]
    lea ebx, [@@target]
    call vec_random_in_hemisphere, ebx, ecx
    
    ;; Catch null vectors. These will give us a hard time in calculations so we
    ;; will just get rid of them entirely.
    call vec_eq, ebx, offset nullvec
    cmp eax, 1
    jne @@not_null
    call vec_cpy, ebx, ecx

@@not_null:
    ;; Now set the ray location to the hit point on the material and the new
    ;; random direction.
    mov ecx, [@@out]
    mov eax, [@@hit]
    lea eax, [eax+Hit.hit_point]
    call ray_set, ecx, eax, ebx

    ;; And lastly invoke the texture 
    mov ebx, [@@mat]
    mov ebx, [ebx+Lambertian.texture]
    mov ecx, [@@hit]
    call [ebx+Texture.get_color], ebx, [ecx+Hit.u], [ecx+Hit.v], [@@color]

    ;; Since diffuse materials ALWAYS scatter and should get effected by 
    ;; emission return 1. See renderer cast_ray for more information on return 
    ;; values.
    mov eax, 1
    ret
endp lambertian_scatter

proc lambertian_init
    arg @@mat:PTR Lambertian, @@tex:PTR Texture
    uses eax, ebx
 
    call mat_init, [@@mat], offset lambertian_scatter, 0

    mov eax, [@@mat]
    mov ebx, [@@tex]
    mov [eax+Lambertian.texture], ebx

    ret
endp lambertian_init

END