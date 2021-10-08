;; Video functions
GLOBAL set_video_mode:PROC      ;; void set_video_mode(dword mode)
VIDEO_MODE_TEXT         equ 3h
VIDEO_MODE_GRAPHICS     equ 115h

VIDEO_GFX_WIDTH         equ 800
VIDEO_GFX_HEIGHT        equ 600

VIDEO_GFX_BPP           equ 4
VIDEO_GFX_FB_SIZE       equ (VIDEO_GFX_WIDTH*VIDEO_GFX_HEIGHT*VIDEO_GFX_BPP)

;; Renderer functions
GLOBAL renderer_flip:PROC

GLOBAL video_framebuffer:PTR DWORD