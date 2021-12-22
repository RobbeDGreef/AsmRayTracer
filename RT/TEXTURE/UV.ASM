IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/texture/uv.inc"
include "rt/texture/texture.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc uv_get_color
    arg @@tex:PTR Uv, @@u:dword, @@v:dword, @@dest_color:PTR Color
    
    call vec_set, [@@dest_color], [@@u], [@@v], [float_0_90]
    mov eax, 1
    ret
endp uv_get_color

proc uv_init
    arg @@tex:PTR Uv, @@color:PTR Color
    call texture_init, [@@tex], offset uv_get_color
    ret
endp uv_init

END