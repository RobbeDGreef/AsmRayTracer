IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "renderer.inc"

CODESEG

;; =============================================================================
;; Video functions
;; =============================================================================
proc set_video_mode
    arg @@mode:dword
    uses eax, ebx
    ;; We use the bios to set the video mode
    mov eax, 4f02h
    mov ebx, [@@mode]
    int 10h
    ret
endp set_video_mode


END