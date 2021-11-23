IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat.inc"
include "rt/metal.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc metal_scatter
    arg @@mat:PTR Metal, @@in:PTR Ray, @@hit:PTR Hit, @@color:PTR Color,\
        @@out:PTR Ray
    local @@target:Vec, @@temp:Vec
    uses ebx, ecx

    ;; target = random_in_unit_vector(normal)
    mov ecx, [@@hit]
    lea ecx, [ecx+Hit.normal]
    
    ;; unit_vector(in.direction()) - 2(unit_vector(in.direction) * hit.normal) 
    ;;                                                             * hit.normal
    
    ;; udir - 2 (udir dot normal) * normal
    ;; target = udir
    ;; temp = normal
    ;; eax = target dot normal
    ;; temp * eax
    ;; temp * 2
    ;; target -= temp

    mov eax, [@@in]
    lea eax, [eax+Ray.direction]
    lea ebx, [@@target]
    call vec_cpy, ebx, eax
    call vec_length, ebx
    call vec_div_float, ebx, eax

    mov eax, [@@hit]
    lea eax, [eax+Hit.normal]
    lea ecx, [@@temp]
    call vec_cpy, ecx, eax

    call vec_dot, ebx, ecx
    call vec_mul_float, ecx, eax
    call vec_mul_float, ecx, [float_2]
    call vec_sub, ebx, ebx, ecx

    mov ecx, [@@out]
    mov eax, [@@hit]
    lea eax, [eax+Hit.hit_point]
    call ray_set, ecx, eax, ebx

    mov ebx, [@@mat]
    lea ebx, [ebx+Metal.color]
    call vec_cpy, [@@color], ebx

    mov eax, 1
    ret
endp metal_scatter

proc metal_init
    arg @@mat:PTR Metal, @@color:PTR Color
    uses eax, ebx

    call mat_init, [@@mat], offset metal_scatter, 0
    
    mov eax, [@@mat]
    mov ebx, [@@color]
    lea eax, [eax+Metal.color]
    call vec_cpy, eax, ebx

    ret
endp metal_init


END