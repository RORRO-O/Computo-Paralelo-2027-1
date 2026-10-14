# Makefile — Práctica guiada S11: patrones de paralelismo y vectorización con OpenMP.
# Objetivos: all, run, test, clean (obligatorios) + report (vectorizador) + tsan (carrera del scan).
CC      = gcc
CFLAGS  = -std=c11 -O2 -Wall -Wextra -fopenmp
LDLIBS  = -lm
VECINFO = -fopt-info-vec-optimized -fopt-info-vec-missed

PROGS   = jacobi1d array_reduction scan scan_buggy saxpy_simd

.PHONY: all run test clean report tsan

all: $(PROGS)

jacobi1d: jacobi1d.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

array_reduction: array_reduction.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

scan: scan.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

scan_buggy: scan_buggy.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

saxpy_simd: saxpy_simd.c vec_kernels.c vec_kernels.h
	$(CC) $(CFLAGS) saxpy_simd.c vec_kernels.c -o $@ $(LDLIBS)

# Tamaños por defecto: cada programa termina en menos de 5 s en una laptop de 4 núcleos.
run: all
	./array_reduction
	./scan
	./saxpy_simd
	./jacobi1d 100000 2000 1e-6 par 4

test: all
	./tests/run_tests.sh

# Qué vectorizó el compilador y qué no, con archivo:línea. Solo compila (-c), no enlaza.
report:
	@echo "== vec_kernels.c (saxpy en tres versiones y prefix_dep) =="
	$(CC) $(CFLAGS) $(VECINFO) -c vec_kernels.c -o /dev/null
	@echo "== jacobi1d.c (solo 'loop vectorized' y 'couldn't vectorize'; el resto es ruido del compilador) =="
	$(CC) $(CFLAGS) $(VECINFO) -c jacobi1d.c -o /dev/null 2>&1 | grep -E "optimized: loop vectorized|couldn't vectorize loop"

# La carrera del scan ingenuo vista por ThreadSanitizer (tamaño pequeño; TSan es lento).
tsan: scan_buggy.c
	$(CC) -std=c11 -O1 -g -Wall -Wextra -fopenmp -fsanitize=thread $< -o scan_buggy_tsan $(LDLIBS)
	-OMP_NUM_THREADS=4 TSAN_OPTIONS="halt_on_error=0 report_bugs=1" ./scan_buggy_tsan 100000 4 2>&1 | head -40

clean:
	rm -f $(PROGS) scan_buggy_tsan *.o
