# Makefile — Cazador de errores PRIMM (S06 · Unidad V · Cómputo Paralelo 6BM1 · 27/1)
#
#   make           verificación local sin GPU: los .cu a objeto con nvcc -c, los MPI con mpicc, la referencia CPU con gcc
#   make test      sin GPU, < 60 s: compila todo; comprueba que los tres errores SE REPRODUCEN (timeout en MPI,
#                  CUDASIM en CUDA), que las soluciones pasan, que el ejemplo resuelto y los ítems del examen de
#                  práctica dan la salida fijada en la clave, y que el notebook es válido (nbformat)
#   make cazar     tu avance: pasa SOLO cuando corregiste caza1_bcast_buggy.c, caza2_guard_buggy.cu con su espejo
#                  caza2_guard_numba.py, y caza3_reduce_buggy.cu con su espejo caza3_reduce_numba.py
#   make run-mpi   corre caza1 con timeout en cualquier máquina con mpirun (make run-mpi NP=1 para compararlo)
#   make run       REQUIERE GPU (Colab/Kaggle): compila con nvcc -O2 -arch=$(ARCH) y corre los programas CUDA
#   make notebook  regenera notebook_colab.ipynb con nbformat
#   make clean
#
# Variables: ARCH=sm_75 (T4 de Colab; usa ARCH=sm_60 para la P100 de Kaggle), NP=4, N=1000,
#            MPIRUN_FLAGS=--oversubscribe, TIMEOUT=5 (segundos antes de declarar interbloqueo).

NVCC   ?= nvcc
ARCH   ?= sm_75
CC     ?= gcc
MPICC  ?= mpicc
CFLAGS ?= -std=c11 -O2 -Wall -Wextra
PY     ?= python3
MPIRUN_FLAGS ?= --oversubscribe
NP      ?= 4
N       ?= 1000
TIMEOUT ?= 5

CU_SRCS  := caza2_guard_buggy.cu caza3_reduce_buggy.cu ejemplo_grid.cu examen_items/item_II2_reverse.cu \
            soluciones/caza2_guard_fixed.cu soluciones/caza3_reduce_fixed.cu
CU_OBJS  := $(CU_SRCS:.cu=.o)
MPI_BINS := caza1_bcast_buggy soluciones/caza1_bcast_fixed ejemplo_predict_mpi \
            examen_items/item_II1_mpi examen_items/item_IV_dot_mpi
GPU_BINS := caza2_guard_buggy caza3_reduce_buggy ejemplo_grid ejemplo_grid_ok examen_items/item_II2_reverse \
            soluciones/caza2_guard_fixed soluciones/caza3_reduce_fixed

.PHONY: all test cazar run run-mpi notebook clean

all: $(CU_OBJS) $(MPI_BINS) caza_cpu

# Sin GPU solo se compila el código de dispositivo a objeto (no se puede ejecutar).
%.o: %.cu
	$(NVCC) -c -arch=$(ARCH) $< -o $@

$(MPI_BINS): %: %.c
	$(MPICC) $(CFLAGS) $< -o $@

caza_cpu: caza_cpu.c
	$(CC) $(CFLAGS) $< -o $@

# Ejecutables de GPU: solo tienen sentido donde hay GPU (Colab/Kaggle).
ejemplo_grid_ok: ejemplo_grid.cu
	$(NVCC) -O2 -arch=$(ARCH) -DCORREGIDO $< -o $@

$(filter-out ejemplo_grid_ok,$(GPU_BINS)): %: %.cu
	$(NVCC) -O2 -arch=$(ARCH) $< -o $@

run:
	@command -v nvidia-smi >/dev/null 2>&1 || { echo "make run requiere una GPU NVIDIA (usa Colab/Kaggle). Sin GPU: make test"; exit 1; }
	$(MAKE) caza_cpu $(GPU_BINS)
	./caza_cpu todo $(N)
	-./caza2_guard_buggy $(N) 256
	-./caza2_guard_buggy 1024 256
	-./caza3_reduce_buggy $(N)
	-for i in 1 2 3 4 5; do ./caza3_reduce_buggy $(N) | grep -E 'suma_gpu|verificacion'; done
	-./ejemplo_grid $(N) 256
	./ejemplo_grid_ok $(N) 256
	./examen_items/item_II2_reverse

run-mpi: caza1_bcast_buggy caza_cpu
	./caza_cpu media $(N)
	-timeout $(TIMEOUT) mpirun $(MPIRUN_FLAGS) -np $(NP) ./caza1_bcast_buggy $(N); \
	  echo "codigo de salida: $$? (124 = timeout lo mato = interbloqueo)"

test:
	bash tests/run_tests.sh

cazar:
	bash tests/run_tests.sh cazar

notebook: make_notebook.py $(CU_SRCS) caza_cpu.c caza1_bcast_buggy.c caza2_guard_numba.py caza3_reduce_numba.py
	$(PY) make_notebook.py

clean:
	rm -f $(CU_OBJS) $(MPI_BINS) $(GPU_BINS) caza_cpu resultados_S06_*.csv
	rm -rf __pycache__ soluciones/__pycache__ examen_items/__pycache__ tests/out
