# Práctica guiada S04 · Jacobi 1D con halos en MPI
# Objetivos: all, run, test, clean (convención del curso).
# En el entorno de autoría (root, 4 núcleos) se usa MPIRUN_FLAGS="--oversubscribe"; en una laptop normal
# puede dejarse vacío: make MPIRUN_FLAGS= run

CC           = gcc
MPICC       ?= mpicc
CFLAGS      ?= -std=c11 -O2 -Wall -Wextra
LDLIBS       = -lm
MPIRUN      ?= mpirun
MPIRUN_FLAGS ?= --oversubscribe
NP          ?= 4
N           ?= 1000000
TOL         ?= 1e-6
MAX_ITER    ?= 1000

PROGS = jacobi1d_seq jacobi1d_mpi jacobi1d_mpi_buggy

.PHONY: all run run-seq run-mpi test clean

all: $(PROGS)

jacobi1d_seq: jacobi1d_seq.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

jacobi1d_mpi: jacobi1d_mpi.c
	$(MPICC) $(CFLAGS) -o $@ $< $(LDLIBS)

jacobi1d_mpi_buggy: jacobi1d_mpi_buggy.c
	$(MPICC) $(CFLAGS) -o $@ $< $(LDLIBS)

# Corre la secuencial y la MPI con el mismo tamaño para comparar a ojo iteraciones, checksum y tiempo.
run: all run-seq run-mpi

run-seq: jacobi1d_seq
	./jacobi1d_seq $(N) $(TOL) $(MAX_ITER)

run-mpi: jacobi1d_mpi
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./jacobi1d_mpi $(N) $(TOL) $(MAX_ITER)

test: all
	MPIRUN_FLAGS="$(MPIRUN_FLAGS)" ./tests/run_tests.sh

clean:
	rm -f $(PROGS) *.o perfil_*.txt perfil.png
