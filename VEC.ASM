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

proc vec_add
    arg @@dest:PTR Vec, @@v1:PTR Vec, @@v2:PTR Vec
    local @@temp:dword
    uses eax, ebx, ecx, edx
    mov eax, [@@dest]
    mov ebx, [@@v1]
    mov ecx, [@@v2]

    fld [ebx+Vec.x]
    fadd [ecx+Vec.x]
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.x], edx

    fld [ebx+Vec.y]
    fadd [ecx+Vec.y]
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.y], edx

    fld [ebx+Vec.z]
    fadd [ecx+Vec.z]
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.z], edx
    ret
endp vec_add  

proc vec_sub
    arg @@dest:PTR Vec, @@v1:PTR Vec, @@v2:PTR Vec
    local @@temp:dword

    fld1
    fchs
    fstp [@@temp]

    call vec_mul_float, [@@v2], [@@temp]

    call vec_add, [@@dest], [@@v1], [@@v2]
    ret
endp vec_sub

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
    fmul [@@f]
    fstp [@@temp]
    mov ebx, [@@temp]
    mov [eax+Vec.x], ebx

    fld [eax+Vec.y]
    fmul [@@f]
    fstp [@@temp]
    mov ebx, [@@temp]
    mov [eax+Vec.y], ebx

    fld [eax+Vec.z]
    fmul [@@f]
    fstp [@@temp]
    mov ebx, [@@temp]
    mov [eax+Vec.z], ebx
    ret
endp vec_mul_float

proc vec_div_float
    arg @@v:PTR Vec, @@f:dword 
    local @@temp:dword

    fld1
    fdiv [@@f]
    fstp [@@temp]
    call vec_mul_float, [@@v], [@@temp]
    ret
endp vec_div_float

proc vec_length
    arg @@v:PTR Vec returns eax
    local @@temp:dword

    mov eax, [@@v]

    fld [eax+Vec.x]
    fmul [eax+Vec.x]
    fld [eax+Vec.y]
    fmul [eax+Vec.y]
    fadd
    fld [eax+Vec.z]
    fmul [eax+Vec.z]
    fadd
    fsqrt

    fstp [@@temp]
    mov eax, [@@temp]
    ret
endp vec_length

proc vec_length_squared
    arg @@v:PTR Vec returns eax
    local @@temp:dword

    call vec_length, [@@v]
    mov [@@temp], eax
    
    fld [@@temp]
    fmul [@@temp]
    fstp [@@temp]
    mov eax, [@@temp]
    ret
endp vec_length_squared
END