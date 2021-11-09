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
    uses eax, ebx, ecx, edx, edi

    mov eax, 0ff00ffh
    mov ecx, VIDEO_MAX_FB_SIZE / 4
    lea edi, [vesa_lfb]
    rep stosd
    
ret
endp fill_background


END