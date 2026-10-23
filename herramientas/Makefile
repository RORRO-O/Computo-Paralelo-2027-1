# Makefile de herramientas/ · compila los ejemplos de cronometro.h y prueba todas las herramientas.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
#   make          compila ejemplo_cronometro.out (OpenMP), ejemplo_cronometro_seq.out (sin -fopenmp, misma
#                 fuente: referencia secuencial) y, si hay mpicc, ejemplo_mpi.out
#   make run      corre el ejemplo OpenMP con N rectángulos y THREADS hilos (por defecto 20000000 y 4)
#   make test     tests/run_tests.sh: cronometro.h, medir.sh (OpenMP y MPI), graficar_speedup.py,
#                 plantilla-run_tests.sh, Makefile.openmp / Makefile.mpi, seguimiento.py, los fragmentos de código
#                 de colab-kaggle.md y nvcc -c de ejemplo_gpu.cu; código 0 si todo pasa
#   make clean    borra binarios (*.out, *.o) y resultados/, la carpeta que llenan los ejemplos del README
#
# Variables útiles: make run N=100000000 THREADS=2 · make test MPIRUN_FLAGS="--oversubscribe"
# Los templates para copiar a un proyecto son Makefile.openmp y Makefile.mpi (no este archivo).
CC            = gcc
MPICC        ?= mpicc
CFLAGS       ?= -std=c11 -O2 -Wall -Wextra
LDLIBS        = -lm
MPIRUN_FLAGS ?= --oversubscribe
N            ?= 20000000
THREADS      ?= 4

BIN_OMP = ejemplo_cronometro.out
BIN_SEQ = ejemplo_cronometro_seq.out
BIN_MPI = ejemplo_mpi.out

# El ejemplo MPI solo se compila si hay mpicc; así `make` funciona en una laptop sin MPI instalado.
HAY_MPICC := $(shell command -v $(MPICC) 2>/dev/null)
ifneq ($(HAY_MPICC),)
PROGS = $(BIN_OMP) $(BIN_SEQ) $(BIN_MPI)
else
PROGS = $(BIN_OMP) $(BIN_SEQ)
endif

.PHONY: all run test clean

all: $(PROGS)

$(BIN_OMP): ejemplo_cronometro.c cronometro.h
	$(CC) $(CFLAGS) -fopenmp -o $@ ejemplo_cronometro.c $(LDLIBS)

$(BIN_SEQ): ejemplo_cronometro.c cronometro.h
	$(CC) $(CFLAGS) -o $@ ejemplo_cronometro.c $(LDLIBS)

$(BIN_MPI): ejemplo_mpi.c
	$(MPICC) $(CFLAGS) -o $@ ejemplo_mpi.c $(LDLIBS)

run: $(BIN_OMP)
	OMP_NUM_THREADS=$(THREADS) ./$(BIN_OMP) $(N)

test: all
	MPIRUN_FLAGS="$(MPIRUN_FLAGS)" ./tests/run_tests.sh

clean:
	rm -f *.out *.o
	rm -rf resultados __pycache__
