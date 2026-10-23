---
name: race-check
description: "Detecta carreras de datos en programas OpenMP en C compilando con ThreadSanitizer (clang + Archer si está disponible, si no gcc) y ejecutando con varios hilos; con --asan agrega AddressSanitizer y UBSan. Úsalo antes de medir o de abrir un PR, cuando el resultado paralelo difiera del secuencial o cambie entre corridas, o cuando se mencione carrera, race, segfault en paralelo o resultado que a veces sale bien."
argument-hint: "src/programa.c [más .c] [--threads 4] [--asan] [--out resultados/race-check.txt] -- [args del programa]"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/race-check.sh:*), Bash(make tsan:*), Bash(make:*), Read, Glob, Grep
---
# /race-check — carreras de datos con ThreadSanitizer

Argumentos recibidos: `$ARGUMENTS`

Si la práctica tiene `make tsan` (P4 lo tiene), úsalo primero: ya fija el programa y el tamaño. Si no:
```bash
${CLAUDE_SKILL_DIR}/scripts/race-check.sh src/programa.c -- 20000 16
${CLAUDE_SKILL_DIR}/scripts/race-check.sh src/a.c src/b.c --threads 8 --out resultados/race-check.txt -- 100000
${CLAUDE_SKILL_DIR}/scripts/race-check.sh src/programa.c --asan -- 50000      # además memoria y UB
```
- Compila con `-std=c11 -fopenmp -g -O1 -fsanitize=thread`. Con **clang + Archer** (`libarcher.so`) TSan entiende la
  semántica de OpenMP y casi no da falsos positivos; con gcc puede reportar barreras internas de libgomp (el script
  las filtra: solo cuentan los reportes que tocan **tus** archivos).
- Tamaño de problema **pequeño**: TSan hace el programa 5–15 veces más lento. Nunca midas tiempos con este binario.
- Código de salida: 0 sin hallazgos, 1 con carreras (o problemas de ASan/UBSan), 2 error de compilación o archivo inexistente.

## Cómo leer el reporte
`WARNING: ThreadSanitizer: data race` seguido de dos pilas (`Write of size … by thread T2` y `Previous read/write …
by thread T1`); la línea de **tu** archivo en cada pila es el conflicto. El script resume `archivo:línea` únicos.
Causas típicas: acumulador sin `reduction`; índice de bucle interno compartido (`private(j)`); `nowait` que quita una
barrera; `rand()` compartido; `taskwait` faltante; escritura a `a[i]` con `i` compartida. Un programa sin carreras aún
puede ser incorrecto; uno con carreras siempre lo es, aunque "dé bien" hoy. Los archivos `*_buggy.c` tienen carreras a
propósito: ahí el objetivo es que el reporte las muestre y el estudiante las explique.

## Después
Corrige y repite hasta exit 0. Guarda la salida final con `--out resultados/race-check.txt` como evidencia y pásala a
`openmp-reviewer` si pides revisión.
