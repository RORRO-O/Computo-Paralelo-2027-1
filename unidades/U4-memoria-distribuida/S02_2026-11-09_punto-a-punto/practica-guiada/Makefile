# Makefile — Práctica guiada S02 · Comunicación punto a punto (Unidad IV)
#
# Objetivos:  make        compila todo
#             make run    corre la secuencia de demostración de la sesión
#             make test   ejecuta tests/run_tests.sh (código 0 si todo pasa)
#             make clean  borra los ejecutables
#
# Variables que puedes cambiar desde la línea de comandos:
#   make NP=5 run                      número de procesos del anillo
#   make MPIRUN_FLAGS="" test          si tu MPI no acepta --oversubscribe (p. ej. MPICH)

MPICC       ?= mpicc
CFLAGS      ?= -std=c11 -O2 -Wall -Wextra
MPIRUN      ?= mpirun
MPIRUN_FLAGS ?= --oversubscribe
NP          ?= 4

PROGS = status_demo ring_token ping_pong cross_exchange_buggy \
        cross_exchange_fixed cross_exchange_sendrecv ring_neighbors

.PHONY: all run test clean

all: $(PROGS)

%: %.c
	$(MPICC) $(CFLAGS) -o $@ $<

run: all
	@echo "== status_demo (-np 3) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np 3 ./status_demo
	@echo "== ring_token (-np $(NP)) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./ring_token
	@echo "== cross_exchange_fixed paridad (-np 2, n=1000000) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np 2 ./cross_exchange_fixed paridad 1000000
	@echo "== ping_pong (-np 2) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np 2 ./ping_pong

test: all
	MPIRUN="$(MPIRUN)" MPIRUN_FLAGS="$(MPIRUN_FLAGS)" bash tests/run_tests.sh

clean:
	rm -f $(PROGS)
