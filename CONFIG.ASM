IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "config.inc"

DATASEG
    config_video_img_width              dd 400
    config_video_img_height             dd 300
    config_video_img_focal_length       dd 1.0
    config_render_samples               dd 8
    config_render_max_bounces           dd 4
END