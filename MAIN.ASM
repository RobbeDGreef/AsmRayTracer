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

    call init

    call log_str, offset start_str
    call set_video_mode, VIDEO_MODE_GRAPHICS
    
    call renderer_render
    call renderer_flip

    call sleep_millis, 1000

    call set_video_mode, VIDEO_MODE_TEXT
    call exit, 0
endp main

STACK 5000h

DATASEG
    start_str db "Ray tracer started", 0

END main