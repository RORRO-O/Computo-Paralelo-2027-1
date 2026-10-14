# Makefile — S10 · Práctica guiada: rendimiento (protocolo, Amdahl medido, falso compartido, sobrecarga)
# Objetivos: all · run · test · clean · medir · grafica · afinidad
# Variables ajustables: make run THREADS=2 · make medir HILOS="1 2 4 8" N_FS=200000000

CC      = gcc
CFLAGS  = -std=c11 -O2 -Wall -Wextra -fopenmp
LDLIBS  = -lm
THREADS ?= 4
HILOS   ?= 1 2 4
RES     ?= resultados
# Afinidad: un hilo por nucleo fisico, sin migraciones. Es la configuracion que el curso declara en todo reporte:
# en cuatro nucleos iguales y desocupados cambia poco; con hyper-threading o nucleos hibridos cambia mucho
# (`make afinidad` lo muestra). Si tu sistema no soporta afinidad (macOS), usa: make medir BIND=
BIND    ?= OMP_PROC_BIND=close OMP_PLACES=cores

# Tamaños de la fase Ejecutar (cada programa termina en < 5 s con 4 nucleos)
N_FS     ?= 100000000
N_AMDAHL ?= 2000000
ITERS    ?= 64
N_SAXPY  ?= 10000000
N_MATMUL ?= 640
N_WEAK   ?= 1000000

PROGS = false_sharing profile_amdahl region_overhead saxpy_vs_matmul weak_scaling

.PHONY: all run test clean medir grafica afinidad

all: $(PROGS)

%: %.c common.h
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

# Corre los cinco programas con THREADS hilos (salida legible; sin CSV).
run: all
	$(BIND) OMP_NUM_THREADS=$(THREADS) ./false_sharing $(N_FS)
	@echo
	$(BIND) OMP_NUM_THREADS=$(THREADS) ./profile_amdahl $(N_AMDAHL) $(ITERS)
	@echo
	$(BIND) OMP_NUM_THREADS=$(THREADS) ./region_overhead 2000 20000
	@echo
	$(BIND) OMP_NUM_THREADS=$(THREADS) ./region_overhead 2000000 20
	@echo
	$(BIND) OMP_NUM_THREADS=$(THREADS) ./saxpy_vs_matmul $(N_SAXPY) $(N_MATMUL)
	@echo
	$(BIND) OMP_NUM_THREADS=$(THREADS) ./weak_scaling $(N_WEAK)

# Protocolo completo: barrido de HILOS, un CSV por experimento en $(RES)/ (se borran los anteriores).
medir: all
	mkdir -p $(RES)
	rm -f $(RES)/false_sharing.csv $(RES)/profile_amdahl.csv $(RES)/saxpy_vs_matmul.csv $(RES)/weak_scaling.csv
	@for t in $(HILOS); do \
	  echo "== OMP_NUM_THREADS=$$t"; \
	  $(BIND) OMP_NUM_THREADS=$$t ./false_sharing $(N_FS) $(RES)/false_sharing.csv | grep -v '^RESULT'; \
	  $(BIND) OMP_NUM_THREADS=$$t ./profile_amdahl $(N_AMDAHL) $(ITERS) $(RES)/profile_amdahl.csv | grep -v '^RESULT'; \
	  $(BIND) OMP_NUM_THREADS=$$t ./saxpy_vs_matmul $(N_SAXPY) $(N_MATMUL) $(RES)/saxpy_vs_matmul.csv | grep -v '^RESULT'; \
	  $(BIND) OMP_NUM_THREADS=$$t ./weak_scaling $(N_WEAK) $(RES)/weak_scaling.csv | grep -v '^RESULT'; \
	done
	@echo "CSV escritos en $(RES)/ ; ahora: make grafica"

# Una grafica (speedup vs hilos con la linea ideal) por CSV + tabla Markdown en pantalla.
grafica:
	python3 graficar.py $(RES)/false_sharing.csv   --titulo "Falso compartido: contadores por hilo"
	python3 graficar.py $(RES)/profile_amdahl.csv  --titulo "Amdahl medido: total vs. seccion paralela"
	python3 graficar.py $(RES)/saxpy_vs_matmul.csv --titulo "Memoria (saxpy) vs. computo (matmul)"
	python3 graficar.py $(RES)/weak_scaling.csv    --titulo "Escalabilidad fuerte y debil"

# Panorama de afinidad: el mismo programa sin fijar hilos y con OMP_PROC_BIND/OMP_PLACES;
# OMP_DISPLAY_AFFINITY=true (OpenMP 5.0) hace que libgomp imprima en que CPU quedo cada hilo.
afinidad: weak_scaling
	@echo "== sin afinidad (OMP_PROC_BIND=false): el sistema operativo mueve los hilos entre nucleos"
	OMP_PROC_BIND=false OMP_NUM_THREADS=$(THREADS) ./weak_scaling $(N_WEAK) | grep -E '^  (secuencial|fuerte|debil) '
	@echo "== OMP_PROC_BIND=close OMP_PLACES=cores: un hilo por nucleo, sin migraciones"
	OMP_DISPLAY_AFFINITY=true OMP_PROC_BIND=close OMP_PLACES=cores OMP_NUM_THREADS=$(THREADS) \
	  ./weak_scaling $(N_WEAK) 2>&1 | grep -E '^  (secuencial|fuerte|debil) |affinity' | awk '!seen[$$0]++'
	@echo "== OMP_PROC_BIND=spread OMP_PLACES=threads: reparte los hilos lo mas lejos posible"
	OMP_PROC_BIND=spread OMP_PLACES=threads OMP_NUM_THREADS=$(THREADS) ./weak_scaling $(N_WEAK) | grep -E '^  (fuerte|debil) '

test: all
	bash tests/run_tests.sh

clean:
	rm -f $(PROGS) *.o
	rm -rf $(RES)
