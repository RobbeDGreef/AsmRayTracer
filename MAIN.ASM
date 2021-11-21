IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "vec.inc"
include "video.inc"
include "renderer.inc"
include "init.inc"
include "gui.inc"
include "scene.inc"
include "sphere.inc"
include "mm.inc"

CODESEG

GLOBAL main:PROC

proc main
    local @@begin_time:dword, @@scene:Scene, @@sphere:Sphere, @@loc:Vec,\
          @@sphere2:Sphere
    uses eax, ebx, ecx, edx, edi, esi

    call init
    call gui_init
    call mm_init

    call log_str, offset start_str
    call gettime_millis
    mov [@@begin_time], eax
    call video_set_mode, VIDEO_MODE_GRAPHICS
    
    ;; Setting up our scene
    lea ebx, [@@scene]
    call scene_init, ebx

    lea edx, [@@loc]
    lea ecx, [@@sphere2]
    call vec_set, edx, [float_0], [sphere2_y], [float_minus_1]
    call sphere_set, ecx, edx, [sphere2_radius]
    call scene_add, ebx, ecx

    lea ecx, [@@sphere]
    call vec_set, edx, [float_0], [float_0], [float_minus_1]
    call sphere_set, ecx, edx ,[float_0_50]
    call scene_add, ebx, ecx

    call renderer_init

ifndef NASM
    call text_plot, 0, 0, offset loading_str, 0ffffffh
    call video_buffer_flip
endif

    call renderer_render, ebx
    
ifndef NASM
    call renderer_show_img
    call sleep_millis, 3000
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
    loading_str db "Loading...", 0

    test_str db "Hello world!!", 0

    sphere2_radius dd 100.0
    sphere2_y dd -100.5

END main