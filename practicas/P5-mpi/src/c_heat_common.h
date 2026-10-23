/*
 * c_heat_common.h — Parte C: ecuación de calor 1D. Lo que comparten la versión secuencial y la MPI:
 * el problema (condición inicial fija, fronteras, esquema de actualización, criterio de paro) y la
 * verificación. Así las dos versiones resuelven EXACTAMENTE el mismo problema y se pueden comparar.
 *
 * Problema. Barra de longitud 1 con n celdas interiores (índice global i = 0..n-1, posición
 * x_i = (i+1)/(n+1)) y dos fronteras fijas en 0 °C. Condición inicial: un pulso gaussiano de 100 °C
 * centrado en x = 0.5. En cada paso de tiempo (esquema explícito, forma de Jacobi con dos búferes):
 *     u_new[i] = u[i] + R * (u[i-1] - 2 u[i] + u[i+1]),   R = 0.25  (estable si R <= 0.5)
 * Se detiene cuando max_i |u_new[i] - u[i]| < tol (revisado cada check_every pasos) o al llegar a
 * max_iter. Con tol = 0 corre exactamente max_iter pasos (así se mide escalabilidad con trabajo fijo).
 *
 * Convención de índices en los arreglos: u[0] y u[n+1] son las fronteras; el interior es u[1..n].
 * En MPI cada rango usa la misma convención con su n_local: u[0] y u[n_local+1] son sus celdas
 * fantasma (halos), que contienen la frontera física o el dato del vecino.
 */
#ifndef P5_HEAT_COMMON_H
#define P5_HEAT_COMMON_H

#include "common.h"

#define HEAT_R 0.25
#define HEAT_T_LEFT 0.0
#define HEAT_T_RIGHT 0.0

/* Temperatura inicial de la celda interior global i (0-based) en una barra de n celdas. */
static inline double heat_initial(long long i, long long n)
{
    double x = (double)(i + 1) / (double)(n + 1);
    double z = (x - 0.5) / 0.1;
    return 100.0 * exp(-z * z);
}

static inline double heat_update(double left, double center, double right)
{
    return center + HEAT_R * (left - 2.0 * center + right);
}

/* Un paso sobre las celdas i = from..to (inclusive) de u -> u_new. Devuelve max |u_new - u| en ese
 * tramo si want_diff, o 0.0 si no (ahorra una resta y un fabs por celda en los pasos sin revisión). */
static inline double heat_step_range(const double *u, double *u_new, long long from, long long to, int want_diff)
{
    double diff = 0.0;
    if (want_diff) {
        for (long long i = from; i <= to; i++) {
            u_new[i] = heat_update(u[i - 1], u[i], u[i + 1]);
            double d = fabs(u_new[i] - u[i]);
            if (d > diff) diff = d;
        }
    } else {
        for (long long i = from; i <= to; i++) u_new[i] = heat_update(u[i - 1], u[i], u[i + 1]);
    }
    return diff;
}

/* Llena u[0..n+1] (y u_new igual) con fronteras + condición inicial. */
static inline void heat_init_full(double *u, double *u_new, long long n)
{
    u[0] = u_new[0] = HEAT_T_LEFT;
    u[n + 1] = u_new[n + 1] = HEAT_T_RIGHT;
    for (long long i = 1; i <= n; i++) u[i] = u_new[i] = heat_initial(i - 1, n);
}

/* Resuelve en UN proceso. Al regresar, u[1..n] tiene el estado final (también si terminó en u_new:
 * se copia). Devuelve el número de pasos ejecutados; *converged = 1 si paró por tol; *last_diff =
 * la última diferencia máxima revisada (-1 si no se revisó ningún paso). Es la referencia contra la que
 * se verifica la versión MPI. */
static inline long long heat_solve_seq(double *u, double *u_new, long long n, long long max_iter, double tol,
                                       long long check_every, int *converged, double *last_diff)
{
    long long it = 0;
    double diff = -1.0;
    *converged = 0;
    for (it = 1; it <= max_iter; it++) {
        int check = (it % check_every == 0);
        double d = heat_step_range(u, u_new, 1, n, check);
        double *tmp = u; u = u_new; u_new = tmp; /* doble búfer: el nuevo pasa a ser el actual */
        if (check) {
            diff = d;                             /* solo cuenta la diferencia de un paso revisado */
            if (diff < tol) { *converged = 1; break; }
        }
    }
    if (it > max_iter) it = max_iter;
    /* Tras un número impar de intercambios el resultado quedó en el búfer que el llamador conoce
     * como u_new; se devuelve siempre en el que conoce como u. */
    if (it % 2 == 1) memcpy(u_new, u, (size_t)(n + 2) * sizeof(double)); /* u_new aquí es el u original */
    *last_diff = diff;
    return it;
}

static inline double heat_checksum(const double *interior, long long n)
{
    double s = 0.0;
    for (long long i = 0; i < n; i++) s += interior[i];
    return s;
}

/* Verificación celda a celda con tolerancia absoluta; devuelve 1 si coincide y deja max |dif|. */
static inline int heat_verify(const double *got, const double *ref, long long n, double tol, double *max_diff)
{
    double md = 0.0;
    for (long long i = 0; i < n; i++) {
        double d = fabs(got[i] - ref[i]);
        if (d > md) md = d;
    }
    *max_diff = md;
    return md <= tol;
}

/* Imprime el perfil (para n pequeño): i, x, u */
static inline void heat_print_profile(const double *interior, long long n)
{
    for (long long i = 0; i < n; i++)
        printf("perfil %lld %.6f %.6f\n", i, (double)(i + 1) / (double)(n + 1), interior[i]);
}

#endif /* P5_HEAT_COMMON_H */
