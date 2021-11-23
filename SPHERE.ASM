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
    arg @@object:PTR Object, @@ray:PTR Ray, @@t_min:dword, @@t_max:dword,\
        @@hit:PTR Hit
    local @@ac:Vec, @@temp:dword, @@a:dword, @@half_b:dword, @@c:dword,\
          @@half_b:dword, @@root:dword, @@hit_point:Point, @@sqrt:dword
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
    ;;      (x - Cx)^2 + (y - Cy)^2 + (z - Cz)^2 = (P - C) * (P - C)
    ;; 
    ;; So our equation becomes 
    ;;
    ;;      (P - C) * (P - C) = r^2
    ;;
    ;; Now when we substitute P(t) = A + tD, we finally become
    ;;
    ;;      (A + tD - C) * (A + tD - C) = r^2
    ;;
    ;; Solve the special product
    ;; 
    ;;      t^2D * D + 2tD * (A - C) + (A - C) * (A - C) - r^2 = 0
    ;;
    ;; We need to solve for t. Our equation is quadratic and this means we can
    ;; have two t's (roots). Now this makes perfect sense because a line 
    ;; (or ray) can cross a circle twice. To solve our quadratic equation we use
    ;; good 'ol highschool math and calculate a discriminant and then our two 
    ;; roots.
    ;;
    ;;      (-b +/- sqrt(b^2 - 4 * a * c)) / 2a
    ;;
    ;; In our example we can extract the variables as:
    ;;
    ;;      a = D * D
    ;;      b = 2 * D * (A - C)
    ;;      c = (A + C) * (A + C) - r^2
    ;;
    ;; Now since this code will run a LOT of times we try to optimize it as much
    ;; as we can. For example, we see that our b is multiplied by two and our
    ;; equation is divided by 2. We can simply here, suppose we say 2s = b
    ;;
    ;;        (-2s +/- sqrt((2s)^2 - 4 * a * c)) / 2a
    ;;      = (-2s +/- sqrt(2^2 * s^2 - 4 * a * c)) / 2a
    ;;      = (-2s +/- 2sqrt(s^2 - 4 * a * c)) / 2a
    ;;      = (-s +/- sqrt(s^2 - 4 * a * c)) / a
    ;;
    lea ecx, [@@ac]
    mov ebx, [@@ray]
    lea ebx, [ebx+Ray.origin]
    mov edx, [@@object]

    mov edi, [edx+Sphere.radius]
    mov [@@temp], edi
    
    lea edi, [edx+Object.location]
    call vec_sub, ecx, ebx, edi     ;; (A - C) = Ray.origin - Sphere.location
    
    mov ebx, [@@ray]
    lea ebx, [ebx+Ray.direction]
    call vec_dot, ebx, ebx
    mov [@@a], eax                  ;; a = Ray.Direction * Ray.Direction

    call vec_dot, ecx, ebx          ;; b/2 = (A - C) * Ray.Direction
    mov [@@half_b], eax

    fld [@@temp]                    ;; contains radius
    fld [@@temp]
    fmulp

    call vec_dot, ecx, ecx
    mov [@@c], eax
    fld [@@c]
    fxch
    fsubp                           ;; c = (A - C) * (A - C) - Sphere.Radius^2
                                    ;; c is on the fpu stack now

    fld [@@a]
    fmulp

    fld [@@half_b]
    fmul [@@half_b]
    fxch
    fsubp
    fstp [@@temp]                   ;; D = b^2 - 4 * a * c

    call flt, [@@temp], [float_0]   ;; If our discriminant is smaller than 0
                                    ;; return false. (we can't sqrt negatives)
    cmp eax, 1
    jne @@calc_root

    mov eax, 0
    jmp @@end

@@calc_root:
    ;; Calculate roots
    ;; ((-half_b - sqrt(discriminant)) / a
    ;; Note that we have saved sqrt into temp
    fld [@@temp]
    fsqrt
    fst [@@sqrt]
    
    fld [@@half_b]
    fchs
    fxch
    fsubp
    fld [@@a]
    fdivp
    fstp [@@root]       ;; We calculate the first root (-b - sqrt(D)) / a

    ;; Check if this root is in acceptable range and if it isn't calculate the
    ;; second one
    call flt, [@@root], [@@t_min]
    cmp eax, 1
    je @@find_root2
    call flt, [@@t_max], [@@root]
    cmp eax, 1
    jne @@set_hit
@@find_root2:
    fld [@@sqrt]
    fld [@@half_b]
    fchs
    faddp
    fld [@@a]
    fdivp
    fstp [@@root]       ;; (-b + sqrt(D)) / a

    ;; If this root is also not in range return false, we are going to pretend
    ;; we didn't hit anything.
    call flt, [@@root], [@@t_min]
    cmp eax, 1
    je @@ret_false
    call flt, [@@t_max], [@@root]
    cmp eax, 1
    jne @@set_hit

@@ret_false:
    mov eax, 0
    jmp @@end

@@set_hit:
    mov ebx, [@@hit]
    mov eax, [@@root]
    mov [ebx+Hit.t], eax

    lea ecx, [ebx+Hit.hit_point]
    call ray_at, [@@ray], ecx, [@@root]
    
    mov eax, [@@object]
    lea edi, [eax+Object.location]
    lea eax, [eax+Sphere.radius]
    lea edx, [ebx+Hit.normal]
    call vec_sub, edx, ecx, edi
    call vec_div_float, edx, eax

    mov eax, 1
@@end:
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