IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"

VESA_VIDEO_ADDR     equ 0A0000h
VESA_BANK_SIZE      equ (64*1024)
VESA_BANK_SWITCHES  equ (VIDEO_FB_SIZE/VESA_BANK_SIZE)+1

CODESEG

;; Sets the current video mode via the BIOS. 
proc video_set_mode
    arg @@mode:dword
    uses eax, ebx
    ;; We use the bios to set the video mode
    mov eax, 4f02h
    mov ebx, [@@mode]

ifndef NASM
    int 10h
endif
    ret
endp video_set_mode

;; Local function, switches vesa banks
proc video_set_bank
    arg @@bank_number:dword
    uses eax, ebx, edx

    mov eax, 04f05h
    xor bx, bx
    mov edx, [@@bank_number]

ifndef NASM
    int 10h
endif

    ret
endp video_set_bank

proc video_buffer_flip
    uses eax, ecx, edi, esi

    xor eax, eax
    lea esi, [vesa_lfb]

@@copy_loop:
    cmp eax, VESA_BANK_SWITCHES
    je @@end
    call video_set_bank, eax

    mov edi, VESA_VIDEO_ADDR
    mov ecx, VESA_BANK_SIZE/4
    rep movsd
    
    inc eax
    jmp @@copy_loop

@@end:
    ret
endp video_buffer_flip

UDATASEG
ifdef NASM
    vesa_lfb: resb (VIDEO_FB_WIDTH*VIDEO_FB_WIDTH*VIDEO_FB_BPP)
else
    vesa_lfb db (VIDEO_FB_WIDTH*VIDEO_FB_WIDTH*VIDEO_FB_BPP) dup (?)
endif


END