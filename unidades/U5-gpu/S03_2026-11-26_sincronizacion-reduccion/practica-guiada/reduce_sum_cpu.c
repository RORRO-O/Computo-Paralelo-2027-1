/*
 * reduce_sum_cpu.c — Referencia secuencial de reduce_sum.cu (Unidad V, S03).
 *
 * Calcula la misma suma de cuatro maneras para mostrar que, en float, el ORDEN de las sumas
 * cambia el resultado (idea errónea 10), y emula el orden exacto de los kernels en árbol:
 *   ref_double            suma secuencial en double: la referencia contra la que se verifica
 *   float_secuencial      suma secuencial en float (i = 0, 1, 2, ...)
 *   float_orden_permutado suma en float recorriendo los índices en otro orden (emula el orden
 *                         arbitrario en que llegan las atómicas a la GPU)
 *   float_arbol_div       mismo orden que reduce_tree_div (árbol por bloque) + etapa 2 en double
 *   float_arbol_nodiv     mismo orden que reduce_tree_nodiv + etapa 2 en double
 * También imprime el máximo (fase Modificar) y cuántas operaciones atómicas haría cada versión
 * de GPU con ese n y ese block (fase Predecir).
 *
 * Uso:   ./reduce_sum_cpu [n] [block]        (por defecto 1048576 256)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra reduce_sum_cpu.c -o reduce_sum_cpu -lm
 * Datos: x[i] = 1.0f + (i % 10) * 0.1f, x[n-1] = 9.5f  (iguales a reduce_sum.cu y reduce_sum_numba.py)
 */
#define _POSIX_C_SOURCE 199309L   /* clock_gettime con -std=c11 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define REPS 5
#define MAX_BLOCK 1024
#define TOL_REL 1e-4

static void init_data(float *x, int n)
{
    for (int i = 0; i < n; i++)
        x[i] = 1.0f + (float)(i % 10) * 0.1f;
    x[n - 1] = 9.5f;
}

static double sum_double(const float *x, int n)
{
    double acc = 0.0;
    for (int i = 0; i < n; i++)
        acc += x[i];
    return acc;
}

static float sum_float_sequential(const float *x, int n)
{
    float acc = 0.0f;
    for (int i = 0; i < n; i++)
        acc += x[i];
    return acc;
}

static long gcd(long a, long b)
{
    while (b != 0) {
        long t = a % b;
        a = b;
        b = t;
    }
    return a;
}

/* Recorre los n índices en el orden j, 2j, 3j, ... (mod n) con j coprimo con n: una permutación
 * determinista que imita el orden arbitrario de llegada de las atómicas. */
static float sum_float_permuted(const float *x, int n)
{
    long step = 1000003;
    while (gcd(step, n) != 1)
        step += 2;
    float acc = 0.0f;
    long idx = 0;
    for (int k = 0; k < n; k++) {
        acc += x[idx];
        idx = (idx + step) % n;
    }
    return acc;
}

/* Emula, en float y en el mismo orden, la reducción en árbol por bloque de los kernels. */
static double sum_tree_emulation(const float *x, int n, int block, int divergent)
{
    static float s[MAX_BLOCK];
    int grid = (n + block - 1) / block;
    double total = 0.0;                 /* etapa 2 en double, como el anfitrión de reduce_sum.cu */
    for (int b = 0; b < grid; b++) {
        for (int tid = 0; tid < block; tid++) {
            int i = b * block + tid;
            s[tid] = (i < n) ? x[i] : 0.0f;
        }
        if (divergent) {
            for (int stride = 1; stride < block; stride *= 2)
                for (int tid = 0; tid < block; tid++)
                    if (tid % (2 * stride) == 0)
                        s[tid] += s[tid + stride];
        } else {
            for (int stride = block / 2; stride > 0; stride >>= 1)
                for (int tid = 0; tid < stride; tid++)
                    s[tid] += s[tid + stride];
        }
        total += s[0];
    }
    return total;
}

static double now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e3 + (double)ts.tv_nsec / 1e6;
}

static int cmp_double(const void *a, const void *b)
{
    double da = *(const double *)a, db = *(const double *)b;
    return (da > db) - (da < db);
}

static int report(const char *name, double value, double ref, const char *note)
{
    double err_rel = fabs(value - ref) / fabs(ref);
    int ok = err_rel <= TOL_REL;
    printf("%-22s=%.6f  err_rel=%.2e  %s%s\n", name, value, err_rel, ok ? "dentro_de_tolerancia" : "FUERA", note);
    return ok;
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 20);
    int block = (argc > 2) ? atoi(argv[2]) : 256;
    if (n <= 0 || block <= 0 || block > MAX_BLOCK) {
        fprintf(stderr, "uso: %s [n>0] [block 1..%d]\n", argv[0], MAX_BLOCK);
        return 1;
    }
    int grid = (n + block - 1) / block;
    int pow2 = (block & (block - 1)) == 0;

    float *x = (float *)malloc((size_t)n * sizeof(float));
    if (!x) {
        fprintf(stderr, "Sin memoria para n=%d\n", n);
        return 1;
    }
    init_data(x, n);

    /* Tiempo de la referencia (protocolo: calentamiento + REPS, mediana) */
    double t[REPS];
    volatile double sink = sum_double(x, n);    /* calentamiento */
    for (int r = 0; r < REPS; r++) {
        double t0 = now_ms();
        sink = sum_double(x, n);
        t[r] = now_ms() - t0;
    }
    qsort(t, REPS, sizeof(double), cmp_double);
    double ref = sink;

    printf("reduce_sum_cpu: n=%d block=%d grid=%d\n", n, block, grid);
    printf("ref_double            =%.6f  (suma secuencial en double; mediana_ms=%.3f de %d, min %.3f, max %.3f)\n",
           ref, t[REPS / 2], REPS, t[0], t[REPS - 1]);

    /* Las dos sumas en float con un solo acumulador son informativas: muestran el efecto del orden y, con
     * n grande (2^24), la saturación del acumulador (sumar 1.0 a 16 777 216 ya no cambia el float).
     * La verificación del programa cubre las emulaciones del árbol (son lo que hace la GPU) y el máximo. */
    int ok = 1;
    report("float_secuencial", (double)sum_float_sequential(x, n), ref, "  (informativo: un acumulador)");
    report("float_orden_permutado", (double)sum_float_permuted(x, n), ref,
           "  (informativo: emula el orden arbitrario de las atómicas)");
    if (pow2) {
        ok &= report("float_arbol_div", sum_tree_emulation(x, n, block, 1), ref, "  (mismo orden que tree_div)");
        ok &= report("float_arbol_nodiv", sum_tree_emulation(x, n, block, 0), ref, "  (mismo orden que tree_nodiv)");
    } else {
        printf("float_arbol_*         : no se emulan; block=%d no es potencia de 2 (el árbol perdería sumandos)\n",
               block);
    }

    /* Máximo y su posición (fase Modificar: reducción max) */
    float mx = x[0];
    int imx = 0;
    for (int i = 1; i < n; i++)
        if (x[i] > mx) {
            mx = x[i];
            imx = i;
        }
    printf("max=%.6f en i=%d\n", mx, imx);
    ok &= (mx == 9.5f && imx == n - 1);

    /* Operaciones atómicas en memoria global que haría cada versión de GPU (fase Predecir) */
    printf("atomicas_globales: atomic=%d  tree+etapa2=cpu: 0  tree+etapa2=atomic: %d\n", n, grid);
    printf("verificacion=%s  (emulaciones del árbol dentro de tolerancia y máximo correcto)\n", ok ? "OK" : "FALLA");

    free(x);
    return ok ? 0 : 2;
}
