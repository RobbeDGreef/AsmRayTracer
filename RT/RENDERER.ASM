IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "output/bmp.inc"
include "utils.inc"
include "config.inc"
include "mm.inc"

include "rt/renderer.inc"
include "rt/vec.inc"
include "rt/ray.inc"
include "rt/object.inc"
include "rt/hit.inc"
include "rt/scene.inc"

CODESEG

proc renderer_to_bmp
    arg @@file_name:PTR byte

    call renderer_to_rgbbuffer
    call bmp_write, [@@file_name], [img_rgbbuf], [img_rgbbuf_size],\
                    [config_video_img_width], [config_video_img_height]
    
    ret
endp renderer_to_bmp

proc renderer_to_rgbbuffer
    call renderer_to_buffer, [img_rgbbuf], [config_video_img_width], [config_video_img_height]
    ret
endp renderer_to_rgbbuffer

proc renderer_to_buffer
    arg @@buffer:dword, @@buf_width:dword, @@buf_height:dword
    local @@lineadd_vm:dword, @@lineadd_buf:dword
    uses eax, ebx, ecx

    ;; Pseudo for width (the same goes for height)
    ;;
    ;; if buf_width < videomem_width:
    ;;      lineadd_vm = videomem_width - buf_width
    ;;      lineadd_buf = 0
    ;; if buf_width > videomem_width:
    ;;      lineadd_buf = buf_width - videomem_width
    ;;      lineadd_vm = 0
    ;;      buf_width = videomem_width

    mov [@@lineadd_vm], 0
    mov [@@lineadd_buf], 0
    
    mov eax, [@@buf_width]
    mov ebx, [config_video_img_width]
    cmp eax, ebx
    je @@height_checks
    jl @@less_than_w
    jg @@greater_than_w

@@less_than_w:
    sub ebx, eax
    mov eax, ebx
    mov ebx, VEC_SIZE
    mul ebx
    mov [@@lineadd_vm], eax
    jmp @@height_checks

@@greater_than_w:
    sub eax, ebx
    mov ecx, 4
    mul ecx
    mov [@@lineadd_buf], eax
    mov [@@buf_width], ebx

@@height_checks:
    mov eax, [@@buf_height]
    mov ebx, [config_video_img_height]
    cmp eax, ebx
    je @@start_copy
    jg @@greater_than_h
    jl @@start_copy

@@greater_than_h:
    mov [@@buf_height], ebx 

@@start_copy:

    mov eax, [@@buffer]
    mov ebx, [img_framebuffer]

    xor ecx, ecx
    xor edx, edx

@@height_loop:
    cmp ecx, [@@buf_height]
    jge @@end

    xor edx, edx
    @@width_loop:
        cmp edx, [@@buf_width]
        jge @@end_width_loop
    
        fld [dword ptr ebx+8]
        fmul [float_max_char]
        fistp [word ptr eax]
         
        fld [dword ptr ebx+4]
        fmul [float_max_char]
        fistp [word ptr eax+1]

        fld [dword ptr ebx]
        fmul [float_max_char]
        fistp [word ptr eax+2]

        ;; Set alpha
        mov [byte ptr eax+3], 0ffh

        add ebx, VEC_SIZE
        add eax, 4

        inc edx
        jmp @@width_loop
    
    @@end_width_loop:
    add eax, [@@lineadd_buf]
    add ebx, [@@lineadd_vm]
    
    inc ecx
    jmp @@height_loop

@@end:
    ret
endp renderer_to_buffer

;; Writes the current video framebuffer contents to the screen
;; WARNING: This is a slow function becaue it needs to convert all the RGB float
;; values to integers.
proc renderer_show_img

    lea eax, [vesa_lfb]
    call renderer_to_buffer, eax, VIDEO_FB_WIDTH, VIDEO_FB_HEIGHT 
    call video_buffer_flip

    ret
endp renderer_show_img

proc cast_ray
    arg @@ray:PTR Ray, @@dest_color:PTR Color, @@scene:PTR Scene
    local @@temp_vec:Vec, @@temp:dword, @@hit:Hit
    uses eax, ebx, ecx, edx

    lea ecx, [@@hit]
    call scene_hit, [@@scene], [@@ray], [float_0], [float_pos_inf], ecx
    cmp eax, 0
    je @@background

    call flt, [float_0], [ecx+Hit.t]
    cmp eax, 1
    jne @@background

    ;; Shading our normals. This is temporary since the material invocation
    ;; code will come here. This is just to check if our normals are correct.
    mov ebx, [@@dest_color]
    call ray_at, [@@ray], ebx, [ecx+Hit.t]
    
    mov edx, [@@ray]
    lea edx, [edx+Ray.direction]
    
    lea edx, [@@temp_vec]
    call vec_set, edx, [float_0], [float_0], [float_minus_1]
    call vec_sub, ebx, ebx, edx
    
    call vec_length, ebx
    call vec_div_float, ebx, eax
    
    call vec_set, edx, [float_1], [float_1], [float_1]
    call vec_add, ebx, ebx, edx
    call vec_mul_float, ebx, [float_0_50]

    jmp @@end

@@background:
    ;; Calculate a lerp from blue to white.
    ;; Because our direction Y component goes from -1.0 to 1.0 (after 
    ;; normalisation) we scale it to 0.0 - 1.0. This is easy enough. Just add
    ;; 1.0 and divide in half
    ;;
    ;;      t = (normalize(ray.direction).y + 1.0) / 2
    ;;
    ;; then we add blue and white to the mix to scale. When t = 0 we want white,
    ;; 1.0 means blue. In the middle we will get our lerp.
    ;;
    ;;      lerp_value = ((1 - t) * white) + (t * blue)

    ;; TODO: instead of doing it ourselves, implement unit_vector function.
    ;; Calculate the unit vector
    mov ebx, [@@ray]
    lea ebx, [ebx + Ray.direction]
    call vec_length, ebx
    lea ecx, [@@temp_vec]
    call vec_cpy, ecx, ebx
    call vec_div_float, ecx, eax
    
    ;; Calculate t
    call vec_get_y, ecx
    mov [@@temp], eax
    fld [@@temp]
    fadd [float_1]
    fdiv [float_2]
    fst [@@temp]

    ;; Set the blue value 
    call vec_set, ecx, [float_0_50], [float_0_75], [float_1]
    call vec_mul_float, ecx, [@@temp]

    ;; Set the white value and lerp
    mov ebx, [@@dest_color]
    call vec_set, ebx, [float_1], [float_1], [float_1]
    fld1
    fxch
    fsub
    fstp [@@temp]
    call vec_mul_float, ebx, [@@temp]
    ;; Finally write it to the dest color by adding both of them together
    call vec_add, ebx, ecx, ebx

@@end:
    ret
endp cast_ray

;; This will render the frame of the current scene.
;; Setting up the scene will happen through various other functions in the 
;; future. We are in the early stages so we do not need to think about that yet
;; (passing a bounding box tree as argument etc)
;;
;; This function has a very large callframe but that is not a problem since we
;; don't run this recursively. And this is better than doing things on the heap.
proc renderer_render
    arg @@scene:PTR Scene
    local @@temp:dword, @@camera_loc:Point, @@horizontal:Vec, @@vertical:Vec, \
          @@lower_left_corner:Vec, @@temp_vec:Vec, @@temp_vec2:Vec, \
          @@ray:Ray, @@u:dword, @@v:dword, @@float_width_minus_1:dword, \
          @@float_height_minus_1:dword
    uses eax, ecx, ebx, edx, edi, esi

    ;; First calculate width and height - 1
    fild [config_video_img_width]
    fsub [float_1]
    fstp [@@float_width_minus_1]
    
    fild [config_video_img_height]
    fsub [float_1]
    fstp [@@float_height_minus_1]

    ;; camera_loc = (0, 0, 0)
    lea eax, [@@camera_loc]
    call vec_set, eax, [float_0], [float_0], [float_0]
    
    ;; horizontal = (viewport_height * aspect_ratio, 0, 0)
    lea eax, [@@horizontal]

    ;; Calculate aspect ratio and multiply it with the viewport height
    fild [config_video_img_width]
    fild [config_video_img_height]
    fdiv
    fmul [viewport_height]
    fstp [@@temp]
    call vec_set, eax, [@@temp], [float_0], [float_0]

    ;; vertical = (0, viewport_height, 0)
    lea eax, [@@vertical]
    call vec_set, eax, [float_0], [viewport_height], [float_0]

    ;; lower_left_corner = camera_loc - horizontal / 2 - vertical / 2 
    ;;                     - (0, 0, focal_length)
    lea eax, [@@lower_left_corner]
    lea ebx, [@@camera_loc]
    call vec_cpy, eax, ebx

    lea ebx, [@@temp_vec]
    lea ecx, [@@horizontal]
    call vec_cpy, ebx, ecx
    call vec_div_float, ebx, [float_2]
    call vec_sub, eax, eax, ebx

    lea ecx, [@@vertical]
    call vec_cpy, ebx, ecx
    call vec_div_float, ebx, [float_2]
    call vec_sub, eax, eax, ebx
    
    call vec_set, ebx, [float_0], [float_0], [config_video_img_focal_length]
    call vec_sub, eax, eax, ebx

    mov esi, [img_framebuffer]
    mov eax, [config_video_img_height]
    dec eax

    call log_str, offset render_start_str

@@height_loop:
    cmp eax, 0
    jl @@end_height_loop

    mov ebx, 0

    @@width_loop:
        cmp ebx, [config_video_img_width]
        je @@end_width_loop
        
        ; u = width_iter / width
        ; v = height_iter / height

        mov [@@temp], ebx
        fild [@@temp]
        fld [@@float_width_minus_1]
        fdiv
        fstp [@@u]

        mov [@@temp], eax
        fild [@@temp]
        fld [@@float_height_minus_1]
        fdiv
        fstp [@@v]

        ;; ray = origin, ray_direction
        ;; ray_direction = lower_left_corner + u*horizontal + v*vertical 
        ;;                 - origin
        lea edi, [@@temp_vec]
        lea ecx, [@@lower_left_corner]
        call vec_cpy, edi, ecx

        lea ecx, [@@temp_vec2]
        lea edx, [@@horizontal]
        call vec_cpy, ecx, edx
        call vec_mul_float, ecx, [@@u]
        call vec_add, edi, edi, ecx

        lea edx, [@@vertical]
        call vec_cpy, ecx, edx
        call vec_mul_float, ecx, [@@v]
        call vec_add, edi, edi, ecx
        
        lea ecx, [@@camera_loc]
        call vec_sub, edi, edi, ecx

        lea ecx, [@@ray]
        lea edx, [@@camera_loc]
        call ray_set, ecx, edx, edi

        ;; Finally cast a ray with ecx:Ray and esi:destination pixel
        call cast_ray, ecx, esi, [@@scene]
        
        add esi, VEC_SIZE
        inc ebx
        jmp @@width_loop

    @@end_width_loop:

    dec eax
    jmp @@height_loop


@@end_height_loop:

    ret
endp renderer_render

proc renderer_init
    uses eax, ebx, ecx
    mov ecx, 16
    not ecx

    mov eax, [config_video_img_height]
    mov ebx, [config_video_img_width]
    mul ebx
    mov ebx, VIDEO_FB_BPP
    mul ebx
    mov [img_rgbbuf_size], eax

    mov eax, [config_video_img_width]
    mov ebx, [config_video_img_height]
    mul ebx
    mov ebx, VEC_SIZE
    mul ebx
    mov [img_framebuffer_size], eax

ifndef NASM
    mov ebx, 0500000h                     ;; Load the video framebuffer at 5 MB
    mov [img_framebuffer], ebx
    add ebx, eax

    ;; Make sure it is 16bytes aligned (for optimalisation reasons)
    and ebx, ecx
    add ebx, 16
    mov [img_rgbbuf], ebx
else
    add eax, [img_rgbbuf_size]
    add eax, 64                     ;; Some extra padding bytes
    
    call alloc, eax

    mov [img_framebuffer], eax
    add eax, [img_framebuffer_size]
    and eax, ecx
    add eax, 16
    mov [img_rgbbuf], eax
endif 
    ret
endp renderer_init

DATASEG
    viewport_height dd 2.0

    ;; These are set in renderer_init(
    img_framebuffer       dd 0
    img_rgbbuf            dd 0
    img_framebuffer_size  dd 0
    img_rgbbuf_size       dd 0

    render_start_str db "Render start", 0

END 
