# Práctica guiada S05 · Rendimiento en MPI (escalabilidad, modelo de costo, híbrido)
# Objetivos: all, run, test, clean (convenciones §3)
CC        = mpicc
CC_SEQ    = gcc
CFLAGS    = -std=c11 -O2 -Wall -Wextra
OMPFLAGS  = -fopenmp
MPIRUN_FLAGS ?= --oversubscribe
NP        ?= 4
N         ?= 1000000
ITERS     ?= 500

PROGS = jacobi_seq jacobi_mpi hybrid_min pingpong

# Como root (contenedor de prácticas) Open MPI exige declararlo; para cualquier otro usuario
# estas dos líneas no hacen nada (el Makefile no depende de ser root; guía de autoría §E).
ifeq ($(shell id -u),0)
export OMPI_ALLOW_RUN_AS_ROOT = 1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = 1
endif

.PHONY: all run run-fuerte run-hibrido run-pingpong test clean

all: $(PROGS)

jacobi_seq: jacobi_seq.c
	$(CC_SEQ) $(CFLAGS) -o $@ $<

jacobi_mpi: jacobi_mpi.c
	$(CC) $(CFLAGS) -o $@ $<

hybrid_min: hybrid_min.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -o $@ $<

pingpong: pingpong.c
	$(CC) $(CFLAGS) -o $@ $<

# run: estudio completo de escalabilidad fuerte y débil (CSV + PNG en resultados/)
run: all
	MPIRUN_FLAGS="$(MPIRUN_FLAGS)" ./escalado.sh

# Una sola corrida MPI con NP procesos (p. ej. make run-fuerte NP=2 N=20000)
run-fuerte: jacobi_seq jacobi_mpi
	./jacobi_seq $(N) $(ITERS)
	mpirun $(MPIRUN_FLAGS) -np $(NP) ./jacobi_mpi $(N) $(ITERS)

run-hibrido: hybrid_min
	OMP_NUM_THREADS=2 mpirun $(MPIRUN_FLAGS) -np 2 ./hybrid_min

run-pingpong: pingpong
	mpirun $(MPIRUN_FLAGS) -np 2 ./pingpong

test: all
	MPIRUN_FLAGS="$(MPIRUN_FLAGS)" ./tests/run_tests.sh

# clean borra binarios y las corridas propias; resultados-ejemplo/ (corrida de referencia) se conserva.
clean:
	rm -f $(PROGS) *.o resultados-prueba.log
	rm -rf resultados resultados-prueba resultados-chico
