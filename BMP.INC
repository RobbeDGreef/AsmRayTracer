BMP_HDR_ID                  equ 4d42h
BMP_HDR_SIZE                equ 14
BMP_DIB_SIZE                equ 40
BMP_DIB_PLANES              equ 1
BMP_DIB_BPP                 equ 32
BMP_DIB_COMPRESSION_TYPE    equ 0
BMP_DIB_COMPRESSION_SIZE    equ 0

struc bmp_hdr
    id              dw ?
    size            dd ?
    reserved        dd ?
    img_data_off    dd ?
ends bmp_hdr

struc bmp_dip_hdr
    size                    dd ?
    img_width               dd ?
    img_height              dd ?
    places_cnt              dw ?
    bpp                     dw ?
    compression_type        dd ?
    compression_size        dd ?
    x_ppm                   dd ?
    y_ppm                   dd ?
    used_colors_cnt         dd ?
    important_colors_cnt    dd ? 
ends bmp_dip_hdr

GLOBAL bmp_write:PROC   ;; void bmp_write(char* filename, char* buf, 
                        ;;                size_t buf_size, int width, 
                        ;;                int height)

GLOBAL bmp_read:PROC