# Makefile de las plantillas del proyecto integrador (esqueleto medible + prueba de humo de los scripts).
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
#   make        compila plantilla_main.out
#   make run    ejecuta el esqueleto con N (por defecto 200000000)
#   make test   corre tests/run_tests.sh: resultado correcto, run_all.sh y graficar_proyecto.py funcionan
#   make clean  borra el binario y la carpeta resultados-prueba/
CC      = gcc
CFLAGS  = -std=c11 -O2 -Wall -Wextra -fopenmp
BIN     = plantilla_main.out
N      ?= 200000000

all: $(BIN)

$(BIN): plantilla_main.c
	$(CC) $(CFLAGS) $< -o $@

run: $(BIN)
	./$(BIN) $(N)

test: $(BIN)
	./tests/run_tests.sh

clean:
	rm -f $(BIN)
	rm -rf resultados-prueba

.PHONY: all run test clean
