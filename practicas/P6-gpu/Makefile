# Makefile — Práctica 6 · Aceleración en GPU con CUDA (Colab/Kaggle) · versión estudiante
#
#   make            (= make all) verificación local SIN GPU: nvcc -c de cada src/*.cu + referencias CPU con gcc
#   make run        REQUIERE GPU (Colab/Kaggle): compila con nvcc -O2 -arch=sm_75, corre Partes A y B, grafica
#   make test       verificación sin GPU (tests/run_tests.sh): compilación, referencias CPU, espejos Numba en
#                   CUDASIM, graficar.py, notebook. Los TODO pendientes de la Parte B se reportan como PEND.
#   make test-b     solo Parte B y estricta: falla hasta que TODO(1)–TODO(4) estén completos y correctos
#   make sim        corre los espejos Numba bajo NUMBA_ENABLE_CUDASIM=1 (sin GPU; solo correctitud)
#   make notebook   regenera notebook_colab.ipynb con nbformat a partir de src/ (hazlo tras editar un fuente)
#   make graficas   python3 graficar.py sobre resultados/*.csv (los CSV que bajaste de Colab/Kaggle)
#   make clean
#
# Variables: ARCH=sm_60 (Kaggle con P100)  TILE=8|16|32  N=... (n de la Parte A)  BLOCK=...  PY=python3
NVCC   ?= nvcc
ARCH   ?= sm_75
TILE   ?= 16
N      ?= 16777216
BLOCK  ?= 256
PY     ?= python3
CC      = gcc
CFLAGS ?= -std=c11 -O2 -Wall -Wextra
SRC    := src
CSV    ?= resultados/resultados_P6.csv

CU_SRCS := $(wildcard $(SRC)/*.cu)
CU_OBJS := $(CU_SRCS:.cu=.o)
CU_BINS := $(CU_SRCS:.cu=)
C_SRCS  := $(wildcard $(SRC)/*_cpu.c)
C_BINS  := $(C_SRCS:.c=)
TILED_BINS := $(SRC)/b_matmul_tiled_t8 $(SRC)/b_matmul_tiled_t16 $(SRC)/b_matmul_tiled_t32

.PHONY: all run test test-b sim notebook graficas clean

# --- Verificación local (sin GPU): los .cu solo se compilan a objeto ---
all: $(CU_OBJS) $(C_BINS)
	@echo "Compilación local lista (objetos de los .cu + referencias CPU). Con GPU: make run"

$(SRC)/%.o: $(SRC)/%.cu $(SRC)/common.cuh
	$(NVCC) -c -O2 -arch=$(ARCH) -DTILE=$(TILE) $< -o $@

$(SRC)/%_cpu: $(SRC)/%_cpu.c
	$(CC) $(CFLAGS) $< -o $@ -lm

# --- Ejecutables completos: enlazan en cualquier máquina con nvcc, pero solo corren con GPU ---
$(SRC)/%: $(SRC)/%.cu $(SRC)/common.cuh
	$(NVCC) -O2 -arch=$(ARCH) -DTILE=$(TILE) $< -o $@

$(SRC)/b_matmul_tiled_t%: $(SRC)/b_matmul_tiled.cu $(SRC)/common.cuh
	$(NVCC) -O2 -arch=$(ARCH) -DTILE=$* $< -o $@

run: $(CU_BINS) $(C_BINS) $(TILED_BINS)
	@command -v nvidia-smi >/dev/null 2>&1 || { echo "make run requiere una GPU NVIDIA (usa Colab/Kaggle). Sin GPU: make test"; exit 1; }
	mkdir -p resultados && rm -f $(CSV)
	./$(SRC)/a_vectores_cpu 1000
	./$(SRC)/a_vectores uno 1000 $(BLOCK)
	./$(SRC)/a_vectores umbral $(BLOCK) $(CSV)
	./$(SRC)/a_vectores bloque $(N) $(CSV)
	./$(SRC)/b_matmul_cpu 512 $(TILE)
	for t in 8 16 32; do for n in 512 1024; do ./$(SRC)/b_matmul_tiled_t$$t $$n $(CSV) || true; done; done
	./$(SRC)/b_matmul_tiled 1000 $(CSV) || true
	@echo ">> Parte C: corre tu programa a mano (p. ej. ./$(SRC)/c_mi_kernel ... $(CSV)) y después: make graficas"
	$(PY) graficar.py $(CSV) -o resultados

test:
	bash tests/run_tests.sh

test-b:
	bash tests/run_tests.sh B

sim:
	NUMBA_ENABLE_CUDASIM=1 $(PY) $(SRC)/a_vectores_numba.py 1000 256
	NUMBA_ENABLE_CUDASIM=1 $(PY) $(SRC)/b_matmul_numba.py 32 16 || true
	NUMBA_ENABLE_CUDASIM=1 $(PY) $(SRC)/b_matmul_numba.py 20 16 || true

notebook:
	$(PY) tests/build_notebook.py

graficas:
	$(PY) graficar.py resultados/*.csv -o resultados

clean:
	rm -f $(SRC)/*.o $(CU_BINS) $(C_BINS) $(TILED_BINS)
	rm -rf tests/out $(SRC)/__pycache__ tests/__pycache__ __pycache__
