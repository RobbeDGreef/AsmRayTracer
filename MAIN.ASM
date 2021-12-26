IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "output/video.inc"
include "rt/vec.inc"
include "rt/renderer.inc"
include "rt/scene.inc"
include "rt/sphere.inc"
include "gui/gui.inc"
include "rt/triangle.inc"

include "rt/mat/lmbrtian.inc"
include "rt/mat/metal.inc"
include "rt/mat/unlit.inc"
include "rt/mat/emissive.inc"
include "rt/mat/glass.inc"

include "rt/texture/solid.inc"
include "rt/texture/tiles.inc"
include "rt/texture/image.inc"
include "rt/texture/uv.inc"

include "input/objload.inc"
include "input/sloader.inc"

include "init.inc"
include "utils.inc"
include "mm.inc"
include "config.inc"

CODESEG

GLOBAL main:PROC

proc main
    local @@begin_time:dword, @@scene:Scene
    uses eax, ebx, ecx, edx, edi, esi

    call init
    call mm_init

    ;; Video mode needs to be set before gui_start is called
    call video_set_mode, VIDEO_MODE_GRAPHICS

    ;; Gui aspect should only run in dosbox
ifndef NASM
    call gui_init
    call gui_start
    ;; gui_destruct HAS TO BE CALLED before the program finishes, it will 
    ;; disable the mouse and if we don't do that dos will try to dispatch
    ;; mouse events to a program that doesn't exist anymore resulting in 
    ;; crashes.
    call gui_destruct
else
    ;; Linux has no gui so we still have to set these values
    call strlen, offset render_scene_file
    inc eax
    call memcpy, offset config_render_scene_file, offset render_scene_file, eax
    
    call strlen, offset render_hdri_file
    inc eax
    call memcpy, offset config_render_hdri_path, offset render_hdri_file, eax
    
    call log_str, offset config_render_hdri_path

endif
    ;; Once gui is over we start the ray tracer

    call log_str, offset load_str
    call gettime_millis
    mov [@@begin_time], eax
 
    ;; Setting up our scene
    lea ebx, [@@scene]
    call scene_init, ebx
    
    ;; Load the scene from file
    call scene_load, ebx, offset config_render_scene_file

    ;; Build the scene BVH
    call scene_build_bvh, ebx

    ;; And run the renderer
    call log_str, offset start_str
    call renderer_init
    call renderer_render, ebx
    
    ;; On linux we just output the BMP
    call renderer_to_bmp, offset bmpout
ifndef NASM
    call renderer_show_img
    call wait_for_keypress
    
    call video_set_mode, VIDEO_MODE_TEXT
endif

    mov ebx, [@@begin_time]
    call gettime_millis
    sub eax, ebx
    call print_str, offset finished_str
    call print_int, eax
    call print_str, offset finished_str2
    call print_newline

    call exit, 0
    ret
endp main

STACK 5000h

DATASEG
    load_str db "Loading scene started", 0
    start_str db "Ray tracer started", 0
    finished_str db "Ray tracer finished in ", 0
    finished_str2 db " milliseconds", 0
    bmpout db "RENDERED.BMP", 0

    render_scene_file db "SCENES/ALLMAT.TXT", 0
    render_hdri_file db "IMAGES/SNOWY_H.BMP", 0

END main