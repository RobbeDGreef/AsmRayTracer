IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "renderer.inc"
include "vec.inc"
include "ray.inc"
include "config.inc"

VESA_VIDEO_ADDR     equ 0A0000h
VESA_BANK_SIZE      equ (64*1024)
VESA_BANK_SWITCHES  equ (VIDEO_FB_SIZE/VESA_BANK_SIZE)+1

CODESEG

;; Sets the current video mode via the BIOS. 
proc set_video_mode
    arg @@mode:dword
    uses eax, ebx
    ;; We use the bios to set the video mode
    mov eax, 4f02h
    mov ebx, [@@mode]

ifndef NASM
    int 10h
endif
    ret
endp set_video_mode

;; Local function, switches vesa banks
proc set_bank
    arg @@bank_number:dword
    uses eax, ebx, edx

    mov eax, 04f05h
    xor bx, bx
    mov edx, [@@bank_number]

ifndef NASM
    int 10h
endif

    ret
endp set_bank

BMP_HDR_ID                  equ 4d42h
BMP_HDR_SIZE                equ 14
BMP_DIB_SIZE                equ 40
BMP_DIB_PLANES              equ 1
BMP_DIB_BPP                 equ 32
BMP_DIB_COMPRESSION_TYPE    equ 0
BMP_DIB_COMPRESSION_SIZE    equ 0

struc bmp_hdr
    id              dw ?
    size            dd ?
    reserved        dd ?
    img_data_off    dd ?
ends bmp_hdr

struc bmp_dip_hdr
    size                    dd ?
    img_width               dd ?
    img_height              dd ?
    places_cnt              dw ?
    bpp                     dw ?
    compression_type        dd ?
    compression_size        dd ?
    x_ppm                   dd ?
    y_ppm                   dd ?
    used_colors_cnt         dd ?
    important_colors_cnt    dd ? 
ends bmp_dip_hdr

proc renderer_to_bmp
    arg @@file_name:PTR byte
    local @@hdr:bmp_hdr, @@dip_hdr:bmp_dip_hdr
    uses eax, ebx, ecx

    call renderer_to_rgbbuffer 

    call create_file, [@@file_name], 0
    mov ebx, eax

    lea eax, [@@hdr]
    mov [word ptr eax+bmp_hdr.id], BMP_HDR_ID
    mov ecx, BMP_HDR_SIZE+BMP_DIB_SIZE+2
    add ecx, [img_rgbbuf_size]
    mov [dword ptr eax+bmp_hdr.size], ecx
    mov [dword ptr eax+bmp_hdr.img_data_off], BMP_HDR_SIZE+BMP_DIB_SIZE+2
    
    call write_file, ebx, eax, BMP_HDR_SIZE

    lea eax, [@@dip_hdr]
    mov [dword ptr eax+bmp_dip_hdr.size], BMP_DIB_SIZE
    mov ecx, [config_video_img_width]
    mov [dword ptr eax+bmp_dip_hdr.img_width], ecx
    mov ecx, [config_video_img_height]
    mov [dword ptr eax+bmp_dip_hdr.img_height], ecx
    mov [word ptr eax+bmp_dip_hdr.places_cnt], BMP_DIB_SIZE
    mov [word ptr eax+bmp_dip_hdr.bpp], BMP_DIB_BPP
    mov [dword ptr eax+bmp_dip_hdr.compression_type], BMP_DIB_COMPRESSION_TYPE
    mov [dword ptr eax+bmp_dip_hdr.compression_size], BMP_DIB_COMPRESSION_SIZE
    mov [dword ptr eax+bmp_dip_hdr.x_ppm], 0
    mov [dword ptr eax+bmp_dip_hdr.y_ppm], 0
    mov [dword ptr eax+bmp_dip_hdr.used_colors_cnt], 0
    mov [dword ptr eax+bmp_dip_hdr.important_colors_cnt], 0

    call write_file, ebx, eax, BMP_DIB_SIZE
    ;; 2 pad bytes, reused ebx as address but this might as well have been 
    ;; something else
    call write_file, ebx, eax, 2

    call write_file, ebx, [img_rgbbuf], [img_rgbbuf_size]
    call close_file, ebx

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

    call print_hex, [img_framebuffer]
    call print_newline

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

proc renderer_buf_to_screen
    uses eax, ecx, edi, esi

    xor eax, eax
    lea esi, [vesa_lfb]

@@copy_loop:
    cmp eax, VESA_BANK_SWITCHES
    je @@end
    call set_bank, eax

    mov edi, VESA_VIDEO_ADDR
    mov ecx, VESA_BANK_SIZE/4
    rep movsd
    
    inc eax
    jmp @@copy_loop

@@end:
    ret
endp renderer_buf_to_screen

;; Writes the current video framebuffer contents to the screen
;; WARNING: This is a slow function becaue it needs to convert all the RGB float
;; values to integers.
proc renderer_show_img

    lea eax, [vesa_lfb]
    call renderer_to_buffer, eax, VIDEO_FB_WIDTH, VIDEO_FB_HEIGHT 
    call renderer_buf_to_screen

    ret
endp renderer_show_img

proc hit_sphere
    arg @@center:PTR Point, @@radius:dword, @@ray:PTR Ray
    local @@oc:Vec, @@temp:dword, @@b:dword, @@c:dword

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
    call vec_sub, ecx, ebx, [@@center]
    
    mov ebx, [@@ray]
    lea ebx, [ebx+Ray.direction]
    call vec_dot, ebx, ebx
    mov edx, eax

    call vec_dot, ecx, ebx
    mov [@@b], eax
    fld [@@b]
    fmul [float_2]
    fstp [@@b]

    fld [@@radius]
    fmul [@@radius]

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

proc cast_ray
    arg @@ray:PTR Ray, @@dest_color:PTR Color
    local @@temp_vec:Vec, @@temp:dword
    uses eax, ebx, ecx, edx

    ;; For now we are just setting up the 'scene' here. We check if we hit a 
    ;; sphere at (0, 0, 0) with a width of 0.5 units.
    lea eax, [@@temp_vec]
    call vec_set, eax, [float_0], [float_0], [float_minus_1]
    call hit_sphere, eax, [float_0_50], [@@ray]
    cmp eax, 0
    je @@background

    call vec_set, [@@dest_color], [float_0_50], [float_0], [float_0]
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

    ;; lower_left_corner = camera_loc - horizontal / 2 - vertical / 2 - (0, 0, focal_length)
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
        call cast_ray, ecx, esi
        
        add esi, VEC_SIZE
        inc ebx
        jmp @@width_loop

    @@end_width_loop:

    dec eax
    jmp @@height_loop


@@end_height_loop:

    ret
endp renderer_render

ifdef NASM
;; compat-skip1
extern _end
;; compat-skip1
extern malloc
endif

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
    mov ebx, 0500000h                     ;; Load the video framebuffer at 3MB
    mov [img_framebuffer], ebx
    add ebx, eax

    ;; Make sure it is 16bytes aligned (for optimalisation reasons)
    and ebx, ecx
    add ebx, 16
    mov [img_rgbbuf], ebx
else
    ;; Allocate a little more memory
    ;; I wanted to use the linux brk syscall but it is giving me a hard time
    ;; so i'm going to be lazy and link in malloc. This is safer anyway.
    add eax, [img_rgbbuf_size]
    add eax, 64                     ;; Some extra padding bytes
    
    ;; C uses a different calling convention so we need to remember and save
    ;; the registers we are using.
    push ecx
    call malloc, eax
    pop ecx 

    mov [img_framebuffer], eax
    add eax, [img_framebuffer_size]
    and eax, ecx
    add eax, 16
    mov [img_rgbbuf], eax
endif 
    ret
endp renderer_init

UDATASEG
ifdef NASM
    vesa_lfb: resb (VIDEO_FB_WIDTH*VIDEO_FB_WIDTH*VIDEO_FB_BPP)
else
    vesa_lfb db (VIDEO_FB_WIDTH*VIDEO_FB_WIDTH*VIDEO_FB_BPP) dup (?)
endif

DATASEG
    viewport_height dd 2.0

    ;; These are set in renderer_init(
    img_framebuffer       dd 0
    img_rgbbuf            dd 0
    img_framebuffer_size  dd 0
    img_rgbbuf_size       dd 0

    render_start_str db "Render start", 0

END 
