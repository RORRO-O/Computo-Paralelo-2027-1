# v1/Makefile · V1 secuencial · Plantilla del proyecto integrador
# Uso: make [all|run|test|clean]      Ejemplo: make && ./v1 1000000 7
CC       = gcc
CFLAGS  ?= -std=c11 -O2 -Wall -Wextra
LDLIBS  ?= -lm
INC      = -I../comun
BIN      = v1

.PHONY: all run test clean

all: $(BIN)

$(BIN): main.c ../comun/problema.h
	$(CC) $(CFLAGS) $(INC) -o $@ main.c $(LDLIBS)

run: $(BIN)
	./$(BIN)

# Las pruebas de todo el proyecto viven en ../tests; aquí solo se verifica que corre.
test: $(BIN)
	./$(BIN) 1000 1 > /dev/null

clean:
	rm -f $(BIN) *.o
