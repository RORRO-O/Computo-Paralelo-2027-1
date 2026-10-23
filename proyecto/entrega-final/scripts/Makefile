# Makefile · proyecto/entrega-final/scripts · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
# Uso:
#   make          = make all: revisa la sintaxis de los scripts (bash -n).
#   make run      corre el verificador sobre una copia de ../plantilla-repo convertida en repositorio git:
#                 muestra lo que ve un equipo que aún no llena la plantilla (se esperan FAIL).
#   make test     ejecuta tests/run_tests.sh (≈ 30 s): código 0 solo si todo pasa.
#   make clean    no hay nada que borrar: las pruebas trabajan en carpetas temporales que se eliminan solas.
# Para verificar un repositorio de equipo: bash verificar_entrega.sh RUTA_AL_REPO

.PHONY: all run test clean

all:
	bash -n verificar_entrega.sh
	bash -n tests/run_tests.sh
	@echo "Scripts verificados (bash -n)."

run:
	@tmp=$$(mktemp -d "$${TMPDIR:-/tmp}/demo_verificar.XXXXXX"); \
	cp -a ../plantilla-repo "$$tmp/repo" && cd "$$tmp/repo" && git init -q . && git add -A && \
	git -c user.name=demo -c user.email=demo@ejemplo.mx commit -qm "Agregar plantilla" && \
	bash "$(CURDIR)/verificar_entrega.sh" . --sin-red; \
	echo "(La plantilla sin llenar no es una entrega: los FAIL de arriba son los que el equipo debe resolver.)"; \
	rm -rf "$$tmp"

test:
	bash tests/run_tests.sh

clean:
	@echo "Nada que limpiar en scripts/ (las pruebas usan carpetas temporales)."
