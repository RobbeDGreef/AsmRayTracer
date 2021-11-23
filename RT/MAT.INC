struc Mat
    scatter dd ?    ;; bool scatter(Ray* in, Hit* hit, Color* color, Ray* out)
    emission dd ?   ;; void emission(Ray* in, Hit* hit, Color* emission)
ends Mat 

GLOBAL mat_init:PROC ;; void mat_init(Mat* mat, scatter_fp scatter, emission_fp emission)