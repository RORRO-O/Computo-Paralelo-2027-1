# Makefile — Práctica guiada de GPU: referencia en CPU (C) + espejo Numba CUDA. Lo generó /nueva-sesion.
#
#   make          compila main_cpu (referencia en CPU)
#   make run      REQUIERE GPU (Colab/Kaggle): corre la referencia y el espejo Numba con N y BLOCK
#   make test     sin GPU: tests/run_tests.sh compara el espejo Numba bajo CUDASIM contra la referencia en CPU
#   make sim      corre el espejo Numba en el simulador (solo correctitud, n pequeño)
#   make clean
#
# Si agregas un kernel en CUDA C (.cu): compílalo con `nvcc -O2 -arch=sm_75` en Colab/Kaggle, agrega aquí la
# verificación `nvcc -c` y sigue herramientas/colab-kaggle.md. Variables: N=... BLOCK=... PY=python3
CC      = gcc
CFLAGS ?= -std=c11 -O2 -Wall -Wextra
PY     ?= python3
N      ?= 4000000
BLOCK  ?= 256

.PHONY: all run test sim clean

all: main_cpu

main_cpu: main_cpu.c
	$(CC) $(CFLAGS) $< -o $@

run: all
	@echo ">> Requiere GPU. Sin tarjeta usa 'make sim'."
	./main_cpu $(N)
	$(PY) main_numba.py $(N) $(BLOCK)

sim:
	NUMBA_ENABLE_CUDASIM=1 $(PY) main_numba.py 4096 64

test: all
	PY="$(PY)" bash tests/run_tests.sh

clean:
	rm -f main_cpu *.o
	rm -rf __pycache__ tests/out
