# Makefile — Mini PRIMM "aplanar y mapear" (S05 · Unidad V · Cómputo Paralelo 6BM1 · 27/1)
#
#   make          → verificación local sin GPU: nvcc -c del .cu + referencia CPU con gcc
#   make run      → REQUIERE GPU (Colab/Kaggle): compila con nvcc -O2 -arch=sm_75 y ejecuta
#   make test     → pruebas sin GPU: compilación de los .cu, referencia CPU, espejo Numba en CUDASIM
#   make notebook → regenera notebook_colab.ipynb con nbformat
#   make clean
#
# Variables: ARCH=sm_75 (T4 de Colab; usa sm_60 para P100 de Kaggle), H W ITERS BX BY MODE COPY.

NVCC   ?= nvcc
ARCH   ?= sm_75
# CC con "=" (no "?="): make ya trae CC=cc por defecto. Se cambia con `make CC=...`.
CC     = gcc
CFLAGS ?= -std=c11 -O2 -Wall -Wextra
PY     ?= python3

H     ?= 1024
W     ?= 1024
ITERS ?= 100
BX    ?= 16
BY    ?= 16
MODE  ?= 2d
COPY  ?= 0

.PHONY: all run run-numba test notebook clean

all: flatten_map_2d.o flatten_map_cpu

# Verificación local: solo compila el código de dispositivo (no hay GPU en la máquina de autoría).
flatten_map_2d.o: flatten_map_2d.cu
	$(NVCC) -c -arch=$(ARCH) $< -o $@

flatten_map_cpu: flatten_map_cpu.c
	$(CC) $(CFLAGS) $< -o $@

# Ejecutable completo: requiere GPU para correr.
flatten_map_2d: flatten_map_2d.cu
	$(NVCC) -O2 -arch=$(ARCH) $< -o $@

run: flatten_map_2d flatten_map_cpu
	./flatten_map_cpu $(H) $(W) $(ITERS)
	./flatten_map_2d $(H) $(W) $(ITERS) $(BX) $(BY) $(MODE) $(COPY)

run-numba:
	$(PY) flatten_map_numba.py $(H) $(W) $(ITERS) $(BX) $(BY) $(MODE) $(COPY)

test:
	bash tests/run_tests.sh

notebook:
	$(PY) make_notebook.py

clean:
	rm -f flatten_map_2d.o flatten_map_2d flatten_map_cpu sin_guardia
	rm -rf __pycache__
