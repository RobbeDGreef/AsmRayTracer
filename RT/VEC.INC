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
GLOBAL vec_set_rgb:PROC     ;; void vec_set(Vec* v, char r, char g, char b)
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
GLOBAL vec_mul_float:PROC   ;; void vec_mul_float(Vec* v, float f)
GLOBAL vec_div_float:PROC   ;; void vec_div_float(Vec* v, float f)
GLOBAL vec_div_int:PROC     ;; void vec_div_int(Vec* v, int i)
GLOBAL vec_length:PROC      ;; float vec_length(Vec* v)
GLOBAL vec_length_squared:PROC      ;; float vec_length_squared(Vec* v)
GLOBAL vec_cross:PROC       ;; void vec_cross(Vec* dest, Vec* v1, Vec* v2)
GLOBAL vec_sqrt:PROC        ;; void vec_sqrt(Vec* vec)
GLOBAL vec_mul:PROC         ;; void vec_mul(Vec* dest, Vec* v1, Vec* v2)
GLOBAL vec_random:PROC      ;; void vec_random(Vec* vec, float min, float max)
GLOBAL vec_random_unit_vec:PROC ;; void vec_random_unit_vec(Vec* vec)
GLOBAL vec_random_in_hemisphere:PROC ;; void vec_random_in_hemisphere(Vec* vec, Vec* normal)

GLOBAL nullvec:Vec