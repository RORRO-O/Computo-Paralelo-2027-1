# Práctica guiada S09 · Paralelismo de tareas: task, taskwait, taskloop y corte (cutoff)
# Objetivos: all, run, test, clean (convención del curso) + cutoffs, tsan.
# Variables ajustables: make run THREADS=2 N=1000000

CC        = gcc
CFLAGS    = -std=c11 -O2 -Wall -Wextra -fopenmp
LDLIBS    = -lm
TSANFLAGS = -std=c11 -O1 -g -Wall -Wextra -fopenmp -fsanitize=thread

PROGS   = mergesort_tasks fib_tasks fib_buggy taskwait_buggy list_tasks taskloop_demo tree_sum_tasks
THREADS ?= 4
N       ?= 2000000

.PHONY: all run cutoffs test tsan clean

all: $(PROGS)

%: %.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

# Demostración corta (< 10 s en 4 núcleos): traza con n=8, lista, fibonacci y mergesort por defecto.
run: all
	OMP_NUM_THREADS=$(THREADS) ./mergesort_tasks 8 2
	@echo
	OMP_NUM_THREADS=$(THREADS) ./list_tasks 8
	@echo
	OMP_NUM_THREADS=$(THREADS) ./fib_tasks 32 20
	@echo
	OMP_NUM_THREADS=$(THREADS) ./mergesort_tasks $(N) 4096

# Barrido del corte (fase Modificar y tarea): mismo n, cutoff de 1 hasta n. Una línea por cutoff.
cutoffs: mergesort_tasks
	@for c in 1 16 256 4096 65536 $(N); do \
	  OMP_NUM_THREADS=$(THREADS) ./mergesort_tasks $(N) $$c | grep '^resumen'; done

test: all
	bash tests/run_tests.sh

# La carrera a propósito, vista con ThreadSanitizer (no sirve para medir tiempos).
tsan: taskwait_buggy.c
	$(CC) $(TSANFLAGS) taskwait_buggy.c -o taskwait_tsan
	-OMP_NUM_THREADS=$(THREADS) TSAN_OPTIONS="halt_on_error=0" ./taskwait_tsan 2000000

clean:
	rm -f $(PROGS) taskwait_tsan *.o
