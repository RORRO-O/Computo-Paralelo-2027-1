# Makefile — Práctica guiada S04 · Rendimiento en GPU (Unidad V)
#
#   make        (all)  verificación local sin GPU: compila cada .cu a objeto con nvcc -c y la referencia CPU
#   make run           requiere GPU (Colab/Kaggle): compila con -O2, corre los tres programas y grafica
#   make test          sin GPU: nvcc -c (sm_75 y sm_60), espejo Numba en CUDASIM, referencia CPU, gráficas, notebook
#   make notebook      regenera notebook_colab.ipynb con nbformat a partir de los fuentes de esta carpeta
#   make clean
NVCC      ?= nvcc
# T4 de Colab. En Kaggle con P100 usa: make ARCH=sm_60 run
ARCH ?= sm_75
CC         = gcc
CFLAGS    ?= -std=c11 -O2 -Wall -Wextra
PY        ?= python3

CU_SRCS := medir_eventos.cu bench_gpu.cu pinned_streams.cu
CU_OBJS := $(CU_SRCS:.cu=.o)
BINS    := medir_eventos bench_gpu pinned_streams
CSV     := resultados.csv

.PHONY: all run test notebook clean

all: $(CU_OBJS) bench_cpu

%.o: %.cu
	$(NVCC) -c -arch=$(ARCH) $< -o $@

bench_cpu: bench_cpu.c
	$(CC) $(CFLAGS) $< -o $@ -lm

# Ejecutables de GPU: solo tienen sentido donde hay GPU.
$(BINS): %: %.cu
	$(NVCC) -O2 -arch=$(ARCH) $< -o $@

run:
	@command -v nvidia-smi >/dev/null 2>&1 || { echo "make run requiere una GPU NVIDIA (usa Colab/Kaggle). Sin GPU: make test"; exit 1; }
	$(MAKE) $(BINS)
	./medir_eventos
	rm -f $(CSV)
	./bench_gpu bloque 16777216 $(CSV)
	./bench_gpu bloque 4096 $(CSV)
	./bench_gpu umbral 256 $(CSV)
	./bench_gpu umbral 256 $(CSV) pinned
	./pinned_streams
	$(PY) graficar.py $(CSV) .

test:
	bash tests/run_tests.sh

notebook: generar_notebook.py $(CU_SRCS) graficar.py bench_numba.py
	$(PY) generar_notebook.py

clean:
	rm -f $(CU_OBJS) $(BINS) bench_cpu $(CSV) resultados_ejemplo.csv tiempo_vs_bloque.png speedup_vs_n.png
	rm -rf tests/out __pycache__
