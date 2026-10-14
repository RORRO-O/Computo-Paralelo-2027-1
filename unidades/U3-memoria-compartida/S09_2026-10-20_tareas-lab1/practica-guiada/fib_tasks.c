/* fib_tasks.c — Fibonacci recursivo con tareas y corte (cutoff).
 * Ejemplo resuelto S09 · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Es un ejemplo DIDÁCTICO: muestra la mecánica de task / shared / taskwait / cutoff con el código más corto
 * posible. Es un MAL ejemplo de rendimiento: el algoritmo recursivo repite trabajo de forma exponencial y el
 * mejor secuencial (lineal) tarda menos de un microsegundo. El programa imprime los dos speedups para que
 * se vea la diferencia.
 *
 * Uso: ./fib_tasks [n] [cutoff]   (por defecto n=40, cutoff=25: el recursivo tarda ~0.16 s y con 4 hilos las
 *      tareas lo mejoran ~2x; con n=36 el trabajo es tan corto que despertar hilos cuesta más que lo que ahorra).
 *      Entorno: OMP_NUM_THREADS, REPS (5).
 */
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_REPS 32

static long task_count;   /* tareas ejecutadas (contador atómico) */

/* El mejor secuencial: O(n). Según el protocolo del curso, ESTE es T(1). */
static long fib_linear(int n)
{
    long a = 0, b = 1;
    for (int i = 0; i < n; i++) {
        long t = a + b;
        a = b;
        b = t;
    }
    return a;
}

/* Recursivo ingenuo: O(1.618^n) llamadas. Es la versión de la que parte la paralelización con tareas. */
static long fib_seq(int n)
{
    return n < 2 ? n : fib_seq(n - 1) + fib_seq(n - 2);
}

/* Con tareas: cada llamada con n >= cutoff crea dos tareas; por debajo del corte, secuencial. */
static long fib_tasks(int n, int cutoff)
{
    if (n < cutoff)                 /* corte: no crear tareas para subproblemas diminutos */
        return fib_seq(n);
    long x, y;
    #pragma omp task shared(x)      /* x la ESCRIBE la hija y la LEE el padre: debe ser shared, no una copia */
    {
        #pragma omp atomic
        task_count++;
        x = fib_tasks(n - 1, cutoff);
    }
    #pragma omp task shared(y)
    {
        #pragma omp atomic
        task_count++;
        y = fib_tasks(n - 2, cutoff);
    }
    #pragma omp taskwait            /* antes de esta línea NO es seguro leer x ni y */
    return x + y;
}

static int cmp_double(const void *p, const void *q)
{
    double a = *(const double *)p, b = *(const double *)q;
    return (a > b) - (a < b);
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : 40;
    int cutoff = (argc > 2) ? atoi(argv[2]) : 25;
    if (n < 0) n = 0;
    if (n > 45) n = 45;             /* más allá, el recursivo tarda minutos */
    if (cutoff < 2) cutoff = 2;
    /* Guarda: el número de tareas es 2*(fib(n-cutoff+3)-1) y crece como 1.618^(n-cutoff). Con n-cutoff = 28
     * son ~2.7 millones de tareas (segundos); con 34, 48 millones (minutos). Se acota para que una prueba
     * del corte "por curiosidad" no cuelgue la máquina del laboratorio. */
    if (n - cutoff > 28) {
        fprintf(stderr, "aviso: cutoff=%d crearia demasiadas tareas para n=%d; se usa cutoff=%d (n-28)\n",
                cutoff, n, n - 28);
        cutoff = n - 28;
    }
    const char *env = getenv("REPS");
    int reps = env ? atoi(env) : 5;
    if (reps < 1) reps = 1;
    if (reps > MAX_REPS) reps = MAX_REPS;
    int threads = omp_get_max_threads();

    /* Lineal: tarda nanosegundos; se repite 1000 veces y se divide para poder medirlo. */
    volatile long sink = 0;
    double t0 = omp_get_wtime();
    for (int k = 0; k < 1000; k++)
        sink = fib_linear(n);
    double t_lin = (omp_get_wtime() - t0) / 1000.0;
    long expected = sink;

    /* Recursivo: 1 calentamiento + reps repeticiones, mediana. */
    double t_seq[MAX_REPS];
    long r_seq = 0;
    for (int r = -1; r < reps; r++) {
        t0 = omp_get_wtime();
        r_seq = fib_seq(n);
        double t = omp_get_wtime() - t0;
        if (r >= 0)
            t_seq[r] = t;
    }

    /* Con tareas: igual. Un hilo (single) arranca la recursión; los demás toman tareas de la cola. */
    double t_par[MAX_REPS];
    long r_par = 0;
    for (int r = -1; r < reps; r++) {
        task_count = 0;
        t0 = omp_get_wtime();
        #pragma omp parallel
        #pragma omp single
        r_par = fib_tasks(n, cutoff);
        double t = omp_get_wtime() - t0;
        if (r >= 0)
            t_par[r] = t;
    }

    qsort(t_seq, (size_t)reps, sizeof t_seq[0], cmp_double);
    qsort(t_par, (size_t)reps, sizeof t_par[0], cmp_double);
    double m_seq = t_seq[reps / 2], m_par = t_par[reps / 2];
    int ok = (r_seq == expected) && (r_par == expected);

    printf("fib(%d) = %ld   hilos=%d cutoff=%d reps=%d (mediana tras 1 calentamiento)\n",
           n, expected, threads, cutoff, reps);
    printf("lineal    : %.9f s   <- mejor secuencial: T(1) del protocolo\n", t_lin);
    printf("recursivo : %.4f s  (min %.4f  max %.4f)\n", m_seq, t_seq[0], t_seq[reps - 1]);
    printf("tareas    : %.4f s  (min %.4f  max %.4f)   tareas creadas = %ld\n",
           m_par, t_par[0], t_par[reps - 1], task_count);
    printf("speedup contra el recursivo: %.2f   speedup contra el lineal: %.6f\n",
           m_par > 0 ? m_seq / m_par : 0.0, m_par > 0 ? t_lin / m_par : 0.0);
    printf("verificacion: %s\n", ok ? "OK" : "FALLA");
    return ok ? 0 : 1;
}
