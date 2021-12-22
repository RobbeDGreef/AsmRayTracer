GLOBAL gui_init:PROC               ;; void gui_init()
GLOBAL gui_destruct:PROC           ;; void gui_destruct()
GLOBAL pixel_plot:PROC             ;; void pixel_plot(int x, int y, int color)
GLOBAL char_plot:PROC              ;; void draw_char(int x, int y, int char, int color)
GLOBAL text_plot:PROC              ;; void text_plot(int x, int y, char* text, int color)
GLOBAL fill_background:PROC        ;; void fill_background(int color)
GLOBAL draw_horizontal_line:PROC   ;; void draw_horizontal_line (int x1, int x2, int y, int color)
GLOBAL draw_rect:PROC              ;; void draw_rect(int x1, int y1, int x2, int y2, int color)
GLOBAL draw_button:PROC            ;; void draw_button(int x1, int y1, int x2, int y2, String text, int color)
GLOBAL gui_start:PROC              ;; void gui_start();
GLOBAL gui_progress_notify:PROC ;; void gui_progress_notify(int done, int total)

struc Coordinate
    x dd ? ; x position
    y dd ? ; y position
ends Coordinate

struc Button
    upperleft   dd ? 
    bottomright dd ?
    onclick dd ? ;;procedure that should be called on click
ends Button

FONTCHAR_WIDTH  equ     8
FONTCHAR_HEIGHT equ     16 
FONTCHAR_SIZE   equ     16
FONTCHAR_COUNT  equ     128
FONTFILE_SIZE   equ     (FONTCHAR_SIZE * FONTCHAR_COUNT)

CURSORFILE_SIZE equ CURSOR_SIZE