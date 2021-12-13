IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat/mat.inc"

CODESEG

proc mat_init
    arg @@mat:PTR Mat, @@scatter:dword, @@emission:dword
    uses eax, ebx, ecx
    
    ;; Simply sets the scatter and emission variables in the structure

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