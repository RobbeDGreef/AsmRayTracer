IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "utils.inc"

include "gui/gui.inc"

CODESEG

proc gui_init
    uses eax

    call open_file, offset font_file_name, 0
    call read_file, eax, offset font_array, FONTFILE_SIZE

    ret
endp gui_init

proc fill_background
    arg @@color:dword
    uses eax, ebx, ecx, edx, edi

    mov eax, [@@color]
    mov ecx, VIDEO_MAX_FB_SIZE / 4
    ; video_framebuffer is buffer
    lea edi, [vesa_lfb]
    rep stosd
    
ret
endp fill_background

;; todo: optimize, remove registers pushes and just trash some registers, essentially making it an inline function 
proc pixel_plot
    arg @@x_coord:dword, @@y_coord:dword, @@color:dword
    uses eax, ebx, edx

    mov eax, VIDEO_FB_WIDTH
    mul [@@y_coord]
    add eax, [@@x_coord]
    lea ebx, [vesa_lfb + eax*4]
    mov edx, [@@color]
    mov [ebx], edx

    ret
endp

proc char_plot
    arg @@x_coord:dword, @@y_coord:dword, @@char:dword, @@color:dword
    uses eax, ecx, edx, edi

    mov eax, FONTCHAR_SIZE
    mul [@@char]
    lea edi, [font_array + eax]

    xor edx, edx
@@height_loop:
    cmp edx, FONTCHAR_HEIGHT
    je @@end
    
    mov ecx, (FONTCHAR_WIDTH-1)
    @@width_loop:
        cmp ecx, 0
        js @@end_width_loop

        movzx eax, [byte ptr edi]
        shr eax, cl
        and eax, 1
        cmp eax, 1
        jne @@continue

        call pixel_plot, [@@x_coord], [@@y_coord], [@@color]

        @@continue:
        inc [@@x_coord]
        dec ecx
        jmp @@width_loop

@@end_width_loop:
    inc [@@y_coord]
    inc edi
    inc edx
    sub [@@x_coord], FONTCHAR_WIDTH
    jmp @@height_loop

@@end:
    ret
endp char_plot

proc text_plot
    arg @@x_coord:dword, @@y_coord:dword, @@text:dword, @@color:dword
    uses eax, ebx

    mov ebx, [@@text]
@@char_loop:
    cmp [byte ptr ebx], 0
    je @@end

    movzx eax, [byte ptr ebx]
    call char_plot, [@@x_coord], [@@y_coord], eax, [@@color]

    add [@@x_coord], FONTCHAR_WIDTH
    inc ebx
    jmp @@char_loop

@@end:
    ret
endp text_plot

proc gui_clear_line
    arg @@line:dword
    uses eax, ebx, ecx, edi

    lea edi, [vesa_lfb]
    xor ebx, ebx
@@clear_loop:
    cmp ebx, FONTCHAR_HEIGHT
    je @@end

    mov eax, 0
    mov ecx, VIDEO_FB_WIDTH
    rep stosd

    inc ebx
    jmp @@clear_loop

@@end:
    ret
endp gui_clear_line

proc gui_progress_notify
    arg @@done:dword, @@total:dword
    uses eax, edx

    mov eax, 100
    mul [@@done]
    div [@@total]

ifdef NASM
    call print_int, eax
    call print_newline
else
    call gui_clear_line, 0
    call itoa, eax, offset buf, 10
    call text_plot, 0, 0, offset buf, 0ffffffh
    call video_buffer_flip
endif

    ret
endp gui_progress_notify

DATASEG
    buf db 32 dup (0)
    font_file_name db "GUI\FONT.BIN", 0
    font_array db FONTFILE_SIZE dup (?)

END