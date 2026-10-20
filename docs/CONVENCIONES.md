# Convenciones del repositorio y del material

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Contrato del material · versión 1.0 · 14 de octubre de 2026

Este documento es el contrato que sigue **todo** el material del curso a partir del 14 de octubre de 2026
(Cómputo Paralelo · Grupo 6BM1 · ESCOM-IPN · Semestre 27/1). Si un archivo del curso contradice estas
convenciones, se corrige el archivo, no la convención.

## 1. Estructura de carpetas

```
README.md                         Índice del curso (qué hay, dónde está, cómo se usa)
docs/
  CONVENCIONES.md                 Este archivo
  metodo/                         Marco pedagógico, plantillas, evaluación, política de IA, evidencia
planeacion/
  calendario-27-1.md              Sesión por sesión, con fechas reales del grupo
  mapa-evaluacion.md              Ponderaciones, entregas, fechas límite
unidades/
  U3-memoria-compartida/          Sesiones S07–S13 (15 oct – 29 oct), Práctica 4, repaso Examen 2
  U4-memoria-distribuida/         Sesiones S01–S06 (5 nov – 19 nov), Práctica 5
  U5-gpu/                         Sesiones S01–S06 (23 nov – 3 dic), Práctica 6, repaso Examen 3
practicas/
  P4-openmp/  P5-mpi/  P6-gpu/    Enunciado, código base, pruebas, rúbrica (versión estudiante)
proyecto/                         Proyecto integrador: hitos H1/H2, entrega final, defensa, plantillas
herramientas/                     Scripts de medición, gráficas, Makefiles base, notebooks Colab
docente/                          SOLO PROFESOR: exámenes, claves, soluciones, notas. NO se publica.
```

Cada **sesión** vive en una carpeta `Sxx_AAAA-MM-DD_tema-corto/` y contiene exactamente los archivos siguientes (las sesiones de repaso previas a examen agregan además su `examen-practica-*.md`):

| Archivo | Para quién | Contenido obligatorio |
|---|---|---|
| `plan-sesion.md` | Profesor | Guion minuto a minuto (ver `docs/metodo/02-plantilla-sesion.md`) |
| `retrieval-inicio.md` | Estudiantes | 4–5 preguntas de recuperación (2 de la sesión anterior, 1–2 de unidades previas, 1 del tema que viene); respuestas en bloque `<details>` |
| `notas-estudiante.md` | Estudiantes | Lectura breve (≤ 2 páginas) con el concepto, 1 ejemplo resuelto comentado y "errores frecuentes" |
| `ejemplo-resuelto.md` | Ambos | Ejemplo resuelto paso a paso con pausas de autoexplicación ("¿por qué este paso?") |
| `conceptests.md` | Profesor | 2–3 preguntas de opción múltiple para instrucción entre pares; cada distractor nace de una idea errónea documentada; incluye porcentaje esperado y qué decir en la discusión |
| `practica-guiada/` | Estudiantes | Actividad PRIMM (Predecir → Ejecutar → Investigar → Modificar → Crear) con `README.md`, código base, `Makefile` y `tests/` |
| `exit-ticket.md` | Estudiantes | 2 preguntas de salida + 1 de confianza; clave en `<details>` |
| `tarea-espaciada.md` | Estudiantes | 20–40 min de trabajo: 1 ejercicio del tema, 1 intercalado de unidades previas, 1 de preparación de la siguiente sesión |

Las tareas espaciadas son **individuales**. Se entregan en el repositorio del equipo, en
`tareas/<usuario-github>/U<k>-S<xx>.md` (y, si hay código, en `tareas/<usuario-github>/U<k>-S<xx>/`). Vencen al
inicio de la sesión siguiente del calendario (fecha y hora de esa sesión) y se autocalifican con su clave en los
minutos 5–10 de esa sesión. Quien faltó la entrega en esa misma fecha (`docs/metodo/04-evaluacion.md`, §5).

Cada **práctica** (`practicas/Pn-.../`) contiene: `README.md` (enunciado completo según `docs/metodo/03-plantilla-practica.md`),
`src/` (código base que compila), `tests/` (verificación automática), `rubrica.md`, `entrega.md` (qué, cómo y cuándo).
La solución de referencia va en `docente/practicas/Pn/`.

## 2. Idioma y estilo

- Español de México, registro académico claro. Al estudiante se le habla de **tú**; al colega docente, en
  impersonal ("se recomienda") o segunda persona.
- Frases cortas. Una idea por párrafo. Nada de relleno motivacional.
- Los términos técnicos se dan en español con el término en inglés entre paréntesis la primera vez:
  "condición de carrera (*data race*)". Después se usa el que sea más común en la industria.
- Títulos en Markdown con jerarquía `#` → `##` → `###`. Tablas para lo que se compara. Listas para lo que se enumera.
- Cada archivo empieza con un encabezado de metadatos:

```
> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208
```

- Fechas con día de la semana y hora. Nunca "la próxima clase": siempre la fecha.
- Las ponderaciones y fechas límite se citan desde `planeacion/mapa-evaluacion.md`; no se inventan otras.

## 3. Código

| Tecnología | Compilación / ejecución | Medición de tiempo |
|---|---|---|
| C + OpenMP | `gcc -std=c11 -O2 -Wall -Wextra -fopenmp` | `omp_get_wtime()` |
| C + MPI | `mpicc -std=c11 -O2 -Wall -Wextra`; `mpirun -np N` (`$(MPIRUN_FLAGS)` para `--oversubscribe`) | `MPI_Wtime()` |
| CUDA C | `.cu` ejecutado en Colab/Kaggle con `nvcc`; localmente se verifica con `nvcc -c` | `cudaEvent_t` |
| Python (Numba CUDA / CuPy / NumPy) | `python3`; kernels verificables con `NUMBA_ENABLE_CUDASIM=1` | `time.perf_counter()`; con GPU, tras `cuda.synchronize()` o `cp.cuda.Device().synchronize()` (eventos CUDA opcionales) |

Requisito de compilador: `gcc` ≥ 11.

Reglas:

1. Todo directorio con código tiene un `Makefile` con objetivos `all`, `run`, `test`, `clean`. `make test` termina con
   código 0 si pasa y distinto de 0 si falla. Las pruebas comparan contra la versión secuencial con tolerancia.
2. Identificadores en inglés (`n_threads`, `partial_sum`), comentarios y mensajes en español.
3. Sin *warnings* con `-Wall -Wextra`. Sin comportamiento indefinido conocido. Las carreras de datos se
   introducen solo a propósito, en archivos cuyo nombre termina en `_buggy.c`, y se explican.
4. Toda medición de rendimiento sigue el protocolo de `herramientas/protocolo-medicion.md`: calentamiento,
   5 repeticiones, se reporta la mediana, se fija el tamaño del problema y la lista de hilos/procesos.
5. Los programas aceptan el tamaño del problema por línea de comandos y tienen un tamaño por defecto que
   corre en menos de 5 s en una laptop de 4 núcleos.
6. El código que se entrega al estudiante compila tal cual. Lo que debe completar está marcado con
   `/* TODO(n): ... */` y el programa imprime `TODO pendiente` si se ejecuta sin completar.

## 4. Pedagogía (resumen operativo; el detalle está en `docs/metodo/`)

- Toda sesión abre con recuperación (5 min) y cierra con *exit ticket* (5 min). Sin excepciones.
- Primero instrucción explícita con ejemplo resuelto; después práctica guiada en parejas; al final transferencia.
- Toda práctica guiada sigue PRIMM. Todo ConcepTest sigue voto → discusión en parejas → revoto → explicación.
- Los distractores de cualquier pregunta de opción múltiple se construyen a partir de ideas erróneas reales
  (listadas en `docs/metodo/01-marco-pedagogico.md`, anexo A).
- Nada se evalúa sin rúbrica publicada antes. Nada se califica sin retroalimentación en ≤ 7 días.
- La IA generativa se usa según `docs/metodo/05-politica-ia.md`. Los exámenes, los *retrieval* y la defensa
  oral son zonas sin IA.

## 5. Qué es público y qué no

El repositorio es público. Por eso:

- `docente/` está en `.gitignore`. Ahí viven exámenes, claves, soluciones de prácticas y notas del profesor.
- La hoja de seguimiento **llena** vive en `docente/seguimiento-grupo.csv` y no se versiona;
  `herramientas/seguimiento-grupo.csv` es solo la plantilla vacía.
- Las respuestas de *retrieval*, *exit tickets* y ConcepTests sí se publican (sirven para autoestudio), pero
  dentro de bloques `<details>` para no estropear el efecto de recuperación.
- Los nombres y correos de estudiantes nunca entran al repositorio.

## 6. Control de versiones

- Ramas `claude/...` para material generado con asistencia de IA; se integran a `main` tras revisión del profesor.
- Mensajes de *commit* en español, en infinitivo: "Agregar sesión S08 de la Unidad III".
- Los binarios no se versionan (ver `.gitignore`).
