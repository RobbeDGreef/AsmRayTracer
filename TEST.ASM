;; =============================================================================
;; HOW TO USE
;; =============================================================================
;; - Create a unit test procedure with the 'test_begin' and 'test_end' macros
;;   note that they take the test name as a parameter
;; - Add the tests name as a string in the data segment. The label should be 
;;   named as follow:
;;      test_example_name db "example", 0
;; - Call your test from the main function
;; =============================================================================
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "utils.inc"

CODESEG
    jmp main

;; =============================================================================
;; TESTING FUNCTIONS
;; =============================================================================

proc test_passed
    arg @@test_name:dword
    call print_str, offset test_passed_text
    call print_str, [@@test_name]
    call print_newline
    ret
endp test_passed

proc test_failed
    arg @@test_name:dword, @@value:dword
    call print_str, offset test_failed_text
    call print_str, [@@test_name]
    ;; TODO: print the value here as a failure reason
    call print_newline
    call exit, [@@value]
endp test_failed

macro test_begin name 
proc test_&name
endm test_begin

macro test_end name
@@completed:
    call test_passed, offset test_&name&_name
    ret
endp test_&name
endm test_end name

;; =============================================================================
;; TESTS START HERE
;; =============================================================================

;; -----------------------------------------------------------------------------
;; test_strlen
;; -----------------------------------------------------------------------------
test_begin strlen
    uses eax
    call strlen, offset test_strlen_nullb
    cmp eax, 0
    je @@success1
    call test_failed, offset test_strlen_nullb_failed, eax

@@success1:
    call strlen, offset test_strlen_abc
    cmp eax, 3
    je @@end
    call test_failed, offset test_strlen_abc_failed, eax

@@end:
    call test_passed, offset test_strlen_name
    ret
test_end strlen

;; -----------------------------------------------------------------------------
;; test_memcmp
;; -----------------------------------------------------------------------------
test_begin memcmp
    uses eax
    call memcmp, offset test_memcmp_in1, offset test_memcmp_in1, 3
    cmp eax, 0
    je @@success1
    call test_failed, offset test_memcmp_same_failed, eax
    
@@success1:
    call memcmp, offset test_memcmp_in1, offset test_memcmp_in2, 3
    
    cmp eax, 0
    jl @@success2
    call test_failed, offset test_memcmp_ds_failed, eax

@@success2:
    call memcmp, offset test_memcmp_in2, offset test_memcmp_in1, 3
    
    cmp eax, 0
    jg @@completed
    call test_failed, offset test_memcmp_dl_failed, eax
test_end memcmp

;; -----------------------------------------------------------------------------
;; test_strcmp
;; -----------------------------------------------------------------------------
test_begin strcmp
    uses eax
    call strcmp, offset test_memcmp_in1, offset test_memcmp_in1
    cmp eax, 0
    je @@success1
    call test_failed, offset test_strcmp_same_failed, eax
    
@@success1:
    call strcmp, offset test_memcmp_in1, offset test_memcmp_in2
    
    cmp eax, 0
    jl @@success2
    call test_failed, offset test_strcmp_ds_failed, eax

@@success2:
    call strcmp, offset test_memcmp_in2, offset test_memcmp_in1
    cmp eax, 0
    jg @@completed
    call test_failed, offset test_strcmp_dl_failed, eax
test_end strcmp

;; -----------------------------------------------------------------------------
;; test_itoa
;; test_strrev
;; -----------------------------------------------------------------------------
test_begin itoa
    call itoa, 0, offset test_buffer, 10
    call strcmp, offset test_buffer, offset test_itoa_out_zero
    cmp eax, 0
    je @@success1
    call test_failed, offset test_itoa_zero_failed, eax

@@success1:
    call itoa, 123, offset test_buffer, 10
    call strcmp, offset test_buffer, offset test_itoa_out_dec
    cmp eax, 0
    je @@success2
    call print_str, offset test_buffer
    call print_newline
    call test_failed, offset test_itoa_dec_failed, eax

@@success2:
    call itoa, 0d0f1h, offset test_buffer, 16
    call strcmp, offset test_buffer, offset test_itoa_out_hex
    cmp eax, 0
    je @@success3
    call test_failed, offset test_itoa_hex_failed, eax

@@success3:
    call itoa, 13, offset test_buffer, 2
    call strcmp, offset test_buffer, offset test_itoa_out_bin
    cmp eax, 0
    je @@success4
    call test_failed, offset test_itoa_bin_failed, eax

@@success4:
    call itoa, -123, offset test_buffer, 10
    call strcmp, offset test_buffer, offset test_itoa_out_neg
    cmp eax, 0
    je @@completed
    call test_failed, offset test_itoa_neg_failed, eax
test_end itoa

test_begin strrev
    ;; Since itoa also automatically tested strrev, we mark it as passed
test_end strrev

;; -----------------------------------------------------------------------------
;; test_file_io
;; -----------------------------------------------------------------------------
test_begin file_io
    call create_file, offset test_file_io_file, 0
    mov ebx, eax
    jnc @@success1
    call test_failed, offset test_file_io_create_failed, ebx

@@success1:
    call read_file, ebx, offset test_buffer, 512
    cmp eax, 0
    je @@success2
    call test_failed, offset test_file_io_nullread_failed

@@success2:
    call write_str, ebx, offset test_file_io_str
    call read_file, ebx, offset test_buffer, 512
    call strcmp, offset test_buffer, offset test_file_io_str
    cmp eax, 0
    je @@completed
    call test_failed, offset test_file_io_writeread_failed, eax

test_end file_io

;; =============================================================================
;; ADD YOUR TESTS TO THE MAIN FUNCTION HERE
;; =============================================================================
proc main
    call test_strlen
    call test_memcmp
    call test_strcmp
    call test_itoa
    call test_strrev
    call test_file_io

    call exit, 0
    ret
endp main

DATASEG
    test_passed_text db "[PASSED] ", 0
    test_failed_text db "[FAILED] ", 0

    test_strlen_name db "strlen", 0
    test_strlen_nullb db 0
    test_strlen_abc db "abc", 0
    test_strlen_abc_failed db "strlen - abc", 0
    test_strlen_nullb_failed db "strlen - nullbyte", 0

    test_memcmp_name db "memcmp", 0
    test_memcmp_in1 db "abcdefg", 0
    test_memcmp_in2 db "abdefgh", 0
    test_memcmp_same_failed db "memcmp - same", 0
    test_memcmp_ds_failed db "memcmp - different smaller", 0
    test_memcmp_dl_failed db "memcmp - different larger", 0

    test_strcmp_name db "strcmp", 0
    test_strcmp_same_failed db "strcmp - same", 0
    test_strcmp_ds_failed db "strcmp - different smaller", 0
    test_strcmp_dl_failed db "strcmp - different larger", 0

    test_buffer db 512 dup (?)

    test_itoa_name db "itoa", 0
    test_itoa_out_zero db "0", 0
    test_itoa_out_dec db "123", 0
    test_itoa_out_neg db "-123", 0
    test_itoa_out_hex db "D0F1", 0
    test_itoa_out_bin db "1101", 0
    test_itoa_zero_failed db "itoa - zero", 0
    test_itoa_dec_failed db "itoa - dec", 0
    test_itoa_neg_failed db "itoa - neg", 0
    test_itoa_hex_failed db "itoa - hex", 0
    test_itoa_bin_failed db "itoa - bin", 0

    test_strrev_name db "strrev", 0

    test_file_io_name db "file_io", 0
    test_file_io_str db "abc", 0
    test_file_io_file db "testing/test.txt", 0
    test_file_io_create_failed db "file_io - create file", 0
    test_file_io_nullread_failed db "file_io - nullread", 0
    test_file_io_writeread_failed db "file_io - writeread", 0

STACK 1000h

END