IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat/mat.inc"
include "rt/mat/metal.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc reflect
    arg @@out:PTR Vec, @@direction:PTR Vec, @@normal:PTR Vec
    local @@temp:Vec
    uses eax, ebx, ecx

    ;; A perfect reflective material will bounce a ray back over the normal
    ;; This is an easy calculation. 
    ;;
    ;; unit_vector(in.direction()) - 2(unit_vector(in.direction) * hit.normal) 
    ;;                                                             * hit.normal

    ;; udir - 2 (udir dot normal) * normal
    ;; target = udir
    ;; temp = normal
    ;; eax = target dot normal
    ;; temp * eax
    ;; temp * 2
    ;; target -= temp

    mov eax, [@@direction]
    mov ebx, [@@out]
    call vec_cpy, ebx, eax
    call vec_length, ebx
    call vec_div_float, ebx, eax

    mov eax, [@@normal]
    lea ecx, [@@temp]
    call vec_cpy, ecx, eax

    call vec_dot, ebx, ecx
    call vec_mul_float, ecx, eax
    call vec_mul_float, ecx, [float_2]
    call vec_sub, ebx, ebx, ecx

    ret
endp reflect

proc metal_scatter
    arg @@mat:PTR Metal, @@in:PTR Ray, @@hit:PTR Hit, @@color:PTR Color,\
        @@out:PTR Ray
    local @@target:Vec
    uses ebx, ecx

    mov ecx, [@@hit]
    lea ecx, [ecx+Hit.normal]
    
    ;; This perfect metal material will return a ray perfectly bounced mirrored
    ;; over the normal line, esssentially bouncing it back perfectly.

    mov eax, [@@in]
    lea eax, [eax+Ray.direction]
    mov ecx, [@@hit]
    lea ecx, [ecx+Hit.normal]
    lea ebx, [@@target]
    call reflect, ebx, eax, ecx

    ;; Now set the out ray with the current hit point and the bounced ray.
    mov ecx, [@@out]
    mov eax, [@@hit]
    lea eax, [eax+Hit.hit_point]
    call ray_set, ecx, eax, ebx

    ;; And lastly invoke the texture 
    mov ebx, [@@mat]
    mov ebx, [ebx+Metal.texture]
    mov ecx, [@@hit]
    call [ebx+Texture.get_color], ebx, [ecx+Hit.u], [ecx+Hit.v], [@@color]

    ;; Metal materials always bounce back and are affected by emission so 1 is 
    ;; returned. Check renderer cast_ray for more information on return values 
    ;; of this function.
    mov eax, 1
    ret
endp metal_scatter

proc metal_init
    arg @@mat:PTR Metal, @@tex:PTR Texture
    uses eax, ebx

    call mat_init, [@@mat], offset metal_scatter, 0
    
    mov eax, [@@mat]
    mov ebx, [@@tex]
    mov [eax+Metal.texture], ebx

    ret
endp metal_init


END