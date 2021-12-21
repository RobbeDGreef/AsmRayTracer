IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "rt/texture/tiles.inc"
include "rt/texture/texture.inc"
include "rt/vec.inc"
include "rt/hit.inc"
include "rt/ray.inc"
include "utils.inc"

CODESEG

proc get_color
    arg @@tex:PTR Tiles, @@u:dword, @@v:dword, @@dest_color:PTR Color
    local @@temp:dword

    ;; The algorithm here is pretty simple. We want a tiled grid, e.i. :
    ;;    0 1 2 3
    ;; 0 |x   x
    ;; 1 |  x   x
    ;; 2 |x   x
    ;; 3 |  x   x
    ;;
    ;; As you can see all coordinate couples of the x's are couples where 
    ;; x+y is even. So we will simply check if our u+v is even. Since computers
    ;; work in binary this is easy, we simply check if the most significant bit
    ;; is set (e.i does our value end on 1), if it is our value is odd.
    ;; We also want to scale the tiles so we add a scale factor to the equation:
    ;;
    ;;      (x*scale + y*scale) even? 
    ;;
    ;; same as ?
    ;;
    ;;      (x+y)*scale even?  
    ;;
    ;; No! Because this entire algorithm is based on the fact that integers 
    ;; truncate and floats don't truncate. So what we actually want to do is
    ;; scale the floats, convert them to ints and then check if they are even.

    ;; Load the scale
    mov eax, [@@tex]
    mov eax, [eax+Tiles.scale]
    mov [@@temp], eax
    
    fld [@@u]
    fmul [@@temp]
    frndint         ;; We need to round to integer (truncate) for this algorithm
                    ;; to work.

    fld [@@v]
    fmul [@@temp]
    frndint
    faddp

    ;; Now save the integer value to memory
    fistp [@@temp]

    ;; Check if our value is odd, if it is set the secondary color
    and [@@temp], 1
    cmp [@@temp], 0
    jne @@sec_color

@@prim_color:
    mov eax, [@@tex]
    lea eax, [eax+Tiles.primary_color]
    call vec_cpy, [@@dest_color], eax
    jmp @@end

@@sec_color:
    mov eax, [@@tex]
    lea eax, [eax+Tiles.secondary_color]
    call vec_cpy, [@@dest_color], eax

@@end:
    mov eax, 1
    ret
endp get_color

proc tiles_init
    arg @@tex:PTR Tiles, @@prim_color:PTR Color, @@sec_color:PTR Color,\
        @@scale:dword
    uses eax, ebx

    call texture_init, [@@tex], offset get_color

    mov eax, [@@tex]
    lea ebx, [eax+Tiles.primary_color]
    call vec_cpy, ebx, [@@prim_color]
    lea ebx, [eax+Tiles.secondary_color]
    call vec_cpy, ebx, [@@sec_color]
    mov ebx, [@@scale]
    mov [eax+Tiles.scale], ebx

    ret
endp tiles_init

END