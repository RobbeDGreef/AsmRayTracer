;; Video functions
GLOBAL set_video_mode:PROC      ;; void set_video_mode(dword mode)
VIDEO_MODE_TEXT         equ 3h
VIDEO_MODE_GRAPHICS     equ 115h

VIDEO_FB_WIDTH         equ 800
VIDEO_FB_HEIGHT        equ 600

VIDEO_FB_BPP           equ 4
VIDEO_FB_SIZE          equ (VIDEO_FB_WIDTH*VIDEO_FB_HEIGHT*VIDEO_FB_BPP)

VIDEO_MAX_FB_WIDTH      equ 800
VIDEO_MAX_FB_HEIGHT     equ 600
VIDEO_MAX_FB_SIZE       equ (VIDEO_MAX_FB_HEIGHT*VIDEO_MAX_FB_WIDTH*VIDEO_FB_BPP)

;; Renderer functions
GLOBAL renderer_show_img:PROC       ;; void renderer_show_img()
GLOBAL renderer_render:PROC         ;; void renderer_render()
GLOBAL renderer_to_bmp:PROC         ;; void renderer_to_bmp(char* filename)
GLOBAL renderer_init:PROC           ;; void renderer_init()

GLOBAL img_framebuffer:PTR dword
GLOBAL img_framebuffer_size:PTR dword
GLOBAL img_rgbbuf:PTR dword
GLOBAL img_rgbbuf_size:PTR dword
GLOBAL vesa_lfb:dword