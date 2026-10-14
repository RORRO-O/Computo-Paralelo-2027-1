# Makefile · Práctica guiada S01 (Unidad IV) · Modelo SPMD
# Objetivos: all, run, test, clean.   Variables: NP (procesos), N (tamaño).
#   make run NP=4 N=10        make test        make clean
MPICC        := mpicc
CC           := gcc
CFLAGS       ?= -std=c11 -O2 -Wall -Wextra
MPIRUN       ?= mpirun
MPIRUN_FLAGS ?= --oversubscribe
NP           ?= 4
N            ?= 10

MPI_PROGS   := hello_rank suma_distribuida suma_distribuida_buggy
SEQ_PROGS   := referencia_secuencial
# Programa de la fase "Crear" de PRIMM: se compila solo si el archivo existe.
EXTRA_PROGS := $(patsubst %.c,%,$(wildcard promedio_maximo.c))

all: $(MPI_PROGS) $(SEQ_PROGS) $(EXTRA_PROGS)

$(MPI_PROGS) promedio_maximo: %: %.c
	$(MPICC) $(CFLAGS) -o $@ $<

$(SEQ_PROGS): %: %.c
	$(CC) $(CFLAGS) -o $@ $<

run: all
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./hello_rank
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./suma_distribuida $(N) bloques

test: all
	@MPIRUN="$(MPIRUN)" MPIRUN_FLAGS="$(MPIRUN_FLAGS)" ./tests/run_tests.sh

clean:
	rm -f $(MPI_PROGS) $(SEQ_PROGS) promedio_maximo

.PHONY: all run test clean
