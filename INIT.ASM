IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "init.inc"

CODESEG

proc init
    local @@temp:word
    uses eax
    ;; Enable interrupts (lol why are we executing ring 0 instructions, dos is
    ;; weird)
    sti
    cld

    ;; Set the extra segment to be the same as the data segment
    ;; This is probably not necessary because everytime we use ES we probably
    ;; explicitly set it to some value but better safe than sorry
    mov ax, ds
    mov es, ax

    ;; Initialize the FPU for floating point operations
    finit

    ;; Set rounding control to 0
    ;; Don't change this because this was one annoying bug to fix. Thank god I 
    ;; remembered this is a thing.
    fnstcw [@@temp]
    mov ax, [@@temp]
    or ax, 0c00h
    mov [@@temp], ax
    fldcw [@@temp]

    ret
endp init

END