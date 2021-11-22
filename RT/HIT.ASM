IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/hit.inc"

CODESEG

proc hit_cpy
    arg @@dest:PTR Hit, @@src:PTR Hit
    uses edi, esi, ecx

    mov ecx, size Hit
    shr ecx, 2          ;; / 4    
    mov edi, [@@dest]
    mov esi, [@@src]
    rep movsd

    ret
endp hit_cpy

END