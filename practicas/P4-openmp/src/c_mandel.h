/* c_mandel.h — Parte C (opción principal): CONTRATO del conjunto de Mandelbrot. No lo modifiques.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4
 *
 * Este archivo fija lo que hace comparable tu resultado con el de cualquier otro equipo y con las pruebas:
 * la región del plano, cómo se mapea un píxel a un número complejo, cómo se cuenta la iteración de escape,
 * cómo se calculan los checksums y cómo se escribe la imagen. Las pruebas comparan contra valores obtenidos
 * con él. Lo que diseñas tú (cómo se reparte el trabajo y con qué schedule) va en c_mandelbrot.c.
 */
#ifndef P4_C_MANDEL_H
#define P4_C_MANDEL_H

#include "common.h"

/* Región fija del plano complejo (ancho 2.6 × alto 2.4: proporción 13:12). */
#define MANDEL_X_MIN (-2.0)
#define MANDEL_X_MAX ( 0.6)
#define MANDEL_Y_MIN (-1.2)
#define MANDEL_Y_MAX ( 1.2)
#define MANDEL_MAX_ITER_LIMIT 65535   /* el píxel se guarda en 16 bits */

typedef unsigned short pixel_t;       /* iteraciones de escape (max_iter = interior del conjunto) */

/* Centro del píxel (col, row) -> c = cx + i*cy. La fila 0 es la de ARRIBA (y máxima). */
static inline void mandel_pixel_to_c(int col, int row, int width, int height, double *cx, double *cy)
{
    *cx = MANDEL_X_MIN + (col + 0.5) * (MANDEL_X_MAX - MANDEL_X_MIN) / (double)width;
    *cy = MANDEL_Y_MAX - (row + 0.5) * (MANDEL_Y_MAX - MANDEL_Y_MIN) / (double)height;
}

/* Iteración de escape: z <- z^2 + c desde z = 0; se detiene cuando |z|^2 > 4 o al llegar a max_iter.
 * Devuelve cuántas iteraciones se hicieron (max_iter => el punto se considera dentro del conjunto).
 * Es el "trabajo" de un píxel: varía entre 1 y max_iter según el punto. Esa variación, concentrada en las
 * filas del centro de la imagen, es el problema de balance de carga de esta parte. */
static inline int mandel_pixel(double cx, double cy, int max_iter)
{
    double x = 0.0, y = 0.0, x2 = 0.0, y2 = 0.0;
    int k = 0;
    while (k < max_iter && x2 + y2 <= 4.0) {
        y = 2.0 * x * y + cy;
        x = x2 - y2 + cx;
        x2 = x * x;
        y2 = y * y;
        k++;
    }
    return k;
}

/* Checksums de la imagen completa. Son sumas, así que no dependen del orden en que se llenaron los píxeles:
 * una versión paralela correcta da EXACTAMENTE los mismos valores que la secuencial.
 *   checksum  = suma de iteraciones de todos los píxeles (el trabajo total)
 *   checksum2 = suma de (k + 1) * (índice + 1) módulo 2^64 (detecta píxeles correctos en la posición
 *               equivocada, p. ej. dos filas intercambiadas, que checksum no ve). */
static inline void mandel_checksum(const pixel_t *img, int width, int height, long *cs1,
                                   unsigned long long *cs2)
{
    long s1 = 0;
    unsigned long long s2 = 0;
    long npix = (long)width * height;
    for (long i = 0; i < npix; i++) {
        s1 += img[i];
        s2 += (unsigned long long)(img[i] + 1) * (unsigned long long)(i + 1);
    }
    *cs1 = s1;
    *cs2 = s2;
}

/* Escribe la imagen en PGM binario (P5): interior del conjunto en negro, exterior en una escala cíclica de
 * grises según la iteración de escape. Se abre con cualquier visor de imágenes (o con python3 + matplotlib).
 * Devuelve 0 si pudo escribir. */
static inline int mandel_write_pgm(const pixel_t *img, int width, int height, int max_iter, const char *path)
{
    FILE *f = fopen(path, "wb");
    if (!f) { perror(path); return 1; }
    fprintf(f, "P5\n%d %d\n255\n", width, height);
    unsigned char *row = malloc((size_t)width);
    if (!row) { fclose(f); return 1; }
    for (int r = 0; r < height; r++) {
        for (int c = 0; c < width; c++) {
            int k = img[(long)r * width + c];
            row[c] = (k >= max_iter) ? 0 : (unsigned char)(40 + (k * 9) % 216);
        }
        fwrite(row, 1, (size_t)width, f);
    }
    free(row);
    return fclose(f) != 0;
}

#endif /* P4_C_MANDEL_H */
