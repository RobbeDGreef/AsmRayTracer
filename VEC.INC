struc Vec
    x   dd ?
    y   dd ?
    z   dd ?
ends Vec

GLOBAL vec_set:PROC         ;; void vec_set(Vec* v, float x, float y, float z)
<<<<<<< HEAD
<<<<<<< Updated upstream
GLOBAL vec_dot:PROC         ;; float vec_dot(Vec* v1, Vec* v2)
=======
GLOBAL vec_dot:PROC         ;; float vec_dot(Vec* v1, Vec* v2)
GLOBAL vec_mul_float:PROC   ;; float vec_mul_float(Vec* v, float f)
GLOBAL vec_div_float:PROC   ;; float vec_div_float(Vec* v, float f)
>>>>>>> Stashed changes
=======
GLOBAL vec_dot:PROC         ;; float vec_dot(Vec* v1, Vec* v2)
GLOBAL vec_mul_float:PROC   ;; float vec_mul_float(Vec* v, float f)
>>>>>>> b49b0fb94ffdd06bc6b28772786103b38494ce73
