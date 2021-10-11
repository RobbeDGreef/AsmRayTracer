macro def_vec name
struc &name&
    x   dd ?
    y   dd ?
    z   dd ?
ends &name&
endm def_vec

def_vec Vec
def_vec Color
def_vec Point

VEC_SIZE    equ (4*3)

GLOBAL vec_print:PROC       ;; void vec_print(Vec* v)
GLOBAL vec_set:PROC         ;; void vec_set(Vec* v, float x, float y, float z)
GLOBAL vec_cpy:PROC         ;; void vec_cpy(Vec* dest, Vec* src)
GLOBAL vec_eq:PROC          ;; int vec_eq(Vec* arg1, Vec* arg2)
GLOBAL vec_get_x:PROC       ;; float vec_get_x(Vec* v)
GLOBAL vec_get_y:PROC       ;; float vec_get_y(Vec* v)
GLOBAL vec_get_z:PROC       ;; float vec_get_z(Vec* v)
GLOBAL vec_set_x:PROC       ;; float vec_set_x(Vec* v, float f)
GLOBAL vec_set_y:PROC       ;; float vec_set_y(Vec* v, float f)
GLOBAL vec_set_z:PROC       ;; float vec_set_z(Vec* v, float f)
GLOBAL vec_add:PROC         ;; void vec_add(Vec* dest, Vec* v1, Vec* v2)
GLOBAL vec_sub:PROC         ;; void vec_sub(Vec* dest, Vec* v1, Vec* v2)
GLOBAL vec_dot:PROC         ;; float vec_dot(Vec* v1, Vec* v2)
GLOBAL vec_mul_float:PROC   ;; float vec_mul_float(Vec* v, float f)
GLOBAL vec_div_float:PROC   ;; float vec_div_float(Vec* v, float f)
GLOBAL vec_length:PROC      ;; float vec_length(Vec* v)
GLOBAL vec_length_squared:PROC      ;; float vec_length_squared(Vec* v)
GLOBAL vec_cross:PROC       ;; void vec_cross(Vec* dest, Vec* v1, Vec* v2)
