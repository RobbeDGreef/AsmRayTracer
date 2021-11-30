struc Texture
    get_color dd ? ;; int get_color(Teture* float u, float v, Color* dest)
ends Texture

GLOBAL texture_init:PROC ;; void texture_init(Texture* mat, color_fptr color)