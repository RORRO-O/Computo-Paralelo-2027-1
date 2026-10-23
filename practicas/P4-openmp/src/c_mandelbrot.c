/* c_mandelbrot.c — Parte C (opción principal): conjunto de Mandelbrot por filas con OpenMP.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4 · ESQUELETO (E/S, medición y checksums)
 *
 * Uso:  ./c_mandelbrot [ancho] [alto] [max_iter] [modo] [schedule] [chunk] [salida.pgm|-] [--verificar]
 *   ancho alto  píxeles (por defecto 1300 × 1200); max_iter iteraciones máximas (por defecto 500)
 *   modo        seq | omp (por defecto omp)
 *   schedule    static | dynamic | guided | auto (por defecto static); chunk 0 = el que OpenMP decida
 *               (llegan a schedule(runtime) con omp_set_schedule)
 *   salida.pgm  si se da, escribe la imagen (PGM P5); "-" = no escribir (por defecto no se escribe)
 *   --verificar en modo omp, corre además la secuencial una vez y compara píxel a píxel y los checksums
 * Entorno: OMP_NUM_THREADS; REPS (repeticiones cronometradas, 5; siempre 1 calentamiento).
 *
 * Contrato (c_mandel.h fija región, mapeo, iteración, checksums y PGM): render_seq y render_omp llenan
 * img[row*width + col] = mandel_pixel(...) para todos los píxeles y dejan en iters_by_thread[t] el total de
 * iteraciones que calculó el hilo t (en seq, todo en iters_by_thread[0]). Con eso main imprime el balance
 * de carga (máximo / promedio entre hilos), el dato que justifica el schedule.
 *
 * Lo que diseñas tú (TODO(4) y TODO(5)) y justificas con datos en REPORTE.md:
 *   - cómo se reparten las FILAS entre los hilos (una fila = una iteración del ciclo que se reparte);
 *   - qué schedule y qué chunk, con la medición que lo respalda (el esqueleto ya pasa los argumentos
 *     [schedule] [chunk] a omp_set_schedule; los usa un ciclo con schedule(runtime), si eliges usarlo);
 *   - cómo cuenta cada hilo sus iteraciones SIN critical ni atomic dentro del ciclo de píxeles
 *     (restricción de la Parte C) y sin escribir en casillas vecinas de un arreglo compartido en el ciclo
 *     caliente (falso compartido, S10).
 * Mientras TODO(4) o TODO(5) estén pendientes el programa imprime "TODO pendiente" y las pruebas de la
 * opción Mandelbrot fallan.
 */
#include "c_mandel.h"

/* Versión secuencial: la referencia T(1) del speedup y la verdad contra la que se compara (--verificar). */
static void render_seq(pixel_t *img, int width, int height, int max_iter, long *iters_by_thread)
{
    /* TODO(4): recorre las filas de arriba abajo y, en cada fila, las columnas; para cada píxel obtén c con
     * mandel_pixel_to_c, su iteración de escape k con mandel_pixel y guarda img[row * width + col] = k.
     * Al final, iters_by_thread[0] = suma de todas las k. Borra p4_todo(4) y la línea (void). */
    p4_todo(4);
    (void)img; (void)width; (void)height; (void)max_iter;
    iters_by_thread[0] = 0;
}

/* Versión paralela POR FILAS: mismo resultado que render_seq, píxel por píxel. */
static void render_omp(pixel_t *img, int width, int height, int max_iter, long *iters_by_thread)
{
    /* TODO(5): tu diseño. Contrato: al terminar, img es idéntica a la de render_seq y iters_by_thread[t]
     * tiene las iteraciones que calculó el hilo t (la suma de todas es el checksum). Restricciones: sin
     * critical ni atomic dentro del ciclo de píxeles; el schedule se justifica con la tabla de la Parte D.
     * Borra p4_todo(5) y la línea (void). */
    p4_todo(5);
    (void)img; (void)width; (void)height; (void)max_iter; (void)iters_by_thread;
}

/* ======================= Desde aquí: E/S, medición y checksums (código base) ======================= */

static int parse_schedule(const char *name, omp_sched_t *kind)
{
    if (strcmp(name, "static") == 0)  { *kind = omp_sched_static;  return 0; }
    if (strcmp(name, "dynamic") == 0) { *kind = omp_sched_dynamic; return 0; }
    if (strcmp(name, "guided") == 0)  { *kind = omp_sched_guided;  return 0; }
    if (strcmp(name, "auto") == 0)    { *kind = omp_sched_auto;    return 0; }
    return 1;
}

int main(int argc, char **argv)
{
    int width = 1300, height = 1200, max_iter = 500, chunk = 0, verify = 0, argn = 0;
    const char *mode = "omp", *sched = "static", *out_path = NULL;
    const char *pos[7] = { 0 };
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--verificar") == 0) verify = 1;
        else if (argn < 7) pos[argn++] = argv[i];
    }
    if (pos[0]) width = atoi(pos[0]);
    if (pos[1]) height = atoi(pos[1]);
    if (pos[2]) max_iter = atoi(pos[2]);
    if (pos[3]) mode = pos[3];
    if (pos[4]) sched = pos[4];
    if (pos[5]) chunk = atoi(pos[5]);
    if (pos[6] && strcmp(pos[6], "-") != 0) out_path = pos[6];
    omp_sched_t kind;
    if (width < 1 || height < 1 || max_iter < 1 || max_iter > MANDEL_MAX_ITER_LIMIT || chunk < 0
        || parse_schedule(sched, &kind) || (strcmp(mode, "seq") != 0 && strcmp(mode, "omp") != 0)) {
        fprintf(stderr, "uso: %s [ancho>=1] [alto>=1] [max_iter 1..%d] [seq|omp] [static|dynamic|guided|auto] "
                        "[chunk>=0] [salida.pgm|-] [--verificar]\n", argv[0], MANDEL_MAX_ITER_LIMIT);
        return 2;
    }
    omp_set_schedule(kind, chunk);            /* lo que usa schedule(runtime), si tu render_omp lo usa */
    int is_omp = strcmp(mode, "omp") == 0;
    int threads = is_omp ? omp_get_max_threads() : 1;
    int reps = p4_reps();
    long npix = (long)width * height;
    pixel_t *img = calloc((size_t)npix, sizeof(pixel_t));
    long iters_by_thread[P4_MAX_THREADS];
    double t[P4_MAX_REPS] = { 0 };
    if (!img || threads > P4_MAX_THREADS) { fprintf(stderr, "sin memoria o demasiados hilos\n"); return 2; }

    printf("c_mandelbrot: %dx%d max_iter=%d modo=%s schedule=%s chunk=%d hilos=%d reps=%d\n",
           width, height, max_iter, mode, sched, chunk, threads, reps);
    printf("n=%ld\n", npix);
    for (int r = -1; r < reps; r++) {            /* r = -1: calentamiento (no se cuenta) */
        memset(iters_by_thread, 0, sizeof iters_by_thread);
        double t0 = omp_get_wtime();
        if (is_omp) render_omp(img, width, height, max_iter, iters_by_thread);
        else        render_seq(img, width, height, max_iter, iters_by_thread);
        double el = omp_get_wtime() - t0;
        if (r >= 0) t[r] = el;
    }
    long cs1; unsigned long long cs2;
    mandel_checksum(img, width, height, &cs1, &cs2);

    /* Balance de carga de la última repetición: iteraciones por hilo, máximo / promedio. */
    long it_max = 0, it_tot = 0;
    for (int k = 0; k < threads; k++) {
        it_tot += iters_by_thread[k];
        if (iters_by_thread[k] > it_max) it_max = iters_by_thread[k];
    }
    double imbalance = it_tot > 0 ? (double)it_max * threads / (double)it_tot : 0.0;
    printf("iteraciones por hilo:");
    for (int k = 0; k < threads; k++) printf(" %ld", iters_by_thread[k]);
    printf("\nmax/promedio = %.3f (eficiencia maxima por desbalance = %.2f)  suma %s checksum\n", imbalance,
           imbalance > 0 ? 1.0 / imbalance : 0.0, it_tot == cs1 ? "= " : "DISTINTA del");
    double mn, mx, med = p4_median(t, reps, &mn, &mx);
    printf("mediana %.4f s (min %.4f max %.4f)  %.2f ns/iteracion\n", med, mn, mx,
           cs1 > 0 ? med * 1e9 / (double)cs1 : 0.0);
    printf("checksum=%ld checksum2=%llu\n", cs1, cs2);

    const char *status = (it_tot == cs1) ? "OK" : "FALLA";   /* el reparto contó cada iteración una vez */
    if (verify && is_omp) {
        pixel_t *ref = calloc((size_t)npix, sizeof(pixel_t));
        long ref_it[P4_MAX_THREADS] = { 0 }, r1;
        unsigned long long r2;
        if (!ref) { fprintf(stderr, "sin memoria\n"); return 2; }
        render_seq(ref, width, height, max_iter, ref_it);
        mandel_checksum(ref, width, height, &r1, &r2);
        int same = memcmp(ref, img, (size_t)npix * sizeof(pixel_t)) == 0;
        if (!(same && r1 == cs1 && r2 == cs2)) status = "FALLA";
        printf("verificacion contra la secuencial (pixel a pixel y checksums): %s\n",
               p4_todo_mask ? "NO APLICA (TODO pendiente)" : (same && r1 == cs1 && r2 == cs2 ? "OK" : "FALLA"));
        free(ref);
    }
    if (out_path) {
        if (mandel_write_pgm(img, width, height, max_iter, out_path) == 0)
            printf("imagen escrita en %s (%dx%d, PGM P5)\n", out_path, width, height);
        else
            status = "FALLA";
    }
    if (p4_report_todo()) status = "TODO";
    p4_print_times(t, reps);
    printf("RESULT,c_mandelbrot,%s,%d,%d,%d,%d,%s,%d,%ld,%llu,%.6f,%.3f,%s\n", mode, threads, width, height,
           max_iter, sched, chunk, cs1, cs2, med, imbalance, status);
    free(img);
    return strcmp(status, "OK") == 0 ? 0 : 1;
}
