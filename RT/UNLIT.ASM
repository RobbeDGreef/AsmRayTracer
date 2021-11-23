IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat.inc"
include "rt/unlit.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc unlit_scatter
    arg @@mat:PTR Unlit, @@in:PTR Ray, @@hit:PTR Hit, @@color:PTR Color,\
        @@out:PTR Ray
    uses ebx

    mov ebx, [@@mat]
    lea ebx, [ebx+Unlit.color]
    call vec_cpy, [@@color], ebx

    mov eax, 0
    ret
endp unlit_scatter

proc unlit_init
    arg @@mat:PTR Unlit, @@color:PTR Color
    uses eax, ebx

    call mat_init, [@@mat], offset unlit_scatter, 0
    mov eax, [@@mat]
    mov ebx, [@@color]
    lea eax, [eax+Unlit.color]
    call vec_cpy, eax, ebx

    ret
endp unlit_init


END