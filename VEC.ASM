IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "vec.inc"

CODESEG

proc vec_set
    arg @@v:dword, @@x:dword, @@y:dword, @@z:dword 
    uses eax, ebx
    mov ebx, [@@v]
    mov eax, [@@x]
    mov [ebx+Vec.x], eax
    mov eax, [@@y]
    mov [ebx+Vec.y], eax
    mov eax, [@@z]
    mov [ebx+Vec.z], eax
    ret
endp vec_set

proc vec_dot
    arg @@v1:PTR Vec, @@v2:PTR Vec returns eax
    local @@temp:dword
    uses ebx

    mov eax, [@@v1]
    mov ebx, [@@v2]

    fld [eax+Vec.x]
    fld [ebx+Vec.x]
    fmul
    fld [eax+Vec.y]
    fld [ebx+Vec.y]
    fmul 
    fld [eax+Vec.z]
    fld [ebx+Vec.z]
    fmul 

    fadd
    fadd

    fstp [@@temp]
    mov eax, [@@temp]
    ret
endp vec_dot

proc vec_mul_float
    arg @@v:PTR Vec, @@f:dword 
    local @@temp:dword
    uses eax, ebx

    mov eax, [@@v]

    fld [eax+Vec.x]
    fld [@@f]
    fmul
    fstp [@@temp]
    mov ebx, [@@temp]
    mov [eax+Vec.x], ebx

    fld [eax+Vec.y]
    fld [@@f]
    fmul
    fstp [@@temp]
    mov ebx, [@@temp]
    mov [eax+Vec.y], ebx

    fld [eax+Vec.z]
    fld [@@f]
    fmul
    fstp [@@temp]
    mov ebx, [@@temp]
    mov [eax+Vec.z], ebx
    ret
endp vec_mul_float


END