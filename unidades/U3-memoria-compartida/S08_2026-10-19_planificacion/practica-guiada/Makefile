# Práctica guiada S08 · Planificación y balance de carga (OpenMP)
# Objetivos: all, run, test, clean (convención del curso) + tabla, tsan.

CC        = gcc
CFLAGS    = -std=c11 -O2 -Wall -Wextra -fopenmp
LDLIBS    = -lm
TSANFLAGS = -std=c11 -O1 -g -Wall -Wextra -fopenmp -fsanitize=thread

PROGS   = schedule_map collapse_map unbalanced nowait_buggy
THREADS ?= 4

.PHONY: all run tabla test tsan clean

all: $(PROGS)

%: %.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

# Demostración corta: mapas con n=16 y una tabla de tiempos del ciclo triangular.
run: all
	OMP_NUM_THREADS=$(THREADS) ./schedule_map 16 all
	@echo
	OMP_NUM_THREADS=$(THREADS) ./collapse_map 3 6
	@echo
	OMP_NUM_THREADS=$(THREADS) ./unbalanced triangular 20000 static static,1 dynamic,16 guided,16

# Tabla completa de tiempos por política para los cuatro núcleos (~1.5 min con 4 hilos).
tabla: all
	OMP_NUM_THREADS=$(THREADS) ./unbalanced uniform    8000000 static static,1 dynamic dynamic,1024 guided,64
	@echo
	OMP_NUM_THREADS=$(THREADS) ./unbalanced triangular 40000   static static,1 static,64 dynamic dynamic,16 guided,16
	@echo
	OMP_NUM_THREADS=$(THREADS) ./unbalanced collatz    2000000 static static,1 dynamic dynamic,256 guided,64
	@echo
	OMP_NUM_THREADS=$(THREADS) ./unbalanced mandelbrot 1000    static static,1 dynamic dynamic,4 guided,4

test: all
	bash tests/run_tests.sh

# La carrera a propósito, vista con ThreadSanitizer (no medir tiempos con esto).
tsan: nowait_buggy.c
	$(CC) $(TSANFLAGS) nowait_buggy.c -o nowait_tsan
	-OMP_NUM_THREADS=$(THREADS) TSAN_OPTIONS="halt_on_error=0" ./nowait_tsan 2000 dynamic

clean:
	rm -f $(PROGS) nowait_tsan *.o
