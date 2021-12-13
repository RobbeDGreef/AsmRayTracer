IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/object.inc"
include "rt/mat.inc"

CODESEG

proc object_set
    arg @@obj:PTR Object, @@point:PTR Point, @@hit_function:dword, @@mat:PTR Mat
    uses eax, ebx

    ;; Simply sets the values in the object struct.

    mov eax, [@@obj]
    lea eax, [eax+Object.location]
    mov ebx, [@@point]
    call vec_cpy, eax, ebx

    mov eax, [@@obj]
    mov ebx, [@@hit_function]
    mov [eax+Object.hit_function], ebx

    mov eax, [@@obj]
    mov ebx, [@@mat]
    mov [eax+Object.material], ebx

    ret
endp object_set

END