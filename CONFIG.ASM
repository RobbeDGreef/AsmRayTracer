IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "config.inc"
include "./RT/vec.inc"

DATASEG
    config_video_img_width              dd 400
    config_video_img_height             dd 300
    config_video_img_focal_length       dd 1.0
    config_video_img_fov                dd 90.0
    config_render_samples               dd 16
    config_render_max_bounces           dd 12
    config_render_background            dd 0.5, 0.5, 0.8
    config_render_hdri_path             db "IMAGES/NIGHT.BMP", 0
    config_render_cam_pos               dd 0.0, 0.0, 2.0
    config_render_cam_look_at           dd 0.0, 0.0, 0.0
END