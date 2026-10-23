# Makefile · Práctica guiada S12 · perfilado por secciones
# Objetivos: all, run, test, clean (obligatorios) + medir, tsan (apoyo)
CC      = gcc
CFLAGS  = -std=c11 -O2 -Wall -Wextra -fopenmp
LDLIBS  = -lm
PROGS   = fases ejemplo_perfil

all: $(PROGS)

%: %.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

# Corre el programa del PRIMM con tamaño por defecto y un hilo (perfil secuencial)
run: all
	OMP_NUM_THREADS=1 ./fases

test: all
	./tests/run_tests.sh

# Protocolo de medición: calentamiento + 5 repeticiones, mediana, 1/2/4 hilos
medir: all
	./medir.sh ./fases computo "1 2 4"

# Versión con ThreadSanitizer para cazar la carrera si olvidas la reducción. Se compila con -O0
# a propósito: así el aviso cae en la línea de `sum += p`; con -O1 (S07, H2) el compilador acumula
# en un registro y el aviso cae en la línea del pragma. Nunca se mide con este binario.
tsan: fases.c
	$(CC) -std=c11 -O0 -g -Wall -Wextra -fopenmp -fsanitize=thread $< -o fases_tsan $(LDLIBS)

clean:
	rm -f $(PROGS) fases_tsan *.o

.PHONY: all run test medir tsan clean
