;; Video functions
GLOBAL video_set_mode:PROC      ;; void video_set_mode(dword mode)
GLOBAL video_buffer_flip:PROC   ;; void video_buffer_flip()

VIDEO_MODE_TEXT         equ 3h
VIDEO_MODE_GRAPHICS     equ 115h

VIDEO_FB_WIDTH         equ 800
VIDEO_FB_HEIGHT        equ 600

VIDEO_FB_BPP           equ 4
VIDEO_FB_SIZE          equ (VIDEO_FB_WIDTH*VIDEO_FB_HEIGHT*VIDEO_FB_BPP)

VIDEO_MAX_FB_WIDTH      equ 800
VIDEO_MAX_FB_HEIGHT     equ 600
VIDEO_MAX_FB_SIZE       equ (VIDEO_MAX_FB_HEIGHT*VIDEO_MAX_FB_WIDTH*VIDEO_FB_BPP)

GLOBAL vesa_lfb:dword