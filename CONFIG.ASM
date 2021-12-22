IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "config.inc"
include "./RT/vec.inc"

DATASEG
    config_video_img_width              dd 800 ;
    config_video_img_height             dd 600 ;
    config_video_img_focal_length       dd 1.0
    config_video_img_fov                dd 30.0 ;
    config_render_samples               dd 16 ;
    config_render_max_bounces           dd 16 ;
    config_render_background            dd 0.5, 0.5, 0.8
    config_render_hdri_path             db 32 dup (0) ;
    config_render_cam_pos               dd 0.0, 0.0, -10.0 ;
    config_render_cam_look_at           dd 0.0, 0.0, 0.0
    config_render_scene_file            dd "SCENES/EX1.TXT"
END