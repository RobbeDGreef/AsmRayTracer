IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "vec.inc"

CODESEG
    jmp main

proc main
    sti
    cld

    ;; Initialize the FPU for floating point operations
    finit

    call log_str, offset start_str
    
    call exit, 0
endp main

DATASEG
    start_str db "Ray tracer started", 0

STACK 1000h

END