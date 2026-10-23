# Makefile — Práctica guiada S03 (Unidad V): reducción en tres versiones + histograma en CUDA C,
# espejos Numba y referencias CPU.
#
#   make            (= make all) compila los .cu con `nvcc -c` (verificación sin GPU) y las referencias CPU
#   make run        REQUIERE GPU (Colab/Kaggle): compila con nvcc -O2 -arch=sm_75, ejecuta y mide
#   make test       verificación disponible SIN GPU: nvcc -c de los .cu (sm_75 y sm_60) + CUDASIM de los
#                   espejos Numba + referencias CPU + validez del notebook. Termina con 0 si todo pasa (< 60 s).
#   make sim        corre los espejos Numba bajo CUDASIM (sin GPU, solo correctitud, n pequeño)
#   make notebook   regenera notebook_colab.ipynb con nbformat a partir de los fuentes
#   make clean
#
# Variables útiles: N=... BLOCK=... ARCH=sm_60 (Kaggle con P100)  PY=python3  BINS=256

NVCC      ?= nvcc
ARCH      ?= sm_75
BINS      ?= 16
NVCCFLAGS ?= -O2 -arch=$(ARCH) -DBINS=$(BINS)
CC        := gcc
CFLAGS    ?= -std=c11 -O2 -Wall -Wextra -DBINS=$(BINS)
PY        ?= python3
N         ?= 1048576
BLOCK     ?= 256

CU_SRCS := reduce_sum.cu histogram.cu
CU_OBJS := $(CU_SRCS:.cu=.o)
CU_BINS := $(CU_SRCS:.cu=)
CPU_BINS := reduce_sum_cpu histogram_cpu

.PHONY: all run test sim notebook clean

# --- Verificación local (sin GPU): los .cu solo se compilan a objeto ---
all: $(CU_OBJS) $(CPU_BINS)

%.o: %.cu
	$(NVCC) $(NVCCFLAGS) -c $< -o $@

reduce_sum_cpu: reduce_sum_cpu.c
	$(CC) $(CFLAGS) $< -o $@ -lm

histogram_cpu: histogram_cpu.c
	$(CC) $(CFLAGS) $< -o $@

# --- Ejecución real: requiere una GPU NVIDIA (Colab: Entorno de ejecución -> GPU T4) ---
run: $(CU_BINS) $(CPU_BINS)
	@echo ">> Requiere GPU. Si ves 'no CUDA-capable device is detected', estás en una máquina sin tarjeta."
	./reduce_sum_cpu $(N) $(BLOCK)
	./reduce_sum all $(N) $(BLOCK) cpu
	./reduce_sum tree_nodiv $(N) $(BLOCK) atomic
	./histogram_cpu $(N) $(BLOCK)
	./histogram all $(N) $(BLOCK)

reduce_sum: reduce_sum.cu
	$(NVCC) $(NVCCFLAGS) $< -o $@

histogram: histogram.cu
	$(NVCC) $(NVCCFLAGS) $< -o $@

# --- Simulador de Numba: correctitud sin GPU, n pequeño ---
sim:
	NUMBA_ENABLE_CUDASIM=1 $(PY) reduce_sum_numba.py all 1000 256
	NUMBA_ENABLE_CUDASIM=1 $(PY) histogram_numba.py all 4096 256 --bins $(BINS)

test:
	bash tests/run_tests.sh

notebook:
	$(PY) make_notebook.py

clean:
	rm -f $(CU_OBJS) $(CU_BINS) $(CPU_BINS) reduce_sum_sin_sync histogram256 histogram_cpu256
	rm -f reduce_max reduce_max.o *.o resultados.csv resultados_S03_*.csv
	rm -rf __pycache__ tests/__pycache__ tests/out
