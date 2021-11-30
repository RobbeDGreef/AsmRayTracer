IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/texture/texture.inc"
include "rt/vec.inc"

CODESEG

proc texture_init
    arg @@tex:PTR Texture, @@get_color:dword
    uses eax, ebx, ecx
    
    mov eax, [@@tex]
    mov ebx, [@@get_color]
    mov [eax+Texture.get_color], ebx

    ret
endp texture_init

END