GLOBAL gui_init:PROC            ;; void gui_init()
GLOBAL pixel_plot:PROC          ;; void pixel_plot(int x, int y, int color)
GLOBAL char_plot:PROC           ;; void draw_char(int x, int y, int char, int color)
GLOBAL text_plot:PROC           ;; void text_plot(int x, int y, char* text, int color)
GLOBAL fill_background:PROC     ;; void fill_background(int color)
GLOBAL gui_progress_notify:PROC ;; void gui_progress_notify(int done, int total)

FONTCHAR_WIDTH  equ     8
FONTCHAR_HEIGHT equ     16 
FONTCHAR_SIZE   equ     16
FONTCHAR_COUNT  equ     128
FONTFILE_SIZE   equ     (FONTCHAR_SIZE * FONTCHAR_COUNT)