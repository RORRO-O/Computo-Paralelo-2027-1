# v2/Makefile · V2 OpenMP · Plantilla del proyecto integrador
# Uso: make [all|run|test|clean]      Ejemplo: make && ./v2 1000000 7 4
CC       = gcc
CFLAGS  ?= -std=c11 -O2 -Wall -Wextra -fopenmp
LDLIBS  ?= -lm
INC      = -I../comun
BIN      = v2

.PHONY: all run test clean

all: $(BIN)

$(BIN): main.c ../comun/problema.h
	$(CC) $(CFLAGS) $(INC) -o $@ main.c $(LDLIBS)

run: $(BIN)
	./$(BIN)

test: $(BIN)
	./$(BIN) 1000 1 2 > /dev/null

clean:
	rm -f $(BIN) *.o
