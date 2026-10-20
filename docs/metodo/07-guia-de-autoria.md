# Guía de autoría de material

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Para quien escribe material (humano o asistente de IA) · versión 1.0

Esta guía convierte el método en pasos. Se usa junto con `docs/CONVENCIONES.md` (estructura y estilo),
`02-plantilla-sesion.md`, `03-plantilla-practica.md`, `04-evaluacion.md` y el Anexo A de
`01-marco-pedagogico.md` (ideas erróneas).

## A. Cómo escribir una sesión

1. **Lee** `planeacion/calendario-27-1.md` y ubica la fila de la sesión: fecha, tipo, tema, entregas, carpeta.
2. **Define 3–4 objetivos** observables (verbo + contenido + condición) y asígnales nivel cognitivo.
3. **Elige las ideas erróneas** del Anexo A que la sesión ataca (mínimo dos). Cada una debe aparecer en: un
   distractor de ConcepTest, un paso de la práctica guiada o una pregunta del *exit ticket*.
4. **Escribe primero el código** de la práctica guiada y del ejemplo resuelto. Compílalo con las banderas de
   las convenciones. Haz que `make test` pase. Solo entonces escribe la prosa: así las salidas "esperadas" son
   reales, no imaginadas.
5. **Ejemplo resuelto**: problema → plan en 3 líneas → código comentado → salida real → 3+ pausas de
   autoexplicación con respuesta en `<details>`. Incluye una "variante que falla" cuando el tema lo permite.
   **Nivel de andamiaje por posición en la unidad** (se declara en `plan-sesion.md`, "Prerrequisitos y vínculo"):
   en las dos primeras sesiones de contenido de cada unidad (U3 S07–S08; U4 S01–S02; U5 S01 y S03) el ejemplo
   resuelto es completo y la práctica guiada lleva las cinco fases de PRIMM. De la tercera en adelante (U3
   S10–S11; U4 S04; U5 S04) el ejemplo resuelto es un problema por completar (2–3 huecos, respuesta en
   `<details>`) y la práctica guiada abrevia Predecir/Investigar para dar ≥ 10 min a Crear; si el ejemplo ya
   está escrito completo, el desvanecimiento se hace en la práctica guiada.
6. **Práctica guiada PRIMM** en `practica-guiada/`:
   - `README.md` con las cinco fases. *Predecir*: preguntas concretas con espacio para la respuesta ("¿qué hilo
     imprime primero? ¿cuántas líneas salen?"). *Ejecutar*: comandos exactos. *Investigar*: tabla de rastreo o
     preguntas sobre líneas específicas. *Modificar*: cambios con objetivo verificable. *Crear*: una variante
     propia con criterio de "listo".
   - Código base (`*.c`, `*.cu`, `*.py`) que compila y corre tal cual; `Makefile` con `all`/`run`/`test`/`clean`;
     `tests/run_tests.sh` ejecutable.
   - Lista de errores esperados (para el profesor) dentro de `plan-sesion.md`, con la pregunta socrática que se
     hace ante cada uno.
7. **ConcepTests** (2–3): enunciado, 4 opciones, respuesta, origen de cada distractor (número del Anexo A o
   descripción), porcentaje de acierto esperado en el primer voto, guion de 3 líneas para la discusión. La
   sesión usa dos; el tercero, si existe, es reserva para la recuperación siguiente o el examen de práctica. En
   el ConcepTest 2 la discusión y el revoto ocurren solo si el primer voto queda entre 30 % y 80 %; fuera de ese
   rango se pasa a la explicación.
8. **Recuperación de inicio** (4–5 preguntas): 2 de la sesión anterior, 1–2 de unidades previas (I–II o anteriores),
   1 que anticipe el tema. Respuestas en `<details>`. Deben contestarse en ≤ 4 minutos sin apuntes. Cada pregunta
   se contesta en una línea o eligiendo una opción (recordar/comprender); nada de rastrear código largo ni de
   "explica con tus palabras": eso va al *exit ticket*, a PRIMM o a la tarea. La que anticipa el tema se plantea
   como conjetura ("¿qué crees que pase si…?"); "no sé" es válida y no cuenta. Si un ítem de la sesión anterior
   quedó bajo 60 %, se repite con pista en lugar de uno nuevo.
9. **Exit ticket**: 2 preguntas (una conceptual, una de aplicación corta) + "¿Qué tan seguro estás? (1–4) ¿Qué
   te quedó menos claro?". Clave en `<details>`. Formato que permite revisar 35 tickets en 10 minutos: la
   pregunta 1 es de opción múltiple con distractores del Anexo A o de respuesta de una línea; la pregunta 2 se
   contesta con un número, una palabra clave o una línea de código, con clave literal. Si una pregunta pide 2–3
   líneas, la clave señala el dato o la palabra que decide bien / parcial / mal. "¿Qué te quedó menos claro?" es
   opcional y no se clasifica.
10. **Tarea espaciada** (20–40 min): 1 ejercicio del tema, 1 intercalado (unidad previa), 1 de preparación de
    la siguiente sesión (lectura breve o la predicción de la práctica guiada siguiente). El ejercicio del tema
    se plantea como elección justificada entre 2–3 alternativas confundibles vistas en sesiones distintas de la
    misma unidad (`atomic`/`critical`/`reduction`; `static`/`dynamic`; `Reduce`/`Allreduce`; `Send`/`Isend`);
    el de unidades previas aporta el espaciado. Si en clase se recortó Transferencia, el "Crear" de PRIMM es el
    ejercicio del tema. Entrega fija, igual en todas las sesiones: es individual, se sube al repositorio del
    equipo en `tareas/<usuario-github>/U<k>-S<xx>.md` (el código, si lo hay, en `tareas/<usuario-github>/U<k>-S<xx>/`)
    y vence al inicio de la sesión siguiente del calendario (fecha y hora de esa sesión); el estudiante la
    autocalifica con la clave en `<details>` en esa sesión (2 min, dentro del bloque 5–10); el profesor registra entrega,
    no acierto, y revisa 3 al azar por parcial. En U4–U5 la tarea dice, con estas palabras: "Esta tarea no tiene
    peso propio; el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del Examen 3 toman
    ítems de aquí".
11. **Notas del estudiante** (≤ 2 páginas): el concepto con sus palabras clave, el ejemplo resuelto resumido,
    errores frecuentes, y "para saber más" (documentación oficial, no blogs).
12. **Plan de sesión**: llena el esqueleto de `02-plantilla-sesion.md` minuto a minuto. Debe poder darla otro
    profesor sin hablar contigo. La sección "Diferenciación" se llena con dos formas concretas: "Apoyo" es el
    mismo ejemplo resuelto con un hueco menos o una pista sellada en `<details>`; "Ampliación" es el problema sin
    ejemplo. "Prerrequisitos y vínculo" declara el nivel de andamiaje (A.5).
13. **Verifica** con la lista de cotejo de `02-plantilla-sesion.md` §4. Corrige lo que falle.

## B. Cómo escribir una práctica

Sigue `03-plantilla-practica.md` sección por sección. Además:

- Las Partes A y B se prueban en ≤ 90 minutos de laboratorio por un equipo promedio (≤ 55 min cuando el
  Laboratorio 1 abre con el ejemplo resuelto de un constructo nuevo: U3 S09, U4 S03, U5 S02). Un constructo que
  aparece por primera vez en el Laboratorio 1 entra en la Parte A como código completo para leer y predecir;
  nunca como `TODO` en la Parte B de esa misma sesión. La Parte C requiere trabajo fuera de clase. La Parte D usa
  `herramientas/protocolo-medicion.md` y `herramientas/graficar_speedup.py`.
- La solución de referencia completa (todas las partes) va en `docente/practicas/Pn/` con su propio `Makefile`
  y pasa `tests/run_tests.sh`. La carpeta pública solo tiene el código base con `TODO(n)`.
- Los casos de prueba públicos cubren lo básico; en `docente/` hay 2–3 casos adicionales para calificar.
- La rúbrica se instancia con criterios específicos de la práctica (no se copia la genérica tal cual). Ningún
  descriptor usa "claro", "adecuado", "sólido" o "útil" sin el dato que lo demuestra (modelo: filas Medición y
  Proceso e integridad de `03` §2).
- El pre-laboratorio de P6 incluye, obligatorio: "Antes del martes 24 de noviembre, verifica que obtienes GPU en
  Colab y en Kaggle (verificación telefónica hecha), anota el modelo asignado y reporta ese día si no pudiste."
  La correctitud de P6 se verifica sin GPU (`04-evaluacion.md`, §5).

## C. Cómo escribir un examen departamental

Sigue `04-evaluacion.md`. Entregables en `docente/examenes/En/`: `tabla-especificaciones.md`,
`examen-A.md`, `examen-B.md`, `clave-A.md`, `clave-B.md`, `instrucciones-aplicacion.md`. Además un
`examen-practica.md` público (versión corta, misma estructura, con clave en `<details>`) en la carpeta de la
sesión de repaso. Cada ítem de opción múltiple declara el origen de sus distractores. Los ítems de código se
compilaron y ejecutaron para obtener la salida correcta. Las versiones A y B cambian números, nombres y
orden de opciones, no el constructo medido.

## D. Cómo escribir material del proyecto

Rúbricas analíticas con cuatro niveles y pesos que suman 100; listas de cotejo para pares; plantillas que el
equipo llena (no ejemplos "para inspirarse"). Todo hito pide: qué se midió, cómo, y qué no se entiende todavía.

## E. Reglas de código para quien genera material

- Antes de dar por terminado un directorio con código: `make clean && make && make test` sin *warnings*.
- MPI en el entorno de autoría: `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1` si se
  ejecuta como root; `MPIRUN_FLAGS="--oversubscribe"`. El `Makefile` no debe depender de ser root.
- CUDA en el entorno de autoría: `nvcc -c -arch=sm_75 archivo.cu` debe compilar sin errores. La ejecución se
  documenta con la salida obtenida en Colab (o se marca "salida esperada" si no se pudo ejecutar) y, cuando el
  *kernel* tenga espejo en Numba, se verifica con `NUMBA_ENABLE_CUDASIM=1 python3 archivo_numba.py`.
- Los notebooks de Colab se generan con `nbformat` (válidos) y contienen: celda de verificación de GPU
  (`!nvidia-smi`), celdas `%%writefile` con el código, celda de compilación `!nvcc ...`, celda de ejecución y
  celda de medición. Se guardan como `notebook_colab.ipynb`.
- Tamaños por defecto: la versión secuencial de cualquier ejemplo corre en ≤ 5 s en 4 núcleos; las pruebas
  usan tamaños pequeños (≤ 1 s).
- Nada de rutas absolutas en el material. Nada de nombres de estudiantes.

## F. Reporte de autoría (lo que devuelve quien genera un bloque)

```
Carpeta: ...
Archivos creados: lista
Compilación: comandos y resultado (sin warnings / con estos warnings)
Pruebas: make test → PASS/FAIL por caso
Salidas verificadas: qué salidas "esperadas" del material se obtuvieron realmente al ejecutar
Lista de cotejo (02 §4): ítem por ítem ✓/✗
Pendientes o dudas para el profesor: lista
```

El profesor no revisa todo lo generado: aplica la revisión mínima de `01-marco-pedagogico.md`, §4 (20 min por
sesión) y muestrea el resto. Lo que falle se anota en "Notas post-sesión".
