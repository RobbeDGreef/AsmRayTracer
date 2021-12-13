IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "rt/vec.inc"
include "rt/renderer.inc"
include "rt/scene.inc"
include "rt/sphere.inc"
include "gui/gui.inc"

include "rt/mat/lmbrtian.inc"
include "rt/mat/metal.inc"
include "rt/mat/unlit.inc"
include "rt/mat/emissive.inc"

include "init.inc"
include "utils.inc"
include "mm.inc"

CODESEG

GLOBAL main:PROC

proc main
    local @@begin_time:dword, @@scene:Scene, @@sphere:Sphere, @@loc:Vec,\
          @@sphere2:Sphere, @@lam:Lambertian, @@color:Color, @@met:Metal,\
          @@color2:Color, @@sphere3:Sphere, @@color3:Color, @@unlit:Unlit,\
          @@emission:Emissive, @@color4:Color
    uses eax, ebx, ecx, edx, edi, esi

    call init
    call gui_init
    call mm_init

    call gui_start

    call video_buffer_flip

    call log_str, offset start_str
    call gettime_millis
    mov [@@begin_time], eax
    call video_set_mode, VIDEO_MODE_GRAPHICS
    
    ;; Setting up our scene
    lea ebx, [@@scene]
    call scene_init, ebx

    lea eax, [@@color]
    call vec_set, eax, [float_0_75], [float_0_25], [float_0_25]
    lea edi, [@@lam]
    call lambertian_init, edi, eax

    lea eax, [@@color2]
    call vec_set, eax, [float_0], [float_0_50], [float_0_75]
    lea edi, [@@met]
    call metal_init, edi, eax

    lea eax, [@@color3]
    call vec_set, eax, [float_0_20], [float_0_25], [float_0_90]
    lea edi, [@@unlit]
    call unlit_init, edi, eax

    lea eax, [@@color4]
    call vec_set, eax, [float_1], [float_1], [float_1]
    lea edi, [@@emission]
    call emissive_init, edi, eax, [float_2]

    lea edx, [@@loc]
    lea ecx, [@@sphere2]
    lea edi, [@@lam]
    call vec_set, edx, [float_0], [sphere2_y], [float_minus_1]
    call sphere_set, ecx, edx, [sphere2_radius], edi
    call scene_add, ebx, ecx

    lea ecx, [@@sphere]
    lea edi, [@@lam]
    call vec_set, edx, [float_0], [float_0], [float_minus_1]
    call sphere_set, ecx, edx ,[float_0_50], edi
    call scene_add, ebx, ecx

    lea ecx, [@@sphere3]
    lea edi, [@@emission]
    call vec_set, edx, [float_0_75], [float_0_25], [float_minus_0_75]
    call sphere_set, ecx, edx, [float_0_25], edi
    call scene_add, ebx, ecx

    ;; End setting up scene

    ;; Start renderer
    ;;call renderer_init
    ;;call renderer_render, ebx
    
ifndef NASM
   ;; call renderer_show_img
    call sleep_millis, 6000
else
    call renderer_to_bmp, offset bmpout
endif

    call video_set_mode, VIDEO_MODE_TEXT

    mov ebx, [@@begin_time]
    call gettime_millis
    sub eax, ebx
    call print_str, offset finished_str
    call print_int, eax
    call print_str, offset finished_str2
    call print_newline

    call exit, 0
endp main

STACK 5000h

DATASEG
    start_str db "Ray tracer started", 0
    finished_str db "Ray tracer finished in ", 0
    finished_str2 db " milliseconds", 0
    bmpout db "test.bmp", 0

    test_str db "Hello world!!", 0

    sphere2_radius dd 100.0
    sphere2_y dd -100.5

END main