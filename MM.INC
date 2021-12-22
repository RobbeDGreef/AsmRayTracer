GLOBAL mm_init:PROC ;; void init_mm()
GLOBAL alloc:PROC  ;; void* malloc(dword size);

ifdef NASM
extern realloc
endif