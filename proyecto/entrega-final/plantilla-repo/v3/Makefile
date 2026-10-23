# v3/Makefile · V3 GPU (CUDA C) · Plantilla del proyecto integrador
#
# Uso:
#   make check   Solo compila (nvcc -c). Sirve en una máquina SIN GPU para detectar
#                errores de sintaxis y warnings antes de subir a Colab/Kaggle.
#   make all     Compila y enlaza el ejecutable ./v3 (requiere GPU + driver; en Colab).
#   make run     Ejecuta ./v3 con los valores por defecto (en Colab).
#   make test    Compara el checksum de ./v3 contra ./v1 (en Colab; usa ../tests). Sin GPU: make check + SKIP.
#   make clean
# Ejemplo (Colab):  make all && ./v3 4000000 12345 256
#
# ARCH: sm_75 es la GPU T4 de Colab gratuito. Si Colab/Kaggle te asigna otra (L4 = sm_89,
# P100 = sm_60), cambia ARCH y anótalo en resultados/entorno_gpu.txt.
NVCC    ?= nvcc
ARCH    ?= sm_75
NVFLAGS ?= -O2 -arch=$(ARCH) -Xcompiler -Wall,-Wextra
INC      = -I../comun
BIN      = v3

.PHONY: all check run test clean

all: $(BIN)

$(BIN): kernel.cu ../comun/problema.h
	$(NVCC) $(NVFLAGS) $(INC) -o $@ kernel.cu

check: kernel.cu ../comun/problema.h
	$(NVCC) $(NVFLAGS) $(INC) -c -o kernel.o kernel.cu
	@echo "v3: compilación correcta con nvcc -c (solo sintaxis; la ejecución y las pruebas de V3 son en Colab/Kaggle)"

run: $(BIN)
	./$(BIN)

# Sin GPU (no hay nvidia-smi) no se ejecuta ./v3: se compila con nvcc -c y se avisa (SKIP, código 0).
test:
	@if command -v nvidia-smi > /dev/null 2>&1; then \
	    $(MAKE) $(BIN) && bash ../tests/run_tests.sh --solo-v3; \
	else \
	    $(MAKE) check && echo "SKIP  v3 == v1: sin GPU en esta máquina; la prueba se ejecuta en Colab/Kaggle (notebook, celda 'Verificación')"; \
	fi

clean:
	rm -f $(BIN) *.o
