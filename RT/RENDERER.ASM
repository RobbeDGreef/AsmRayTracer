IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "gui/gui.inc"
include "output/video.inc"
include "bmp.inc"
include "utils.inc"
include "config.inc"
include "mm.inc"

include "rt/renderer.inc"
include "rt/vec.inc"
include "rt/ray.inc"
include "rt/object.inc"
include "rt/hit.inc"
include "rt/scene.inc"
include "rt/cam.inc"
include "rt/mat/mat.inc"
include "rt/texture/image.inc"
include "rt/sphere.inc"

CODESEG

;; Wrapper function to render the renderer buffer to a BMP image.
proc renderer_to_bmp
    arg @@file_name:PTR byte

    call renderer_to_rgbbuffer
    call bmp_write, [@@file_name], [img_rgbbuf], [img_rgbbuf_size],\
                    [config_video_img_width], [config_video_img_height]
    
    ret
endp renderer_to_bmp

;; 
proc renderer_to_rgbbuffer
    call renderer_to_buffer, [img_rgbbuf], [config_video_img_width], [config_video_img_height]
    ret
endp renderer_to_rgbbuffer

proc fclamp_0_to_1
    arg @@value:dword
    local @@temp:dword

    fld [@@value]
    fld1
    faddp

    fld [@@value]
    fld1
    fsubp
    fabs

    fsubp
    fst [@@temp]
    fld [@@temp]
    fabs
    faddp
    fmul [float_0_25]

    fst [@@temp]

    ret
endp fclamp_0_to_1


proc renderer_to_buffer
    arg @@buffer:dword, @@buf_width:dword, @@buf_height:dword
    local @@lineadd_vm:dword, @@lineadd_buf:dword, @@temp:dword
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
    
        call fclamp_0_to_1, [dword ptr ebx+8]
        fmul [float_max_char]
        fistp [word ptr eax]
         
        call fclamp_0_to_1, [dword ptr ebx+4]
        fmul [float_max_char]
        fistp [word ptr eax+1]

        call fclamp_0_to_1, [dword ptr ebx]
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

proc shade_normals
    arg @@ray:PTR Ray, @@hit:PTR Hit, @@dest_color:PTR Vec
    local @@temp_vec:Vec
    uses ebx, ecx, edx

    ;; Shading our normals. This is good for debugging
    ;; (normal + (1, 1, 1)) * 0.5
    
    mov ebx, [@@dest_color]
    mov ecx, [@@hit]
    lea ecx, [ecx+Hit.normal]

    call vec_cpy, ebx, ecx
    lea ecx, [@@temp_vec]
    call vec_set, ecx, [float_1], [float_1], [float_1]
    call vec_add, ebx, ebx, ecx
    call vec_mul_float, ebx, [float_0_50]

    ret
endp shade_normals

proc cast_ray
    arg @@ray:PTR Ray, @@dest_color:PTR Color, @@bounces:dword, @@scene:PTR Scene
    local @@temp_vec:Vec, @@target:Vec, @@temp:dword, @@hit:Hit, @@bounced:Ray,\
          @@color:Color, @@u:dword, @@v:dword
    uses eax, ebx, ecx, edx, edi, esi

    ;; This line is veryyyyy important. We want to make sure that our return 
    ;; color is at least black. Otherwise we might have garbage in this memory
    ;; space and get garbage colors. (believe me i trakced a hard bug on this,
    ;; we don't want stack values in our colors).
    call vec_set, [@@dest_color], [float_0], [float_0], [float_0]

    cmp [@@bounces], 0
    je @@background

    lea ecx, [@@hit]
    call scene_hit, [@@scene], [@@ray], [float_0_0_1], [float_pos_inf], ecx
    cmp eax, 0
    je @@background

    call flt, [float_0], [ecx+Hit.t]
    cmp eax, 1
    jne @@background

    ;; Usefull for debugging.
    ;call shade_normals, [@@ray], ecx, [@@dest_color] 
    ;jmp @@end

    mov edx, [ecx+Hit.hit_mat]
    lea edi, [@@bounced]
    mov edx, [edx]

    ;; Calculate the material scatter and bounce the ray
    call [edx+Mat.scatter], edx, [@@ray], ecx, [@@dest_color], edi
    ;; If we return 0, we don't want to bounce again, just the emission
    ;; if we return -1, don't bounce and don't do emission
    cmp eax, 0
    je @@emission
    cmp eax, -1
    je @@end

    lea esi, [@@color]
    dec [@@bounces]
    call cast_ray, edi, esi, [@@bounces], [@@scene]
    call vec_mul, [@@dest_color], [@@dest_color], esi

@@emission:
    cmp [edx+Mat.emission], 0
    je @@end
    call [edx+Mat.emission], edx, [@@ray], ecx, esi
    call vec_add, [@@dest_color], esi

    jmp @@end

@@background:
    
    cmp [img_hdri_texture], 0
    jne @@hdri_texture
    call vec_cpy, [@@dest_color], offset config_render_background
    jmp @@end

@@hdri_texture:
    lea ebx, [@@u]
    lea ecx, [@@v]
    mov edx, [@@ray]
    lea edx, [edx+Ray.direction]
    lea edi, [@@temp_vec]
    call vec_cpy, edi, edx
    call vec_length, edi
    call vec_div_float, edi, eax

    call sphere_calc_coords, edi, ebx, ecx
    call image_get_color, [img_hdri_texture], [ebx], [ecx], [@@dest_color]

@@end:
    ret
endp cast_ray

proc lerp
    arg @@dest_color:PTR Color, @@ray:PTR Ray, @@c1:PTR Color, @@c2:PTR Color
    local @@temp:dword, @@temp_vec:Vec
    uses ebx, ecx
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
    call vec_cpy, ecx, [@@c1]
    call vec_mul_float, ecx, [@@temp]

    ;; Set the white value and lerp
    mov ebx, [@@dest_color]
    call vec_cpy, ebx, [@@c2]

    fld1
    fxch
    fsub
    fstp [@@temp]
    call vec_mul_float, ebx, [@@temp]
    ;; Finally write it to the dest color by adding both of them together
    call vec_add, ebx, ecx, ebx
    ret
endp lerp

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
          @@float_height_minus_1:dword, @@pixel:Vec
    uses eax, ecx, ebx, edx, edi, esi

    ;; First calculate width and height - 1
    fild [config_video_img_width]
    fsub [float_1]
    fstp [@@float_width_minus_1]
    
    fild [config_video_img_height]
    fsub [float_1]
    fstp [@@float_height_minus_1]

    ;; Set the camera location to (0, 0, 0)
    lea eax, [@@temp_vec]
    call vec_set, eax, [float_0], [float_0], [float_0]
    call cam_set_loc, eax

    mov esi, [img_framebuffer]
    mov eax, [config_video_img_height]
    dec eax

    call log_str, offset render_start_str

@@height_loop:
    cmp eax, 0
    jl @@end_height_loop

    mov ebx, eax
    and ebx, 0fh
    cmp ebx, 0
    jne @@start_width_loop
    call gui_progress_notify, eax, [config_video_img_height]

@@start_width_loop:
    mov ebx, 0
    @@width_loop:
        cmp ebx, [config_video_img_width]
        je @@end_width_loop

        lea ecx, [@@ray]
        lea edi, [@@pixel]
        mov edx, [config_render_samples]
        dec edx

        @@sample_loop:
            cmp edx, 0
            jl @@end_sample_loop

            ; u = width_iter / width
            ; v = height_iter / height

            mov [@@temp], ebx
            fild [@@temp]
            call random_float
            faddp
            fld [@@float_width_minus_1]
            fdiv
            fstp [@@u]

            mov [@@temp], eax
            fild [@@temp]
            call random_float
            faddp
            fld [@@float_height_minus_1]
            fdiv
            fstp [@@v]

            call cam_get_ray, ecx, [@@u], [@@v]

            ;; Cast a ray with esi:destination pixel
            call cast_ray, ecx, edi, [config_render_max_bounces], [@@scene]
            call vec_add, esi, esi, edi

            dec edx
            jmp @@sample_loop

        @@end_sample_loop:

        call vec_div_int, esi, [config_render_samples]
        
        ;; Do gamma correction
        call vec_sqrt, esi

        add esi, VEC_SIZE
        inc ebx
        jmp @@width_loop

    @@end_width_loop:

    dec eax
    jmp @@height_loop


@@end_height_loop:

    ret
endp renderer_render

proc renderer_denoise
    local @@temp:dword
    uses eax, ebx, ecx
    ret
endp renderer_denoise

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

    add eax, [img_rgbbuf_size]
    add eax, 64                     ;; Some extra padding bytes
    
    call alloc, eax

    mov [img_framebuffer], eax
    add eax, [img_framebuffer_size]
    and eax, ecx
    add eax, 16
    mov [img_rgbbuf], eax

    call memset, [img_framebuffer], 0, [img_framebuffer_size]

    cmp [config_render_hdri_path], 0
    je @@end
    call alloc, size Image
    mov [img_hdri_texture], eax
    call image_init, eax, offset config_render_hdri_path

@@end:
    ret
endp renderer_init

DATASEG
    viewport_height dd 2.0

    ;; These are set in renderer_init(
    img_framebuffer       dd 0
    img_rgbbuf            dd 0
    img_framebuffer_size  dd 0
    img_rgbbuf_size       dd 0
    img_hdri_texture      dd 0

    render_start_str db "Render start", 0

END 
