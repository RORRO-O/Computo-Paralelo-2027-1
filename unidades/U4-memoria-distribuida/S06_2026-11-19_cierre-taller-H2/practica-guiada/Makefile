# Makefile — Práctica guiada S06 · Cazador de errores MPI + revisor de mediciones (taller hacia H2)
#
# Objetivos de la convención del curso:
#   make            compila el ejemplo resuelto, los tres programas con error y tus correcciones (si existen)
#   make run        corre el ejemplo resuelto y el revisor sobre el CSV de ejemplo correcto
#   make test       tests/run_tests.sh: el material se verifica a sí mismo; tus correcciones cuentan si existen
#   make clean      borra los ejecutables
# Objetivos de la sesión:
#   make sintomas   corre los tres programas con error bajo `timeout 10` y muestra el código de salida
#   make listo      como `make test`, pero FALLA mientras falte alguna corrección (caza1/2/3 y caza4 si existe)
#   make revisar    revisor de mediciones sobre los dos CSV de ejemplo (el correcto y el que tiene errores)
#
# Variables que puedes cambiar desde la línea de comandos:
#   make NP=6 run                       procesos del ejemplo (par)
#   make MPIRUN_FLAGS="" test           si tu MPI no acepta --oversubscribe (p. ej. MPICH)

MPICC        ?= mpicc
CFLAGS       ?= -std=c11 -O2 -Wall -Wextra
MPIRUN       ?= mpirun
MPIRUN_FLAGS ?= --oversubscribe
NP           ?= 4
PYTHON       ?= python3
TIMEOUT      ?= timeout --foreground -k 2 10

# Open MPI se niega a correr como root salvo que se declare (contenedores, entorno de autoría).
ifeq ($(shell id -u),0)
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
endif

EXAMPLE = ejemplo_columna_split
BUGGY   = caza1_orden_send_buggy caza2_bcast_solo_raiz_buggy caza3_recv_corto_buggy
# Tus correcciones: caza1_orden_send.c, caza2_bcast_solo_raiz.c, caza3_recv_corto.c, y caza4*.c (fase Crear).
FIXED   = $(patsubst %.c,%,$(filter-out %_buggy.c,$(wildcard caza[1-4]*.c)))

.PHONY: all run sintomas revisar test listo clean

all: $(EXAMPLE) $(BUGGY) $(FIXED)

%: %.c
	$(MPICC) $(CFLAGS) -o $@ $<

run: all
	@echo "== Ejemplo resuelto: tipo derivado (columna) + comunicador por fila (-np $(NP)) =="
	$(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./$(EXAMPLE)
	@echo
	@echo "== Revisor de mediciones sobre ejemplo_mediciones_ok.csv (máquina de 4 núcleos) =="
	$(PYTHON) revisar_mediciones.py ejemplo_mediciones_ok.csv --nucleos 4

sintomas: $(BUGGY)
	@for p in $(BUGGY); do \
	    echo "== $$p (-np $(NP), timeout 10 s) =="; \
	    $(TIMEOUT) $(MPIRUN) $(MPIRUN_FLAGS) -np $(NP) ./$$p; rc=$$?; \
	    echo "   -> código de salida $$rc  (124/137 = no terminó en 10 s; 0 = terminó; otro = abortó)"; echo; \
	done

revisar:
	$(PYTHON) revisar_mediciones.py ejemplo_mediciones_ok.csv --nucleos 4
	@echo
	-$(PYTHON) revisar_mediciones.py ejemplo_mediciones_mal.csv --nucleos 4

test: all
	MPIRUN="$(MPIRUN)" MPIRUN_FLAGS="$(MPIRUN_FLAGS)" PYTHON="$(PYTHON)" bash tests/run_tests.sh

listo: all
	STRICT=1 MPIRUN="$(MPIRUN)" MPIRUN_FLAGS="$(MPIRUN_FLAGS)" PYTHON="$(PYTHON)" bash tests/run_tests.sh

clean:
	rm -f $(EXAMPLE) $(BUGGY) $(FIXED) speedup_ejemplo.png
