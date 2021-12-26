IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/texture/image.inc"
include "rt/texture/texture.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"
include "mm.inc"
include "bmp.inc"

CODESEG

proc image_get_color
    arg @@tex:PTR Image, @@u:dword, @@v:dword, @@dest_color:PTR Color
    local @@width:dword, @@height:dword
    uses ebx, ecx, edx, edi

    mov eax, [@@tex]
    mov ebx, [eax+Image.width]
    mov ecx, [eax+Image.height]
    mov edi, [eax+Image.buffer]
    dec ebx
    dec ecx

    mov [@@width], ebx
    mov [@@height], ecx

    ;; Simple calculation. U and V are in between 0 and 1. So if we take the
    ;; width (and height for V) of the image we can multiply them with this
    ;; U or V and get the action pixel location (in integer values)

    ;; Calculate the pixel's height
    fild [@@width]
    fmul [@@u]
    fistp [@@width]

    ;; Calculate the pixel's height
    fild [@@height]
    fmul [@@v]
    fistp [@@height]

    ;; Now we just find and copy that pixel out of memory to the ray and we are
    ;; done 
    mov eax, [@@height]
    inc ebx
    mul ebx
    add eax, [@@width]

    mov edx, VEC_SIZE
    mul edx

    add edi, eax
    call vec_cpy, [@@dest_color], edi

    mov eax, 1
    ret
endp image_get_color

proc image_init
    arg @@tex:PTR Image, @@image_path:PTR byte
    local @@temp:dword
    uses eax, ebx, ecx, edx

    call texture_init, [@@tex], offset image_get_color

    mov ebx, [@@tex]
    lea ecx, [ebx+Image.width]
    lea edx, [ebx+Image.height]
    call bmp_read, [@@image_path], ecx, edx
    mov [ebx+Image.buffer], eax

    ret

endp image_init


END