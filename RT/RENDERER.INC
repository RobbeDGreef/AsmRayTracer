;; Renderer functions
GLOBAL renderer_show_img:PROC       ;; void renderer_show_img()
GLOBAL renderer_render:PROC         ;; void renderer_render(Scene* scene)
GLOBAL renderer_to_bmp:PROC         ;; void renderer_to_bmp(char* filename)
GLOBAL renderer_init:PROC           ;; void renderer_init()
GLOBAL renderer_buf_to_screen:PROC  ;; void renderer_buf_to_screen()

GLOBAL img_framebuffer:PTR dword
GLOBAL img_framebuffer_size:PTR dword
GLOBAL img_rgbbuf:PTR dword
GLOBAL img_rgbbuf_size:PTR dword
