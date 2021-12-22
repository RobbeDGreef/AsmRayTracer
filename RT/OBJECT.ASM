IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/object.inc"
include "rt/mat/mat.inc"

CODESEG

proc object_set
    arg @@obj:PTR Object, @@hit_function:dword, @@mat:PTR Mat
    uses eax, ebx

    ;; Simply sets the values in the object struct.
    mov eax, [@@obj]
    mov ebx, [@@hit_function]
    mov [eax+Object.hit_function], ebx

    mov eax, [@@obj]
    mov ebx, [@@mat]
    mov [eax+Object.material], ebx

    ret
endp object_set

END