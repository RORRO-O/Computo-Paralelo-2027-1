# Práctica 4 · Procesamiento paralelo de datos con OpenMP
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
# Objetivos del curso: all, run, test, clean. Además:
#   make test-a | test-b | test-c   solo esa parte (PARTE_C=mandelbrot|calor|ambas para forzar la opción)
#   make tsan        carrera de la Parte A vista con ThreadSanitizer (n pequeño; no sirve para medir)
#   make speedup-a   Parte A: versiones sin critical con 1, 2 y 4 hilos, n = 10^7 (~20 s)
#   make cortes      Parte B: barrido del corte con n = 2·10^6 (~30 s; cutoff = 1 tarda varios segundos)
#   make medir       Parte D: protocolo completo con 1, 2, 4 y 8 hilos -> resultados/p4.csv (~2–3 min)
#   make graficar    Parte D: resultados/p4.csv -> resultados/p4_speedup.png y p4_eficiencia.png
#   make imagen      Parte C: resultados/mandelbrot.pgm y su conversión a PNG
# Variables: THREADS (run, tsan), HILOS, PARTE_C, MANDEL, SCHED, SCHED_ALT, HEAT, NB, CUT, CSV (ver abajo).

CC        = gcc
CFLAGS    = -std=c11 -O2 -Wall -Wextra -fopenmp
LDLIBS    = -lm
TSANFLAGS = -std=c11 -O1 -g -Wall -Wextra -fopenmp -fsanitize=thread

SRC   = src
BIN   = bin
PROGS = a_histogram a_histogram_buggy b_mergesort c_mandelbrot c_heat
BINS  = $(addprefix $(BIN)/,$(PROGS))
HDRS  = $(wildcard $(SRC)/*.h)

THREADS ?= 4

# --- Parte D (ajústalas a tu elección y a tu máquina; T(1) debe tardar >= 1 s) ---
# SCHED es la política que eligieron para la Parte C ("tipo chunk"); SCHED_ALT, la que comparan contra ella.
HILOS     ?= 1 2 4 8
PARTE_C   ?= mandelbrot
MANDEL    ?= 1950 1800 1000
SCHED     ?=
SCHED_ALT ?= static 0
SCHED_RUN  = $(or $(SCHED),static 0)
HEAT      ?= 2000000 500 0 1
NB        ?= 15000000
CUT       ?= 4096
CSV       ?= resultados/p4.csv

empty :=
space := $(empty) $(empty)

.PHONY: all run test test-a test-b test-c tsan speedup-a cortes medir graficar imagen clean

all: $(BINS)

$(BIN)/%: $(SRC)/%.c $(HDRS) | $(BIN)
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

$(BIN):
	mkdir -p $(BIN)

# Demostración corta con los tamaños por defecto. Un programa con TODO pendiente lo dice y se sigue.
run: all
	-OMP_NUM_THREADS=$(THREADS) $(BIN)/a_histogram
	-OMP_NUM_THREADS=$(THREADS) $(BIN)/b_mergesort
	-OMP_NUM_THREADS=$(THREADS) $(BIN)/c_mandelbrot 1300 1200 500 omp $(SCHED_RUN) - --verificar
	-OMP_NUM_THREADS=$(THREADS) $(BIN)/c_heat 500000 500 0 1 omp --verificar

test:
	bash tests/run_tests.sh

test-a:
	PARTES=A bash tests/run_tests.sh

test-b:
	PARTES=B bash tests/run_tests.sh

test-c:
	PARTES=C bash tests/run_tests.sh

# ThreadSanitizer: compila con -fsanitize=thread -g -O1 y corre con n pequeño (TSan multiplica el tiempo).
tsan: | $(BIN)
	$(CC) $(TSANFLAGS) $(SRC)/a_histogram_buggy.c -o $(BIN)/a_histogram_buggy_tsan $(LDLIBS)
	$(CC) $(TSANFLAGS) $(SRC)/a_histogram.c -o $(BIN)/a_histogram_tsan $(LDLIBS)
	-OMP_NUM_THREADS=$(THREADS) REPS=1 TSAN_OPTIONS="halt_on_error=1" $(BIN)/a_histogram_buggy_tsan 20000 16
	-OMP_NUM_THREADS=$(THREADS) REPS=1 TSAN_OPTIONS="halt_on_error=1" $(BIN)/a_histogram_tsan reduction 20000 16

speedup-a: $(BIN)/a_histogram
	@for t in 1 2 4; do echo "--- $$t hilo(s)"; \
	  OMP_NUM_THREADS=$$t $(BIN)/a_histogram rapidas 10000000 64 | grep -E '^(seq|atomic|local|reduction|tareas) '; done

cortes: $(BIN)/b_mergesort
	@for c in 1 16 256 4096 65536 2000000; do \
	  OMP_NUM_THREADS=$(THREADS) REPS=3 $(BIN)/b_mergesort 2000000 $$c | grep '^resumen'; done

medir: all
	rm -rf $(CSV) $(dir $(CSV))salidas
ifeq ($(PARTE_C),calor)
	./medir.sh -c C-seq -t 1 -o $(CSV) -- $(BIN)/c_heat $(HEAT) seq
	./medir.sh -c C-omp --base C-seq -t "$(HILOS)" -o $(CSV) -- $(BIN)/c_heat $(HEAT) omp
else
	$(if $(SCHED),,$(error Indica la política que eligieron: make medir SCHED="<static|dynamic|guided> <chunk>" (y SCHED_ALT si la suya es static)))
	./medir.sh -c C-seq -t 1 -o $(CSV) -- $(BIN)/c_mandelbrot $(MANDEL) seq
	./medir.sh -c C-$(subst $(space),-,$(SCHED)) --base C-seq -t "$(HILOS)" -o $(CSV) -- \
	  $(BIN)/c_mandelbrot $(MANDEL) omp $(SCHED)
	./medir.sh -c C-$(subst $(space),-,$(SCHED_ALT)) --base C-seq -t "$(HILOS)" -o $(CSV) -- \
	  $(BIN)/c_mandelbrot $(MANDEL) omp $(SCHED_ALT)
endif
	./medir.sh -c B-seq -t 1 -o $(CSV) -- $(BIN)/b_mergesort $(NB) $(CUT) seq
	./medir.sh -c B-tareas --base B-seq -t "$(HILOS)" -o $(CSV) -- $(BIN)/b_mergesort $(NB) $(CUT) omp
	python3 graficar.py $(CSV) --titulo "Práctica 4"

graficar:
	python3 graficar.py $(CSV) --titulo "Práctica 4"

imagen: $(BIN)/c_mandelbrot
	mkdir -p resultados
	OMP_NUM_THREADS=$(THREADS) REPS=1 $(BIN)/c_mandelbrot 1300 1200 500 omp $(SCHED_RUN) resultados/mandelbrot.pgm
	python3 graficar.py --pgm resultados/mandelbrot.pgm

clean:
	rm -rf $(BIN) tests/out
