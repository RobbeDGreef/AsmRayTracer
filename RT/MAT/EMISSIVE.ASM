IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat/mat.inc"
include "rt/mat/emissive.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc emissive_scatter
    arg @@mat:PTR Emissive, @@in:PTR Ray, @@hit:PTR Hit, @@color:PTR Color,\
        @@out:PTR Ray
    
    ;; Emissive materials are basically unlit materials so we just copy the 
    ;; color and stop bouncing.
    mov eax, [@@mat]
    lea eax, [eax+Emissive.color]
    call vec_cpy, [@@color], eax

    ;; Don't bounce, don't calculate the emissiveness on itself.
    mov eax, -1
    ret
endp emissive_scatter

proc emission
    arg @@mat:PTR Emissive, @@ray:PTR Ray, @@hit:PTR Hit, @@color:PTR Color
    uses ebx

    ;; Set the emissive color to its own color * strength
    ;; note: this is calculated once in the constructor.
    mov ebx, [@@mat]
    lea ebx, [ebx+Emissive.emission_color]
    call vec_cpy, [@@color], ebx

    ret
endp emission

proc emissive_init
    arg @@mat:PTR Emissive, @@color:PTR Color, @@strength:dword
    uses eax, ebx

    call mat_init, [@@mat], offset emissive_scatter, offset emission
    
    ;; Set the emission color
    mov eax, [@@mat]
    lea eax, [eax+Emissive.color]
    call vec_cpy, eax, [@@color]
    
    ;; Calculate the emission color * strength once and save it, instead of 
    ;; calculating it each time we hit an emissive material.
    lea eax, [@@mat] 
    lea eax, [eax+Emissive.emission_color]
    call vec_cpy, eax, [@@color]
    call vec_mul_float, eax, [@@strength]

    ret
endp emissive_init


END