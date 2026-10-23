/* c_heat.h — Parte C (alternativa): CONTRATO de la ecuación de calor 1D (Jacobi explícito). No lo modifiques.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4
 *
 * Fija el problema, la condición inicial, la regla de actualización de UN punto y el checksum, para que el
 * resultado de cualquier implementación correcta sea igual al de la referencia. Lo que diseñas tú (cómo se
 * reparte cada paso, cómo se decide la convergencia en paralelo) va en c_heat.c.
 *
 * Problema: barra con n celdas (índices 0..n-1); las dos celdas extremas son fronteras fijas en 0 °C.
 * Condición inicial: 100 °C en el tercio central, 0 °C en el resto (un escalón que se difunde).
 * Cada paso (Jacobi: se lee SOLO el arreglo viejo y se escribe SOLO el nuevo):
 *     u_new[i] = u[i] + R * (u[i-1] - 2*u[i] + u[i+1]),   R = 0.25,   para 1 <= i <= n-2
 * Convergencia: se detiene cuando max_i |u_new[i] - u[i]| < tol, revisado cada check_every pasos (y en el
 * último paso permitido), o al llegar a max_iter pasos. Con tol = 0 corre exactamente max_iter pasos.
 */
#ifndef P4_C_HEAT_H
#define P4_C_HEAT_H

#include <math.h>
#include "common.h"

#define HEAT_R 0.25

static inline void heat_init(double *u, double *u_new, long n)
{
    long lo = n / 3, hi = 2 * n / 3;              /* tercio central: [lo, hi) */
    for (long i = 0; i < n; i++) {
        u[i] = (i >= lo && i < hi) ? 100.0 : 0.0;
        u_new[i] = 0.0;
    }
    u[0] = u[n - 1] = 0.0;                        /* fronteras: fijas en 0 en los dos búferes */
    u_new[0] = u_new[n - 1] = 0.0;
}

/* Valor nuevo del punto interior i. Úsala tal cual: fija el orden de las operaciones en punto flotante, así
 * que cualquier reparto de las celdas entre hilos da los mismos bits que la secuencial. */
static inline double heat_point(const double *u, long i)
{
    return u[i] + HEAT_R * (u[i - 1] - 2.0 * u[i] + u[i + 1]);
}

/* ¿Toca revisar la convergencia al terminar el paso número `step` (contando desde 1)? */
static inline int heat_is_check_step(long step, long check_every, long max_iter)
{
    return (step % check_every == 0) || (step == max_iter);
}

/* Checksums del estado final, calculados en orden de índice (deterministas para el mismo arreglo):
 *   checksum  = suma de u[i]: el calor total; casi no cambia mientras el frente no llega a las fronteras,
 *               así que sola NO distingue un paso de otro.
 *   checksum2 = suma de u[i]^2: baja en cada paso porque el escalón se suaviza; detecta pasos de más o de
 *               menos y celdas mal calculadas. */
static inline double heat_checksum(const double *u, long n)
{
    double s = 0.0;
    for (long i = 0; i < n; i++) s += u[i];
    return s;
}

static inline double heat_checksum2(const double *u, long n)
{
    double s = 0.0;
    for (long i = 0; i < n; i++) s += u[i] * u[i];
    return s;
}

#endif /* P4_C_HEAT_H */
