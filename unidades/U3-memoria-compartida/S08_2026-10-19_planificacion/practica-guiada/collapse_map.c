/*
 * collapse_map.c — ¿Qué hilo ejecuta cada celda (i, j) de un ciclo anidado?
 *
 * Compara tres formas de repartir un ciclo doble de filas x columnas:
 *   A) parallel for sobre el ciclo externo (solo se reparten las filas)
 *   B) collapse(2) + static  (se reparten las filas*columnas celdas)
 *   C) collapse(2) + dynamic,2
 * Cada celda espera un tiempo fijo para que el reparto dinámico sea visible.
 *
 * Uso:  ./collapse_map [filas] [columnas]      (por defecto 3 x 6)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp collapse_map.c -o collapse_map
 */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define MAX_DIM     16
#define MAX_THREADS 64
#define CELL_US     300.0   /* costo de cada celda en microsegundos */

static void spin_us(double us)
{
    double t_end = omp_get_wtime() + us * 1e-6;
    while (omp_get_wtime() < t_end) { /* ocupado */ }
}

static void cell(int i, int j, int owner[MAX_DIM][MAX_DIM])
{
    owner[i][j] = omp_get_thread_num();
    spin_us(CELL_US);
}

static void clear(int rows, int cols, int owner[MAX_DIM][MAX_DIM])
{
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++) owner[i][j] = -1;
}

static void print_grid(const char *label, int rows, int cols, int owner[MAX_DIM][MAX_DIM])
{
    int n_threads = omp_get_max_threads();
    if (n_threads > MAX_THREADS) n_threads = MAX_THREADS;
    int count[MAX_THREADS] = {0};

    printf("%s\n", label);
    for (int i = 0; i < rows; i++) {
        printf("  fila %2d:", i);
        for (int j = 0; j < cols; j++) {
            printf(" %d", owner[i][j]);
            if (owner[i][j] >= 0 && owner[i][j] < n_threads) count[owner[i][j]]++;
        }
        printf("\n");
    }
    int idle = 0;
    printf("  celdas por hilo:");
    for (int t = 0; t < n_threads; t++) {
        printf(" %d", count[t]);
        if (count[t] == 0) idle++;
    }
    printf("   (hilos sin trabajo: %d)\n", idle);
}

int main(int argc, char **argv)
{
    int rows = (argc > 1) ? atoi(argv[1]) : 3;
    int cols = (argc > 2) ? atoi(argv[2]) : 6;
    if (rows < 1 || rows > MAX_DIM || cols < 1 || cols > MAX_DIM) {
        fprintf(stderr, "filas y columnas deben estar en 1..%d\n", MAX_DIM);
        return 2;
    }
    static int owner[MAX_DIM][MAX_DIM];
    printf("filas=%d columnas=%d celdas=%d hilos=%d\n", rows, cols, rows * cols,
           omp_get_max_threads());

    /* A) Solo se reparte el ciclo externo: hay a lo más 'rows' trozos de trabajo. */
    clear(rows, cols, owner);
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            cell(i, j, owner);
    print_grid("A) parallel for schedule(static) sobre i (sin collapse):", rows, cols, owner);

    /* B) collapse(2): el espacio de iteraciones es el producto filas*columnas. */
    clear(rows, cols, owner);
    #pragma omp parallel for collapse(2) schedule(static)
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            cell(i, j, owner);
    print_grid("B) parallel for collapse(2) schedule(static):", rows, cols, owner);

    /* C) collapse(2) con reparto dinámico de a 2 celdas. */
    clear(rows, cols, owner);
    #pragma omp parallel for collapse(2) schedule(dynamic, 2)
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            cell(i, j, owner);
    print_grid("C) parallel for collapse(2) schedule(dynamic,2):", rows, cols, owner);

    return 0;
}
