IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "utils.inc"
include "config.inc"
include "gui/mouse.inc"

include "output/video.inc"

include "gui/gui.inc"

CODESEG

;; GUI COLOR PALETTE https://colorhunt.co/palette/0f2c67cd1818f3950df4e185

proc gui_init
    uses eax, ebx

    call open_file, offset font_file_name, 0
    mov ebx, eax
    call read_file, ebx, offset font_array, FONTFILE_SIZE
    call close_file, ebx

    call open_file, offset cursor_file_name, 0
    mov ebx, eax
    call read_file, ebx, offset cursor_array, CURSORFILE_SIZE
    call close_file, ebx

    ret
endp gui_init

proc gui_destruct
    call mouse_uninstall
    ret
endp gui_destruct

proc gui_start
    call fill_background, 0F2C67h
    call text_plot, 10, 5, offset title_name_string, 0CD1818h 
    call draw_horizontal_line, 0, [config_video_img_width], 45, 0CD1818h 

    call draw_start_button, 50, 475
    call draw_sample_count, 100, 100
    call draw_focal_length, 100, 130
    call draw_video_height, 100, 160
    call draw_video_width, 100, 190

    call video_buffer_flip

    call mouse_init
    
    ret
endp gui_start

;; ---------------------------------------------------------------
;;                        MAIN FUNCTIONALITY
;; ---------------------------------------------------------------

proc set_config_values
    uses eax

    lea eax, [max_bounces_string_buffer]
    call atoi, eax
    mov [config_render_max_bounces], eax

    lea eax, [sample_count_string_buffer]
    call atoi, eax
    mov [config_render_samples], eax

    lea eax, [fov_string_buffer]
    call atof, eax
    mov [config_video_img_fov], eax

    lea eax, [video_height_string_buffer]
    call atoi, eax
    mov [config_video_img_height], eax

    lea eax, [video_width_string_buffer]
    call atoi, eax
    mov [config_video_img_width], eax

    lea eax, [cam_pos_x_string_buffer]
    call atof, eax
    mov [config_render_cam_pos], eax

    lea eax, [cam_pos_y_string_buffer]
    call atof, eax
    mov [config_render_cam_pos + 4], eax

    lea eax, [cam_pos_z_string_buffer]
    call atof, eax
    mov [config_render_cam_pos + 8], eax

    ret
endp set_config_values

proc main_loop

    @@run:
    ;; check whether running_main_loop is 1
    cmp [running_main_loop], 1
    jne @@end

    mov bl, [keyb_keys_active]

    cmp bl, 0
    je @@skipkeyhandle

    cmp [key_reset], 1
    jne @@run

    movzx ebx, [keyb_raw_scan_code]
    movzx eax, [byte ptr character_mapping + ebx] ;; character

    mov ebx, [selected_field] ;; field pointer
    cmp ebx, 0
    je @@nofieldselected

    mov ecx, [ebx + Field.value] ;; value pointer
    call append, ecx, eax
    call draw_field, ebx, 0F4E185h 
    call video_buffer_flip

@@nofieldselected:

    mov [key_reset], 0
    jmp @@run

    @@skipkeyhandle:
    mov [key_reset], 1

    jmp @@run

@@end:
    call set_config_values

ret
endp main_loop

proc handle_click
    arg @@x_coord:dword, @@y_coord:dword

    mov eax, [@@x_coord]
    mov ebx, [@@y_coord]
    xor ecx, ecx
    jmp @@buttonloop

@@nextbutton:
    inc ecx

@@buttonloop:
    cmp ecx, [button_count]
    jge @@end

    mov edx, [button_array + 4*ecx] ;; get button
    mov esi, [edx + Button.upperleft]
    mov edi, [edx + Button.bottomright]

    mov edx, [esi + Coordinate.x]
    cmp edx, [@@x_coord]
    jl @@nextbutton ;; check whether it's not smaller than the starting x

    mov edx, [edi + Coordinate.x]
    cmp edx, [@@x_coord]
    jg @@nextbutton ;; Check whether it's not bigger than the second x

    mov edx, [esi + Coordinate.y]
    cmp edx, [@@y_coord]
    jl @@nextbutton ;; Check whether it's not smaller than the starting y

    mov edx, [edi + Coordinate.y]
    cmp edx, [@@y_coord]
    jg @@nextbutton ;; Check whether it's not bigger than second y

    ;; We clicked this button
    mov edx, [button_array + 4 * ecx] 
    call [edx + Button.onclick] ;; Call the corresponding action

@@end:
    ret
endp handle_click

proc mouse_handler
    uses eax, ebx, ecx, edx, edi, esi

    movzx eax, dx		; get mouse height 
	
    ;; This isn't true as far as i can tell ??
    ;sar cx, 1			; horizontal cursor position is doubled in input 
    movzx ebx, cx

    call log_int, eax ;; y
    call log_int, ebx ;; x

    lea edi, [last_cursor_position]
    ;; This won't fully work. What if the user hovered over something else than the background?
    call cursor_plot, [edi + Coordinate.x], [edi + Coordinate.y], 0F2C67h ;;  remove old cursor

    lea esi, [edi + Coordinate.x]
    mov [esi], ebx
    lea esi, [edi + Coordinate.y]
    mov [esi], eax

    call cursor_plot, ebx, eax, 0CD1818h
    call video_buffer_flip  

	and bl, 3			; check for two mouse buttons (2 low end bits)
	jz @@skip_click_handle			; only execute if a mousebutton is pressed

    ;; check clicks here
    ;; call handle_click, x, y <- should handle click

	@@skip_click_handle:
    ret
endp mouse_handler

proc mouse_init ;; TODO UNINSTALL?
    uses eax 
    call mouse_install, offset mouse_handler, VIDEO_FB_WIDTH, VIDEO_FB_HEIGHT
    ret
endp mouse_init

proc fill_background
    arg @@color:dword
    uses eax, ecx, edi

    mov eax, [@@color]
    mov ecx, VIDEO_MAX_FB_SIZE / 4
    ; video_framebuffer is buffer
    lea edi, [vesa_lfb]
    rep stosd
    
    ret
endp fill_background

proc draw_focal_length
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset focal_length_string, 0CD1818h
    add ebx, 300

    ;call itoa, [config_video_img_focal_length], offset focal_length_string_buffer, 10
    ;call text_plot, ebx, ecx, eax, 0CD1818h
    call float_plot, ebx, ecx, [config_video_img_focal_length], 0CD1818h 
    ret
endp draw_focal_length

proc draw_video_height
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset video_height_string, 0CD1818h
    add ebx, 300

    call itoa, [config_video_img_height], offset video_height_string_buffer, 10
    call text_plot, ebx, ecx, eax, 0CD1818h
ret
endp draw_video_height

proc draw_video_width
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset video_width_string, 0CD1818h
    add ebx, 300

    call itoa, [config_video_img_width], offset video_width_string_buffer, 10
    call text_plot, ebx, ecx, eax, 0CD1818h
ret
endp draw_video_width

proc draw_sample_count
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset sample_count_string, 0CD1818h
    add ebx, 300

    call itoa, [config_render_samples], offset sample_count_string_buffer, 10
    call text_plot, ebx, ecx, eax, 0CD1818h

    ;call draw_rect, [@@x1], [@@y1], ebx, eax, [@@backgroundcolor]

ret
endp

proc handle_run_click
    ;; start renderer
    call log_int, 6969
    ret
endp handle_run_click

proc draw_start_button  
    arg @@x:dword, @@y:dword
    
    call draw_button, [@@x], [@@y], 82, offset start_button_string, 0ff2540h, offset handle_run_click 

ret
endp draw_start_button

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
    uses eax, ebx

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
    arg @@x1:dword, @@y1:dword, @@width:dword, @@text:dword, @@backgroundcolor:dword, @@action:dword
    uses eax, ebx, ecx, edx, edi
    local @@upper_left:PTR Coordinate, @@bottom_right:PTR Coordinate, @@button:PTR Button

    ;; Set coords 
    mov edi, [@@upper_left]

    mov ebx, [@@x1]
    mov [edi + Coordinate.x], ebx
    add ebx, [@@width]

    mov eax, [@@y1]
    mov [edi + Coordinate.y], eax
    add eax, 40 ;; add height

    mov edi, [@@bottom_right]
    mov [edi + Coordinate.x], ebx
    mov [edi + Coordinate.y], eax

    ;; Draw the rectangle
    call draw_rect, [@@x1], [@@y1], ebx, eax, [@@backgroundcolor]

    ;; Align the coords for the text
    mov ebx, [@@x1] 
    add ebx, 18

    sub eax, [@@y1]
    xor edx, edx

    mov ecx, 2
    div ecx

    sub eax, 15
    add eax, [@@y1]

    ;; Draw the text
    call text_plot, ebx, eax, [@@text], 000000h

    ;; Initialise button
    mov edi, [@@button]

    mov eax, [@@upper_left]
    mov [edi + Button.upperleft], eax
    mov eax, [@@bottom_right]
    mov [edi + Button.bottomright], eax
    mov eax, [@@action]
    mov [edi + Button.onclick], eax

    ;; Write button to array
    mov eax, [button_count]
    inc eax
    mov [button_count], eax

    lea edi, [button_array + 4*eax]
    mov eax, [@@button]
    mov [edi], eax

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

proc cursor_plot
    arg @@x_coord:dword, @@y_coord:dword, @@color:dword
    uses eax, ecx, edx, edi

    xor eax, eax
    lea edi, [cursor_array]

    xor edx, edx
@@height_loop:
    cmp edx, CURSOR_HEIGHT
    je @@end

    mov ecx, (CURSOR_WIDTH - 1)
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
    sub [@@x_coord], CURSOR_WIDTH
    jmp @@height_loop

@@end:
    ret
endp cursor_plot

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

proc float_plot
    arg @@x_coord:dword, @@y_coord:dword, @@float:dword, @@color:dword
    local @@temp:dword
    uses eax, ebx

    mov ebx, [@@x_coord]

    xor eax, eax
    fldz 
    fld [@@float]
    fcompp
    fnstsw ax
    fld [@@float]
    shr eax, 8
    and eax, 111B
    cmp eax, 1
    jne @@not_negative
    call char_plot_double, ebx, [@@y_coord], '-', [@@color]
    add ebx, 8
    fld1
    fchs
    fmul ;; make the float positive

@@not_negative:
    fist [@@temp]
    call itoa, [@@temp], offset focal_length_upper_string_buffer, 10
    call text_plot, ebx, [@@y_coord], eax, 0CD1818h
    add ebx, 16
    call char_plot_double, ebx, [@@y_coord], ',', 0CD1818h 
    fild [@@temp]
    fsub
    fld [float_1000000]
    fmul 
    fistp [@@temp]
    add ebx, 16
    call itoa, [@@temp], offset focal_length_lower_string_buffer, 10
    call text_plot, ebx, [@@y_coord], eax, 0CD1818h

    ret
endp float_plot
    

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
    highlighted_component dd (?)

    button_array dd 10 dup (?)
    button_count dd 0

    last_cursor_position dd 0, 0

    buf db 32 dup (0)

    font_file_name db "GUI\FONT.BIN", 0
    font_array db FONTFILE_SIZE dup (?)

    cursor_file_name db "GUI\CURSOR.BIN", 0
    cursor_array db CURSORFILE_SIZE dup (?)

    title_name_string db "Assembly Raytracer", 0

    sample_count_string_buffer db 16 dup (?)
    video_width_string_buffer db 16 dup (?)
    video_height_string_buffer db 16 dup (?)
    focal_length_upper_string_buffer db 16 dup (?)
    focal_length_lower_string_buffer db 16 dup (?)


    start_button_string db "Run", 0
    sample_count_string db "Sample Count: ", 0
    video_width_string db "Image Width: ", 0
    video_height_string db "Image Height: ", 0
    focal_length_string db "Focal Length: ", 0
    test_str db "Hello world!!", 0
END