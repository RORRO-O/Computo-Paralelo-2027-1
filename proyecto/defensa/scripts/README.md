# Scripts de la defensa oral

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Defensa oral · jueves 10 de diciembre de 2026 · 10:30–12:00 · Salón 3208 · para el profesor · versión 1.1 · 20 de octubre de 2026

Dos *scripts* en Python 3 sin bibliotecas externas. Se corren desde esta carpeta. El detalle de cada opción está en el
docstring de cada archivo (`python3 <script> --help` resume los argumentos).

| Archivo | Para qué | Cuándo | Documento que aplica |
|---|---|---|---|
| `sortear_orden.py` | Orden de defensa por SHA-256 de `"<semilla>-equipoNN"`, horario por sesión según el formato (completo, corto, mixto) y tema de la pregunta 2 por integrante | Lunes 7 de diciembre, en clase (sesión C1) | `../logistica-defensa.md` §2–§4 |
| `calificar_defensa.py` | Defensa (/15) por integrante, conteo de respuestas Insuficientes, factor de ajuste, aviso de C6 y proyecto individual con el tope de 20 puntos | El mismo día de cada sesión de defensa | `../rubrica-defensa.md` §2–§4, `../logistica-defensa.md` §7 |
| `ejemplo/equipos.csv` | 12 equipos de ejemplo (once de 3 y uno de 2) | Pruebas y ensayo del comando | — |
| `ejemplo/registro-defensa.csv` | Registro de ejemplo con usuarios ficticios; produce la tabla de `rubrica-defensa.md` §4.1 | Pruebas | — |
| `tests/run_tests.sh` | 33 casos `PASS`/`FAIL`, incluida la comparación de la tabla de `logistica-defensa.md` §4 con la salida real y la lectura de CSV exportados desde una hoja de cálculo (marca BOM, equipo "7" = "07") | Antes de usar los *scripts* y después de cambiarlos | — |

## Comandos

```bash
make            # verifica la sintaxis (no escribe __pycache__/)
make test       # 33 casos; código 0 solo si todo pasa
make run        # ejemplos: salida/orden-corto.md y salida/calificaciones.csv
make clean      # borra salida/ y __pycache__/

# Sorteo real (lunes 7 de diciembre): una línea "equipo,integrantes" por equipo inscrito
python3 sortear_orden.py --semilla 20261210 --equipos ejemplo/equipos.csv --formato completo --salida ../orden-defensa.md

# Calificación real: el registro con usuarios de GitHub vive en docente/ (en .gitignore), nunca aquí
python3 calificar_defensa.py ../../../docente/proyecto/registro-defensa.csv \
    --salida ../../../docente/proyecto/calificaciones-defensa.csv
```

## Códigos de salida

| Script | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| `sortear_orden.py` | Todos los equipos tienen horario | — | Argumentos inválidos (mensaje en stderr) | Algún equipo queda **SIN HORARIO** con ese formato y esas sesiones (el informe se imprime igual) |
| `calificar_defensa.py` | Todo calculado | Archivo inexistente, columna faltante, nivel o número inválido, integrante vacío o repetido en su equipo, D1–D3 distintos dentro de un equipo, uso de `A` fuera de una ausencia (se indica fila y columna) | Argumentos inválidos (argparse) | — |

## Qué no se versiona

`salida/` y `__pycache__/` (las regenera `make run`), y cualquier `registro-*.csv` o `calificaciones*.csv` en esta carpeta
(`.gitignore`): contienen calificaciones con usuarios de GitHub y van en `docente/`. La salida del sorteo
(`../orden-defensa.md`) sí se publica: solo tiene números de equipo.
