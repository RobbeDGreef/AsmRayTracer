IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "rt/vec.inc"

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

proc vec_set_rgb
    arg @@v:dword, @@r:dword, @@g:dword, @@b:dword 
    uses eax
    mov eax, [@@v]
    fild [@@r]
    fdiv [float_max_char]
    fstp [eax+Vec.x]
    fild [@@g]
    fdiv [float_max_char]
    fstp [eax+Vec.y]
    fild [@@b]
    fdiv [float_max_char]
    fstp [eax+Vec.z]
    ret
endp vec_set_rgb

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
    uses ebx, ecx

    mov ebx, [@@v1]
    mov ecx, [@@v2]
    
    call feq, [ebx+Vec.x], [ecx+Vec.x]
    cmp eax, 1
    jne @@end
    
    call feq, [ebx+Vec.y], [ecx+Vec.y]
    cmp eax, 1
    jne @@end
    
    call feq, [ebx+Vec.z], [ecx+Vec.z]
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
    fmulp
    fld [eax+Vec.y]
    fld [ebx+Vec.y]
    fmulp
    faddp
    fld [eax+Vec.z]
    fld [ebx+Vec.z]
    fmulp
    faddp

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

proc vec_div_int
    arg @@v:PTR Vec, @@i:dword
    local @@temp:dword

    fld1
    fidiv [@@i]
    fstp [@@temp]
    call vec_mul_float, [@@v], [@@temp]
    ret
endp vec_div_int

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
    fsubp
    fstp [eax+Vec.x]

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

proc vec_sqrt
    arg @@v:PTR Vec
    uses eax
    
    mov eax, [@@v]
    fld [eax+Vec.x]
    fld [eax+Vec.y]
    fld [eax+Vec.z]
    fsqrt
    fstp [eax+Vec.z]
    fsqrt
    fstp [eax+Vec.y]
    fsqrt
    fstp [eax+Vec.x]

    ret
endp vec_sqrt

proc vec_mul
    arg @@dest:PTR Vec, @@v1:PTR Vec, @@v2:PTR Vec
    local @@temp:dword
    uses eax, ebx, ecx, edx
    mov eax, [@@dest]
    mov ebx, [@@v1]
    mov ecx, [@@v2]

    fld [ebx+Vec.x]
    fmul [ecx+Vec.x]
    fstp [eax+Vec.x]

    fld [ebx+Vec.y]
    fmul [ecx+Vec.y]
    fstp [eax+Vec.y]

    fld [ebx+Vec.z]
    fmul [ecx+Vec.z]
    fstp [eax+Vec.z]
    ret
endp vec_mul

proc vec_random
    arg @@v:PTR Vec, @@min:dword, @@max:dword
    local @@temp:dword

    call random_float_ranged, [@@min], [@@max]
    call random_float_ranged, [@@min], [@@max]
    call random_float_ranged, [@@min], [@@max]

    fstp [@@temp]
    push [@@temp]
    fstp [@@temp]
    push [@@temp]
    fstp [@@temp]
    push [@@temp]
    push [@@v]
    call vec_set
    add esp, 16 

    ret
endp vec_random

;; We generate a random vector in a unit sphere
;; essentially we just choose 3 random vectors
;; and if its length squared is lower than 1 it 
;; is in the unit vector (since x^2 + y^2 + z^2 = r^2)
;; WARNING: TRASHES EAX 
;; WARNING: HIGHLY OPTIMIZED, DONT CALL DIRECTLY
vec_random_in_unit_sphere:
    push [float_1]
    push [float_minus_1]
    push [esp+12]
@@check_loop:
    call vec_random
    call vec_length_squared
    call flt, eax, [float_1]
    cmp eax, 1
    jne @@check_loop
    add esp, 12
    ret

proc vec_random_unit_vec
    arg @@v:PTR Vec
    uses eax

    call vec_random_in_unit_sphere, [@@v]
    call vec_length, [@@v]
    call vec_div_float, [@@v], eax

    ret
endp vec_random_unit_vec

proc vec_random_in_hemisphere
    arg @@v:PTR Vec, @@normal:PTR Vec
    local @@temp:dword

    call vec_random_in_unit_sphere, [@@v]
    call vec_dot, [@@v], [@@normal]
    mov [@@temp], eax
    call flt, [float_0], [@@temp]
    cmp eax, 1
    je @@end
    call vec_mul_float, [@@v], [float_minus_1]
    
@@end:
    ret
endp vec_random_in_hemisphere

proc vec_get_idx
    arg @@v:PTR Vec, @@idx:dword
    uses ebx, ecx

    mov ebx, [@@v]
    mov ecx, [@@idx]
    mov eax, [ebx+ecx*4]

    ret
endp vec_get_idx

proc vec_set_idx
    arg @@v:PTR Vec, @@idx:dword, @@value:dword
    uses eax, ebx, ecx

    mov eax, [@@value]
    mov ebx, [@@v]
    mov ecx, [@@idx]
    mov [ebx+ecx*4], eax

    ret
endp vec_set_idx

proc vec_min_values
    arg @@res:PTR Vec, @@v1:PTR Vec, @@v2:PTR Vec
    uses eax, ebx, ecx

    mov ecx, 0
@@min_loop:
    cmp ecx, 3
    je @@end

    ;; Essentially what we do here is:
    ;; res[i] = fmin(v1[i], v2[i])
    call vec_get_idx, [@@v1], ecx
    mov ebx, eax
    call vec_get_idx, [@@v2], ecx
    call fmin, ebx, eax
    call vec_set_idx, [@@res], ecx, eax 

    inc ecx
    jmp @@min_loop

@@end:
    ret
endp vec_min_values

proc vec_max_values
    arg @@res:PTR Vec, @@v1:PTR Vec, @@v2:PTR Vec
    uses eax, ebx, ecx

    mov ecx, 0
@@min_loop:
    cmp ecx, 3
    je @@end

    ;; Essentially what we do here is:
    ;; res[i] = fmax(v1[i], v2[i])
    call vec_get_idx, [@@v1], ecx
    mov ebx, eax
    call vec_get_idx, [@@v2], ecx
    call fmax, ebx, eax
    call vec_set_idx, [@@res], ecx, eax 

    inc ecx
    jmp @@min_loop

@@end:
    ret
endp vec_max_values

DATASEG
    ;; Kinda breaks abstraction but it has enough padding to handle future 
    ;; enlargement of vector (even though that will never happen)
    nullvec dd 0.0, 0.0, 0.0, 0.0, 0.0
    vec_print_x_str db "x: ", 0
    vec_print_y_str db " y: ", 0
    vec_print_z_str db " z: ", 0

END