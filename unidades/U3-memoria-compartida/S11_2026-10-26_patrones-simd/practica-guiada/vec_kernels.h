/* vec_kernels.h — Núcleos (kernels) cortos para estudiar la vectorización con -fopt-info. */
#ifndef VEC_KERNELS_H
#define VEC_KERNELS_H

/* y = a*x + y, tres versiones del MISMO ciclo. */
void saxpy_plain(float a, const float *x, float *y, long n);
void saxpy_restrict(float a, const float *restrict x, float *restrict y, long n);
void saxpy_simd(float a, const float *x, float *y, long n);

/* Suma de prefijos secuencial: tiene dependencia acarreada por el ciclo (a[i] usa a[i-1]). */
void prefix_dep(double *a, const double *b, long n);

#endif
