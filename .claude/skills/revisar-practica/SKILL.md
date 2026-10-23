---
name: revisar-practica
description: "Revisión completa de una práctica o entrega antes de calificarla o de abrir un PR. Reproduce make clean, make y make test, corre race-check en el código OpenMP, lanza en paralelo el reviewer de la tecnología (openmp, mpi o cuda) y perf-analyst sobre los CSV, comprueba la lista de entrega.md y, con --calificar, aplica la rúbrica con el subagente calificador."
argument-hint: "<ruta de la práctica o de la entrega del equipo> [--calificar] [--rubrica practicas/P4-openmp/rubrica.md]"
disable-model-invocation: true
---
# /revisar-practica — revisión en paralelo con veredicto

Argumentos recibidos: `$ARGUMENTS`

Orquesta la revisión con subagentes (herramienta Agent, en paralelo); no hagas tú solo la revisión en serie y no
modifiques código ni reporte durante la revisión. Si no se pasó ruta, pregunta cuál práctica o entrega revisar.

## 1. Reproducir (tú, en primer plano, uno a la vez)
```bash
cd <ruta> && make clean && make 2>&1 | tee /tmp/make.txt && make test 2>&1 | tee /tmp/test.txt
```
Anota warnings (cuentan como fallo del criterio de correctitud), PASS/FAIL por caso y programas con `TODO pendiente`.
Si hay `#pragma omp`: `make tsan` si existe, o `.claude/skills/race-check/scripts/race-check.sh src/<archivos>.c -- <n pequeño>`.
Nunca corras `make medir` aquí: medir no es revisar, y dos cargas a la vez invalidan la medición.

## 2. Lanzar en paralelo (Agent tool, un subagente por línea, en segundo plano)
- `openmp-reviewer` si hay `#pragma omp`; `mpi-reviewer` si hay `mpi.h` o `mpi4py`; `cuda-reviewer` si hay `.cu` o
  `numba.cuda` (en híbridos, varios). Prompt: "Revisa <ruta>/src y devuelve la tabla de hallazgos con archivo:línea".
- `perf-analyst` sobre `<ruta>/resultados/*.csv` y `entorno.txt`. Si no hay CSV, que lo diga y pida `/medir`.
- Si se pasó `--calificar`: `calificador` con la rúbrica indicada (o `practicas/Pn-…/rubrica.md`) y la ruta de la
  entrega; pásale también la salida de `make`/`make test` del paso 1 para que no la repita.

## 3. Lista de entrega (tú, con `entrega.md` de la práctica si existe; si no, la genérica)
`REPORTE.md` con todas las secciones y sin `{{…}}` ni `[PENDIENTE]`; CSV con encabezado del protocolo, filas
`*-seq`, >= 5 repeticiones, hilos pedidos, `T(1) >= 1 s`; `entorno.txt`; las dos gráficas con ejes y línea ideal;
`prelab/` por integrante; declaración de IA con las cuatro líneas; `git status` sin binarios, `tests/out/` ni
`cp-env/`; etiqueta de entrega; commits en español.

## 4. Consolidar
- **Veredicto**: LISTA / LISTA CON CAMBIOS MENORES / NO LISTA (y, con `--calificar`, la tabla de niveles del calificador).
- **Bloqueantes**: CRÍTICOS de los reviewers, carreras detectadas, `make test` en FAIL, warnings, metodología
  inválida, números sin respaldo.
- **Mejoras recomendadas**: máximo 7, con archivo:línea.
- **Pendientes de la entrega**: secciones o archivos faltantes.
- **Preguntas de mini-defensa**: dos por integrante (una de su parte, una ajena), con la respuesta esperada.
- **Siguiente paso** exacto (comandos).
Ofrece aplicar las correcciones después, cambio por cambio, nunca durante la revisión.
