IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "utils.inc"
include "config.inc"

include "gui/gui.inc"

CODESEG

;; GUI COLOR PALETTE https://colorhunt.co/palette/0f2c67cd1818f3950df4e185

proc gui_init
    uses eax

    call open_file, offset font_file_name, 0
    call read_file, eax, offset font_array, FONTFILE_SIZE
    
    ret
endp gui_init

proc gui_start

    call fill_background, 0F2C67h
    call text_plot, 10, 5, offset title_name_string, 0CD1818h 
    call draw_horizontal_line, 0, [config_video_img_width], 45, 0CD1818h 

    ret
endp gui_start

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

proc draw_horizontal_line
    arg @@x1:dword, @@x2:dword, @@y:dword, @@color:dword
    uses eax, ebx, ecx, edx

    mov eax, [@@x1]
    mov ebx, [@@x2]

    @@printline:
        cmp eax, ebx
        jg @@end
        call pixel_plot, eax, [@@y], [@@color]
        inc eax
        jmp @@printline

    @@end:
    ret
endp draw_horizontal_line

proc draw_vertical_line
    arg @@x:dword, @@y1:dword, @@y2:dword, @@color:dword
    uses eax, ebx

    mov eax, [@@y1]
    mov ebx, [@@y2]
    @@printline:
        cmp eax, ebx
        jg @@end
        call pixel_plot, [@@x], eax, [@@color]
        inc eax
        jmp @@printline

    @@end:    
    ret
endp draw_vertical_line    

proc draw_button
    arg @@x1:dword, @@y1:dword, @@text:dword, @@backgroundcolor:dword
    uses eax, ebx

    mov eax, [@@x1]
    add eax, 200

    mov ebx, [@@y1]
    add ebx, 80

    call draw_rect, [@@x1], [@@y1], eax, ebx, [@@backgroundcolor]
    call draw_vertical_line, [@@x1], [@@y1], ebx, 0ff2540h   ;;add these later for   3D effect
    call draw_vertical_line, eax, [@@y1], ebx, 0ff2540h 

    sub ebx, 45

    call text_plot, [@@x1], ebx, offset test_str, 000000h
    ret
endp draw_button


proc draw_rect
    arg @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword, @@color:dword 
    uses ebx, edx

    mov ebx, [@@y1]
    mov edx, [@@y2]

    @@printlines:
        cmp ebx, edx
        jg @@end
        call draw_horizontal_line, [@@x1], [@@x2], ebx, [@@color]
        inc ebx
        jmp @@printlines

    @@end:
    ret
endp draw_rect   

proc char_plot_double
    arg @@x_coord:dword, @@y_coord:dword, @@char:dword, @@color:dword
    uses eax, ebx, ecx, edx, edi

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
        jl @@end_width_loop

        movzx eax, [byte ptr edi]
        shr eax, cl ;; ecx
        and eax, 1
        cmp eax, 1
        jne @@continue   

        mov eax, [@@x_coord]
        inc eax
        mov ebx, [@@y_coord]
        inc ebx

        call pixel_plot, [@@x_coord], [@@y_coord], [@@color]
        call pixel_plot, eax, [@@y_coord], [@@color]
        call pixel_plot, [@@x_coord], ebx, [@@color]
        call pixel_plot, eax, ebx, [@@color]

        @@continue:
        add [@@x_coord], 2
        dec ecx
        jmp @@width_loop

@@end_width_loop:
    add [@@y_coord], 2
    inc edi
    inc edx
    sub [@@x_coord], FONTCHAR_WIDTH*2
    jmp @@height_loop

@@end:
    ret
endp char_plot_double

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
        jl @@end_width_loop

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

    movzx eax, [byte ptr ebx] ; zero extend
    call char_plot_double, [@@x_coord], [@@y_coord], eax, [@@color]

    add [@@x_coord], FONTCHAR_WIDTH*2
    inc ebx
    jmp @@char_loop

@@end:
    ret
endp text_plot
 
DATASEG
    highlighted_component dd, 0
    font_file_name db "FONT.BIN", 0
    font_array db FONTFILE_SIZE dup (?)
    title_name_string db "Assembly Raytracer", 0
    test_str db "Hello world!!", 0
END