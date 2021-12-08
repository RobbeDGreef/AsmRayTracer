IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "bmp.inc"
include "mm.inc"
include "rt/vec.inc"

CODESEG

;; Note that this bmp read function only supports 32 bit BMPS where the image
;; offset is aligned in such a manner that width lines are not padded. We 
;; assume this to make the loader simpler.
proc bmp_read
    arg @@file_name:PTR byte, @@width_ptr:dword, @@height_ptr:dword 
    local @@hdr:bmp_hdr, @@dib_hdr:bmp_dip_hdr, @@temp:dword
    uses ebx, ecx, edx, edi, esi

    ;; BMP file structure is:
    ;; bmp header
    ;; bmp dib header
    ;; image data
    ;;
    ;; So we will first load in the two first structures and then determin
    ;; the image data offset and read the buffer into memory

    call open_file, [@@file_name], 0
    cmp eax, 0
    je @@end

    mov ebx, eax

    lea edi, [@@hdr]
    call read_file, ebx, edi, BMP_HDR_SIZE
    lea esi, [@@dib_hdr]
    call read_file, ebx, esi, BMP_DIB_SIZE

    ;; Save the width information
    mov eax, [@@width_ptr]
    mov ecx, [esi+bmp_dip_hdr.img_width]
    mov [eax], ecx
    mov eax, [@@height_ptr]
    mov ecx, [esi+bmp_dip_hdr.img_height]
    mov [eax], ecx
 
    ;; We will create a buffer to hold the loaded bitmap in vector format
    ;; meaning we will have to convert the RGBA to (RGB) vector. Essentially
    ;; we will just ignore the alpha component and convert to vectors
    ;; width * height * vec
    mov eax, [esi+bmp_dip_hdr.img_width]
    mul [esi+bmp_dip_hdr.img_height]
    mov edx, VEC_SIZE
    mul edx
    call alloc, eax
    mov ecx, eax

    ;; Set the file seek to the image data offset to start reading the data
    ;; into memory.
    call lseek_file, ebx, [edi+bmp_hdr.img_data_off], LSEEK_ORIGIN_START
    mov edx, [edi+bmp_hdr.size]
    sub edx, [edi+bmp_hdr.img_data_off]
    call read_file, ebx, ecx, edx
    call close_file, ebx

    ;; To save precious ram space, we will do a little trick here. We will reuse
    ;; the vector buffer as a bitmap buffer. We loaded the RGBA values into the
    ;; buffer. Note that the buffer is not filled since a vector == 12 bytes and
    ;; one RGBA pixel == 4 bytes. Meaning we can start filling the buffer up
    ;; from back to the front, this way we will never overwrite the RGBA data 
    ;; and don't have to allocate another buffer.
    

    ;; vecptr = base + (width * height) * vec_size - vec_size
    ;; rgbptr = base + (width * height) * 4 - 4
    ;;
    ;; while (rgbptr > 0)
    ;;  v = *rgbptr
    ;;  *vecptr = calc(v)
    ;;  rgbptr -= 4
    ;;  vecptr -= vec_size

    mov ebx, ecx
    mov edi, ecx

    mov eax, [esi+bmp_dip_hdr.img_width]
    mul [esi+bmp_dip_hdr.img_height]
    dec eax
    mov edx, VEC_SIZE
    mul edx

    add ebx, eax

    mov eax, [esi+bmp_dip_hdr.img_width]
    mul [esi+bmp_dip_hdr.img_height]
    dec eax
    shl eax, 2 ;; * 4
    add ecx, eax

    ;; ebx contains the vector pointer
    ;; ecx contains the rgba pointer

    call print_hex, ecx
    call print_newline

@@transform_loop:
    cmp ecx, edi
    jl @@end_loop

    movzx eax, [byte ptr ecx]
    mov [@@temp], eax
    fild [@@temp]
    fdiv [float_max_char]
    fstp [dword ptr ebx]
    
    movzx eax, [byte ptr ecx+1]
    mov [@@temp], eax
    fild [@@temp]
    fdiv [float_max_char]
    fstp [dword ptr ebx+4]

    movzx eax, [byte ptr ecx+2]
    mov [@@temp], eax
    fild [@@temp]
    fdiv [float_max_char]
    fstp [dword ptr ebx+8]

    sub ebx, VEC_SIZE
    sub ecx, 4

    jmp @@transform_loop

@@end_loop:
    mov eax, edi

@@end:
    ret
endp bmp_read


END