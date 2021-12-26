IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/mat/mat.inc"
include "rt/mat/glass.inc"
include "rt/mat/metal.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

;; The glass material I must admit is largely taken from:
;; https://raytracing.github.io/books/RayTracingInOneWeekend.html#dielectrics/refraction
;; or from 
;; https://github.com/RobbeDGreef/CppPathTracer/blob/main/src/materials.cpp
;;
;; That last one is an old codebase of mine. The original source code came 
;; partially of the first link and some from various locations across the 
;; internet.

;; This refractive function is basically a fun remix of Snell's law. 
;; n*sin(Omega) = n'*sin(Omega')
;;
;; We can do some fun vector stuff for which I am not going to write down the 
;; proof here since it is unnecessary to understand this function. 
;; 
;; The math and function comes from https://raytracing.github.io/books/RayTracingInOneWeekend.html#dielectrics/refraction
proc refract
    arg @@out:PTR Vec, @@direction:PTR Vec, @@normal:PTR Vec,\
        @@refract_index:dword, @@cos_theta:dword
    local @@r_out_perp:Vec, @@r_out_parallel:Vec, @@temp:dword
    uses eax, ebx, ecx

    ;; r_out_perp = refract_ratio * (direction + cos_theta*normal)
    lea ebx, [@@r_out_perp]
    call vec_cpy, ebx, [@@normal]
    call vec_mul_float, ebx, [@@cos_theta]
    call vec_add, ebx, ebx, [@@direction]
    call vec_mul_float, ebx, [@@refract_index]
    
    ;; r_out_parallel = -sqrt(fabs(1 - r_out_perp.length_squared())) * normal
    lea ecx, [@@r_out_parallel]
    call vec_cpy, ecx, [@@normal]

    call vec_length_squared, ebx  
    mov [@@temp], eax
    fld1
    fsub [@@temp]
    fabs
    fsqrt
    fchs
    fstp [@@temp]
    call vec_mul_float, ecx, [@@temp]
    
    ;; result = r_out_perp + r_out_parallel
    call vec_add, [@@out], ebx, ecx
    ret
endp refract

proc reflectance
    arg @@cos:dword, @@refract_index:dword
    local @@r0:dword, @@temp:dword

    ;; We use schlicks approximation for reflectance
    ;; R(theta) = R0 + (1 - R0) (1 - cos(theta))^5
    ;;
    ;; https://en.wikipedia.org/wiki/Schlick%27s_approximation 
    ;;
    ;; The actual correct way to calculate this is very complex and large. 
    ;; This approximation is accurate enough.

    ;; (1 - refract_index) / (1 + refract_index)
    fld1
    fsub [@@refract_index]
    fld1
    fadd [@@refract_index]
    fdivp
    fst [@@r0]
    ;; r0^2
    fmul [@@r0]
    fst [@@r0]

    ;; r0 + (1 - r0) * pow(1 - cos, 5)
    fld1
    fsub [@@r0]
    ;; r0 is still on the stack
    faddp

    fld1
    fsub [@@cos]
    fst [@@temp]

    ;; Calculate the power of 1 - cos, by just looping 5 times and multiplying
    ;; by itself each time
    mov eax, 4
@@pow_loop:
    cmp eax, 0
    je @@end

    fmul [@@temp]

    dec eax
    jmp @@pow_loop

@@end:

    ;; Multiply the two parts together
    fmulp
    fstp [@@temp]
    mov eax, [@@temp]
    ret
endp reflectance

proc glass_scatter
    arg @@mat:PTR Glass, @@in:PTR Ray, @@hit:PTR Hit, @@color:PTR Color,\
        @@out:PTR Ray
    local @@target:Vec, @@refraction_ratio:dword, @@temp_vec:Vec, @@cos_theta:dword, @@sin_theta:dword, @@temp:dword
    uses ebx, ecx

    ;; invoke the texture to set the color of the hit.
    mov ebx, [@@mat]
    mov ebx, [ebx+Glass.texture]
    mov ecx, [@@hit]
    call [ebx+Texture.get_color], ebx, [ecx+Hit.u], [ecx+Hit.v], [@@color]

    ;; Now we calculate the reflective ratio. This is according to snells law
    ;; again. refraction_index = n / n'. Since air has a refractive 
    ;; index of 1. We can just say that n' == 1 and so refraction_index = n.
    ;; (n = IOR)
    ;; However one interesting property of rays is at play here. If the ray
    ;; goes in the opposite direction (we hit the outside of the glass. Our n'
    ;; becomes equal to the IOR value and we have to invert that value 1 / n'
    mov ebx, [@@hit]
    mov ecx, [@@mat]
    cmp [ebx+Hit.hit_front], 1
    je @@hit_front

    ;; refraction_ratio = IOR since we go from dielectric to glass
    mov eax, [ecx+Glass.refraction_index]
    mov [@@refraction_ratio], eax

    jmp @@calc_direction
@@hit_front:

    ;; Invert the IOR value since we go from air to dielectric
    fld1 
    fdiv [ecx+Glass.refraction_index]
    fstp [@@refraction_ratio]

@@calc_direction:

    ;; Now we can calculate the unit vector direction to calculate our refracted
    ;; (or reflected) ray.
    mov ebx, [@@in]
    lea ebx, [ebx+Ray.direction]
    lea ecx, [@@temp_vec]
    call vec_cpy, ecx, ebx
    call vec_length, ecx
    call vec_div_float, ecx, eax
    
    ;; cos_theta = -unit_direction * normal.
    ;; however this value cannot be come larger than 1 so we clamp it at 1
    ;; by using fmin(cos_theta, 1)
    mov ebx, [@@hit]
    lea ebx, [ebx+Hit.normal]
    call vec_mul_float, ecx, [float_minus_1]
    call vec_dot, ecx, ebx
    call fmin, eax, [float_1]
    mov [@@cos_theta], eax

    ;; Basic conversion math:
    ;; sin_theta = sqrt(1 - cos_theta^2)
    fld1
    fld [@@cos_theta]
    fmul [@@cos_theta]
    fsubp
    fsqrt
    fstp [@@sin_theta]

    fld [@@refraction_ratio]
    fmul [@@sin_theta]
    fstp [@@temp]

    ;; ecx contains the normalized direction * -1 so we will multiply by -1 
    ;; again to flip it back to just the normalized direction
    call vec_mul_float, ecx, [float_minus_1] 

    ;; If the angle is too small we will always reflect
    call flt, [float_1], [@@temp]
    cmp eax, 1
    jne @@refract
@@reflect:

    mov eax, [@@out]
    lea eax, [eax+Ray.direction]
    mov ebx, [@@hit]
    lea ebx, [ebx+Hit.normal]
    call reflect, eax, ecx, ebx

    jmp @@end
@@refract:

    ;; Sometimes we will randomly reflect. The change of this happening 
    ;; increases to larger the angle between the ray and the normal becomes
    call reflectance, [@@cos_theta], [@@refraction_ratio]
    mov ebx, eax
    call random_float_ranged, [float_0], [float_0_75]
    fstp [@@temp]
    call flt, [@@temp], ebx
    cmp eax, 1
    je @@reflect

    mov eax, [@@out]
    lea eax, [eax+Ray.direction]
    mov ebx, [@@hit]
    lea ebx, [ebx+Hit.normal]
    call refract, eax, ecx, ebx, [@@refraction_ratio], [@@cos_theta]

@@end:
    
    ;; Set the hit point
    mov eax, [@@out]
    lea eax, [eax+Ray.origin]
    mov ebx, [@@hit]
    lea ebx, [ebx+Hit.hit_point]
    call vec_cpy, eax, ebx

    ;; Glass materials always bounce back and are affected by emission so 1 is 
    ;; returned. Check renderer cast_ray for more information on return values 
    ;; of this function.
    mov eax, 1
    ret
endp glass_scatter

proc glass_init
    arg @@mat:PTR Glass, @@tex:PTR Texture, @@refract_index:dword
    uses eax, ebx

    call mat_init, [@@mat], offset glass_scatter, 0
    
    mov eax, [@@mat]
    mov ebx, [@@tex]
    mov [eax+Glass.texture], ebx
    mov ebx, [@@refract_index]
    mov [eax+Glass.refraction_index], ebx

    ret
endp glass_init

END