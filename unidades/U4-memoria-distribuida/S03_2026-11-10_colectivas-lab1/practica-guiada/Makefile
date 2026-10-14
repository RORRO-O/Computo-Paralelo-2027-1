# Makefile · Práctica guiada S03 (Unidad IV) · Colectivas y producto matriz-vector
#
# Objetivos:  make        compila todo (mpicc -std=c11 -O2 -Wall -Wextra; sin warnings)
#             make run    corre la secuencia de demostración de la sesión
#             make run-buggy  corre la variante que falla con timeout 10 (N=8 termina mal; N=1024 se cuelga)
#             make test   ejecuta tests/run_tests.sh (código 0 solo si no hay FAIL)
#             make clean  borra los ejecutables
#
# Variables que puedes cambiar desde la línea de comandos:
#   make run NP=4 N=8                  procesos y tamaño de la demostración
#   make MPIRUN_FLAGS="" test          si tu MPI no acepta --oversubscribe (p. ej. MPICH)

MPICC        ?= mpicc
CC           := gcc
CFLAGS       ?= -std=c11 -O2 -Wall -Wextra
LDLIBS       ?= -lm
MPIRUN       ?= mpirun
MPIRUN_FLAGS ?= --oversubscribe
NP           ?= 4
N            ?= 8

MPI_PROGS   := colectivas_demo matvec_collectives matvec_p2p matvec_bcast_buggy \
               matvec_scatterv matvec_allgather
SEQ_PROGS   := matvec_seq
# Programa de la fase "Crear" de PRIMM: se compila solo si el archivo existe.
EXTRA_PROGS := $(patsubst %.c,%,$(wildcard norma_allreduce.c))

.PHONY: all run run-buggy test clean

all: $(MPI_PROGS) $(SEQ_PROGS) $(EXTRA_PROGS)

$(MPI_PROGS) norma_allreduce: %: %.c matvec_data.h
	$(MPICC) $(CFLAGS) -o $@ $< $(LDLIBS)

$(SEQ_PROGS): %: %.c matvec_data.h
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

run: all
	@echo "== colectivas_demo (-np $(NP)) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./colectivas_demo
	@echo "== matvec_seq N=$(N) =="
	./matvec_seq $(N)
	@echo "== matvec_collectives (-np $(NP), N=$(N)) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./matvec_collectives $(N)
	@echo "== matvec_p2p (-np $(NP), N=$(N)) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./matvec_p2p $(N)

# Variante que falla a propósito (Bcast solo en el rango 0). SIEMPRE con timeout:
# código 124 = se colgó; código 0 con checksum distinto de la secuencial = terminó mal.
#   make run-buggy N=8      make run-buggy N=1024
run-buggy: matvec_bcast_buggy
	-timeout 10 $(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./matvec_bcast_buggy $(N); echo "codigo de salida: $$?"

test: all
	@MPIRUN="$(MPIRUN)" MPIRUN_FLAGS="$(MPIRUN_FLAGS)" bash tests/run_tests.sh

clean:
	rm -f $(MPI_PROGS) $(SEQ_PROGS) norma_allreduce
