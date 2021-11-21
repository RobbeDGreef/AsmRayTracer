IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "output/bmp.inc"

CODESEG

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

proc bmp_write
    arg @@file_name:PTR byte, @@buf:PTR byte, @@buf_size:dword, @@width:dword, @@height:dword 
    local @@hdr:bmp_hdr, @@dip_hdr:bmp_dip_hdr
    uses eax, ebx, ecx

    call create_file, [@@file_name], 0
    mov ebx, eax

    lea eax, [@@hdr]
    mov [word ptr eax+bmp_hdr.id], BMP_HDR_ID
    mov ecx, BMP_HDR_SIZE+BMP_DIB_SIZE+2
    add ecx, [@@buf_size]
    mov [dword ptr eax+bmp_hdr.size], ecx
    mov [dword ptr eax+bmp_hdr.img_data_off], BMP_HDR_SIZE+BMP_DIB_SIZE+2
    
    call write_file, ebx, eax, BMP_HDR_SIZE

    lea eax, [@@dip_hdr]
    mov [dword ptr eax+bmp_dip_hdr.size], BMP_DIB_SIZE
    mov ecx, [@@width]
    mov [dword ptr eax+bmp_dip_hdr.img_width], ecx
    mov ecx, [@@height]
    mov [dword ptr eax+bmp_dip_hdr.img_height], ecx
    mov [word ptr eax+bmp_dip_hdr.places_cnt], BMP_DIB_SIZE
    mov [word ptr eax+bmp_dip_hdr.bpp], BMP_DIB_BPP
    mov [dword ptr eax+bmp_dip_hdr.compression_type], BMP_DIB_COMPRESSION_TYPE
    mov [dword ptr eax+bmp_dip_hdr.compression_size], BMP_DIB_COMPRESSION_SIZE
    mov [dword ptr eax+bmp_dip_hdr.x_ppm], 0
    mov [dword ptr eax+bmp_dip_hdr.y_ppm], 0
    mov [dword ptr eax+bmp_dip_hdr.used_colors_cnt], 0
    mov [dword ptr eax+bmp_dip_hdr.important_colors_cnt], 0

    call write_file, ebx, eax, BMP_DIB_SIZE
    ;; 2 pad bytes, reused ebx as address but this might as well have been 
    ;; something else
    call write_file, ebx, eax, 2

    call write_file, ebx, [@@buf], [@@buf_size]
    call close_file, ebx

    ret
endp bmp_write

END