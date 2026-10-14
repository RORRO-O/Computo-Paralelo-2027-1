# Makefile — S07 · Práctica guiada: corrección en memoria compartida
# Objetivos: all · run · test · clean · tsan (ThreadSanitizer sobre los *_buggy)
# Variables ajustables: make run THREADS=2 N=5000000 NBINS=16

CC        = gcc
CFLAGS    = -std=c11 -O2 -Wall -Wextra -fopenmp
TSANFLAGS = -std=c11 -fsanitize=thread -g -O1 -Wall -Wextra -fopenmp
THREADS  ?= 4
N        ?= 10000000
NBINS    ?= 64

PROGS = counter_buggy sum_variants private_buggy barrier_demo nowait_buggy \
        histogram_buggy histogram_critical histogram_atomic histogram_local
# Fase "Crear": si existe histogram_locks.c se compila y se prueba tambien.
EXTRA = $(patsubst %.c,%,$(wildcard histogram_locks.c))
BUGGY = counter_buggy nowait_buggy histogram_buggy
TSAN_BINS = $(addsuffix _tsan,$(BUGGY))

.PHONY: all run run-histograms run-sum run-demos test tsan clean

all: $(PROGS) $(EXTRA)

%: %.c common.h
	$(CC) $(CFLAGS) $< -o $@

%_tsan: %.c common.h
	$(CC) $(TSANFLAGS) $< -o $@

# Version sin optimizar, para ver que la carrera del contador se manifiesta distinto (ejemplo resuelto).
%_O0: %.c common.h
	$(CC) -std=c11 -O0 -Wall -Wextra -fopenmp $< -o $@

# Corre todo con THREADS hilos (tamanos por defecto: < 5 s en total en 4 nucleos).
run: run-histograms run-sum run-demos

run-histograms: all
	@for v in buggy critical atomic local $(patsubst histogram_%,%,$(EXTRA)); do \
	  OMP_NUM_THREADS=$(THREADS) ./histogram_$$v $(N) $(NBINS); echo; done

run-sum: sum_variants counter_buggy
	OMP_NUM_THREADS=$(THREADS) ./counter_buggy $(N)
	@echo
	OMP_NUM_THREADS=$(THREADS) ./sum_variants $(N)

run-demos: private_buggy barrier_demo nowait_buggy
	OMP_NUM_THREADS=$(THREADS) ./private_buggy
	@echo
	OMP_NUM_THREADS=$(THREADS) ./barrier_demo
	@echo
	OMP_NUM_THREADS=$(THREADS) ./nowait_buggy

test: all
	bash tests/run_tests.sh

# ThreadSanitizer: se detiene en el primer reporte (halt_on_error) para leerlo con calma.
# Tamanos pequenos: con TSan el programa corre 5-20x mas lento.
tsan: $(TSAN_BINS)
	@for b in $(BUGGY); do \
	  echo "===== $$b bajo ThreadSanitizer ====="; \
	  OMP_NUM_THREADS=$(THREADS) TSAN_OPTIONS="halt_on_error=1" ./$${b}_tsan 200000 2>&1 | head -40; \
	  echo; done; true

clean:
	rm -f $(PROGS) $(EXTRA) *_tsan *_O0 *.o
