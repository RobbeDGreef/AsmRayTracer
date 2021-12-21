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

    mov ebx, [@@hit]
    mov [ebx+Hit.hit_front], 1

    ;; If our ray_direction * normal > 0 we hit the inside of the sphere and we
    ;; need to flip our normal (we want our normal to always point out).
    mov eax, [@@ray]
    lea eax, [eax+Ray.direction]
    call vec_dot, eax, edx
    call flt, eax, [float_0]
    cmp eax, 1
    jne @@flip_normals
    jmp @@end

@@flip_normals:
    mov [ebx+Hit.hit_front], 0
    lea eax, [ebx+Hit.normal]
    call vec_mul_float, eax, [float_minus_1]

@@end:
    ret
endp hit_set_face_normal

END