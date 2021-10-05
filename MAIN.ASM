IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "utils.inc"

SCREEN_WIDTH    EQU 640
SCREEN_HEIGHT   EQU 480
VM_ADDR         EQU 0A0000h

CODESEG
    jmp main

proc main
    ;; Aren't these ring 0 instructions ???
    sti
    cld

    call print_str, offset teststr
    call print_space
    call print_hex, 0deadbeefh
    call print_space
    call print_int, -123
    call print_newline
    call exit, 0
endp main

DATASEG
    teststr db "Hello world!", 0
    log_file db "logfile.log", 0

STACK 1000h

END