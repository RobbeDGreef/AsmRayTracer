IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "gui.inc"
include "utils.inc"
include "vec.inc"
include "renderer.inc"

CODESEG
; video_framebuffer is buffer
proc fill_background
    local @@color:dword
    uses eax, ebx, ecx, edx

    lea eax, [@@color]
    call vec_set, eax, float_0, float_max_char, float_0 ; we put the color in eax

    lea ebx, video_framebuffer
    mov edx, ebx

    mov ecx, VIDEO_GFX_WIDTH * VIDEO_GFX_HEIGHT

@@setpixel:
    mov [ebx], eax
    lea ebx, [edx+4]
    mov edx, ebx
    loop @@setpixel

   ; call renderer_flip

ret
endp fill_background


END