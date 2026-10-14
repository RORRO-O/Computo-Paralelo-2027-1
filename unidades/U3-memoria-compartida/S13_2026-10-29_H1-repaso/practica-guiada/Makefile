# Makefile — S13 · Práctica guiada "cazador de errores" + ejemplo resuelto + ítems del examen de práctica
# (Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1)
#
#   make            compila todo con -std=c11 -O2 -Wall -Wextra -fopenmp (sin warnings)
#   make run        corre los tres cazadores con THREADS hilos (caza2 se cuelga: timeout 10) y el ejemplo
#   make test       verifica el material tal como se entrega (< 60 s): compila sin warnings, los errores
#                   se reproducen, las soluciones pasan, los ítems del examen dan la salida de la clave
#   make cazar      tu avance: pasa SOLO cuando corregiste caza1_race_buggy.c, caza2_barrier_buggy.c y
#                   caza3_private_buggy.c (y caza4_*_buggy.c si ya escribiste el tuyo)
#   make tsan       ThreadSanitizer sobre caza1, caza3 y la variante que falla del ejemplo (n pequeño)
#   make warn       compila caza3 con el ayudante inline: gcc avisa lo que ve (fase Investigar)
#   make run-examen corre los ítems del examen de práctica y muestra las salidas de la clave
#   make clean
#
# Variables: THREADS=4  N=4000000  TIMEOUT=10

CC        = gcc
CFLAGS    = -std=c11 -O2 -Wall -Wextra -fopenmp -I.
TSANFLAGS = -std=c11 -fsanitize=thread -g -O1 -Wall -Wextra -fopenmp -I.
LDLIBS    = -lm
THREADS  ?= 4
N        ?= 4000000
TIMEOUT  ?= 10

CAZA    = caza1_race_buggy caza2_barrier_buggy caza3_private_buggy
FIXED   = soluciones/caza1_race_fixed soluciones/caza2_barrier_fixed soluciones/caza3_private_fixed
# Fase Crear: si existe caza4_<tema>_buggy.c se compila y se prueba también.
EXTRA   = $(patsubst %.c,%,$(wildcard caza4_*_buggy.c))
EJEMPLO = ejemplo_revision ejemplo_revision_falla
EXAMEN  = examen_items/item_II1_firstprivate examen_items/item_II2_static_map \
          examen_items/item_III1_dot_buggy examen_items/item_III1_dot_fixed \
          examen_items/item_III2_scan_buggy examen_items/item_III2_scan_fixed \
          examen_items/item_IV_tasks_sum examen_items/item_VI_collatz
TSAN_BINS = caza1_race_buggy_tsan caza3_private_buggy_tsan ejemplo_revision_falla_tsan

.PHONY: all run run-examen test cazar tsan warn clean

all: $(CAZA) $(FIXED) $(EXTRA) $(EJEMPLO) $(EXAMEN)

%: %.c common.h
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

%_tsan: %.c common.h
	$(CC) $(TSANFLAGS) $< -o $@ $(LDLIBS)

ejemplo_revision_falla: ejemplo_revision.c common.h
	$(CC) $(CFLAGS) -DVARIANTE_FALLA $< -o $@ $(LDLIBS)

ejemplo_revision_falla_tsan: ejemplo_revision.c common.h
	$(CC) $(TSANFLAGS) -DVARIANTE_FALLA $< -o $@ $(LDLIBS)

examen_items/item_III1_dot_fixed: examen_items/item_III1_dot_buggy.c common.h
	$(CC) $(CFLAGS) -DCORREGIDO $< -o $@ $(LDLIBS)

examen_items/item_III2_scan_fixed: examen_items/item_III2_scan_buggy.c common.h
	$(CC) $(CFLAGS) -DCORREGIDO $< -o $@ $(LDLIBS)

run: $(CAZA) $(EXTRA) ejemplo_revision
	@echo "== caza1 (THREADS=$(THREADS))"
	-OMP_NUM_THREADS=$(THREADS) ./caza1_race_buggy $(N)
	@echo; echo "== caza2 (THREADS=$(THREADS)); si se cuelga, timeout lo mata a los $(TIMEOUT) s (codigo 124)"
	-OMP_NUM_THREADS=$(THREADS) timeout $(TIMEOUT) ./caza2_barrier_buggy $(N); echo "codigo de salida: $$?"
	@echo; echo "== caza3 (THREADS=$(THREADS))"
	-OMP_NUM_THREADS=$(THREADS) ./caza3_private_buggy $(N)
	@for b in $(EXTRA); do echo; echo "== $$b (THREADS=$(THREADS))"; OMP_NUM_THREADS=$(THREADS) timeout $(TIMEOUT) ./$$b || true; done
	@echo; echo "== ejemplo resuelto (n=16, THREADS=$(THREADS))"
	OMP_NUM_THREADS=$(THREADS) ./ejemplo_revision 16

run-examen: $(EXAMEN)
	@echo "== II.1 (predecir): 4 hilos y 1 hilo"
	OMP_NUM_THREADS=4 ./examen_items/item_II1_firstprivate
	OMP_NUM_THREADS=1 ./examen_items/item_II1_firstprivate
	@echo "== II.2 (predecir): equipo de 4 fijado en el codigo"
	./examen_items/item_II2_static_map
	@echo "== III.1 (encontrar el error): con el error y corregido, 4 hilos"
	-OMP_NUM_THREADS=4 ./examen_items/item_III1_dot_buggy
	OMP_NUM_THREADS=4 ./examen_items/item_III1_dot_fixed
	@echo "== III.2 (encontrar el error): con el error y corregido, 4 hilos"
	-OMP_NUM_THREADS=4 ./examen_items/item_III2_scan_buggy
	OMP_NUM_THREADS=4 ./examen_items/item_III2_scan_fixed
	@echo "== IV (completar codigo, huecos llenos), 4 hilos"
	OMP_NUM_THREADS=4 ./examen_items/item_IV_tasks_sum
	@echo "== V (problema numerico)"
	python3 examen_items/item_V_numeros.py
	@echo "== VI (diseno breve): referencia medida, 4 hilos"
	OMP_NUM_THREADS=4 ./examen_items/item_VI_collatz

test:
	bash tests/run_tests.sh

cazar:
	bash tests/run_tests.sh cazar

# ThreadSanitizer: n pequeno (corre 5-20x mas lento); se detiene en el primer reporte.
tsan: $(TSAN_BINS)
	@echo "===== caza1 bajo ThreadSanitizer (carrera real: dos hilos en las lineas del cuerpo del for) ====="
	-OMP_NUM_THREADS=$(THREADS) TSAN_OPTIONS="halt_on_error=1" ./caza1_race_buggy_tsan 200000 2>&1 | head -25
	@echo; echo "===== caza3 bajo ThreadSanitizer (no hay carrera; lo que aparezca es ruido de libgomp) ====="
	-OMP_NUM_THREADS=$(THREADS) TSAN_OPTIONS="halt_on_error=1" ./caza3_private_buggy_tsan 200000 2>&1 | head -25
	@echo; echo "===== variante que falla del ejemplo (nowait + mapas distintos) ====="
	-OMP_NUM_THREADS=$(THREADS) TSAN_OPTIONS="halt_on_error=1" ./ejemplo_revision_falla_tsan 64 2>&1 | head -25

warn:
	@echo "== gcc -O2 -Wall -Wextra con el ayudante inline (-DINLINE_HELPER): lee el aviso"
	-$(CC) $(CFLAGS) -DINLINE_HELPER caza3_private_buggy.c -o caza3_private_warn $(LDLIBS)

clean:
	rm -f $(CAZA) $(FIXED) $(EXTRA) $(EJEMPLO) $(EXAMEN) $(TSAN_BINS) *_tsan caza3_private_warn *.o
	rm -rf tests/out
