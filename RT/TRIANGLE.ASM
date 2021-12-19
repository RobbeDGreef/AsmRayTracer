eIDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "rt/vec.inc"
include "rt/ray.inc"
include "rt/triangle.inc"
include "rt/object.inc"
include "rt/hit.inc"
include "rt/mat/mat.inc"

CODESEG

proc hit_triangle
    arg @@object:PTR Object, @@ray:PTR Ray, @@t_min:dword, @@t_max:dword,\
        @@hit:PTR Hit
    local @@edge1:Vec, @@edge2:Vec, @@pvec:Vec, @@tvec:Vec, @@temp:dword,\
          @@u:dword, @@v:dword, @@qvec:Vec, @@inv_d:dword
    uses ebx, ecx, edx, edi, esi

    ;; Moller-Trumbore intersection algorithm
    ;; c++ example code taken from my own c++ raytracer codebase
    ;; https://github.com/RobbeDGreef/CppPathTracer/blob/main/src/hitables/triangle.cpp
    ;;
    ;; This is quite a complex function because it is quite a complex algorithm
    ;; for more information on it check 
    ;; https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/moller-trumbore-ray-triangle-intersection
    
    ;; edge1 = p2 - p1
    ;; edge2 = p3 - p1
    lea ebx, [@@edge1]
    lea ecx, [@@edge2]
    mov edx, [@@object]
    call vec_sub, ebx, [edx+Triangle.p2], [edx+Triangle.p1]
    call vec_sub, ecx, [edx+Triangle.p3], [edx+Triangle.p1]

    ;; pvec = cross(ray.direction, edge2)
    mov eax, [@@ray]
    lea eax, [eax+Ray.direction]
    lea edx, [@@pvec]
    call vec_cross, edx, eax, ecx

    ;; d = dot(edge1, pvec)
    call vec_dot, ebx, edx
    mov ebx, eax

@@check_parallel:
    mov [@@temp], ebx
    fld [@@temp]
    fabs 
    fstp [@@temp]

    ;; Our ray is parallel to the plane, return false
    call flt, [@@temp], [epsilon]
    cmp eax, 1
    je @@return_false

    push ebx
    ;; tvec = origin - p1
    mov ebx, [@@ray]
    lea ebx, [ebx+Ray.origin]
    lea ecx, [@@tvec]
    mov edx, [@@object]
    call vec_sub, ecx, ebx, [edx+Triangle.p1]

    ;; u = dot(tvec, pvec) * (1 / d)
    lea ebx, [@@pvec]
    call vec_dot, ebx, ecx
    mov [@@temp], eax
    fld [@@temp]
    
    ;; Calculate the inverse d
    fld1
    pop ebx
    mov [@@temp], ebx
    fld [@@temp]
    fdivp
    fst [@@inv_d]

    fmulp
    fstp [@@u]

    ;; check if u is > 0 and < 1, if it isn't return false
    call flt, [@@u], [float_0]
    cmp eax, 1
    je @@return_false
    call flt, [float_1], [@@u]
    cmp eax, 1
    je @@return_false

    ;; qvec = cross(tvec, edge1)
    lea eax, [@@edge1]
    lea ebx, [@@tvec]
    lea ecx, [@@qvec]
    call vec_cross, ecx, ebx, eax

    ;; v = dot(direction, qvec) * (1 / d)
    mov eax, [@@ray]
    lea eax, [eax+Ray.direction]
    call vec_dot, eax, ecx
    mov [@@temp], eax
    fld [@@inv_d]
    fmul [@@temp]
    fst [@@v]

    fadd [@@u]
    fstp [@@temp]

    ;; check if v > 0 and v+u < 1, if it is, return false because our ray is 
    ;; not in the triangle.
    call flt, [@@v], [float_0]
    cmp eax, 1
    je @@return_false
    call flt, [float_1], [@@temp]
    cmp eax, 1
    je @@return_false

    ;; Now we are sure the ray intersects the triangle, we can start filling the
    ;; hit structure and return 1
    lea eax, [@@qvec]
    lea ebx, [@@edge2]
    call vec_dot, eax, ebx
    mov [@@temp], eax
    fld [@@temp]
    fld [@@inv_d]
    fmulp
    fstp [@@temp]

    call flt, [@@temp], [@@t_min]
    cmp eax, 1
    je @@return_false
    call flt, [@@t_max], [@@temp]
    cmp eax, 1
    je @@return_false

    mov ebx, [@@hit]
    
    ;; set t
    mov eax, [@@temp]
    mov [ebx+Hit.t], eax

    ;; set the hit point
    lea ecx, [ebx+Hit.hit_point]
    call ray_at, [@@ray], ecx, [ebx+Hit.t]
    
    mov eax, [@@u]
    mov [ebx+Hit.u], eax
    mov eax, [@@v]
    mov [ebx+Hit.v], eax

    mov eax, [@@object]
    mov eax, [eax+Object.material]
    mov [ebx+Hit.hit_mat], eax

    ;; Calculate the normal
    lea ecx, [@@edge1]
    lea edx, [@@edge2]
    lea edi, [ebx+Hit.normal]
    call vec_cross, edi, ecx, edx
    call hit_calc_hit_front, [@@hit], [@@ray]

    mov eax, 1
    jmp @@end

@@return_false:
    mov eax, 0

@@end:
    ret
endp hit_triangle

proc triangle_set
    arg @@triangle:PTR Triangle, @@p1:PTR Point, @@p2:PTR Point, @@p3:PTR Point, @@mat:PTR Mat
    uses eax, ebx

    call object_set, [@@triangle], offset hit_triangle, [@@mat]

    ;; Copy the 3 vertex indeces
    mov eax, [@@triangle]
    mov ebx, [@@p1]
    mov [eax+Triangle.p1], ebx
    mov ebx, [@@p2]
    mov [eax+Triangle.p2], ebx
    mov ebx, [@@p3]
    mov [eax+Triangle.p3], ebx

    ret
endp triangle_set

DATASEG

epsilon dd 0.00001

END