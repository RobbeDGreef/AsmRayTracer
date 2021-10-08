struc Vec
    x   dd ?
    y   dd ?
    z   dd ?
ends Vec

GLOBAL vec_set:PROC         ;; void vec_set(Vec* v, float x, float y, float z)
GLOBAL vec_add:PROC         ;; void vec_add(Vec* dest, Vec* v1, Vec* v2)
GLOBAL vec_dot:PROC         ;; float vec_dot(Vec* v1, Vec* v2)
GLOBAL vec_mul_float:PROC   ;; float vec_mul_float(Vec* v, float f)
GLOBAL vec_div_float:PROC   ;; float vec_div_float(Vec* v, float f)