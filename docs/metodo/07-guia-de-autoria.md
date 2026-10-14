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
   descripción), porcentaje de acierto esperado en el primer voto, guion de 3 líneas para la discusión.
8. **Recuperación de inicio** (4–5 preguntas): 2 de la sesión anterior, 1–2 de unidades previas (I–II o anteriores),
   1 que anticipe el tema. Respuestas en `<details>`. Deben contestarse en ≤ 4 minutos sin apuntes.
9. **Exit ticket**: 2 preguntas (una conceptual, una de aplicación corta) + "¿Qué tan seguro estás? (1–4) ¿Qué
   te quedó menos claro?". Clave en `<details>`.
10. **Tarea espaciada** (20–40 min): 1 ejercicio del tema, 1 intercalado (unidad previa), 1 de preparación de
    la siguiente sesión (lectura breve o pregunta de predicción). Indica cómo se entrega y qué cuenta.
11. **Notas del estudiante** (≤ 2 páginas): el concepto con sus palabras clave, el ejemplo resuelto resumido,
    errores frecuentes, y "para saber más" (documentación oficial, no blogs).
12. **Plan de sesión**: llena el esqueleto de `02-plantilla-sesion.md` minuto a minuto. Debe poder darla otro
    profesor sin hablar contigo.
13. **Verifica** con la lista de cotejo de `02-plantilla-sesion.md` §4. Corrige lo que falle.

## B. Cómo escribir una práctica

Sigue `03-plantilla-practica.md` sección por sección. Además:

- Las Partes A y B se prueban en ≤ 90 minutos de laboratorio por un equipo promedio. La Parte C requiere
  trabajo fuera de clase. La Parte D usa `herramientas/protocolo-medicion.md` y `herramientas/graficar_speedup.py`.
- La solución de referencia completa (todas las partes) va en `docente/practicas/Pn/` con su propio `Makefile`
  y pasa `tests/run_tests.sh`. La carpeta pública solo tiene el código base con `TODO(n)`.
- Los casos de prueba públicos cubren lo básico; en `docente/` hay 2–3 casos adicionales para calificar.
- La rúbrica se instancia con criterios específicos de la práctica (no se copia la genérica tal cual).

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
