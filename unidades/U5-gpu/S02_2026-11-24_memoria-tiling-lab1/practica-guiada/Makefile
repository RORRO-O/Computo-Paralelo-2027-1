# Makefile — práctica guiada S02 · Unidad V · jerarquía de memoria y tiling
#
# Objetivos:
#   make            = make all: verificación local SIN GPU (nvcc -c de los .cu + referencia CPU)
#   make run        REQUIERE GPU (Colab/Kaggle): compila con nvcc -O2 -arch=sm_75 y ejecuta
#   make test       pruebas sin GPU: compilación de los .cu, referencia CPU, espejos Numba con
#                   NUMBA_ENABLE_CUDASIM=1, validación del notebook (tests/run_tests.sh)
#   make notebook   regenera notebook_colab.ipynb a partir de los fuentes (tests/build_notebook.py)
#   make clean
#
# Variables: N (tamaño), TILE (mosaico), BLOCK (bloque de la ingenua), ARCH (sm_75 por defecto)
NVCC      ?= nvcc
ARCH      ?= sm_75
TILE      ?= 16
BLOCK     ?= 16
N         ?= 512
NVCCFLAGS ?= -O2 -arch=$(ARCH) -DTILE=$(TILE) -DBLOCK=$(BLOCK)
CC         = gcc
CFLAGS    ?= -std=c11 -O2 -Wall -Wextra

CU_SRCS = matmul_naive.cu matmul_tiled.cu transpose.cu
OBJS    = $(CU_SRCS:.cu=.o)
BINS    = $(CU_SRCS:.cu=)

.PHONY: all run test notebook clean

all: $(OBJS) matmul_cpu
	@echo "Compilación local lista (objetos .cu + matmul_cpu). Para ejecutar en GPU: make run"

# Solo compila (sin enlazar ni ejecutar): es lo que se puede verificar en una máquina sin GPU.
%.o: %.cu common.cuh
	$(NVCC) -c $(NVCCFLAGS) $< -o $@

matmul_cpu: matmul_cpu.c
	$(CC) $(CFLAGS) $< -o $@

# Ejecutables completos: enlazan en cualquier máquina con nvcc, pero solo corren con GPU.
%: %.cu common.cuh
	$(NVCC) $(NVCCFLAGS) $< -o $@

run: $(BINS) matmul_cpu
	@echo "== Requiere GPU (Colab/Kaggle). Sin GPU verás: 'no CUDA-capable device is detected' =="
	./matmul_cpu $(N) $(TILE)
	./matmul_naive $(N)
	./matmul_tiled $(N)
	./transpose $(N)

test:
	bash tests/run_tests.sh

notebook:
	python3 tests/build_notebook.py

clean:
	rm -f $(OBJS) $(BINS) matmul_cpu *.csv
	rm -rf __pycache__ tests/__pycache__
