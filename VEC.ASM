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

    push ds
    pop es

    mov edi, [@@dest]
    mov esi, [@@src]
    mov ecx, 3
    rep movsd
    
    ret
endp vec_cpy

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


END