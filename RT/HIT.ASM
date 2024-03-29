IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/hit.inc"
include "rt/ray.inc"
include "rt/vec.inc"
include "utils.inc"

CODESEG

proc hit_cpy
    arg @@dest:PTR Hit, @@src:PTR Hit
    uses edi, esi, ecx

    ;; Simple copy function
    mov ecx, size Hit
    shr ecx, 2          ;; / 4    
    mov edi, [@@dest]
    mov esi, [@@src]
    rep movsd

    ret
endp hit_cpy

;; Calculate whether or not we hit the front of the face or the back
proc hit_calc_hit_front
    arg @@hit:PTR Hit, @@ray:PTR Ray
    uses eax, ebx, ecx

    mov ebx, [@@hit]
    mov [ebx+Hit.hit_front], 1

    ;; If our ray_direction * normal > 0 we hit the inside of our object and we
    ;; need to flip it. (we want normals to always point out)
    mov eax, [@@ray]
    lea eax, [eax+Ray.direction]
    lea ecx, [ebx+Hit.normal]
    call vec_dot, eax, ecx
    call flt, [float_0], eax
    cmp eax, 1
    je @@flip_normals
    jmp @@end

@@flip_normals:
    ;call log_char, 'F'
    mov [ebx+Hit.hit_front], 0
    lea eax, [ebx+Hit.normal]
    call vec_mul_float, eax, [float_minus_1]

@@end:
    ret
endp hit_calc_hit_front

END