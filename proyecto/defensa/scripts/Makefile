# Makefile · proyecto/defensa/scripts · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
# Uso (desde esta carpeta; requiere solo python3, sin bibliotecas externas):
#   make          = make all: verifica la sintaxis de los dos scripts sin escribir __pycache__/.
#   make run      corre los ejemplos: sorteo de 12 equipos en formato corto 6 + 6 (salida/orden-corto.md) y
#                 calificación de ejemplo/registro-defensa.csv (salida/calificaciones.csv).
#   make test     ejecuta tests/run_tests.sh; termina con código 0 solo si todo pasa.
#   make clean    borra salida/ y cualquier __pycache__/.
#   make run SEMILLA=20261214   repite el ejemplo con otra semilla.
# salida/ está en .gitignore: lo que produce `make run` no se versiona.
PYTHON ?= python3
SEMILLA ?= 20261210
export PYTHONDONTWRITEBYTECODE = 1

.PHONY: all run test clean

all:
	$(PYTHON) -W error -c "import sys, pathlib; [compile(pathlib.Path(f).read_text(encoding='utf-8'), f, 'exec') for f in sys.argv[1:]]" \
	    sortear_orden.py calificar_defensa.py
	@echo "Scripts verificados (sintaxis)."

run:
	$(PYTHON) sortear_orden.py --semilla $(SEMILLA) --equipos ejemplo/equipos.csv --formato corto \
	    --sesiones "2026-12-10 10:30 90" "2026-12-14 10:30 90" --max-por-sesion 6 --salida salida/orden-corto.md
	$(PYTHON) calificar_defensa.py ejemplo/registro-defensa.csv --salida salida/calificaciones.csv

test:
	bash tests/run_tests.sh

clean:
	rm -rf salida __pycache__ tests/__pycache__
