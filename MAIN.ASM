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
    uses eax, ebx, ecx, edx, edi, esi

    call init

    call log_str, offset start_str
    call set_video_mode, VIDEO_MODE_GRAPHICS
    
    ;call renderer_render
    call fill_background


ifndef NASM
    call renderer_flip
else
    call renderer_to_bmp, offset bmpout
endif

    call log_str, offset finished_str

ifndef NASM
    call sleep_millis, 8000
endif

    call set_video_mode, VIDEO_MODE_TEXT
    call exit, 0
endp main

STACK 5000h

DATASEG
    start_str db "Ray tracer started", 0
    finished_str db "Ray tracer finished", 0
    bmpout db "test.bmp", 0

END main