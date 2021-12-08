IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "config.inc"

DATASEG
    config_video_img_width              dd 400
    config_video_img_height             dd 300
    config_video_img_focal_length       dd 1.2
    config_render_samples               dd 64
    config_render_max_bounces           dd 50
    config_render_background            dd 0.5, 0.5, 0.8
END