IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "vec.inc"
include "utils.inc"

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

;; Copy the src vector into the destination vector
proc vec_cpy
    arg @@dest:PTR Vec, @@src:PTR Vec
    uses edi, esi, ecx

    mov edi, [@@dest]
    mov esi, [@@src]
    mov ecx, 3
    rep movsd
    
    ret
endp vec_cpy

proc vec_print
    arg @@v:PTR Vec
    uses eax
    mov eax, [@@v]
    call print_str, offset vec_print_x_str
    call print_float, [eax+Vec.x]
    call print_str, offset vec_print_y_str
    call print_float, [eax+Vec.y]
    call print_str, offset vec_print_z_str
    call print_float, [eax+Vec.z]
    
    ret
endp vec_print

;; Tests the vectors against each other to check if they
;; are equal. If they are 1 will be returned, 0 otherwise.
proc vec_eq
    arg @@v1:PTR Vec, @@v2:PTR Vec
    uses ebx, ecx, edi, esi

    xor eax, eax
    
    mov edi, [@@v1]
    mov esi, [@@v2]
    
    mov ebx, [edi+Vec.x]
    mov ecx, [esi+Vec.x]
    call feq, ebx, ecx
    cmp eax, 1
    jne @@end
    
    mov ebx, [edi+Vec.y]
    mov ecx, [esi+Vec.y]
    call feq, ebx, ecx
    cmp eax, 1
    jne @@end
    
    mov ebx, [edi+Vec.z]
    mov ecx, [esi+Vec.z]
    call feq, ebx, ecx
@@end:
    ret
endp vec_eq

proc vec_get_x
    arg @@v:PTR Vec returns eax
    uses ebx

    mov ebx, [@@v]
    mov eax, [ebx+Vec.x]
    ret
endp vec_get_x

proc vec_get_y
    arg @@v:PTR Vec returns eax
    uses ebx

    mov ebx, [@@v]
    mov eax, [ebx+Vec.y]
    ret
endp vec_get_y

proc vec_get_z
    arg @@v:PTR Vec returns eax
    uses ebx

    mov ebx, [@@v]
    mov eax, [ebx+Vec.z]
    ret
endp vec_get_z

proc vec_set_x
    arg @@v:PTR Vec, @@f:dword
    uses eax, ebx

    mov eax, [@@v]
    mov ebx, [@@f]
    mov [eax+Vec.x], ebx
    ret
endp vec_set_x

proc vec_set_y
    arg @@v:PTR Vec, @@f:dword
    uses eax, ebx

    mov eax, [@@v]
    mov ebx, [@@f]
    mov [eax+Vec.y], ebx
    ret
endp vec_set_y

proc vec_set_z
    arg @@v:PTR Vec, @@f:dword
    uses eax, ebx

    mov eax, [@@v]
    mov ebx, [@@f]
    mov [eax+Vec.z], ebx
    ret
endp vec_set_z

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
    uses eax, ebx, ecx, edx
    mov eax, [@@dest]
    mov ebx, [@@v1]
    mov ecx, [@@v2]

    fld [ebx+Vec.x]
    fsub [ecx+Vec.x]
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.x], edx

    fld [ebx+Vec.y]
    fsub [ecx+Vec.y]
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.y], edx

    fld [ebx+Vec.z]
    fsub [ecx+Vec.z]
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.z], edx
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
    uses eax

    mov eax, [@@v]

    fld [eax+Vec.x]
    fmul [@@f]
    fstp [eax+Vec.x]

    fld [eax+Vec.y]
    fmul [@@f]
    fstp [eax+Vec.y]

    fld [eax+Vec.z]
    fmul [@@f]
    fstp [eax+Vec.z]
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

proc vec_cross
    arg @@dest:PTR Vec, @@v1:PTR Vec, @@v2:PTR Vec 
    local @@temp:dword
    uses eax, ebx, ecx, edx

    mov eax, [@@dest]
    mov ebx, [@@v1]
    mov ecx, [@@v2]

    fld [ebx+Vec.y]
    fmul [ecx+Vec.z]
    fld [ebx+Vec.z]
    fmul [ecx+Vec.y]
    fsub
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.x], edx

    fld [ebx+Vec.z]
    fmul [ecx+Vec.x]
    fld [ebx+Vec.x]
    fmul [ecx+Vec.z]
    fsub
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.y], edx

    fld [ebx+Vec.x]
    fmul [ecx+Vec.y]
    fld [ebx+Vec.y]
    fmul [ecx+Vec.x]
    fsub
    fstp [@@temp]
    mov edx, [@@temp]
    mov [eax+Vec.z], edx
    ret
endp vec_cross

DATASEG
    vec_print_x_str db "x: ", 0
    vec_print_y_str db " y: ", 0
    vec_print_z_str db " z: ", 0

END