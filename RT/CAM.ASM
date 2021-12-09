IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "config.inc"
include "rt/vec.inc"
include "rt/ray.inc"
include "rt/cam.inc"

CODESEG

;; This function sets the location of the global camera. It also calculates all
;; the necessary helper variables to go with it.
proc cam_set_loc
    arg @@loc:PTR Point, @@lookat:PTR Point
    local @@temp:dword, @@temp_vec:Vec, @@w:Vec, @@u:Vec, @@v:Vec
    uses eax, ebx, ecx, edx

    ;; Set the camera location
    call vec_cpy, offset cam_loc, [@@loc]
    
    ;; viewport_height = 2.0 * tan(radians(fov)/2);
    fld [config_video_img_fov]
    call fpu_degrees_to_radians
    fdiv [float_2]
    fptan
    ;; For some reason fptan computes the tangent and then pushes 1.0 onto the 
    ;; fpu stack? Meaning we have to pop that off first so I just pop it to an
    ;; unused temp variable.
    fstp [@@temp]
    fmul [cam_viewport_height]
    fstp [cam_viewport_height]

    ;; aspect_ratio = width/height
    fild [config_video_img_width]
    fild [config_video_img_height]
    fdiv
    fst [cam_aspect_ratio]
    fmul [cam_viewport_height]
    fstp [cam_viewport_width]

    ;; w = unit(loc - lookat)
    lea ebx, [@@w]
    call vec_sub, ebx, [@@loc], [@@lookat]
    call vec_length, ebx
    call vec_div_float, ebx, eax

    ;; u = unit(cross((0, 1, 0), w))
    lea ecx, [@@u]
    lea edx, [@@temp_vec]
    call vec_set, edx, [float_0], [float_1], [float_0]
    call vec_cross, ecx, edx, ebx
    call vec_length, ecx
    call vec_div_float, ecx, eax

    ;; v = cross(w, u)
    lea edx, [@@v]
    call vec_cross, edx, ebx, ecx

    ;; horizontal = viewport_width * u
    call vec_cpy, offset cam_horizontal, ecx
    call vec_mul_float, offset cam_horizontal, [cam_viewport_width]

    ;; vertical = viewport_height * v
    call vec_cpy, offset cam_vertical, edx
    call vec_mul_float, offset cam_vertical, [cam_viewport_height]
    
    ;; lower_left_cornder = origin - horizontal / 2 - vertical / 2 - w
    call vec_cpy, offset cam_lower_left_corner, [@@loc]
    lea ecx, [@@temp_vec]
    call vec_cpy, ecx, offset cam_horizontal
    call vec_div_float, ecx, [float_2]
    call vec_sub, offset cam_lower_left_corner, offset cam_lower_left_corner, ecx
    
    call vec_cpy, ecx, offset cam_vertical
    call vec_div_float, ecx, [float_2]
    call vec_sub, offset cam_lower_left_corner, offset cam_lower_left_corner, ecx
    call vec_sub, offset cam_lower_left_corner, offset cam_lower_left_corner, ebx

    ret
endp cam_set_loc

proc cam_get_ray
    arg @@ray:PTR Ray, @@u:dword, @@v:dword
    local @@temp_vec:Vec, @@temp_vec2:Vec
    uses ebx, ecx
    
    ;; ray_direction = lower_left_corner + u*horizontal + v*vertical 
    ;;                 - origin
    lea ebx, [@@temp_vec]
    lea ecx, [@@temp_vec2]
    call vec_cpy, ebx, offset cam_lower_left_corner
    call vec_cpy, ecx, offset cam_horizontal
    call vec_mul_float, ecx, [@@u]
    call vec_add, ebx, ebx, ecx
    call vec_cpy, ecx, offset cam_vertical
    call vec_mul_float, ecx, [@@v]
    call vec_add, ebx, ebx, ecx
    call vec_sub, ebx, ebx, offset cam_loc

    ;; Set the ray with the calculated direction and the location of the camera
    call ray_set, [@@ray], offset cam_loc, ebx

    ret
endp cam_get_ray

DATASEG
    cam_loc db VEC_SIZE dup (0)
    cam_lower_left_corner db VEC_SIZE dup (0)
    cam_horizontal db VEC_SIZE dup (0)
    cam_vertical db VEC_SIZE dup (0)
    cam_viewport_width dd 0
    cam_viewport_height dd 2.0   ; -1 to 1
    cam_aspect_ratio dd ?

END