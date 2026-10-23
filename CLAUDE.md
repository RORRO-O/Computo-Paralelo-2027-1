# Cómputo Paralelo · Grupo 6BM1 · ESCOM-IPN · Semestre 27/1

Repositorio **público** del curso (agosto–diciembre de 2026): planeación, material de clase (`unidades/`), prácticas
P4–P6, proyecto integrador y herramientas de medición. Lo mantiene el profesor. Los equipos de estudiantes trabajan en
**sus propios repositorios privados** y toman de aquí enunciados, código base, `medir.sh` y plantillas.

Todo texto que generes (material, retroalimentación, mensajes de commit, respuestas) va en **español de México,
registro académico**. Identificadores de código en inglés; comentarios y mensajes del programa en español.

## Documentos normativos (si se contradicen con este archivo, ganan ellos)

- `docs/CONVENCIONES.md`: estructura de carpetas, estilo, reglas de código, qué es público y qué no.
- `docs/metodo/`: marco pedagógico (01), plantilla de sesión (02) y de práctica (03), evaluación (04), política de
  IA (05), evidencia (06), guía de autoría (07).
- `herramientas/protocolo-medicion.md`: toda medición de rendimiento lo sigue. Una medición fuera del protocolo no
  es evidencia.
- `planeacion/calendario-27-1.md` y `planeacion/mapa-evaluacion.md`: fechas y ponderaciones. No inventes otras.

Si alguno no existe todavía en tu rama, está en la rama `claude/metodo-y-material-2027-1` (PR #1). Léelos antes de
escribir material o código del curso.

## Estructura

```
docs/metodo/        Marco pedagógico, plantillas, evaluación, política de IA, evidencia, carta al grupo
planeacion/         Calendario sesión por sesión y mapa de evaluación
unidades/U3-memoria-compartida/  U4-memoria-distribuida/  U5-gpu/   Sesiones Sxx_AAAA-MM-DD_tema/ (8 archivos fijos)
practicas/P4-openmp/  P5-mpi/  P6-gpu/   README (enunciado), src/, tests/run_tests.sh, Makefile, rubrica.md, entrega.md
proyecto/           Hitos H1/H2, entrega final, defensa, plantillas
herramientas/       protocolo-medicion.md, medir.sh, graficar_speedup.py, cronometro.h, Makefile.openmp/.mpi, plantillas
docente/            SOLO PROFESOR, en .gitignore: exámenes, claves, soluciones, seguimiento lleno
.claude/            Hooks, subagentes y skills de Claude Code (tabla al final; detalle en .claude/README.md)
```

## Compilar, ejecutar, verificar

- Banderas del curso: C + OpenMP `gcc -std=c11 -O2 -Wall -Wextra -fopenmp`; C + MPI `mpicc -std=c11 -O2 -Wall -Wextra`
  y `mpirun $MPIRUN_FLAGS -np N`; CUDA `nvcc` (solo en Colab/Kaggle o en una máquina con GPU); Python `python3` con
  numpy, numba, mpi4py, matplotlib.
- Todo directorio con código tiene un `Makefile` con `all`, `run`, `test`, `clean`. `make test` termina en 0 solo si
  todo pasa.
- `./verificar.sh` recorre todos los Makefiles del repositorio (`make clean && make && make test`) y resume
  PASS/PEND/OMIT/FAIL (OMIT = requiere `nvcc` y no hay; se verifica en Colab/Kaggle o con GPU). Córrelo antes de
  cualquier PR que toque código. Requiere `nbformat` en Python para los scripts de la entrega final.
- Sin warnings. Las carreras de datos intencionales van solo en archivos `*_buggy.c` y se explican.
- Hook automático: al editar un `.c`, `.cpp`, `.cu` o `.py`, `.claude/hooks/check-source.sh` lo compila con las
  banderas del curso (a `/dev/null`, sin enlazar) y te devuelve errores y warnings. Corrígelos antes de seguir.

## Medición de rendimiento (resumen del protocolo)

- `-O2` siempre. Nunca se reporta `-O0` ni un binario con sanitizers. Correctitud primero (`make test`).
- 1 calentamiento + **al menos 5 repeticiones**; se reporta la **mediana** (y mín/máx). El cronómetro cubre solo la
  región paralelizada: `omp_get_wtime()`, `MPI_Wtime()`, `cudaEvent`, `time.perf_counter()`. Nunca `clock()`.
- `T(1)` es la **mejor versión secuencial**, no la paralela con 1 hilo. Si usas la paralela, decláralo y reporta
  ambas. El tamaño del problema se fija de modo que `T(1) >= 1 s`.
- Hilos 1, 2, 4, … hasta los núcleos físicos y uno más allá, declarado como sobre-suscripción.
- `S(p) = T(1)/T(p)`, `E(p) = S(p)/p`, Karp–Flatt `f = (1/S - 1/p)/(1 - 1/p)`; si `f` crece con `p`, la sobrecarga
  crece (sincronización, comunicación, false sharing, desbalance).
- CSV del protocolo en `resultados/`: `config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia`, más `entorno.txt`
  (CPU, núcleos, RAM, compilador, carga). Los programas imprimen `tiempo_s=<segundos>` y `n=<valor>`.
- Herramientas: `herramientas/medir.sh` (`/medir`), `herramientas/graficar_speedup.py` (`/graficar`),
  `herramientas/cronometro.h`. Interpretación: subagente `perf-analyst`.
- Nunca inventes ni "mejores" una medición. Si falta un dato, escribe `[PENDIENTE: qué falta y cómo obtenerlo]`.

## Dónde correr qué

| Entorno | Sirve para | No sirve para |
|---|---|---|
| Sesión cloud de Claude Code (este contenedor): 4 núcleos sin SMT, sin GPU, sin contadores de hardware | OpenMP hasta 4 hilos (8 = sobre-suscripción declarada), MPI con `--oversubscribe`, numba con `NUMBA_ENABLE_CUDASIM=1`, `make test`, ThreadSanitizer, `valgrind --tool=cachegrind` | mediciones finales con más de 4 hilos, CUDA real, `perf stat -e cycles` (devuelve `not supported`) |
| Laboratorio LS4 o PC con GPU (con Remote Control si quieres a Claude ahí) | mediciones finales, `nvcc`, `compute-sanitizer`, `ncu` | — |
| Colab / Kaggle | CUDA de la P6 según `herramientas/colab-kaggle.md` | repetir mediciones con el mismo hardware garantizado |

- En el contenedor `mpirun` corre como root: `OMPI_ALLOW_RUN_AS_ROOT*` y `MPIRUN_FLAGS=--oversubscribe` ya están en
  `.claude/settings.json`.
- Compilar en paralelo sí; **medir en paralelo nunca**. Dos benchmarks simultáneos en 4 núcleos invalidan ambos.
  Un benchmark a la vez, en primer plano, sin otros procesos pesados (`uptime` con carga < 0.5 antes de medir).

## Reglas de código (resumen de CONVENCIONES §3)

- Tamaño del problema por línea de comandos (último argumento), con un valor por defecto que corre en menos de 5 s
  en 4 núcleos. El programa imprime `n=<valor>`, `tiempo_s=<valor>` y un resultado verificable `<clave>=<valor>`.
- El código que recibe el estudiante compila tal cual; lo que debe completar lleva `/* TODO(n): ... */` y el programa
  imprime `TODO pendiente` si se ejecuta sin completarlo.
- OpenMP: `default(none)` con cláusulas explícitas; acumuladores con `reduction`; sin `critical`/`atomic` en el
  camino caliente; índices de bucles internos privados; `rand_r` en lugar de `rand`; arreglos indexados por hilo
  rellenados a 64 bytes; la región `parallel` fuera del bucle externo caliente; `schedule` elegido con datos.
- MPI: colectivas llamadas por todos los procesos en el mismo orden; cada `Isend`/`Irecv` con su `Wait`; el caso
  `n % size != 0` manejado; `MPI_Barrier` antes de `MPI_Wtime`; el tiempo reportado es el máximo entre rangos.
- CUDA: guarda de límites en cada kernel, grid redondeado hacia arriba, macro `CUDA_CHECK` en cada llamada,
  `__syncthreads()` fuera de ramas divergentes, tiempos con y sin transferencias.

## Material didáctico

- Sigue `docs/metodo/07-guia-de-autoria.md`: primero el código (compila y `make test` pasa), después la prosa. Las
  salidas "esperadas" son reales, no imaginadas.
- Cada archivo empieza con el encabezado de metadatos de CONVENCIONES §2 (curso, unidad, sesión, fecha con día de
  la semana, hora, salón). Fechas siempre con día de la semana; nunca "la próxima clase".
- Una carpeta de sesión `Sxx_AAAA-MM-DD_tema-corto/` contiene exactamente los 8 archivos de CONVENCIONES §1. Los
  distractores salen del Anexo A de `01-marco-pedagogico.md`. Las respuestas van en bloques `<details>`.
- Antes de dar por terminado material nuevo o modificado, pásalo por el subagente `revisor-material`.

## Privacidad y política de IA

- `docente/` está en `.gitignore`. Nunca copies su contenido a archivos públicos ni lo cites en commits, issues o
  PRs. Nombres, correos y calificaciones de estudiantes nunca entran al repositorio.
- La política de IA (`docs/metodo/05-politica-ia.md`) aplica a los estudiantes. Si quien te habla es un estudiante
  o estás en el repositorio de un equipo, no escribas por él más de 10 líneas de código ni reportes completos: actúa
  como `tutor-socratico`.
- Al calificar con `calificador`, la retroalimentación puede publicarse en el PR del equipo; la nota numérica no (va
  a `docente/`).

## Git

- Ramas `claude/...` para material generado con asistencia de IA; se integran a `main` tras revisión del profesor.
  Una rama por cambio.
- Commits en español, en infinitivo, con el objeto concreto: `Agregar sesión S08 de la Unidad III`,
  `Corregir carrera en c_heat.c`.
- No se versionan binarios, `bin/`, `tests/out/`, `*.pgm`, `cp-env/`, `resultados/salidas/`. Sí se versionan los CSV,
  PNG y `entorno.txt` de ejemplo en `resultados/`.
- Nunca `git push --force` ni `rm -rf` (el hook `guard-bash.sh` los bloquea). `git reset --hard`, `git clean -f` y
  `git checkout -- .` piden confirmación.

## Agentes y skills de este repositorio

| Comando o agente | Para qué |
|---|---|
| `/medir` | aplica el protocolo a un programa (`herramientas/medir.sh` o su respaldo) y deja CSV + `entorno.txt` |
| `/graficar` | CSV del protocolo → `speedup.png`, `eficiencia.png` y tabla Markdown con Karp–Flatt |
| `/race-check` | ThreadSanitizer (clang + Archer, o gcc) sobre un programa OpenMP con n pequeño |
| `/revisar-practica` | revisión completa de una entrega: `make test`, reviewer de la tecnología, perf-analyst, race-check y rúbrica |
| `openmp-reviewer`, `mpi-reviewer`, `cuda-reviewer` | revisión de corrección y rendimiento de código paralelo |
| `perf-analyst` | interpreta CSV: speedup, eficiencia, Karp–Flatt, Amdahl y la causa dominante |
| `revisor-material` | revisa sesiones y prácticas contra CONVENCIONES y la guía de autoría |
| `calificador` | aplica `rubrica.md` a una entrega y redacta la retroalimentación |
| `tutor-socratico` | modo tutor según la política de IA: pistas y preguntas, no soluciones |

## Antes de dar por terminado un cambio

1. Código: `./verificar.sh` (o `make test` del directorio tocado) sin FAIL ni warnings; `/race-check` si hay OpenMP nuevo.
2. Material: `revisor-material` sin hallazgos bloqueantes.
3. Mediciones nuevas: CSV + `entorno.txt` + gráficas en `resultados/`, interpretadas por `perf-analyst`.
4. Commit en español y PR. No lo des por listo hasta que CI esté en verde.
