IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/texture/solid.inc"
include "rt/texture/texture.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc get_color
    arg @@tex:PTR Solid, @@u:dword, @@v:dword, @@dest_color:PTR Color
    
    ;; Simple: return the color

    mov eax, [@@tex]
    lea eax, [eax+Solid.color]
    call vec_cpy, [@@dest_color], eax

    mov eax, 1
    ret
endp get_color

proc solid_init
    arg @@tex:PTR Solid, @@color:PTR Color
    uses eax

    call texture_init, [@@tex], offset get_color

    mov eax, [@@tex]
    lea eax, [eax+Solid.color]
    call vec_cpy, eax, [@@color]

    ret
endp solid_init


END