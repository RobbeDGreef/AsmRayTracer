IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat.inc"

CODESEG

proc mat_init
    arg @@mat:PTR Mat, @@scatter:dword, @@emission:dword
    uses eax, ebx, ecx
    
    mov eax, [@@mat]
    lea ebx, [eax+Mat.scatter]
    mov ecx, [@@scatter]
    mov [ebx], ecx
    lea ebx, [eax+Mat.emission]
    mov ecx, [@@emission]
    mov [ebx], ecx

    ret
endp mat_init

END