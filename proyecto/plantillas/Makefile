# Makefile de las plantillas del proyecto integrador (esqueleto medible + prueba de los scripts).
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
#   make        compila plantilla_main.out (con OpenMP, como una V2) y plantilla_sec.out (sin OpenMP, como una V1)
#   make run    ejecuta las dos variantes con N (por defecto 200000000; ≈ 0.25 s con un hilo en la máquina de autoría)
#   make test   corre tests/run_tests.sh: esqueleto, medir_proyecto.sh (run_all.sh) y graficar_proyecto.py
#   make clean  borra los binarios y la carpeta resultados-prueba/
CC      = gcc
CFLAGS  = -std=c11 -O2 -Wall -Wextra
BIN     = plantilla_main.out
BIN_SEC = plantilla_sec.out
N      ?= 200000000

all: $(BIN) $(BIN_SEC)

$(BIN): plantilla_main.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

$(BIN_SEC): plantilla_main.c
	$(CC) $(CFLAGS) $< -o $@

run: $(BIN) $(BIN_SEC)
	./$(BIN_SEC) $(N)
	./$(BIN) $(N)

test: $(BIN) $(BIN_SEC)
	./tests/run_tests.sh

clean:
	rm -f $(BIN) $(BIN_SEC)
	rm -rf resultados-prueba

.PHONY: all run test clean
