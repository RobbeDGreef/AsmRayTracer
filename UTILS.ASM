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
    mov ah, 02h 
    mov edx, [@@char]
    ;; dl: the character to print
    int 21h 
    ;; al: last character output
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

;; Prints an integer to STDOUT in hexadecimal notation (prefixed with 0x)
proc print_hex
    arg @@value:dword
    uses eax
    call print_str, offset hex_prefix
    call itoa, [@@value], offset print_int_buffer, 16
    call print_str, offset print_int_buffer
    ret
endp print_hex

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
    mov ebx, [@@exitcode]
    mov ah, 4ch
    mov al, bl
    int 21h
    ret
endp exit

;; =============================================================================
;; file io functions
;; =============================================================================

;; Creates a file, returns the file handle. If the file already exists
;; it will trunctate the file.
proc create_file
    arg @@file_name:dword, @@access_mode:dword returns eax
    uses ecx, edx

    ;; Since the return value is in ax, we want to make sure the entire
    ;; register is clean
    xor eax, eax

    mov edx, [@@file_name]
    mov ecx, [@@access_mode]
    mov ah, 3Ch
    int 21h

    ret
endp create_file

;; Closes a file
proc close_file
    arg @@file_handle:dword
    uses eax, ebx
    mov ebx, [@@file_handle]
    mov ah, 3Eh
    int 21h
    
    ret
endp close_file

;; Reads bytes from a file.
proc read_file
    arg @@file_handle:dword, @@data:dword, @@count:dword returns eax
    uses ebx, ecx, edx
    mov ah, 3Fh
    mov ebx, [@@file_handle]
    mov ecx, [@@count]
    mov edx, [@@data]
    int 21h
    ret
endp read_file

;; Writes bytes to a file.
proc write_file
    arg @@file_handle:dword, @@data:dword, @@count:dword
    uses eax, ebx, ecx, edx
    mov ah, 40h

    mov ebx, [@@file_handle]
    mov ecx, [@@count]
    mov edx, [@@data]
    int 21h
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

;; =============================================================================
;; time functions
;; =============================================================================

;; Returns the current time in milliseconds
proc gettime_millis
    arg returns eax
    uses ebx, ecx, edx, esi
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
    ;; eax holds the milliseconds
    ret
endp gettime_millis

;; Waits for the specified amount of milliseconds.
proc sleep_millis
    arg @@millis:dword
    uses eax, ebx
    call gettime_millis
    mov ebx, eax
    add ebx, [@@millis]
@@waiting:
    hlt
    call gettime_millis
    cmp eax, ebx
    jl @@waiting
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

    float_epsilon dd 0.0001

    float_0         dd 0.0
    float_0_25      dd 0.25
    float_0_50      dd 0.50
    float_0_75      dd 0.75
    float_1         dd 1.0
    float_minus_one dd -1.0
    float_max_char  dd 255.0
END