IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/vec.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc ray_set
    arg @@ray:PTR Ray, @@origin:PTR Point, @@direction:PTR Vec
    uses eax, ebx, ecx, edx, edi

    mov eax, [@@ray]
    mov ebx, [@@origin]
    mov ecx, [@@direction]

    lea edx, [eax+Ray.origin]
    lea edi, [eax+Ray.direction]
    call vec_cpy, edx, ebx
    call vec_cpy, edi, ecx

    ret
endp ray_set

proc ray_at
    arg @@ray:PTR Ray, @@res:PTR Point, @@t:dword
    uses eax, ebx, edx

    mov eax, [@@ray]
    mov ebx, [@@res]

    lea edx, [eax+Ray.direction]
    call vec_cpy, ebx, edx
    call vec_mul_float, ebx, [@@t]

    lea edx, [eax+Ray.origin]
    call vec_add, ebx, ebx, edx
    ret
endp ray_at

END