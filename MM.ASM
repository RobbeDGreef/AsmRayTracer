IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "mm.inc"

CODESEG

proc mm_init
    mov [mm_start_addr], 0400000h ;; load the memory manager at 4mb
    ret
endp mm_init

ifdef NASM
extern malloc
endif

proc alloc
    arg @@size:dword
    uses ebx
ifndef NASM
    mov eax, [mm_start_addr]
    mov ebx, [@@size]
    add [mm_start_addr], ebx
else
    ;; Allocate a little more memory
    ;; I wanted to use the linux brk syscall but it is giving me a hard time
    ;; so i'm going to be lazy and link in malloc. This is safer anyway.

    ;; linux uses a different calling convention so we need to save ALL the
    ;; registers we are using. And since this includes all the registers
    ;; functions in our backtrace are using as well, we will simply
    ;; push and pop all regs (except eax and ebx since we are already 
    ;; returning/saving them)
    push ecx
    push edx
    push edi
    push esi
    call malloc, [@@size]
    pop esi
    pop edi
    pop edx
    pop ecx
endif

    ret
endp alloc

;; Since we use a single allocation memory manager. A free function is not yet
;; necessary.

DATASEG
    mm_start_addr dd 0

END