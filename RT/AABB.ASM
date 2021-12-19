IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/aabb.inc"
include "rt/vec.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc aabb_set
    arg @@box:PTR Aabb, @@min:PTR Point, @@max:PTR Point
    uses eax, ebx

    ;; Store the minimum and maximum points

    mov eax, [@@box]
    
    lea ebx, [eax+Aabb.min]
    call vec_cpy, ebx, [@@min]

    lea ebx, [eax+Aabb.max]
    call vec_cpy, ebx, [@@max]

    ret
endp aabb_set

proc aabb_surrounding
    arg @@res:PTR Aabb, @@b1:PTR Aabb, @@b2:PTR Aabb
    local @@min:Point, @@max:Point
    uses eax, ebx, ecx

    ;; Calculate the new minimum.
    ;; Simply take the minimum values of each axis
    ;; from box 1 and 2
    lea eax, [@@min]
    mov ebx, [@@b1]
    lea ebx, [ebx+Aabb.min]
    mov ecx, [@@b2]
    lea ecx, [ecx+Aabb.min]
    call vec_min_values, eax, ebx, ecx

    ;; Calculate the new maximum. Same as before but now 
    ;; take the maximum values
    lea eax, [@@max]
    mov ebx, [@@b1]
    lea ebx, [ebx+Aabb.max]
    mov ecx, [@@b2]
    lea ecx, [ecx+Aabb.max]
    call vec_max_values, eax, ebx, ecx

    ;; Set new aabb with our new min and max
    lea eax, [@@min]
    lea ebx, [@@max]
    call aabb_set, [@@res], eax, ebx

    ret
endp aabb_surrounding

proc aabb_hit
    arg @@box:PTR Aabb, @@ray:PTR Ray, @@t_min:dword, @@t_max:dword
    local @@temp:dword, @@inv_d:dword, @@t0:dword, @@t1:dword
    uses ebx, ecx, edx, edi

    mov edx, [@@box]
    mov ebx, [@@ray]

    ;; This algorithm was taken from 
    ;; https://raytracing.github.io/books/RayTracingTheNextWeek.html#boundingvolumehierarchies/anoptimizedaabbhitmethod

    mov ecx, 0
@@axis_loop:
    cmp ecx, 3
    je @@end_success

    ;; inverted_direction = 1 / ray.direction
    lea eax, [ebx+Ray.direction]
    call vec_get_idx, eax, ecx
    mov [@@temp], eax
    fld1
    fdiv [@@temp]
    fstp [@@inv_d]

    ;; t0 = (box.min[i] - ray.origin[i]) * inv_d
    lea eax, [edx+Aabb.min]
    call vec_get_idx, eax, ecx
    mov [@@temp], eax
    fld [@@temp]

    lea eax, [ebx+Ray.origin]
    call vec_get_idx, eax, ecx
    mov [@@temp], eax
    fld [@@temp]

    fsubp
    fmul [@@inv_d]
    fstp [@@t0]
    
    ;; t1 = (box.max[i] - ray.origin[i]) * inv_d
    lea eax, [edx+Aabb.max]
    call vec_get_idx, eax, ecx
    mov [@@temp], eax
    fld [@@temp]

    lea eax, [ebx+Ray.origin]
    call vec_get_idx, eax, ecx
    mov [@@temp], eax
    fld [@@temp]

    fsubp
    fmul [@@inv_d]
    fstp [@@t1]

    ;; if inverted_d is smaller than 0, flip t0 and t1
    call flt, [@@inv_d], [float_0]
    cmp eax, 1
    jne @@compare_t0

    ;; Swap t0 and t1
    mov edi, [@@t0]
    mov eax, [@@t1]
    mov [@@t0], eax
    mov [@@t1], edi

@@compare_t0:
    call flt, [@@t0], [@@t_min]
    cmp eax, 1
    je @@compare_t1

    mov eax, [@@t0]
    mov [@@t_min], eax 

@@compare_t1:
    call flt, [@@t1], [@@t_max]
    cmp eax, 1
    jne @@compare_tminmax

    mov eax, [@@t1]
    mov [@@t_max], eax 

@@compare_tminmax:
    call flt, [@@t_max], [@@t_min]
    cmp eax, 1
    je @@end_failed

    inc ecx
    jmp @@axis_loop

@@end_failed:
    mov eax, 0
    jmp @@end

@@end_success:
    mov eax, 1

@@end:
    ret
endp aabb_hit

END