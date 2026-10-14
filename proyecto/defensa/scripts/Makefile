# Makefile · proyecto/defensa/scripts · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
# Objetivos: all (verifica sintaxis), run (ejemplos de los dos scripts), test (pruebas), clean.
PYTHON ?= python3
SEMILLA ?= 20261210

.PHONY: all run test clean

all:
	$(PYTHON) -m py_compile sortear_orden.py calificar_defensa.py
	@echo "Scripts verificados (py_compile)."

run:
	$(PYTHON) sortear_orden.py --semilla $(SEMILLA) --equipos ejemplo/equipos.csv --formato corto \
	    --sesiones "2026-12-10 10:30 90" "2026-12-14 10:30 90" --max-por-sesion 6 --salida salida/orden-corto.md
	$(PYTHON) calificar_defensa.py ejemplo/registro-defensa.csv --salida salida/calificaciones.csv

test:
	bash tests/run_tests.sh

clean:
	rm -rf salida __pycache__ tests/__pycache__
