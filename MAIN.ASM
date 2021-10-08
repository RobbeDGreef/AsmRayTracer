IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "vec.inc"
include "renderer.inc"

CODESEG
    jmp main

proc main
    uses eax, ebx, ecx, edx, edi, esi
    sti
    cld

    ;; Set the extra segment to be the same as the data segment
    ;; This is probably not necessary because everytime we use ES we probably
    ;; explicitly set it to some value but better safe than sorry
    mov ax, ds
    mov es, ax

    ;; Initialize the FPU for floating point operations
    finit

    call log_str, offset start_str
    call set_video_mode, VIDEO_MODE_GRAPHICS
    
    call sleep_millis, 500

    call set_video_mode, VIDEO_MODE_TEXT
    call exit, 0
endp main

STACK 5000h

DATASEG
    start_str db "Ray tracer started", 0

END main