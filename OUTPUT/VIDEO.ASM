IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "utils.inc"

VESA_VIDEO_ADDR     equ 0A0000h
VESA_BANK_SIZE      equ (64*1024)
VESA_BANK_SWITCHES  equ (VIDEO_FB_SIZE/VESA_BANK_SIZE)+1

CODESEG

;; Small VESA video driver for our project. It handles all the interactions with
;; the VESA video buffer (because we don't have a real vesa LFB). It also
;; handles mouse pointer drawing.

;; Plots a pixel directly into the vesa video memory
proc video_vesa_plot_pixel
    arg @@x_coord:dword, @@y_coord:dword, @@color:dword
    uses eax, ebx, ecx, edx

    mov eax, VIDEO_FB_WIDTH
    mul [@@y_coord]
        add eax, [@@x_coord]
    shl eax, 2 ;; * 4
    mov ebx, VESA_BANK_SIZE
    div ebx
    ;; now eax will contain the bank we should select and edx contains the
    ;; pixel address (we still have to add the vesa video memory address tho)
    call video_set_bank, eax
    mov ecx, [@@color]
    add edx, VESA_VIDEO_ADDR
    mov [edx], ecx

    ret
endp video_vesa_plot_pixel

;; Copies a rectangle from the vesa_lfb to the vesa video memory
;; This can be used to over write video memory with something that should be
;; there according to the vesa lfb (e.i. undraw mouse pointer)
proc video_vesa_copy_rect
    arg @@x_coord:dword, @@y_coord:dword, @@width:dword, @@height:dword
    uses eax, ebx, ecx, edx

    mov edx, [@@y_coord]
    mov eax, VIDEO_FB_WIDTH
    mul edx
    add eax, [@@x_coord]
    shl eax, 2 ;; * 4
    add eax, offset vesa_lfb
    mov edx, eax

    mov ecx, [@@height]
@@height_loop:
    cmp ecx, 0
    je @@end

    mov ebx, 0
    @@width_loop:
        cmp ebx, [@@width]
        je @@width_loop_end

        ;; The video_vesa_plot_pixel handles bank switching for us. Thanks 
        ;; video_vesa_plot_pixel!! 
        ;; Recalculating the location in that function is not terribly efficient
        ;; but its fast enough
        mov eax, [edx+ebx*4]
        call video_vesa_plot_pixel, [@@x_coord], [@@y_coord], eax

        inc [@@x_coord]
        inc ebx
        jmp @@width_loop
    @@width_loop_end:

    add edx, (VIDEO_FB_WIDTH*4)
    inc [@@y_coord]
    mov eax, [@@width]
    sub [@@x_coord], eax
    dec ecx
    jmp @@height_loop

@@end:
    ret
endp video_vesa_copy_rect

;; Set the pointer to the cursor bitmap in memory that the mouse will use
proc video_set_mouse_bitmap
    arg @@bitmap:dword
    uses eax
    mov eax, [@@bitmap]
    mov [video_mouse_bitmap], eax
    ret
endp video_set_mouse_bitmap

;; Undraws the previous mouse and draws the new one.
proc video_update_mouse
    arg @@x_coord:dword, @@y_coord:dword, @@color:dword
    uses eax
    ;; Remove previous mouse pointer by redrawing from the vesa_lfb
    call video_vesa_copy_rect, [video_mouse_x], [video_mouse_y], CURSOR_WIDTH, \
                               CURSOR_HEIGHT
    
    ;; Draw new pointer
    call video_draw_mouse_bitmap, [video_mouse_bitmap], [@@x_coord], \
                                  [@@y_coord], [@@color]
    
    ;; Set previous coords so we can undraw the mouse when it gets updated
    mov eax, [@@x_coord]
    mov [video_mouse_x], eax
    mov eax, [@@y_coord]
    mov [video_mouse_y], eax
    ret
endp video_update_mouse

;; The actual mouse drawing function. Simple loop over the bitmap.
proc video_draw_mouse_bitmap
    arg @@cursor_bitmap:PTR byte, @@x_coord:dword, @@y_coord:dword, \
        @@color:dword
    uses eax, ecx, edx

    xor eax, eax
    mov edi, [@@cursor_bitmap]

    xor edx, edx
@@height_loop:
    cmp edx, CURSOR_HEIGHT
    je @@end

    mov ecx, (CURSOR_WIDTH - 1)
    @@width_loop:
        cmp ecx, 0
        jl @@end_width_loop

        ;; The BITmap is BIT encoded. Shocking, I know. So we have to shift
        ;; right a couple of times and 'and' with 1 to get the bit we want to
        ;; draw (or not draw)

        movzx eax, [byte ptr edi]
        shr eax, cl
        and eax, 1
        cmp eax, 1 
        jne @@continue

        call video_vesa_plot_pixel, [@@x_coord], [@@y_coord], [@@color]

        @@continue:
        inc [@@x_coord]
        dec ecx
        jmp @@width_loop

@@end_width_loop:
    inc [@@y_coord]
    inc edi
    inc edx
    sub [@@x_coord], CURSOR_WIDTH
    jmp @@height_loop

@@end:
    ret
endp video_draw_mouse_bitmap

;; Sets the current video mode via the BIOS. 
proc video_set_mode
    arg @@mode:dword
    uses eax, ebx
    ;; Ask the bios vesa driver nicely to change the video mode
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

    ;; To reduce unnecessary bank switches, save the previous bank index in
    ;; memory.
    mov edx, [@@bank_number]
    cmp [video_current_bank], edx
    je @@end

    ;; 04f05h is the switch vesa banks BIOS function
    mov eax, 04f05h
    xor bx, bx
    mov [video_current_bank], edx

    ;; Only execute this function in dosbox
ifndef NASM
    int 10h
endif

@@end:
    ret
endp video_set_bank

;; Writes the video buffer to screen. (per vesa bank)
proc video_buffer_flip
    uses eax, ecx, edi, esi

    xor eax, eax
    lea esi, [vesa_lfb]

@@copy_loop:
    cmp eax, VESA_BANK_SWITCHES
    je @@end
    ;; Set the video bank
    call video_set_bank, eax

    ;; Copy all the data from the buffer into the vesa bank
    mov edi, VESA_VIDEO_ADDR
    mov ecx, VESA_BANK_SIZE/4
    rep movsd
    
    inc eax
    jmp @@copy_loop

@@end:
    ret
endp video_buffer_flip

DATASEG
    video_mouse_bitmap  dd 0
    video_current_bank  dd 0
    video_mouse_x       dd 0
    video_mouse_y       dd 0

UDATASEG

;; Nasm handles reserving data differently then TASM
ifdef NASM
    vesa_lfb: resb (VIDEO_FB_WIDTH*VIDEO_FB_WIDTH*VIDEO_FB_BPP)
else
    vesa_lfb db (VIDEO_FB_WIDTH*VIDEO_FB_WIDTH*VIDEO_FB_BPP) dup (?)
endif


END