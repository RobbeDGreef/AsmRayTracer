;; Printing to STDOUT
GLOBAL print_str:PROC           ;; void print_str(char* str) 
GLOBAL print_char:PROC          ;; void print_char(dword char)
GLOBAL print_newline:PROC       ;; void print_newline(void)
GLOBAL print_space:PROC         ;; void print_space(void)
GLOBAL print_int:PROC           ;; void print_int(dword value)
GLOBAL print_hex:PROC           ;; void pint_hex(dword value)

;; General 
GLOBAL exit:PROC                ;; void exit(dword exit_code)

;; Will create a file, if it already exists it will truncate it.
GLOBAL create_file:PROC         ;; dword create_file(char* file_name, dword access_mode) 
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
GLOBAL lseek_file:PROC         ;; dword write_lseek(dword file_handle, dword origin, dword offset)

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
GLOBAL strcmp:PROC              ;; dword strcmp(char* s1, char* s2)
GLOBAL memcmp:PROC              ;; dword memcmp(void *d1, void *d2, dword length)