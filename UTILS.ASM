IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"

CODESEG

;; =============================================================================
;; stdout functions
;; =============================================================================

;; Prints a singular character to STDOUT
;; NOT_TESTED
proc print_char
    arg @@char:dword
    uses eax, edx
ifdef NASM
    push ebx
    push ecx
    mov eax, 4
    mov ebx, 1
    lea ecx, [@@char]
    mov edx, 1
    int 80h
    pop ecx
    pop ebx
else
    mov ah, 02h 
    mov edx, [@@char]
    ;; dl: the character to print
    int 21h 
    ;; al: last character output
endif
    ret
endp print_char

;; Prints a newline (CRLF) to STDOUT
proc print_newline
    call print_char, 13
    call print_char, 10
    ret
endp print_newline

proc print_space
    call print_char, ' '
    ret
endp print_space

;; Prints a null terminated string to STDOUT (no newline added)
proc print_str
    uses eax, ebx
    arg @@string:DWORD
    
    ;; Loop until we find a zero character
    mov eax, [@@string]
    @@charloop:
        mov ebx, [eax]
        cmp bl, 0
        je @@end
        call print_char, ebx
        inc eax
        jmp @@charloop

@@end:
    ret
endp print_str

;; Prints an integer to STDOUT
proc print_int
    arg @@value:dword
    uses eax
    call itoa, [@@value], offset print_int_buffer, 10
    call print_str, offset print_int_buffer
    ret
endp print_int

proc pad_print_buffer
    arg @@padding:dword
    uses eax, ebx, edx

    call strlen, offset print_int_buffer
    cmp eax, [@@padding]
    jge @@end

    mov ebx, [@@padding]
    sub ebx, eax
    mov edx, offset print_int_buffer
    add edx, ebx
    inc eax
    call memmove, edx, offset print_int_buffer, eax
    call memset, offset print_int_buffer, '0', ebx

@@end:
    ret
endp pad_print_buffer

proc print_int_padded
    arg @@value:dword, @@padding:dword
    uses eax, ebx
    call itoa, [@@value], offset print_int_buffer, 10
    call pad_print_buffer, [@@padding]
    call print_str, offset print_int_buffer
    ret
endp print_int_padded

;; Prints an integer to STDOUT in hexadecimal notation (prefixed with 0x)
proc print_hex
    arg @@value:dword
    uses eax
    call print_str, offset hex_prefix
    call itoa, [@@value], offset print_int_buffer, 16
    call print_str, offset print_int_buffer
    ret
endp print_hex

proc print_hex_padded
    arg @@value:dword, @@padding:dword
    uses eax
    call itoa, [@@value], offset print_int_buffer, 16
    call pad_print_buffer, [@@padding]
    call print_str, offset print_int_buffer
    ret
endp print_hex_padded

proc print_float
    arg @@fl_value:dword
    local @@temp:dword
    uses eax
    
    xor eax, eax
    fldz
    fld [@@fl_value]
    fcompp
    fnstsw ax
    fld [@@fl_value]
    shr eax, 8
    and eax, 111B
    cmp eax, 1
    jne @@not_negative
    call print_char, '-'
    fld1
    fchs
    fmul
    
@@not_negative:
    ;; intpart:
    fist [@@temp]
    call print_int, [@@temp]
    call print_char, '.'
    fild [@@temp]
    fsub 
    fld [float_1000000]
    fmul
    fistp [@@temp]
    call print_int_padded, [@@temp], 6

    ret
endp print_float

proc print_hex_multiple
    arg @@count:dword
    uses eax, ebx, ecx, edx

    mov eax, 12
    mov ecx, 0
@@print_loop:
    cmp ecx, [@@count]
    je @@end
   
    call print_hex, [dword ptr ebp+eax]
    call print_space
    
    add eax, 4
    inc ecx
    jmp @@print_loop

@@end:
    ret
endp print_hex_multiple

proc print_hexdump
    arg @@addr:PTR byte, @@amount:dword
    uses eax, ebx, ecx

    ;; iterate through memory, print 16 bytes at a time
    mov eax, [@@addr]
    and eax, -10h

    mov ecx, 0

@@print_loop:
    cmp ecx, [@@amount]
    jge @@end

    call print_str, offset hex_prefix
    mov ebx, eax
    add ebx, ecx
    call print_hex_padded, ebx, 8
    call print_char, ':'
    call print_space

    call print_hex_padded, [dword ptr eax+ecx], 8
    call print_space
    add ecx, 4
    call print_hex_padded, [dword ptr eax+ecx], 8
    call print_space
    add ecx, 4
    call print_hex_padded, [dword ptr eax+ecx], 8
    call print_space
    add ecx, 4
    call print_hex_padded, [dword ptr eax+ecx], 8
    call print_newline

    add ecx, 4
    jmp @@print_loop

@@end:
    ret
endp print_hexdump

proc log_prefix
    uses eax
    call print_char, '['
    call print_space
    call gettime_millis
    call print_int, eax
    call print_space
    call print_char, ']'
    call print_space
    ret
endp log_prefix

proc log_str
    arg @@str:dword
    call log_prefix
    call print_str, [@@str]
    call print_newline
    ret
endp log_str

proc log_int
    arg @@value:dword
    call log_prefix
    call print_int, [@@value]
    call print_newline
    ret
endp log_int

proc log_hex
    arg @@value:dword
    call log_prefix
    call print_hex, [@@value]
    call print_newline
    ret
endp log_hex

;; Exits the program with the given statuscode 
proc exit
    arg @@exitcode:dword
    uses eax, ebx
ifdef NASM
    mov eax, 1
    mov ebx, 0
    int 80h
else
    mov ebx, [@@exitcode]
    mov ah, 4ch
    mov al, bl
    int 21h
    ret
endif
endp exit

;; =============================================================================
;; file io functions
;; =============================================================================

;; Creates a file, returns the file handle. If the file already exists
;; it will trunctate the file.
proc create_file
    arg @@file_name:dword, @@access_mode:dword returns eax
    uses ebx, ecx, edx

ifndef NASM
    ;; Since the return value is in ax, we want to make sure the entire
    ;; register is clean
    xor eax, eax

    mov edx, [@@file_name]
    mov ecx, [@@access_mode]
    mov ah, 3Ch
    int 21h
else
    ;; Delete it if it exists, for some reason this is the only way ????
    mov eax, 10
    mov ebx, [@@file_name]
    int 80h

    ;mov eax, 5                  ;; open syscall
    mov eax, 8                  ;; creat syscall
    mov ebx, [@@file_name]
    mov ecx, [@@access_mode]
    
    int 80h
endif

    ret
endp create_file

;; Closes a file
proc close_file
    arg @@file_handle:dword
    uses eax, ebx

ifndef NASM
    mov ebx, [@@file_handle]
    mov ah, 3Eh
    int 21h
else
    mov eax, 6
    mov ebx, [@@file_handle]
    int 80h
endif

    ret
endp close_file

;; Reads bytes from a file.
proc read_file
    arg @@file_handle:dword, @@data:dword, @@count:dword returns eax
    uses ebx, ecx, edx
ifndef NASM
    mov ah, 3Fh
    mov ebx, [@@file_handle]
    mov ecx, [@@count]
    mov edx, [@@data]
    int 21h
else
    mov eax, 3
    mov ebx, [@@file_handle]
    mov ecx, [@@data]
    mov edx, [@@count]
    int 80h
endif
    ret
endp read_file

;; Writes bytes to a file.
proc write_file
    arg @@file_handle:dword, @@data:dword, @@count:dword
    uses eax, ebx, ecx, edx

ifndef NASM
    mov ah, 40h
    mov ebx, [@@file_handle]
    mov ecx, [@@count]
    mov edx, [@@data]
    int 21h
else
    mov eax, 4
    mov ebx, 3
    mov ecx, [@@data]
    mov edx, [@@count]
    int 80h
endif
    ret
endp write_file

;; Writes a null terminated string to a file. Includes the nullbyte.
proc write_str
    arg @@file_handle:dword, @@string:dword
    uses eax
    call strlen, [@@string]
    ;; We want to write the null byte as well
    inc eax
    call write_file, [@@file_handle], [@@string], eax 
    ret
endp write_str

proc lseek_file
    arg @@file_handle:dword, @@origin:dword, @@offset:dword
    uses ebx, ecx, edx

ifndef NASM
    ;; offset is passed via CX:DX
    ;; so here we make sure DX holds the lower half of origin
    mov edx, [@@offset]

    ;; And here we shift so CX holds the upper half of origin
    mov ecx, [@@offset]
    shr ecx, 16

    mov ebx, [@@file_handle]
    mov al, [byte ptr @@origin]
    mov ah, 42h
    int 21h
    
    ;; Stitch dx:ax together to eax
    xor ecx, ecx 
    mov cx, ax
    shl edx, 16
    or ecx, edx
    mov eax, ecx
else
    mov eax, 19
    mov ebx, [@@file_handle]
    mov ecx, [@@offset]
    mov edx, [@@origin]
    int 80h
endif

    ret
endp lseek_file

;; =============================================================================
;; C standard library functions
;; =============================================================================

;; ASM version of C's strlen() function. Returns the length of a null
;; terminated string. 
proc strlen
    arg @@data:dword returns eax
    uses ebx, ecx
    xor eax, eax
    mov ebx, [@@data]

@@countloop:
    mov ecx, [ebx+eax]
    cmp cl, 0
    je @@end

    inc eax
    jmp @@countloop

@@end:
    ret
endp strlen

;; ASM version of C's memcmp() function. Compares two parts of memory. Returns
;; zero in case they are identical.
proc memcmp 
    arg @@d1:dword, @@d2:dword, @@count:dword returns eax
    uses ebx, ecx, esi, edi, edx

    mov eax, 0
    mov ecx, 0
    mov esi, [@@d1]
    mov edi, [@@d2]
    jmp @@cmploop

@@next:
    inc ecx
@@cmploop:
    cmp ecx, [@@count]
    je @@end

    movzx edx, [byte ptr esi + ecx]
    movzx ebx, [byte ptr edi + ecx]
    cmp edx, ebx
    je @@next
    
    mov eax, edx
    sub eax, ebx
@@end:
    ret
endp memcmp

;; ASM version of C's strcmp() function. Compares two null terminated strings
;; and returns 0 if they are identical.
proc strcmp
    arg @@s1:dword, @@s2:dword returns eax
    uses ebx

    call strlen, [@@s2]
    mov ebx, eax
    call strlen, [@@s1]
    sub ebx, eax
    cmp ebx, 0
    jne @@end

    call memcmp, [@@s1], [@@s2], eax
@@end:
    ret
endp strcmp

;; ASM version of C's itoa() function. Converts an integer value to a 
;; null terminated string using the specified base.
proc itoa
    arg @@value:dword, @@buffer:dword, @@base:dword returns eax
    local @@is_neg:dword
    uses ebx, ecx, edx

    mov [@@is_neg], 0
    mov ebx, [@@value]
    mov ecx, [@@buffer]

    ;; Check if value is zero, if so we handle that seperately here
    cmp ebx, 0
    jne @@not_zero
    mov [byte ptr ecx], '0'
    inc ecx
    mov [byte ptr ecx], 0
    jmp @@end
@@not_zero:

    ;; Only base 10 numbers are handled as signed
    cmp [@@base], 10
    jne @@not_neg
    cmp ebx, 0
    jge @@not_neg

    mov [@@is_neg], 1
    neg ebx
@@not_neg:

    cmp ebx, 0
    je @@check_neg
    
    xor edx, edx
    mov eax, ebx
    div [@@base]
    mov ebx, eax

    mov eax, offset itoa_lookup
    mov edx, [eax + edx]
    mov [ecx], edx
    inc ecx
    jmp @@not_neg

@@check_neg:
    cmp [@@is_neg], 0
    je @@add_trailing_zero
    mov [byte ptr ecx], "-"
    inc ecx

@@add_trailing_zero:
    mov [byte ptr ecx], 0
    
    call strrev, [@@buffer]

@@end:
    mov eax, [@@buffer]
    ret
endp itoa

;; ASM version of C's strrev() function. Reverses a null-terminated string
proc strrev
    arg @@string:DWORD
    uses ebx, eax, ecx, edx

    call strlen, [@@string]
    mov ebx, eax
    dec ebx
    mov eax, 0

    @@count_loop:
        cmp eax, ebx
        jge @@end

        mov ecx, [@@string]
        mov edx, [ecx + eax]
        push edx
        
        mov edx, [ecx + ebx]
        add ecx, eax
        mov [byte ptr ecx], dl

        mov ecx, [@@string]
        add ecx, ebx
        pop edx
        mov [byte ptr ecx], dl

        inc eax
        dec ebx
        jmp @@count_loop

@@end:
    ret
endp strrev

;; ASM version of C's memset() function
proc memset
    arg @@data:dword, @@value:dword, @@count:dword returns eax
    uses ecx, edi

    mov ecx, [@@count]
    mov edi, [@@data]
    mov al, [byte ptr @@value]
    rep stosb
    mov eax, [@@data]
    ret
endp memset

;; Non optimized memcpy 
;; TODO: untested
proc memcpy
    arg @@dest:PTR byte, @@src:PTR byte, @@count:dword returns eax
    uses ecx, edi, esi
    
    mov edi, [@@dest]
    mov esi, [@@src]
    mov ecx, [@@count]
    rep movsb

    mov eax, [@@dest]
    ret
endp memcpy

;; Non optimized memmove
;; TODO: untested (pretty damn sure it works tho)
proc memmove
    arg @@dest:PTR byte, @@src:PTR byte, @@count:dword returns eax
    uses ecx, ebx, edi, esi
    
    mov edi, [@@dest]
    mov esi, [@@src]
    mov ecx, [@@count]
    cmp edi, esi
    je @@end            ;; Obviously we don't need to do anything dest == src
    js @@regular        ;; We can do a regular memcpy memmove dest < src

@@right_to_left:
    std                 ;; Set direction flag to right to left

    mov ebx, ecx
    dec ebx
    add edi, ebx
    add esi, ebx

    rep movsb

    cld
    jmp @@end

@@regular:
    rep movsb

@@end:
    mov eax, [@@dest]
    ret
endp memmove

;; =============================================================================
;; time functions
;; =============================================================================

;; Returns the current time in milliseconds
proc gettime_millis
    arg returns eax
    uses ebx, ecx, edx, esi
ifdef NASM
    mov eax, 0
else
    mov ah, 2Ch
    int 21h
    movzx eax, ch
    ;; eax holds the hours
    push edx
    mov esi, 60
    mul esi
    movzx ebx, cl
    add eax, ebx
    ;; eax holds the minutes
    mov esi, 60
    mul esi
    pop edx
    movzx ebx, dh
    add eax, ebx
    ;; eax holds the seconds
    movzx ebx, dl
    mov esi, 100
    mul esi
    add eax, ebx
    ;; eax holds the hundreds of a second
    mov esi, 10
    mul esi
endif
    ;; eax holds the milliseconds
    ret
endp gettime_millis

;; Waits for the specified amount of milliseconds.
proc sleep_millis
    arg @@millis:dword
    uses eax, ebx
ifndef NASM
    call gettime_millis
    mov ebx, eax
    add ebx, [@@millis]
@@waiting:
    hlt
    call gettime_millis
    cmp eax, ebx
    jl @@waiting
endif
    ret
endp sleep_millis

;; =============================================================================
;; floating point helpers
;; =============================================================================

;; Float eq. Returns 1 in eax if the floats are equal.
proc feq
    arg @@arg1:dword, @@arg2:dword returns eax
    ;; diff = arg1 - arg2;
    ;; return (diff < elipson) && (-diff < elipson) 
    xor eax, eax
    fld [@@arg2]
    fld [@@arg1]
    fsubp
    fabs
    fcom [float_epsilon]
    fnstsw ax
    shr eax, 8
    and eax, 111B
    cmp eax, 1
    sete al
    ret
endp feq

DATASEG
    itoa_lookup db "0123456789ABCDEF"
    print_int_buffer db 16 dup (?)
    hex_prefix db "0x", 0

    float_epsilon dd 0.0007

    float_0         dd 0.0
    float_0_25      dd 0.25
    float_0_50      dd 0.50
    float_0_75      dd 0.75
    float_1         dd 1.0
    float_minus_1   dd -1.0
    float_2         dd 2.0
    float_4         dd 4.0
    float_max_char  dd 255.0
    float_1000000   dd 1000000.0
END