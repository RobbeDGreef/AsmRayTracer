macro def_vec name
struc &name
    x   dd ?
    y   dd ?
    z   dd ?
ends &name
endm def_vec

def_vec Vec
def_vec Color
def_vec Point

VEC_SIZE    equ (4*3)

GLOBAL vec_set:PROC         ;; void vec_set(Vec* v, float x, float y, float z)
GLOBAL vec_dot:PROC         ;; float vec_dot(Vec* v1, Vec* v2)
GLOBAL vec_mul_float:PROC   ;; float vec_mul_float(Vec* v, float f)
GLOBAL vec_cpy:PROC         ;; void vec_cpy(Vec* dest, Vec* src)
GLOBAL vec_eq:PROC          ;; int vec_eq(Vec* arg1, Vec* arg2)
