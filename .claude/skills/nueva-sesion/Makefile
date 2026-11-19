# Makefile de la skill /nueva-sesion · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
# El generador y sus plantillas de código son código del curso: ./verificar.sh los prueba como al resto.
#
#   make          comprueba la sintaxis del generador (no hay nada que compilar)
#   make run      muestra, sin crear nada, qué generaría para una sesión del calendario (U=U5 S=S03 TEMA=demo)
#   make test     tests/run_tests.sh: genera una sesión de cada tecnología en una carpeta temporal y exige
#                 los 8 elementos, el encabezado, `make` sin warnings y `make test` en verde
#   make clean
PY   ?= python3
U    ?= U5
S    ?= S03
TEMA ?= demo

.PHONY: all run test clean

all:
	$(PY) -m py_compile scripts/nueva_sesion.py

run:
	$(PY) scripts/nueva_sesion.py $(U) $(S) $(TEMA) --destino /tmp --seco

test: all
	PY="$(PY)" bash tests/run_tests.sh

clean:
	rm -rf scripts/__pycache__
