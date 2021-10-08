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

<<<<<<< HEAD
<<<<<<< Updated upstream
=======
=======
>>>>>>> b49b0fb94ffdd06bc6b28772786103b38494ce73
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

<<<<<<< HEAD
proc vec_div_float
    arg @@v:PTR Vec, @@f:dword 
    local @@temp:dword

    fld1
    fdiv [@@f]
    fstp [@@temp]
    call vec_mul_float, [@@v], [@@temp]
    ret
endp vec_div_float


>>>>>>> Stashed changes
=======

>>>>>>> b49b0fb94ffdd06bc6b28772786103b38494ce73
END