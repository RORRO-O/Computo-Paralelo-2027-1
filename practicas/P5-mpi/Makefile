# Makefile — Práctica 5 · Simulación distribuida con MPI (versión estudiante)
#
#   make              compila todo: secuenciales con gcc, distribuidos con mpicc (-std=c11 -O2 -Wall -Wextra, sin warnings)
#   make run          Parte A con NP procesos (hello + estadísticos): demostración de ~10 s
#   make run-a/b/c    cada parte con NP procesos y tamaños por defecto (≤ 5 s por programa)
#   make run-d        Parte D completa: escalado.sh (fuerte + débil, CSV + PNG en resultados/) y ping-pong (~1–2 min)
#   make pingpong     solo el ping-pong (alpha, beta de TU máquina)
#   make test         tests/run_tests.sh: PASS/FAIL por caso; los TODO pendientes salen como PEND (no cuentan como FAIL)
#   make test-a|b|c|d una parte en modo ESTRICTO: PEND cuenta como FAIL. En Lab 1 corres make test-b; en Lab 2, test-c
#   make test-entrega lo que corre el profesor al calificar: todo, estricto, con PARTE_C=heat o PARTE_C=primes
#   make graficas     vuelve a dibujar resultados/*.png a partir de los CSV
#   make clean
# Variables: NP (procesos, 4) · MPIRUN_FLAGS (--oversubscribe; con MPICH: make MPIRUN_FLAGS= ...) ·
#            PARTE_C=heat|primes (la alternativa que eligió tu equipo) · tamaños de escalado.sh (N, ITERS, NLOCAL, ...)
CC            = gcc
MPICC         = mpicc
CFLAGS       ?= -std=c11 -O2 -Wall -Wextra
LDLIBS        = -lm
MPIRUN_FLAGS ?= --oversubscribe
NP           ?= 4
PARTE_C      ?= heat
SRC           = src

# Como root (contenedor) Open MPI exige declararlo; para cualquier otro usuario estas líneas no hacen nada.
ifeq ($(shell id -u),0)
export OMPI_ALLOW_RUN_AS_ROOT = 1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = 1
endif
export MPIRUN_FLAGS

SEQ_BINS = a2_stats_seq b_matvec_seq c_heat_seq c_primes_seq
MPI_BINS = a1_hello_rank a2_stats_mpi b_matvec_mpi c_heat_mpi c_primes_mpi d_pingpong
BINS     = $(SEQ_BINS:%=$(SRC)/%) $(MPI_BINS:%=$(SRC)/%)

.PHONY: all run run-a run-b run-c run-d pingpong graficas test test-a test-b test-c test-d test-entrega clean

all: $(BINS)

$(SEQ_BINS:%=$(SRC)/%): $(SRC)/%: $(SRC)/%.c $(SRC)/common.h
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

$(MPI_BINS:%=$(SRC)/%): $(SRC)/%: $(SRC)/%.c $(SRC)/common.h
	$(MPICC) $(CFLAGS) -o $@ $< $(LDLIBS)

$(SRC)/c_heat_seq $(SRC)/c_heat_mpi: $(SRC)/c_heat_common.h

run: run-a

run-a: $(SRC)/a1_hello_rank $(SRC)/a2_stats_seq $(SRC)/a2_stats_mpi
	mpirun $(MPIRUN_FLAGS) -np $(NP) ./$(SRC)/a1_hello_rank
	./$(SRC)/a2_stats_seq
	mpirun $(MPIRUN_FLAGS) -np $(NP) ./$(SRC)/a2_stats_mpi

run-b: $(SRC)/b_matvec_seq $(SRC)/b_matvec_mpi
	./$(SRC)/b_matvec_seq
	mpirun $(MPIRUN_FLAGS) -np $(NP) ./$(SRC)/b_matvec_mpi

run-c: $(SRC)/c_heat_seq $(SRC)/c_heat_mpi $(SRC)/c_primes_seq $(SRC)/c_primes_mpi
ifeq ($(PARTE_C),primes)
	./$(SRC)/c_primes_seq
	mpirun $(MPIRUN_FLAGS) -np $(NP) ./$(SRC)/c_primes_mpi --verify
else
	./$(SRC)/c_heat_seq
	mpirun $(MPIRUN_FLAGS) -np $(NP) ./$(SRC)/c_heat_mpi --verify
endif

run-d: all
	./escalado.sh
	$(MAKE) -s pingpong

pingpong: $(SRC)/d_pingpong
	mpirun $(MPIRUN_FLAGS) -np 2 ./$(SRC)/d_pingpong

graficas:
	python3 graficar.py resultados/fuerte.csv resultados/debil.csv resultados

test: all
	bash tests/run_tests.sh all

test-a test-b test-c test-d: all
	STRICT=1 PARTE_C=$(PARTE_C) bash tests/run_tests.sh $(subst test-,,$@)

test-entrega: all
	STRICT=1 PARTE_C=$(PARTE_C) bash tests/run_tests.sh all

clean:
	rm -f $(BINS) $(SRC)/*.o
	rm -rf tests/out resultados-prueba resultados-prueba.log
