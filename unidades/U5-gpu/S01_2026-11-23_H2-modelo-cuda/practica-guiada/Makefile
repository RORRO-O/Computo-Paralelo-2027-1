# Makefile — Práctica guiada S01 (Unidad V): suma de vectores en CUDA C + espejo Numba + referencia CPU.
#
#   make            (= make all) compila los .cu con `nvcc -c` (verificación sin GPU) y la referencia CPU
#   make run        REQUIERE GPU (Colab/Kaggle): compila con nvcc -O2 -arch=sm_75, ejecuta y mide
#   make test       verificación disponible SIN GPU: nvcc -c de los .cu + CUDASIM de los espejos Numba
#                   + referencia CPU + validez del notebook. Termina con 0 si todo pasa.
#   make sim        corre los espejos Numba bajo CUDASIM (sin GPU, solo correctitud, n pequeño)
#   make notebook   regenera notebook_colab.ipynb con nbformat a partir de los fuentes
#   make clean
#
# Variables útiles: N=... BLOCK=... ARCH=sm_60 (Kaggle con P100)  PY=python3

NVCC      ?= nvcc
ARCH      ?= sm_75
NVCCFLAGS ?= -O2 -arch=$(ARCH)
CC        := gcc
CFLAGS    ?= -std=c11 -O2 -Wall -Wextra
PY        ?= python3
N         ?= 16777216
BLOCK     ?= 256

CU_SRCS := vector_add.cu index_probe.cu
CU_OBJS := $(CU_SRCS:.cu=.o)
CU_BINS := $(CU_SRCS:.cu=)

.PHONY: all run test sim notebook clean

# --- Verificación local (sin GPU): solo se compila a objeto ---
all: $(CU_OBJS) vector_add_cpu

%.o: %.cu
	$(NVCC) $(NVCCFLAGS) -c $< -o $@

vector_add_cpu: vector_add_cpu.c
	$(CC) $(CFLAGS) $< -o $@ -lm

# --- Ejecución real: requiere una GPU NVIDIA (Colab: Entorno de ejecución -> GPU T4) ---
run: vector_add index_probe vector_add_cpu
	@echo ">> Requiere GPU. Si ves 'no CUDA-capable device is detected', estás en una máquina sin tarjeta."
	./index_probe 10 4
	./vector_add_cpu $(N)
	./vector_add $(N) $(BLOCK)

vector_add: vector_add.cu
	$(NVCC) $(NVCCFLAGS) $< -o $@

index_probe: index_probe.cu
	$(NVCC) $(NVCCFLAGS) $< -o $@

# --- Simulador de Numba: correctitud sin GPU ---
sim:
	NUMBA_ENABLE_CUDASIM=1 $(PY) index_probe_numba.py 10 4
	NUMBA_ENABLE_CUDASIM=1 $(PY) vector_add_numba.py 1000 256

test:
	bash tests/run_tests.sh

notebook:
	$(PY) make_notebook.py

clean:
	rm -f $(CU_OBJS) $(CU_BINS) vector_add_cpu vector_add_sin_guardia saxpy saxpy.o dot_partial dot_partial.o
	rm -f *.o resultados.csv
	rm -rf __pycache__ tests/__pycache__
