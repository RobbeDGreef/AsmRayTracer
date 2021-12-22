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

include "init.inc"
include "utils.inc"
include "mm.inc"

CODESEG

GLOBAL main:PROC

proc main
    local @@begin_time:dword, @@scene:Scene, @@sphere:Sphere, @@loc:Vec,\
          @@sphere2:Sphere, @@lam:Lambertian, @@color:Color, @@met:Metal,\
          @@color2:Color, @@color3:Color, @@color4:Color, @@sphere3:Sphere, @@unlit:Unlit, @@emission:Emissive,\
          @@texsolid:Solid, @@textiles:Tiles, @@teximage:Image,\ 
          @@texsolid2:Solid, @@met2:Metal, @@texsolid3:Solid, @@met3:Metal,\
          @@loc2:Vec, @@loc3:Vec, @@triangle:Triangle, @@uv:Uv, @@glass:Glass
    uses eax, ebx, ecx, edx, edi, esi

    call init
    call gui_init
    call mm_init

    ;; Video mode needs to be set before gui_start is called
    call video_set_mode, VIDEO_MODE_GRAPHICS
    call gui_start

    ;;call video_buffer_flip

    call log_str, offset start_str
    call gettime_millis
    mov [@@begin_time], eax

    ;call video_buffer_flip
    
    ;; Setting up our scene
    lea ebx, [@@scene]
    call scene_init, ebx
    jmp @@start_renderer ;; skip raytracer

    ;; =========================================================================
    ;; Simple scene
    ;; =========================================================================
@@setup_simple_scene:
    ;; A very simple scene with just 1 lambertian sphere of radius 1 at (0,0,0)
    ;lea eax, [@@color]
    ;call vec_set_rgb, eax, 255, 0, 0
    ;lea ecx, [@@texsolid]
    ;call solid_init, ecx, eax
    ;lea edi, [@@lam]
    ;call lambertian_init, edi, ecx

    lea eax, [@@color]
    call vec_set_rgb, eax, 255, 255, 255
    lea ecx, [@@texsolid]
    call solid_init, ecx, eax
    lea edi, [@@glass]
    call glass_init, edi, ecx, [float_1_50]

    lea edx, [@@loc]
    lea ecx, [@@sphere]
    call vec_set, edx, [float_0], [float_0], [float_0]
    call sphere_set, ecx, edx, [float_1], edi
    call scene_add, ebx, ecx

    jmp @@start_renderer

    lea eax, [@@color]
    call vec_set, eax, [float_0_75], [float_0_25], [float_0_25]
    lea edi, [@@lam]
    call lambertian_init, edi, eax

    lea eax, [@@color2]
    call vec_set, eax, [float_0], [float_0_50], [float_0_75]
    lea edi, [@@met]
    call metal_init, edi, eax

    lea eax, [@@color3]
    call vec_set, eax, [float_0_20], [float_0_25], [float_0_90]
    lea edi, [@@unlit]
    call unlit_init, edi, eax

    lea eax, [@@color4]
    call vec_set, eax, [float_1], [float_1], [float_1]
    lea edi, [@@emission]
    call emissive_init, edi, eax, [float_2]

    lea edx, [@@loc]
    lea ecx, [@@sphere2]
    lea edi, [@@lam]
    call vec_set, edx, [float_0], [sphere2_y], [float_minus_1]
    call sphere_set, ecx, edx, [sphere2_radius], edi
    call scene_add, ebx, ecx

    lea ecx, [@@sphere]
    lea edi, [@@lam]
    call vec_set, edx, [float_0], [float_0], [float_minus_1]
    call sphere_set, ecx, edx ,[float_0_50], edi
    call scene_add, ebx, ecx

    lea ecx, [@@sphere3]
    lea edi, [@@emission]
    call vec_set, edx, [float_0_75], [float_0_25], [float_minus_0_75]
    call sphere_set, ecx, edx, [float_0_25], edi
    call scene_add, ebx, ecx
    jmp @@start_renderer

    ;; =========================================================================
    ;; HDRI test scene
    ;; =========================================================================
@@setup_scene_hdri_test:
    ;; -------------------------------------------------------------------------
    ;; Ball in the middle (copper)
    ;; -------------------------------------------------------------------------
    ;; Set color for solid texture
    lea eax, [@@color]
    call vec_set_rgb, eax, 176, 110, 55
    
    ;; Initialize solid texture
    lea ecx, [@@texsolid3]
    call solid_init, ecx, eax

    ;; Initialize the metal material
    lea edi, [@@met3]
    call metal_init, edi, ecx

    ;; Now finally set up the sphere
    lea ecx, [@@sphere3]
    lea edx, [@@loc]
    call vec_set, edx, [float_minus_0_75], [float_minus_0_25], [float_minus_2]
    call sphere_set, ecx, edx, [float_0_25], edi
    call scene_add, ebx, ecx

    ;; -------------------------------------------------------------------------
    ;; Ball in the middle (gold)
    ;; -------------------------------------------------------------------------
    ;; Set color for solid texture
    lea eax, [@@color]
    call vec_set_rgb, eax, 165, 125, 0
    
    ;; Initialize solid texture
    lea ecx, [@@texsolid2]
    call solid_init, ecx, eax

    ;; Initialize the metal material
    lea edi, [@@met2]
    call metal_init, edi, ecx

    ;; Now finally set up the sphere
    lea ecx, [@@sphere2]
    lea edx, [@@loc]
    call vec_set, edx, [float_0], [float_minus_0_25], [float_minus_2]
    call sphere_set, ecx, edx, [float_0_25], edi
    call scene_add, ebx, ecx

    ;; -------------------------------------------------------------------------
    ;; Ball on the right (silver)
    ;; -------------------------------------------------------------------------
    ;; Set color for solid texture
    lea eax, [@@color]
    call vec_set_rgb, eax, 192, 192, 192
    
    ;; Initialize solid texture
    lea ecx, [@@texsolid]
    call solid_init, ecx, eax

    ;; Initialize the metal material
    lea edi, [@@met]
    call metal_init, edi, ecx

    ;; Now finally set up the sphere
    lea ecx, [@@sphere]
    lea edx, [@@loc]
    call vec_set, edx, [float_0_75], [float_minus_0_25], [float_minus_2]
    call sphere_set, ecx, edx, [float_0_25], edi
    call scene_add, ebx, ecx

    jmp @@start_renderer

    ;; =========================================================================
    ;; Football scene
    ;; =========================================================================
@@setup_football_scene:
    ;; Initialize solid texture
    lea ecx, [@@teximage]
    call image_init, ecx, offset football_texture

    ;; Initialize the metal material
    lea edi, [@@lam]
    call lambertian_init, edi, ecx

    ;; Now finally set up the sphere
    lea ecx, [@@sphere3]
    lea edx, [@@loc]
    call vec_set, edx, [float_0], [float_minus_0_25], [float_minus_2]
    call sphere_set, ecx, edx, [float_0_25], edi
    call scene_add, ebx, ecx
    
    jmp @@start_renderer
    
    ;; =========================================================================
    ;; Triangle test scene
    ;; =========================================================================
@@setup_triangle_test:

    ;; Set color for solid texture
    lea eax, [@@color]
    call vec_set_rgb, eax, 255, 110, 55
    
    ;; Initialize solid texture
    lea ecx, [@@texsolid]
    call solid_init, ecx, eax

    ;; Initialize the metal material
    lea esi, [@@met]
    call metal_init, esi, ecx

    lea ecx, [@@triangle]
    lea edi, [@@loc3]
    lea edx, [@@loc2]
    lea eax, [@@loc]
    call vec_set, edi, [float_1],[float_minus_1],[float_1]
    call vec_set, edx, [float_1],[float_1],[float_1]
    call vec_set, eax, [float_minus_1],[float_minus_1],[float_1]
    call triangle_set, ecx, eax, edx, edi, esi
    call scene_add, ebx, ecx

    jmp @@start_renderer

@@setup_cube_test:
    ;; Gray blender color for fun
    lea eax, [@@color]
    call vec_set_rgb, eax, 255, 255, 255
    
    lea ecx, [@@texsolid]
    call solid_init, ecx, eax

    ;; Initialize the lambertian material
    ;lea esi, [@@met]
    ;call metal_init, esi, ecx
    call glass_init, esi, ecx, [float_1_50]

    call obj_load, ebx, esi, offset cube_path
    jmp @@start_renderer

    ;; End setting up scene

    ;; Start renderer
@@start_renderer:
    ;call scene_build_bvh, ebx
    ;call renderer_init
    ;call renderer_render, ebx
    
ifndef NASM
    ;;call renderer_show_img
    ;call sleep_millis, 6000
    
    ;; gui_destruct HAS TO BE CALLED before the program finishes, it will 
    ;; disable the mouse and if we don't do that dos will try to dispatch
    ;; mouse events to a program that doesn't exist anymore resulting in 
    ;; crashes.
    call gui_destruct
else
    call renderer_to_bmp, offset bmpout
endif

    call video_set_mode, VIDEO_MODE_TEXT

    mov ebx, [@@begin_time]
    call gettime_millis
    sub eax, ebx
    call print_str, offset finished_str
    call print_int, eax
    call print_str, offset finished_str2
    call print_newline

    call destruct

    call exit, 0
    ret
endp main

STACK 5000h

DATASEG
    start_str db "Ray tracer started", 0
    finished_str db "Ray tracer finished in ", 0
    finished_str2 db " milliseconds", 0
    bmpout db "test.bmp", 0

    test_str db "Hello world!!", 0
    
    football_texture db "IMAGES/FOOTBALL.BMP", 0
    cube_path db "OBJS/MONKEY.OBJ"

    sphere2_radius dd 100.0
    sphere2_y dd -100.5

    float_10            dd 10.0
    float_minus_0_25    dd -0.25
    float_minus_2       dd -2.0
    float_0_80          dd 0.80
    float_0_60          dd 0.60
    float_1_50          dd 1.50

END main