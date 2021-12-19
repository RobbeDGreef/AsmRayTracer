;; Printing to STDOUT
GLOBAL print_str:PROC           ;; void print_str(char* str) 
GLOBAL print_char:PROC          ;; void print_char(dword char)
GLOBAL print_newline:PROC       ;; void print_newline(void)
GLOBAL print_space:PROC         ;; void print_space(void)
GLOBAL print_int:PROC           ;; void print_int(dword value)
GLOBAL print_hex:PROC           ;; void pint_hex(dword value)
GLOBAL print_float:PROC         ;; void print_float(float value)
GLOBAL print_hex_multiple:PROC  ;; void print_hex_multiple(dword amount, ...)
GLOBAL print_hexdump:PROC       ;; void print_hexdump(char* loc, dword amount)

GLOBAL log_str:PROC
GLOBAL log_int:PROC
GLOBAL log_hex:PROC

;; General 
GLOBAL exit:PROC                ;; void exit(dword exit_code)

;; Will create a file, if it already exists it will truncate it.
GLOBAL create_file:PROC         ;; dword create_file(char* file_name, dword access_mode) 
GLOBAL open_file:PROC           ;; dword open_file(char* file_name, dword access_mode)
FILE_ATTR_READ_ONLY     equ 1
FILE_ATTR_HIDDEN        equ 2
FILE_ATTR_SYSTEM        equ 4
FILE_ATTR_DIR           equ 16
FILE_ATTR_ARCHIVE       equ 32
FILE_ATTR_SHAREABLE     equ 128

GLOBAL close_file:PROC          ;; void close_file(dword file_handle)
GLOBAL write_file:PROC          ;; void write_file(dword file_handle, char* buffer, dword byte_count)
GLOBAL read_file:PROC           ;; dword read_file(dword file_handle, char* buffer, dword byte_count)
GLOBAL write_str:PROC           ;; void write_str(dword file_handle, char* str)
GLOBAL lseek_file:PROC          ;; dword write_lseek(dword file_handle, dword offset, dword origin)
GLOBAL read_line_from_file:PROC ;; void read_line_from_file(dword file_handle, char* buffer, dword max_bytes)

LSEEK_ORIGIN_START      equ 0
LSEEK_ORIGIN_CUR        equ 1
LSEEK_ORIGIN_END        equ 2

GLOBAL gettime_millis:PROC      ;; dword gettime_millis()
GLOBAL gettime_secs:PROC        ;; dword gettime_secs()
GLOBAL sleep_millis:PROC        ;; void sleep_millis(dword millis)

;; Standard library fakes
GLOBAL strlen:PROC              ;; dword strlen(char* str)
GLOBAL itoa:PROC                ;; void itoa(dword value, char* buffer, dword base)
GLOBAL strrev:PROC              ;; void strrev(char* str)
GLOBAL strchr:PROC              ;; char* strchr(char* str, dword c)
GLOBAL strcmp:PROC              ;; dword strcmp(char* s1, char* s2)
GLOBAL memcmp:PROC              ;; dword memcmp(void *d1, void *d2, dword length)
GLOBAL memset:PROC              ;; void* memset(void *d, dword val, dword length)
GLOBAL memcpy:PROC              ;; void* memcpy(void *d, void *s, dword length)
GLOBAL memmove:PROC             ;; void* memmove(void *d, void *s, dword length)
GLOBAL atof:PROC                ;; float atof(char* str)
GLOBAL atoi:PROC                ;; dword atoi(char* str)

;; Float functions
GLOBAL feq:PROC                 ;; dword feq(float arg1, float arg2)
GLOBAL flt:PROC                 ;; dword flt(float arg1, float arg2)
GLOBAL fpu_arccos:PROC          ;; void fpu_arccos(void) (st0->st0)
GLOBAL fpu_degrees_to_radians: PROC ;; void fpu_degrees_to_radians(void) (st0->st0)

GLOBAL random_int:PROC              ;; dword random_int()
GLOBAL random_float:PROC            ;; void random_float() -> st0
GLOBAL random_float_ranged:PROC     ;; void random_float_ranged(float min, float max) -> st0

;; Float constants
GLOBAL float_0:DWORD
GLOBAL float_0_0_1:DWORD
GLOBAL float_0_20:DWORD
GLOBAL float_0_25:DWORD
GLOBAL float_0_50:DWORD
GLOBAL float_0_75:DWORD
GLOBAL float_0_90:DWORD
GLOBAL float_1:DWORD
GLOBAL float_minus_1:DWORD
GLOBAL float_minus_0_75:DWORD
GLOBAL float_2:DWORD
GLOBAL float_4:DWORD
GLOBAL float_max_char:DWORD
GLOBAL float_pos_inf:DWORD
GLOBAL float_neg_inf:DWORD