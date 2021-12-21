IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "bmp.inc"

CODESEG

proc bmp_write
    arg @@file_name:PTR byte, @@buf:PTR byte, @@buf_size:dword, @@width:dword, @@height:dword 
    local @@hdr:bmp_hdr, @@dip_hdr:bmp_dip_hdr
    uses eax, ebx, ecx, edx, edi, esi

    ;; Create the bmp file
    call create_file, [@@file_name], 0
    mov ebx, eax

    ;; First fill the header and write it to the file
    lea eax, [@@hdr]
    mov [word ptr eax+bmp_hdr.id], BMP_HDR_ID
    mov ecx, BMP_HDR_SIZE+BMP_DIB_SIZE+2
    add ecx, [@@buf_size]
    mov [dword ptr eax+bmp_hdr.size], ecx
    mov [dword ptr eax+bmp_hdr.img_data_off], BMP_HDR_SIZE+BMP_DIB_SIZE+2
    
    call write_file, ebx, eax, BMP_HDR_SIZE

    ;; After the header, the dib header is written to file. This provides extra
    ;; information about the bmp file.
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

    ;; The image data in a BMP file should be 4 byte aligned so we write two 
    ;; random bytes to the file to make sure all the following data is aligned.
    ;; Reused the eax buffer to write the padding bytes.
    call write_file, ebx, eax, 2

    ;; Save ebx because we have too little registers
    push ebx

    ;; BMPs store the width lines upside down for some weird reason so we have
    ;; to copy them
    mov ecx, [@@width]
    shl ecx, 2              ;; * 4

    ;; This part of the code uses two pointers, one starts at the top and one at
    ;; the bottom (esi and edi respectively). Then it will swap the dwords
    ;; between the two registers to make sure the two pointers essentially swap
    ;; in memory.
    mov esi, [@@buf]
    mov edi, esi
    add edi, [@@buf_size]
    sub edi, ecx
@@height_loop:
    cmp esi, edi
    jg @@end_height_loop
    
    mov ebx, ecx
    sub ebx, 4
    @@swap_loop:
        cmp ebx, 0
        jl @@end_swap_loop

        ;; Here we swap the two buffers, dword per dword
        mov edx, [esi+ebx]
        mov eax, [edi+ebx]
        mov [esi+ebx], eax
        mov[edi+ebx], edx

        sub ebx, 4
        jmp @@swap_loop

    @@end_swap_loop:
    
    sub edi, ecx
    add esi, ecx
    jmp @@height_loop

@@end_height_loop:
    
    ;; Now finally write our mirrored buffer to file.
    pop ebx
    call write_file, ebx, [@@buf], [@@buf_size]
    call close_file, ebx

    ret
endp bmp_write

END