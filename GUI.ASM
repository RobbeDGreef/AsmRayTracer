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
    lea edi, [vesa_lfb]
    mov ecx, 0
@@loopke:
    cmp ecx, VIDEO_FB_SIZE/4
    jge @@end

    mov ebx, edi
    add ebx, ecx
    mov [ebx], eax
    call log_hex, ebx

    add ecx, 4
    jmp @@loopke
@@end:
ret
endp fill_background


END