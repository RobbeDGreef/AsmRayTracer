IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "renderer.inc"
include "vec.inc"
include "ray.inc"

VESA_VIDEO_ADDR     equ 0A0000h
VESA_BANK_SIZE      equ (64*1024)
VESA_BANK_SWITCHES  equ (VIDEO_GFX_FB_SIZE/VESA_BANK_SIZE)+1

CODESEG

;; Sets the current video mode via the BIOS. 
proc set_video_mode
    arg @@mode:dword
    uses eax, ebx
    ;; We use the bios to set the video mode
    mov eax, 4f02h
    mov ebx, [@@mode]
    int 10h
    ret
endp set_video_mode

;; Local function, switches vesa banks
proc set_bank
    arg @@bank_number:dword
    uses eax, ebx, edx

    mov eax, 04f05h
    xor bx, bx
    mov edx, [@@bank_number]

    int 10h

    ret
endp set_bank

;; Writes the current video framebuffer contents to the screen
;; WARNING: This is a slow function becaue it needs to convert all the RGB float
;; values to integers.
proc renderer_flip
    uses eax, edi, esi
    xor eax, eax

    lea esi, [video_framebuffer]
@@copy_loop:
    cmp eax, VESA_BANK_SWITCHES
    je @@end
    call set_bank, eax

    mov edi, VESA_VIDEO_ADDR
    
    @@bank_fill_loop:
        cmp edi, VESA_VIDEO_ADDR+VESA_BANK_SIZE
        je @@continue

        fld [dword ptr esi]
        fmul [float_max_char]
        fistp [word ptr edi]

        fld [dword ptr esi+4]
        fmul [float_max_char]
        fistp [word ptr edi+1]

        fld [dword ptr esi+8]
        fmul [float_max_char]
        fistp [word ptr edi+2]

        add edi, 4
        add esi, VEC_SIZE
        jmp @@bank_fill_loop

    @@continue:
    
    inc eax
    jmp @@copy_loop

@@end:
    ret
endp renderer_flip

proc cast_ray
    arg @@ray:PTR Ray, @@dest_color:PTR Color

    call vec_set, [@@dest_color], [float_1], [float_1], [float_1]

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
          @@ray:Ray, @@u:dword, @@v:dword
    uses eax, ecx, ebx, edx, edi, esi

    ;; camera_loc = (0, 0, 0)
    lea eax, [@@camera_loc]
    call vec_set, eax, [float_0], [float_0], [float_0]
    
    ;; horizontal = (viewport_height * aspect_ratio, 0, 0)
    lea eax, [@@horizontal]
    fld [viewport_height]
    fmul [aspect_ratio]
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
    
    call vec_set, ebx, [float_0], [float_0], [focal_length]
    call vec_sub, eax, eax, ebx

    lea esi, [video_framebuffer]
    mov eax, VIDEO_GFX_HEIGHT
    dec eax

@@height_loop:
    cmp eax, 0
    jl @@end_height_loop

    mov ebx, 0

    @@width_loop:
        cmp ebx, VIDEO_GFX_WIDTH
        jge @@end_width_loop
        
        fld [image_width_minus_1]
        mov [@@temp], ebx
        fild [@@temp]
        fdiv
        fstp [@@u]
        fld [image_height_minus_1]
        mov [@@temp], eax
        fild [@@temp]
        fdiv
        fstp [@@v]

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

DATASEG
    ;; Shouldn't be hard coded but this is faster
    image_width_minus_1  dd 799.0
    image_height_minus_1 dd 599.0

    aspect_ratio dd 1.333333    ;; 800/600
    focal_length dd 1.0

    viewport_height dd 2.0

UDATASEG
    video_framebuffer Color (VIDEO_GFX_FB_SIZE/4) dup (?)

END 
