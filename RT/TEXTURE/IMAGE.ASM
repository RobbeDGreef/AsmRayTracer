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

    ;; Calculate the pixel's height
    fild [@@width]
    fmul [@@u]
    fistp [@@width]

    ;; Calculate the pixel's height
    fild [@@height]
    fmul [@@v]
    fistp [@@height]

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

;    mov ebx, [@@tex]
;    mov [ebx+Image.width], 40
;    mov [ebx+Image.height], 20
;
;    call alloc, 40*20*12
;    mov [ebx+Image.buffer], eax
;    call print_hex, [ebx+Image.buffer]
;    call print_newline
;
;    mov ebx, 19
;@@h_loop:
;    cmp ebx, 0
;    jl @@end
;
;    mov ecx, 39
;    @@w_loop:
;        cmp ecx, 0
;        jl @@end_w_loop
;
;        push [float_0_25]
;        mov [@@temp], ebx
;        fild [@@temp]
;        mov [@@temp], 19
;        fild [@@temp]
;        fdivp
;        fstp [@@temp]
;        push [@@temp]
;
;        mov [@@temp], ecx
;        fild [@@temp]
;        mov [@@temp], 39
;        fild [@@temp]
;        fdivp
;        fstp [@@temp]
;        push [@@temp]
;
;        push eax
;        call vec_set
;        add esp, 16
;
;        dec ecx
;        add eax, 12
;        jmp @@w_loop
;    
;    @@end_w_loop:
;    dec ebx
;    jmp @@h_loop
;
;@@end:
;    mov ebx, [@@tex]
;
    ret

endp image_init


END