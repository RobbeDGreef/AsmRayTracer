IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "vec.inc"
include "renderer.inc"
include "init.inc"

CODESEG

proc main
    uses eax, ebx, ecx, edx, edi, esi
    local @@temp:dword

    call init


    call log_str, offset start_str
    call set_video_mode, VIDEO_MODE_GRAPHICS
    
    mov eax, VIDEO_GFX_HEIGHT
    dec eax
    lea ecx, [video_framebuffer]

@@height_loop:
    cmp eax, 0
    jl @@end_height_loop

    mov ebx, 0

    @@width_loop:
        cmp ebx, VIDEO_GFX_WIDTH
        jge @@end_width_loop
        
        mov [@@temp], ebx
        fild [@@temp]
        fdiv [image_width]
        fstp [dword ptr ecx+8]

        mov [@@temp], eax
        fild [@@temp]
        fdiv [image_height]
        fstp [dword ptr ecx+4]

        mov edx, [float_0_25]
        mov [ecx], edx

        add ecx, VEC_SIZE

        inc ebx
        jmp @@width_loop

    @@end_width_loop:
    dec eax
    jmp @@height_loop


@@end_height_loop:

    call renderer_flip

    call sleep_millis, 1000

    call set_video_mode, VIDEO_MODE_TEXT
    call exit, 0
endp main

STACK 5000h

DATASEG
    start_str db "Ray tracer started", 0

    image_width dd 799.0
    image_height dd 599.0

END main