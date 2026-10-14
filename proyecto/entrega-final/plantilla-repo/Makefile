# Makefile · raíz del repositorio del proyecto integrador (plantilla)
#
# Uso:
#   make          = make all: compila V1 y V2 y verifica que V3 compila (nvcc -c) si hay nvcc.
#   make run      corre V1 y V2 con el tamaño por defecto (demostración rápida).
#   make test     ejecuta tests/run_tests.sh; termina con código 0 solo si TODO pasa.
#   make medir    ejecuta ./run_all.sh (pruebas + mediciones + CSV + gráfica).
#   make clean    borra binarios y objetos (no borra resultados/).
# Ejemplo:  make && make test && ./run_all.sh --rapido
#
# Las banderas de compilación están en v1/Makefile, v2/Makefile y v3/Makefile
# (-std=c11 -O2 -Wall -Wextra [-fopenmp]; nvcc -O2 -arch=sm_75 -Xcompiler -Wall,-Wextra).

.PHONY: all run test medir clean v1 v2 v3-check

all: v1 v2 v3-check

v1:
	$(MAKE) -C v1 all

v2:
	$(MAKE) -C v2 all

# Si no hay nvcc (laptop sin CUDA) se avisa y no se falla: la V3 se ejecuta en Colab/Kaggle.
v3-check:
	@if command -v nvcc > /dev/null 2>&1; then \
	    $(MAKE) -C v3 check; \
	else \
	    echo "v3: nvcc no disponible en esta máquina; la verificación de la V3 se hace en Colab/Kaggle"; \
	fi

run: v1 v2
	./v1/v1
	./v2/v2

test: v1 v2
	bash tests/run_tests.sh --sin-compilar

medir:
	./run_all.sh

clean:
	$(MAKE) -C v1 clean
	$(MAKE) -C v2 clean
	$(MAKE) -C v3 clean
