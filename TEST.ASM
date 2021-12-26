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

include "utils.inc"
include "rt/vec.inc"
include "rt/ray.inc"
include "init.inc"

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
    call print_int, [@@value]
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
;; test_memset
;; -----------------------------------------------------------------------------
test_begin memset
    ;; TODO: test memset
test_end memset

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
    call lseek_file, ebx, LSEEK_ORIGIN_START, 0
    call read_file, ebx, offset test_buffer, 512
    call strcmp, offset test_buffer, offset test_file_io_str
    cmp eax, 0
    je @@completed
    call test_failed, offset test_file_io_writeread_failed, eax

test_end file_io

;; -----------------------------------------------------------------------------
;; test_feq
;; -----------------------------------------------------------------------------
test_begin feq
    call feq, [test_feq_v1], [test_feq_v1]
    cmp al, 1
    je @@success1
    call test_failed, offset test_feq_same_failed, eax

@@success1:
    call feq, [test_feq_v1], [test_feq_v2]
    cmp al, 1
    je @@success2
    call test_failed, offset test_feq_near_failed, eax

@@success2:
    call feq, [test_feq_v1], [test_feq_v3]
    cmp al, 0
    je @@completed
    call test_failed, offset test_feq_different_failed, eax
test_end feq

;; -----------------------------------------------------------------------------
;; test_flt
;; -----------------------------------------------------------------------------
test_begin flt
    call flt, [test_feq_v1], [test_feq_v3]
    cmp al, 1
    je @@success1
    call test_failed, offset test_feq_less_than_failed, eax

@@success1:
    call flt, [test_feq_v3], [test_feq_v1]
    cmp al, 0
    je @@completed
    call test_failed, offset test_flt_greater_failed, eax
test_end flt

test_begin vec_eq
    local @@v1:Vec, @@v2:Vec

    lea ebx, [@@v1]
    lea ecx, [@@v2]
    call vec_set, ebx, [float_0_25], [float_0_50], [float_0_75]
    call vec_set, ecx, [float_0_25], [float_0_50], [float_0_75]
    call vec_eq, ebx, ecx
    cmp eax, 1
    je @@success1
    call test_failed, offset test_vec_eq_same_failed, eax

@@success1:
    call vec_set, ebx, [float_0_25], [float_0_75], [float_0_75]
    call vec_set, ecx, [float_0_25], [float_0_50], [float_0_75]
    call vec_eq, ebx, ecx
    cmp eax, 0
    je @@completed
    call test_failed, offset test_vec_eq_different_failed, eax
test_end vec_eq

test_begin vec_cpy
    local @@src:Vec, @@dest:Vec
    
    lea ebx, [@@src]
    lea ecx, [@@dest]
    
    call vec_set, ebx, [float_0_25], [float_0_50], [float_0_75]
    call vec_cpy, ecx, ebx
    call vec_eq, ecx, ebx
    cmp eax, 1
    je @@completed 
    call test_failed, offset test_vec_cpy_simple_failed, eax

test_end vec_cpy

;; -----------------------------------------------------------------------------
;; test_vec_get_x
;; -----------------------------------------------------------------------------
test_begin vec_get_x
    local @@v:Vec

    lea ebx, [@@v]
    call vec_set, ebx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_get_x, ebx
    call feq, eax, [test_vec_dummy_x] 
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_get_x_failed, eax
test_end vec_get_x

;; -----------------------------------------------------------------------------
;; test_vec_get_y
;; -----------------------------------------------------------------------------
test_begin vec_get_y
    local @@v:Vec

    lea ebx, [@@v]
    call vec_set, ebx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_get_y, ebx
    call feq, eax, [test_vec_dummy_y] 
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_get_y_failed, eax
test_end vec_get_y

;; -----------------------------------------------------------------------------
;; test_vec_get_z
;; -----------------------------------------------------------------------------
test_begin vec_get_z
    local @@v:Vec

    lea ebx, [@@v]
    call vec_set, ebx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_get_z, ebx
    call feq, eax, [test_vec_dummy_z] 
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_get_z_failed, eax
test_end vec_get_z

;; -----------------------------------------------------------------------------
;; test_vec_set_x
;; -----------------------------------------------------------------------------
test_begin vec_set_x
    local @@v:Vec

    lea eax, [@@v]
    call vec_set, eax, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_set_x, eax, [test_vec_dummy_x2]
    call feq, [eax+Vec.x], [test_vec_dummy_x2] 
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_set_x_failed, eax
test_end vec_set_x

;; -----------------------------------------------------------------------------
;; test_vec_set_y
;; -----------------------------------------------------------------------------
test_begin vec_set_y
    local @@v:Vec

    lea eax, [@@v]
    call vec_set, eax, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_set_y, eax, [test_vec_dummy_y2]
    call feq, [eax+Vec.y], [test_vec_dummy_y2] 
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_set_y_failed, eax
test_end vec_set_y

;; -----------------------------------------------------------------------------
;; test_vec_set_z
;; -----------------------------------------------------------------------------
test_begin vec_set_z
    local @@v:Vec

    lea eax, [@@v]
    call vec_set, eax, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_set_z, eax, [test_vec_dummy_z2]
    call feq, [eax+Vec.z], [test_vec_dummy_z2] 
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_set_z_failed, eax
test_end vec_set_z

;; -----------------------------------------------------------------------------
;; test_vec_add
;; -----------------------------------------------------------------------------
test_begin vec_add
    local @@v1:Vec, @@v2:Vec

    lea ecx, [@@v1]
    lea edx, [@@v2]
    call vec_set, ecx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_set, edx, [test_vec_dummy_x2], [test_vec_dummy_y2], \
                  [test_vec_dummy_z2]
    call vec_add, ebx, ecx, edx
    call feq, [ebx+Vec.x], [test_vec_add_xoutput]
    cmp eax, 1
    je @@success1
    call test_failed, offset test_vec_add_x_failed, eax

@@success1:
    call feq, [ebx+Vec.y], [test_vec_add_youtput]
    cmp eax, 1
    je @@success2
    call test_failed, offset test_vec_add_y_failed, eax

@@success2:
    call feq, [ebx+Vec.z], [test_vec_add_zoutput]
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_add_z_failed, eax
test_end vec_add

;; -----------------------------------------------------------------------------
;; test_vec_sub
;; -----------------------------------------------------------------------------
test_begin vec_sub
    local @@v1:Vec, @@v2:Vec

    lea ecx, [@@v1]
    lea edx, [@@v2]
    call vec_set, ecx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_set, edx, [test_vec_dummy_x2], [test_vec_dummy_y2], \
                  [test_vec_dummy_z2]
    call vec_sub, ebx, ecx, edx
    call feq, [ebx+Vec.x], [test_vec_sub_xoutput]
    cmp eax, 1
    je @@success1
    call test_failed, offset test_vec_sub_x_failed, eax

@@success1:
    call feq, [ebx+Vec.y], [test_vec_sub_youtput]
    cmp eax, 1
    je @@success2
    call test_failed, offset test_vec_sub_y_failed, eax

@@success2:
    call feq, [ebx+Vec.z], [test_vec_sub_zoutput]
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_sub_z_failed, eax
test_end vec_sub

;; -----------------------------------------------------------------------------
;; test_vec_dot
;; -----------------------------------------------------------------------------
test_begin vec_dot
    local @@v1:Vec, @@v2:Vec

    lea eax, [@@v1]
    lea ebx, [@@v2]
    call vec_set, eax, [float_0_25], [float_minus_1], \
                  [float_0_75]
    call vec_set, ebx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_dot, eax, ebx
    call feq, eax, [test_vec_dot_output]
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_dot_simple_failed, eax
test_end vec_dot

;; -----------------------------------------------------------------------------
;; test_vec_mul_float
;; -----------------------------------------------------------------------------
test_begin vec_mul_float
    local @@v:Vec

    lea ebx, [@@v]
    call vec_set, ebx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_mul_float, ebx, [test_vec_mul_float_fvalue]
    call feq, [ebx+Vec.x], [test_vec_mul_float_xoutput]
    cmp eax, 1
    je @@success1
    call test_failed, offset test_vec_mul_float_x_failed, eax

@@success1:
    call feq, [ebx+Vec.y], [test_vec_mul_float_youtput]
    cmp eax, 1
    je @@success2
    call test_failed, offset test_vec_mul_float_y_failed, eax

@@success2:
    call feq, [ebx+Vec.z], [test_vec_mul_float_zoutput]
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_mul_float_z_failed, eax
test_end vec_mul_float

;; -----------------------------------------------------------------------------
;; test_vec_div_float
;; -----------------------------------------------------------------------------
test_begin vec_div_float
    local @@v:Vec

    lea ebx, [@@v]
    call vec_set, ebx, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_div_float, ebx, [test_vec_div_float_fvalue]
    call feq, [ebx+Vec.x], [test_vec_div_float_xoutput]
    cmp eax, 1
    je @@success1
    call test_failed, offset test_vec_div_float_x_failed, eax

@@success1:
    call feq, [ebx+Vec.y], [test_vec_div_float_youtput]
    cmp eax, 1
    je @@success2
    call test_failed, offset test_vec_div_float_y_failed, eax

@@success2:
    call feq, [ebx+Vec.z], [test_vec_div_float_zoutput]
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_div_float_z_failed, eax
test_end vec_div_float

;; -----------------------------------------------------------------------------
;; test_vec_length
;; -----------------------------------------------------------------------------
test_begin vec_length
    local @@v1:Vec

    lea eax, [@@v1]
    call vec_set, eax, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_length, eax
    call feq, eax, [test_vec_length_output]
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_length_failed, eax
test_end vec_length

;; -----------------------------------------------------------------------------
;; test_vec_length_squared
;; -----------------------------------------------------------------------------
test_begin vec_length_squared
    local @@v1:Vec

    lea eax, [@@v1]
    call vec_set, eax, [test_vec_dummy_x], [test_vec_dummy_y], \
                  [test_vec_dummy_z]
    call vec_length_squared, eax
    call feq, eax, [test_vec_length_squared_output]
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_length_squared_failed, eax
test_end vec_length_squared

;; -----------------------------------------------------------------------------
;; test_rey_set
;; test_ray_at
;; -----------------------------------------------------------------------------
test_begin ray_at
    local @@ray:Ray, @@origin:Point, @@direction:Vec, @@res:Point, \
          @@compare:Point

    lea eax, [@@origin]
    lea ebx, [@@direction]
    lea ecx, [@@ray]
    lea edx, [@@res]

    call vec_set, eax, [float_1], [float_0_25], [float_0]
    call vec_set, ebx, [float_minus_1], [float_0_75], [float_0_25]
    call ray_set, ecx, eax, ebx

    call ray_at, ecx, edx, [test_ray_at_float_t]

    ;; origin:  (1, 0.25, 0)
    ;; dir:     (-1, 0.75, 0.25)
    ;; t:       3.24
    ;; origin + dir*t = (1, 0.25, 0) + (-3.24, 2.43, 0.81)
    ;;                = (-2.24, 2.68, 0.81)

    lea eax, [@@compare]
    call vec_set, eax, [test_ray_at_res_x], [test_ray_at_res_y], \
                       [test_ray_at_res_z]

    call vec_eq, eax, edx
    cmp eax, 1
    je @@completed
    call test_failed, offset test_ray_at_simple_failed, eax
test_end ray_at

;; -----------------------------------------------------------------------------
;; test_vec_cross
;; -----------------------------------------------------------------------------
test_begin vec_cross
    local @@dest:Vec, @@v1:Vec, @@v2:Vec, @@compare:Vec

    lea ebx, [@@v1]
    lea ecx, [@@v2]
    lea edx, [@@dest]
    lea edi, [@@compare]

    call vec_set, ebx, [test_vec_dummy_x], [test_vec_dummy_y], \
                       [test_vec_dummy_z]
    call vec_set, ecx, [test_vec_dummy_x2], [test_vec_dummy_y2], \
                       [test_vec_dummy_z2]
    call vec_cross, edx, ebx, ecx
    
    call vec_set, edi, [test_vec_cross_xoutput], [test_vec_cross_youtput], \
                       [test_vec_cross_zoutput]

    call vec_eq, edi, edx
    cmp eax, 1
    je @@completed
    call test_failed, offset test_vec_cross_simple_failed, eax

test_end vec_cross

;; =============================================================================
;; ADD YOUR TESTS TO THE MAIN FUNCTION HERE
;; =============================================================================
proc main
    call init

    call test_strlen
    call test_memcmp
    call test_strcmp
    call test_itoa
    call test_strrev
    call test_memset
    ;call test_file_io
    call test_feq
    call test_flt
    call test_vec_add
    call test_vec_sub
    call test_vec_dot
    call test_vec_mul_float
    call test_vec_eq
    call test_vec_cpy
    call test_vec_div_float
    call test_vec_length
    call test_vec_length_squared
    call test_vec_get_x
    call test_vec_get_y
    call test_vec_get_z
    call test_vec_set_x
    call test_vec_set_y 
    call test_vec_set_z
    call test_ray_at
    call test_vec_cross

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

    test_memset_name db "memset", 0

    test_feq_name db "feq", 0
    test_feq_v1 dd 123.12345
    test_feq_v2 dd 123.12351
    test_feq_v3 dd 321.123
    test_feq_same_failed db "feq - same", 0
    test_feq_near_failed db "feq - near", 0
    test_feq_different_failed db "feq - different", 0
    test_feq_less_than_failed db "flt - less than", 0
    
    test_flt_name db"flt", 0
    test_flt_greater_failed db "flt - greather than", 0

    test_vec_dummy_x dd 12.123
    test_vec_dummy_y dd 32.321
    test_vec_dummy_z dd 23.854

    ;; In case we need more dummy values
    test_vec_dummy_x2 dd 6.854
    test_vec_dummy_y2 dd 4.521
    test_vec_dummy_z2 dd 12.445

    test_vec_dot_name db "vec_dot", 0
    test_vec_dot_output dd -11.39975
    test_vec_dot_simple_failed db "vec_dot - simple", 0

    test_vec_mul_float_name db "vec_mul_float", 0
    test_vec_mul_float_fvalue dd 2.5
    test_vec_mul_float_xoutput dd 30.3075
    test_vec_mul_float_youtput dd 80.8025
    test_vec_mul_float_zoutput dd 59.635
    test_vec_mul_float_x_failed db "vec_mul_float - x", 0
    test_vec_mul_float_y_failed db "vec_mul_float - y", 0
    test_vec_mul_float_z_failed db "vec_mul_float - z", 0

    test_vec_eq_name db "vec_eq", 0
    test_vec_eq_same_failed db "vec_eq - same", 0
    test_vec_eq_different_failed db "vec_eq - different", 0

    test_vec_cpy_name db "vec_cpy", 0
    test_vec_cpy_simple_failed db  "vec_cpy - simple", 0

    test_vec_div_float_name db "vec_div_float", 0
    test_vec_div_float_fvalue dd 2.5
    test_vec_div_float_xoutput dd 4.8496
    test_vec_div_float_youtput dd 12.9284
    test_vec_div_float_zoutput dd 9.5416
    test_vec_div_float_x_failed db "vec_div_float - x", 0
    test_vec_div_float_y_failed db "vec_div_float - y", 0
    test_vec_div_float_z_failed db "vec_div_float - z", 0

    test_vec_add_name db "vec_add", 0
    test_vec_add_xoutput dd 18.977
    test_vec_add_youtput dd 36.842
    test_vec_add_zoutput dd 36.299
    test_vec_add_x_failed db "vec_add - x", 0
    test_vec_add_y_failed db "vec_add - y", 0
    test_vec_add_z_failed db "vec_add - z", 0

    test_vec_sub_name db "vec_sub", 0
    test_vec_sub_xoutput dd 5.269
    test_vec_sub_youtput dd 27.8
    test_vec_sub_zoutput dd 11.409
    test_vec_sub_x_failed db "vec_sub - x", 0
    test_vec_sub_y_failed db "vec_sub - y", 0
    test_vec_sub_z_failed db "vec_sub - z", 0

    test_vec_length_name db "vec_length", 0
    test_vec_length_output dd 41.95983181567819
    test_vec_length_failed db "vec_length failed", 0

    test_vec_length_squared_name db "vec_length_squared", 0
    test_vec_length_squared_output dd 1760.627486
    test_vec_length_squared_failed db "vec_length_squared", 0

    test_vec_get_x_name db "vec_get_x", 0
    test_vec_get_x_failed db "vec_get_x", 0

    test_vec_get_y_name db "vec_get_y", 0
    test_vec_get_y_failed db "vec_get_y", 0

    test_vec_get_z_name db "vec_get_z", 0
    test_vec_get_z_failed db "vec_get_z", 0

    test_vec_set_x_name db "vec_set_x", 0
    test_vec_set_x_failed db "vec_set_x", 0

    test_vec_set_y_name db "vec_set_y", 0
    test_vec_set_y_failed db "vec_set_y", 0

    test_vec_set_z_name db "vec_set_z", 0
    test_vec_set_z_failed db "vec_set_z", 0

    test_ray_at_name db "ray_at", 0
    test_ray_at_simple_failed db "ray_at - simple", 0
    test_ray_at_float_t dd 3.24
    test_ray_at_res_x dd -2.24
    test_ray_at_res_y dd 2.68
    test_ray_at_res_z dd 0.81

    test_vec_cross_name db "vec_cross", 0
    test_vec_cross_xoutput dd 294.390911
    test_vec_cross_youtput dd 12.624581
    test_vec_cross_zoutput dd -166.720051
    test_vec_cross_simple_failed db "vec_cross - simple", 0

STACK 1000h

END main