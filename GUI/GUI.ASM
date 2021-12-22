IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "utils.inc"
include "config.inc"
include "gui/mouse.inc"
include "keyb.inc"
include "mm.inc"

include "output/video.inc"

include "gui/gui.inc"

CODESEG

;; GUI COLOR PALETTE https://colorhunt.co/palette/0f2c67cd1818f3950df4e185

;; ---------------------------------------------------------------
;;                  INITIALISATION AND DESTRUCTION
;; ---------------------------------------------------------------

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
    call draw_video_width, 100, 190
    call draw_video_height, 100, 160
    call draw_fov, 100, 130
    call draw_sample_count, 100, 100
    call draw_max_bounces, 100, 70
    call draw_hdri_path, 100, 220
    call draw_cam_pos_x, 100, 250
    call draw_cam_pos_y, 100, 280
    call draw_cam_pos_z, 100, 310

    call video_buffer_flip

    call mouse_init

    call main_loop
    
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
    uses eax, ebx, ecx, edx, esi, edi

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
    jge @@nextbutton ;; check whether it's not smaller than the starting x

    mov edx, [edi + Coordinate.x]
    cmp edx, [@@x_coord]
    jl @@nextbutton ;; Check whether it's not bigger than the second x

    mov edx, [esi + Coordinate.y]
    cmp edx, [@@y_coord]
    jge @@nextbutton ;; Check whether it's not smaller than the starting y

    mov edx, [edi + Coordinate.y]
    cmp edx, [@@y_coord]
    jl @@nextbutton ;; Check whether it's not bigger than second y

    ;; We clicked this button
    mov edx, [button_array + 4 * ecx] 
    call [edx + Button.onclick] ;; Call the corresponding action

@@end:
    ret
endp handle_click

proc mouse_handler
    uses eax, ebx, ecx, edx

    movzx edx, dx		; get mouse height 
	
    ;; This isn't true as far as i can tell ??
    ;sar cx, 1			; horizontal cursor position is doubled in input 
    movzx ecx, cx

    lea edi, [last_cursor_position]
    
    lea esi, [edi + Coordinate.x]
    mov [esi], ecx
    lea esi, [edi + Coordinate.y]
    mov [esi], edx

    ;; Call this function to draw the mouse on screen (will undraw the previous
    ;; mouse pointer for you)
    call video_update_mouse, ecx, edx, 0CD1818h

	cmp ebx, 1			            ; check for left button press
	jne @@skip_click_handle			; only execute if a mousebutton is pressed

    ;; Handle the click
    call handle_click, ecx, edx

	@@skip_click_handle:
    ret
endp mouse_handler

proc mouse_init 
    uses eax 
    call mouse_install, offset mouse_handler, VIDEO_FB_WIDTH, VIDEO_FB_HEIGHT
    call video_set_mouse_bitmap, offset cursor_array
    ret
endp mouse_init

;; ---------------------------------------------------------------
;;                        FIELD DRAWING
;; ---------------------------------------------------------------

proc register_field_data
    uses eax, ebx, ecx, edx, esi, edi
    arg @@x:dword, @@y:dword, @@value:dword, @@action:dword, @@field:dword

    mov edx, [@@x]
    add edx, 270
    mov ecx, edx
    add ecx, 415

    mov ebx, [@@y]
    add ebx, 16

    mov esi, ebx
    add esi, 23

    call create_button, edx, ebx, ecx, esi, [@@action]
    call register_button, eax

    call create_field, edx, ebx, ecx, esi, [@@value]
    mov ebx, [@@field]
    mov [ebx], eax

    ret
endp register_field_data

proc draw_fov
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx
    mov ebx, [@@x]
    mov ecx, [@@y]

    call memcpy, offset fov_string_buffer, offset fov_default, 5

    add ecx, 12

    call text_plot, ebx, ecx, offset fov_string, 0CD1818h
    add ebx, 300

    call text_plot, ebx, ecx, offset fov_string_buffer, 0CD1818h 

    call register_field_data, [@@x], [@@y], offset fov_string_buffer, offset handle_fov_click, offset fov_field

    ret
endp draw_fov

proc draw_video_height
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset video_height_string, 0CD1818h
    add ebx, 300

    call itoa, [config_video_img_height], offset video_height_string_buffer, 10
    call text_plot, ebx, ecx, eax, 0CD1818h

    call register_field_data, [@@x], [@@y], offset video_height_string_buffer, offset handle_video_height_click, offset video_height_field

ret
endp draw_video_height

proc draw_video_width
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset video_width_string, 0CD1818h
    add ebx, 300

    call itoa, [config_video_img_width], offset video_width_string_buffer, 10
    call text_plot, ebx, ecx, eax, 0CD1818h

    call register_field_data, [@@x], [@@y], offset video_width_string_buffer, offset handle_video_width_click, offset video_width_field
    
ret
endp draw_video_width

proc draw_sample_count
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset sample_count_string, 0CD1818h
    add ebx, 300

    call itoa, [config_render_samples], offset sample_count_string_buffer, 10
    call text_plot, ebx, ecx, eax, 0CD1818h

    call register_field_data, [@@x], [@@y], offset sample_count_string_buffer, offset handle_sample_count_click, offset sample_count_field

ret
endp draw_sample_count

proc draw_max_bounces
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]

    add ecx, 12
    call text_plot, ebx, ecx, offset max_bounces_string, 0CD1818h
    add ebx, 300

    call itoa, [config_render_max_bounces], offset max_bounces_string_buffer, 10
    call text_plot, ebx, ecx, eax, 0CD1818h

   call register_field_data, [@@x], [@@y], offset max_bounces_string_buffer, offset handle_max_bounces_click, offset max_bounces_field

ret
endp draw_max_bounces

proc draw_hdri_path
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]

    call memcpy, offset config_render_hdri_path, offset hdri_path_default, 17

    add ecx, 12
    call text_plot, ebx, ecx, offset hdri_path_string, 0CD1818h
    add ebx, 300

    call text_plot, ebx, ecx, offset config_render_hdri_path, 0CD1818h

    call register_field_data, [@@x], [@@y], offset config_render_hdri_path, offset handle_hdri_path_click, offset hdri_path_field

ret
endp draw_hdri_path

proc draw_cam_pos_x
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]

    call memcpy, offset cam_pos_x_string_buffer, offset cam_pos_x_default, 4

    add ecx, 12
    call text_plot, ebx, ecx, offset cam_pos_x_string, 0CD1818h
    add ebx, 300

    ;call itoa, [config_render_cam_pos], offset cam_pos_x_string_buffer, 10
    call text_plot, ebx, ecx, offset cam_pos_x_string_buffer, 0CD1818h

    call register_field_data, [@@x], [@@y], offset cam_pos_x_string_buffer, offset handle_cam_pos_x_click, offset cam_pos_x_field

ret
endp draw_cam_pos_x

proc draw_cam_pos_y
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]
    
    call memcpy, offset cam_pos_y_string_buffer, offset cam_pos_y_default, 4


    add ecx, 12
    call text_plot, ebx, ecx, offset cam_pos_y_string, 0CD1818h
    add ebx, 300

    ;call itoa, [config_render_cam_pos + 4], offset cam_pos_y_string_buffer, 10
    call text_plot, ebx, ecx, offset cam_pos_y_string_buffer, 0CD1818h

    call register_field_data, [@@x], [@@y], offset cam_pos_y_string_buffer, offset handle_cam_pos_y_click, offset cam_pos_y_field

ret
endp draw_cam_pos_y

proc draw_cam_pos_z
    arg @@x:dword, @@y:dword
    uses eax, ebx, ecx, edx, esi
    mov ebx, [@@x]
    mov ecx, [@@y]

    call memcpy, offset cam_pos_z_string_buffer, offset cam_pos_z_default, 4

    add ecx, 12
    call text_plot, ebx, ecx, offset cam_pos_z_string, 0CD1818h
    add ebx, 300

    ;call itoa, [config_render_cam_pos + 8], offset cam_pos_z_string_buffer, 10
    call text_plot, ebx, ecx, offset cam_pos_z_string_buffer, 0CD1818h

    call register_field_data, [@@x], [@@y], offset cam_pos_z_string_buffer, offset handle_cam_pos_z_click, offset cam_pos_z_field

ret
endp draw_cam_pos_z

;; ---------------------------------------------------------------
;;                        FIELD UTILITY
;; ---------------------------------------------------------------

proc create_field
    uses ebx, esi
    arg @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword, @@value:dword
    ;; upperleft, bottomright, value -> Field

    call alloc, size Field
    mov esi, eax

    mov eax, [@@value]
    mov [esi + Field.value], eax

    call alloc, size Coordinate

    mov [esi + Field.upperleft], eax

    mov ebx, [@@x1]
    mov [eax + Coordinate.x], ebx
    mov ebx, [@@y1]
    mov [eax + Coordinate.y], ebx

    call alloc, size Coordinate

    mov [esi + Field.bottomright], eax

    mov ebx, [@@x2]
    mov [eax + Coordinate.x], ebx
    mov ebx, [@@y2]
    mov [eax + Coordinate.y], ebx

    mov eax, esi

    ret
endp create_field

;; Remove 1 character from the end of a string
proc shorten 
    arg @@string:dword
    
    call strend, [@@string]
    mov [byte ptr eax-1], 0

    ret
endp shorten

;; Append 1 character to the end of a string
proc append
    arg @@string:dword, @@character:dword
    uses eax, ebx

    call strend, [@@string]
    mov ebx, [@@character]
    mov [byte ptr eax], bl
    mov [byte ptr eax+1], 0

    ret
endp append

;; ---------------------------------------------------------------
;;                        BUTTON ACTIONS
;; ---------------------------------------------------------------

proc draw_field
    uses eax, ebx, ecx, edx, esi, edi
    arg @@field:dword, @@color:dword

    mov eax, [@@field]

    mov ebx, [eax + Field.upperleft] ;; pointer to upperleft
    mov ecx, [ebx + Coordinate.x] ;; x1
    mov edx, [ebx + Coordinate.y] ;; y1

    mov ebx, [eax + Field.bottomright] ;; pointer to bottomright
    mov esi, [ebx + Coordinate.x] ;; x2
    mov edi, [ebx + Coordinate.y] ;; y2

    call draw_rect, ecx, edx, esi, edi, [@@color] 
    
    mov ebx, [eax + Field.value] ;; pointer to string

    add ecx, 30
    sub edx, 4

    call text_plot, ecx, edx, ebx, 0CD1818h 

    call video_buffer_flip

    ret
endp draw_field

proc deselect_current
    uses eax

    mov eax, [selected_field] ;; pointer to Field

    cmp eax, 0
    je @@end

    call draw_field, eax, 0F2C67h 

    @@end:
    ret
endp deselect_current

proc handle_run_click
    ;; Exit out of main loop after setting config values
    mov [running_main_loop], 0

    ret
endp handle_run_click

proc handle_fov_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [fov_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_fov_click

proc handle_video_height_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [video_height_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_video_height_click

proc handle_video_width_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [video_width_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_video_width_click

proc handle_sample_count_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [sample_count_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_sample_count_click

proc handle_max_bounces_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [max_bounces_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_max_bounces_click

proc handle_hdri_path_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [hdri_path_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_hdri_path_click

proc handle_cam_pos_x_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [cam_pos_x_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_cam_pos_x_click

proc handle_cam_pos_y_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [cam_pos_y_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_cam_pos_y_click

proc handle_cam_pos_z_click
    uses eax

    call deselect_current

    ;; Select
    mov eax, [cam_pos_z_field] ;; pointer to fov field
    mov [selected_field], eax ;; Mark fov field as selected 
    ;; F4E185
    call draw_field, eax, 0F4E185h

    ret
endp handle_cam_pos_z_click

proc draw_start_button  
    arg @@x:dword, @@y:dword
    
    call draw_button, [@@x], [@@y], 82, offset start_button_string, 0ff2540h, offset handle_run_click 

ret
endp draw_start_button

proc register_button
    uses eax, ebx 
    arg @@button:dword  

    mov ebx, [@@button]

    mov eax, [button_count]

    lea edi, [button_array + 4*eax]
    mov [edi], ebx ;; insert button in array

     ;; Write button to array
    inc eax
    mov [button_count], eax

    ret
endp register_button

proc create_button
    uses esi, ebx
    arg @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword, @@action:dword

    ;; We place the button inside of esi
    call alloc, size Button
    mov esi, eax

    ;; Add action to the button
    mov eax, [@@action]
    mov [esi + Button.onclick], eax

    ;; Set coords 
    call alloc, size Coordinate

    mov [esi + Button.upperleft], eax ;; Place coordinate inside of button

    mov ebx, [@@x1]
    mov [eax + Coordinate.x], ebx
    mov ebx, [@@y1]
    mov [eax + Coordinate.y], ebx

    call alloc, size Coordinate

    mov [esi + Button.bottomright], eax ;; Place coordinate inside of button

    mov ebx, [@@x2]
    mov [eax + Coordinate.x], ebx
    mov ebx, [@@y2]
    mov [eax + Coordinate.y], ebx

    mov eax, esi

    ret
endp create_button

proc draw_button
    arg @@x1:dword, @@y1:dword, @@width:dword, @@text:dword, @@backgroundcolor:dword, @@action:dword
    uses eax, ebx, ecx, edi

    mov ebx, [@@x1]
    add ebx, [@@width]

    mov edi, [@@y1]
    add edi, 40 ;; add height

    ;; Draw the rectangle
    call draw_rect, [@@x1], [@@y1], ebx, edi, [@@backgroundcolor]

    call create_button, [@@x1], [@@y1], ebx, edi, [@@action]
    ;; eax is button pointer
    call register_button, eax

    ;; Align the coords for the text
    mov ebx, [@@x1] 
    add ebx, 18

    mov edi, [@@y1] 
    add edi, 5

    ;; Draw the text
    call text_plot, ebx, edi, [@@text], 000000h

    ret
endp draw_button

;; ---------------------------------------------------------------
;;                        DRAWING PROCEDURES
;; ---------------------------------------------------------------

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

proc float_plot
    arg @@x_coord:dword, @@y_coord:dword, @@float:dword, @@upper:dword, @@lower:dword, @@color:dword
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
    ;call itoa, [@@temp], offset fov_upper_string_buffer, 10
    call itoa, [@@temp], [@@upper], 10
    call text_plot, ebx, [@@y_coord], eax, 0CD1818h
    add ebx, 32
    call char_plot_double, ebx, [@@y_coord], ',', 0CD1818h 
    fild [@@temp]
    fsub
    fld [float_1000000]
    fmul 
    fistp [@@temp]
    add ebx, 16
    ;call itoa, [@@temp], offset fov_lower_string_buffer, 10
    call itoa, [@@temp], [@@lower], 10
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

proc gui_progress_notify
    arg @@done:dword, @@total:dword
    uses eax, edx

    mov eax, 100
    mul [@@done]
    div [@@total]
    mov ebx, 100
    sub ebx, eax

ifdef NASM
    call print_int, ebx
    call print_newline
else
    ;; Clear the previous update
    call draw_rect, 50, 475, 50+80, 475+40, 0ff2540h
    call itoa, ebx, offset buf, 10
    call append, offset buf, '%'
    call text_plot, 50+18, 475+5, offset buf, 00000000h
    call video_buffer_flip
endif

    ret
endp gui_progress_notify

DATASEG
    selected_field dd 0

    key_reset dd 1

    running_main_loop dd 1

    button_array dd 10 dup (?)
    button_count dd 0

    last_cursor_position dd 0, 0

    buf db 32 dup (0)

    font_file_name db "GUI\FONT.BIN", 0
    font_array db FONTFILE_SIZE dup (?)

    cursor_file_name db "GUI\CURSOR.BIN", 0
    cursor_array db CURSORFILE_SIZE dup (?)

    title_name_string db "Assembly Raytracer", 0

    video_width_field dd (?)
    video_height_field dd (?)
    fov_field dd (?)
    sample_count_field dd (?)
    max_bounces_field dd (?)
    hdri_path_field dd (?)
    cam_pos_x_field dd (?)
    cam_pos_y_field dd (?)
    cam_pos_z_field dd (?)

    video_width_string_buffer db 16 dup (?)
    video_height_string_buffer db 16 dup (?)
    fov_string_buffer db 16 dup (?)
    sample_count_string_buffer db 16 dup (?)
    max_bounces_string_buffer db 16 dup (?)
    cam_pos_x_string_buffer db 16 dup (?)
    cam_pos_y_string_buffer db 16 dup (?)
    cam_pos_z_string_buffer db 16 dup (?)


    start_button_string db "Run", 0
    video_width_string db "Image Width: ", 0
    video_height_string db "Image Height: ", 0
    fov_string db "FOV: ", 0
    sample_count_string db "Sample Count: ", 0
    max_bounces_string db "Max Bounces: ", 0
    hdri_path_string db "HDRI path: ", 0
    cam_pos_x_string db "Cam Pos x: ", 0
    cam_pos_y_string db "Cam Pos y: ", 0
    cam_pos_z_string db "Cam Pos z: ", 0

    fov_default db "90.0", 0
    cam_pos_x_default db "0.0", 0
    cam_pos_y_default db "0.0", 0
    cam_pos_z_default db "2.0", 0
    hdri_path_default db "IMAGES/SNOWY.BMP", 0

    ;;                       a      z     e     r   t      y    u      i     o    p
    ;;                       q      s     d     f   g      h    j      k     l    m
    ;;                       w      x     c     v   b      n
    ;;                      spc     /     .
    ;; Not used.. might be useful later on
   character_scan_codes db 010h,  011h, 012h, 013h, 014h, 015h, 016h, 017h, 018h, 019h
                        db 01Eh,  01Fh, 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
                        db 02Ch,  02Dh, 02Eh, 02Fh, 030h, 031h
                        db 002h,  003h, 004h, 005h, 006h, 007h, 008h, 009h, 00Ah, 00Bh
                        db 039h,  034h, 033h

    character_mapping: db 10h dup (0)       ;; padding
                      db 'A', 'Z', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'
                      db 4 dup (0)
                      db 'Q', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M'
                      db 4 dup (0)
                      db 'W', 'X', 'C', 'V', 'B', 'N', ',', '.', '/'
                      db 4 dup (0)
                      db ' '
                      db 43 dup (0)

END