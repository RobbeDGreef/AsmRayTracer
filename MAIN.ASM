IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "vec.inc"
include "renderer.inc"
include "init.inc"
include "gui.inc"

CODESEG

GLOBAL main:PROC

proc main
    local @@begin_time:dword
    uses eax, ebx, ecx, edx, edi, esi

    call init

    call log_str, offset start_str
    call gettime_millis
    mov [@@begin_time], eax
    call set_video_mode, VIDEO_MODE_GRAPHICS
    
    call renderer_init
    ;call renderer_render
    call fill_background

    ;call renderer_render

ifndef NASM
    call renderer_buf_to_screen
else
    call renderer_to_bmp, offset bmpout
endif


ifndef NASM
    call sleep_millis, 3000
endif

    call set_video_mode, VIDEO_MODE_TEXT

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

END main