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
    arg @@loc:PTR Point
    local @@temp:dword, @@temp_vec:Vec
    uses ebx

    ;; Set the camera location
    call vec_cpy, offset cam_loc, [@@loc]
    
    ;; aspect_ratio = width/height
    fild [config_video_img_width]
    fild [config_video_img_height]
    fdiv
    fst [cam_aspect_ratio]
    fmul [cam_viewport_height]
    fstp [@@temp]

    ;; horizontal = (viewport_height * aspect_ratio, 0, 0)
    call vec_set, offset cam_horizontal, [@@temp], [float_0], [float_0]
    ;; vertical = (0, viewport_width, 0)
    call vec_set, offset cam_vertical, [float_0], [cam_viewport_height],\
                  [float_0]
    
    ;; lower_left_corner = camera_loc - horizontal / 2 - vertical / 2 
    ;;                     - (0, 0, focal_length)
    call vec_cpy, offset cam_lower_left_corner, offset cam_loc
    lea ebx, [@@temp_vec]
    call vec_cpy, ebx, offset cam_horizontal
    call vec_div_float, ebx, [float_2]
    call vec_sub, offset cam_lower_left_corner, offset cam_lower_left_corner, ebx
    
    call vec_cpy, ebx, offset cam_vertical
    call vec_div_float, ebx, [float_2]
    call vec_sub, offset cam_lower_left_corner, offset cam_lower_left_corner, ebx
    
    call vec_set, ebx, [float_0], [float_0], [config_video_img_focal_length]
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