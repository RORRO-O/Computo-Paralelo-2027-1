/*
 * barrier_demo.c — barreras implicitas y explicitas, nowait, single y master.
 *
 * Una region paralela con cuatro fases. Cada fase deja rastro en contadores
 * para poder VERIFICAR que:
 *   - al final de `omp for` hay una barrera implicita (todos terminan antes de seguir);
 *   - `single` lo ejecuta exactamente un hilo (cualquiera) y tiene barrera implicita;
 *   - `master` lo ejecuta solo el hilo 0 y NO tiene barrera;
 *   - `nowait` quita la barrera de `omp for`; luego hace falta `barrier` explicita
 *     antes de leer lo que escribieron los demas.
 * El ORDEN de las lineas "hilo k" cambia entre corridas; los conteos finales, no.
 *
 * Uso: ./barrier_demo [n]      (n por defecto: 1 000 000)
 */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 1000000L;
    if (n <= 0) { fprintf(stderr, "Uso: %s [n > 0]\n", argv[0]); return 2; }

    long *a = malloc((size_t)n * sizeof(long));
    if (!a) { fprintf(stderr, "Sin memoria\n"); return 1; }

    int single_runs = 0, master_runs = 0;   /* cuantas veces se ejecuto cada bloque */
    int single_by = -1, master_by = -1;     /* que hilo lo hizo */
    long sum_phase3 = 0;                    /* combinacion de la fase 3 */
    long sum_read_after_barrier = -1;       /* lo que un hilo leyo tras la barrera */
    int errors_phase2 = 0;

    #pragma omp parallel
    {
        int tid = omp_get_thread_num();

        /* Fase 1: llenar a[]. Al terminar el ciclo hay BARRERA IMPLICITA. */
        #pragma omp for
        for (long i = 0; i < n; i++) a[i] = i;

        /* Fase 2: un solo hilo verifica el arreglo completo. Es seguro porque la
         * barrera de la fase 1 garantiza que TODOS los a[i] ya se escribieron.
         * `single` tambien termina con barrera implicita. */
        #pragma omp single
        {
            long bad = 0;
            for (long i = 0; i < n; i++) if (a[i] != i) bad++;
            errors_phase2 = (int)bad;
            single_runs++;
            single_by = tid;
            printf("hilo %d: single -> verifico a[] (errores=%ld)\n", tid, bad);
        }

        /* Fase 3: cada hilo suma su parte. `nowait` quita la barrera del ciclo:
         * cada hilo pasa a la combinacion en cuanto termina SU parte. */
        long local = 0;
        #pragma omp for nowait
        for (long i = 0; i < n; i++) local += a[i];
        #pragma omp atomic
        sum_phase3 += local;
        printf("hilo %d: fase 3 lista, aporto %ld\n", tid, local);

        /* `master`: solo el hilo 0, SIN barrera. Aqui NO es seguro leer sum_phase3
         * (otros hilos pueden seguir sumando), por eso solo registra quien pasa. */
        #pragma omp master
        {
            master_runs++;
            master_by = tid;
        }

        /* BARRERA EXPLICITA: ahora si, todos aportaron a sum_phase3. */
        #pragma omp barrier

        #pragma omp single
        sum_read_after_barrier = sum_phase3;   /* lectura segura */
    }

    long expected = (n - 1) * n / 2;
    int ok = (single_runs == 1) && (master_runs == 1) && (master_by == 0)
             && (errors_phase2 == 0) && (sum_read_after_barrier == expected);
    printf("single se ejecuto %d vez (hilo %d); master se ejecuto %d vez (hilo %d)\n",
           single_runs, single_by, master_runs, master_by);
    printf("suma tras la barrera = %ld (esperado %ld)\n", sum_read_after_barrier, expected);
    printf("RESULT barrier_demo threads=%d status=%s\n", omp_get_max_threads(),
           ok ? "OK" : "INCORRECTO");
    free(a);
    return ok ? 0 : 1;
}
