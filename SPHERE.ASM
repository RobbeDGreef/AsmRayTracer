IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "vec.inc"
include "ray.inc"
include "sphere.inc"
include "object.inc"
include "hit.inc"

CODESEG

proc hit_sphere
    arg @@object:PTR Object, @@ray:PTR Ray, @@t_min:dword, @@t_max:dword, @@hit:PTR Hit
    local @@oc:Vec, @@temp:dword, @@b:dword, @@c:dword
    uses ebx, ecx, edx, edi

    ;; Yay math. To check if we hit a function we are making use of the good old
    ;; 
    ;;      (x - Cx)^2 + (y - Cy)^2 + (z - Cy)^2 = r^2 
    ;;
    ;; with C(x,y,z) the center of our sphere and r the radius
    ;;
    ;; However this is not in vector format. We want to use our vector functions
    ;; we worked so hard on. So we can replace this with:
    ;; 
    ;;      (P - C) * (P - C) = (x - Cx)^2 + (y - Cy)^2 + (z - Cz)^2
    ;; 
    ;; So our equation becomes 
    ;;
    ;;      (P - C) * (P - C) = r^2+
    ;;
    ;; Now when we substitute P(t) = A + tB, we finally become
    ;;
    ;;      (A + tB - C) * (A + tB - C) = r^2 
    ;;      t^2b * b + 2tb * (A - C) + (A + C) - r^2 = 0
    ;;
    ;; With that we can finally calculate the ray intersection points.
    lea ecx, [@@oc]
    mov ebx, [@@ray]
    lea ebx, [ebx+Ray.origin]
    mov edx, [@@object]
    mov edi, [edx+Sphere.radius]
    mov [@@temp], edi
    lea edi, [edx+Object.location]
    call vec_sub, ecx, ebx, edi
    
    mov ebx, [@@ray]
    lea ebx, [ebx+Ray.direction]
    call vec_dot, ebx, ebx
    mov edx, eax

    call vec_dot, ecx, ebx
    mov [@@b], eax
    fld [@@b]
    fmul [float_2]
    fstp [@@b]

    fld [@@temp] ;; contains radius
    fmul [@@temp]

    call vec_dot, ecx, ecx
    mov [@@c], eax
    fld [@@c]
    fxch
    fsub

    mov [@@temp], edx
    fld [@@temp]
    fmul [float_4]
    fmul

    fld [@@b]
    fmul [@@b]
    fxch
    fsub

    fst [@@temp]

    xor eax, eax
    fldz
    fxch
    fcompp
    fnstsw ax
    shr eax, 8
    and eax, 111B
    cmp eax, 0
    sete al
    
    ret
endp hit_sphere

proc sphere_set
    arg @@sphere:PTR Sphere, @@location:PTR Point, @@radius:dword
    uses eax, ebx

    call object_set, [@@sphere], [@@location], offset hit_sphere
    
    mov eax, [@@sphere]
    mov ebx, [@@radius]
    mov [eax+Sphere.radius], ebx

    ret
endp sphere_set

END