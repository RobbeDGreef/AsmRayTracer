IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "renderer.inc"
include "vec.inc"

VESA_VIDEO_ADDR     equ 0A0000h
VESA_BANK_SIZE      equ (64*1024)
VESA_BANK_SWITCHES  equ (VIDEO_GFX_FB_SIZE/VESA_BANK_SIZE)+1

CODESEG

;; Sets the current video mode via the BIOS. 
proc set_video_mode
    arg @@mode:dword
    uses eax, ebx
    ;; We use the bios to set the video mode
    mov eax, 4f02h
    mov ebx, [@@mode]
    int 10h
    ret
endp set_video_mode

;; Local function, switches vesa banks
proc set_bank
    arg @@bank_number:dword
    uses eax, ebx, edx

    mov eax, 04f05h
    xor bx, bx
    mov edx, [@@bank_number]

    int 10h

    ret
endp set_bank

;; Writes the current video framebuffer contents to the screen
;; WARNING: This is a slow function becaue it needs to convert all the RGB float
;; values to integers.
proc renderer_flip
    uses eax, edi, esi
    xor eax, eax

    lea esi, [video_framebuffer]
@@copy_loop:
    cmp eax, VESA_BANK_SWITCHES
    je @@end
    call set_bank, eax

    mov edi, VESA_VIDEO_ADDR
    
    @@bank_fill_loop:
        cmp edi, VESA_VIDEO_ADDR+VESA_BANK_SIZE
        je @@continue

        fld [dword ptr esi]
        fmul [float_max_char]
        fistp [word ptr edi]

        fld [dword ptr esi+4]
        fmul [float_max_char]
        fistp [word ptr edi+1]

        fld [dword ptr esi+8]
        fmul [float_max_char]
        fistp [word ptr edi+2]

        add edi, 4
        add esi, VEC_SIZE
        jmp @@bank_fill_loop

    @@continue:
    
    inc eax
    jmp @@copy_loop

@@end:
    ret
endp renderer_flip

UDATASEG
    video_framebuffer Color (VIDEO_GFX_FB_SIZE/4) dup (?)

END 