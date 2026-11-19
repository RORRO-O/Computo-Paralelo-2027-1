---
name: nueva-sesion
description: "Crea el andamio de una sesión del curso: la carpeta Sxx_AAAA-MM-DD_tema-corto/ con exactamente los 8 elementos de docs/CONVENCIONES.md §1, el encabezado de metadatos con la fecha y el día de la semana tomados de planeacion/calendario, y una práctica guiada PRIMM cuyo código compila sin warnings y pasa make test. Úsalo cuando se pida crear, iniciar o preparar una sesión nueva de unidades/, o rehacer el material de una sesión que todavía no existe."
argument-hint: "<unidad: U5|5|V> <sesión: S07|7> <tema-corto> [--tec openmp|mpi|gpu] [--fecha AAAA-MM-DD] [--titulo \"...\"] [--tipo ...] [--seco]"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/nueva_sesion.py:*), Bash(python3:*), Bash(make:*), Read, Glob, Grep
---
# /nueva-sesion — andamio de una sesión según el contrato del curso

Argumentos recibidos: `$ARGUMENTS`

## Qué hace el script (y qué no)
`${CLAUDE_SKILL_DIR}/scripts/nueva_sesion.py` crea la carpeta y deja resuelto lo mecánico:

- **Estructura**: `plan-sesion.md`, `retrieval-inicio.md`, `notas-estudiante.md`, `ejemplo-resuelto.md`,
  `conceptests.md`, `exit-ticket.md`, `tarea-espaciada.md` y `practica-guiada/` (README PRIMM, código, `Makefile`,
  `tests/run_tests.sh`, `.gitignore`). Ni más ni menos.
- **Encabezado** de CONVENCIONES §2 en cada `.md`. Fecha, día de la semana, hora, tipo y tema salen de
  `planeacion/calendario-*.md`; el vencimiento de la tarea es el inicio de la siguiente sesión del calendario.
- **Práctica guiada que ya pasa**: OpenMP y MPI se arman con `herramientas/Makefile.openmp` / `Makefile.mpi` y
  `herramientas/plantilla-run_tests.sh`; GPU, con referencia en CPU y espejo Numba verificable con
  `NUMBA_ENABLE_CUDASIM=1`. El programa es un problema de relleno (pi por punto medio, SAXPY) que respeta el contrato
  de salida (`n=`, `tiempo_s=`, `resultado=`).

**No escribe el contenido.** Todo lo que falta queda como `[PENDIENTE: qué escribir]`. Una sesión con un solo
`[PENDIENTE:` no está terminada y no se integra a `main`.

## Pasos
1. Si faltan argumentos, pregunta unidad, número de sesión y tema corto (minúsculas sin acentos y con guiones).
2. Ensayo: `${CLAUDE_SKILL_DIR}/scripts/nueva_sesion.py $ARGUMENTS --seco`. Muestra la ruta y el encabezado.
3. Si el ensayo es correcto, repite sin `--seco`. Códigos: 3 = la sesión ya existe (no se sobrescribe; edita la que
   hay); 2 = argumentos o fecha. Si la fecha contradice el calendario, **corrige primero el calendario**; `--forzar`
   solo cuando el profesor ya decidió el cambio.
4. Comprueba el andamio: `cd <carpeta>/practica-guiada && make && make test`.
5. Llena el contenido en el orden de `docs/metodo/07-guia-de-autoria.md`: **primero el código** de
   `practica-guiada/` (sustituye el problema de relleno; lo que completa el estudiante va en `/* TODO(n): ... */` y el
   programa imprime `TODO pendiente`), después la prosa. Las salidas que cites son de una ejecución real. Los
   distractores salen del Anexo A de `docs/metodo/01-marco-pedagogico.md`. Fechas y pesos, de `planeacion/`.
6. Antes de dar la sesión por terminada: `grep -rn 'PENDIENTE:' <carpeta>` no devuelve nada, `./verificar.sh <carpeta>`
   sin FAIL, `/race-check` si hay OpenMP nuevo y el subagente `revisor-material` sin hallazgos bloqueantes.

## Notas
- Sesión que aún no está en el calendario: `--fecha AAAA-MM-DD` (y `--hora`, `--lugar`, `--tipo`, `--titulo` si no
  valen los valores por defecto). El plan queda con un `[PENDIENTE]` que pide agregarla al calendario.
- Tipos distintos de "Contenido" (laboratorio, repaso, taller, hito): el plan cita la variante de
  `docs/metodo/02-plantilla-sesion.md` §2 que corresponde; **el guion sale con los bloques base y hay que
  reescribirlos** para esa variante. En las sesiones de repaso el script crea además `examen-practica-U<k>.md`.
- Un kernel en CUDA C (`.cu`) se agrega a mano junto al espejo Numba y se verifica en Colab/Kaggle
  (`herramientas/colab-kaggle.md`); en el contenedor solo cabe `nvcc -c` si existe y la revisión de `cuda-reviewer`.
- Pruebas de la propia skill: `make -C ${CLAUDE_SKILL_DIR} test`.
