> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Práctica 6 · publicada el lunes 23 de noviembre de 2026 · Lab 1 martes 24 de noviembre 08:30 · Lab 2 martes 1 de diciembre 08:30 · entrega domingo 6 de diciembre 23:59

# Práctica 6 · Qué se entrega, cómo y cuándo

Fuente de fechas y ponderaciones: `planeacion/mapa-evaluacion.md` y `planeacion/calendario-27-1.md`. Reglas de
entrega: `docs/metodo/04-evaluacion.md` §5. Si algo aquí las contradice, valen ellas.

## 1. Fechas

| Momento | Fecha y hora | Qué pasa |
|---|---|---|
| Publicación | lunes 23 de noviembre de 2026 (en la S01, 10:30) | Enunciado, código base, pruebas y rúbrica disponibles; se asigna el pre-laboratorio |
| Pre-laboratorio | **martes 24 de noviembre, antes de las 08:30** | Un archivo por integrante en el repositorio del equipo; falte o no el estudiante |
| Laboratorio 1 (S02) | martes 24 de noviembre, 08:30–10:00, Lab LS4 | Partes A y B; mini-defensas de la mitad de los equipos solo si hay más de 12 (lista publicada al inicio del laboratorio) |
| Entre sesiones | 25–30 de noviembre | Parte C; tarea espaciada de la S04 (lunes 30) produce el pre-mortem y la primera fila de la Parte D |
| Laboratorio 2 (S05) | martes 1 de diciembre, 08:30–10:00, Lab LS4 | Parte D, punto de control (una tabla por equipo, 1 min), mini-defensas (todas; con más de 12 equipos, la mitad que no se defendió el 24) |
| **Fecha límite** | **domingo 6 de diciembre de 2026, 23:59** | Entrega en el repositorio del equipo (etiqueta `P6`) |
| Primera sesión después | lunes 7 de diciembre, 10:30 | 5 min: un integrante al azar de 2–3 equipos explica qué cambió desde el laboratorio |
| Retroalimentación | a más tardar el jueves 10 de diciembre | Salida de `tests/run_tests.sh` + nivel por criterio + ≤ 2 líneas por criterio |
| Segunda entrega (solo si la primera obtiene < 70 %) | hasta el martes 15 de diciembre, 08:30 | Una sola vez, con nota de cambios; tope 80 % |
| Medición en GPU pendiente por cuota (ver §6) | a más tardar el martes 15 de diciembre, 08:30 | Sin penalización si se entregó a tiempo con la evidencia |
| Mini-defensa pendiente (ver §4) | a más tardar el martes 15 de diciembre, 08:30 | Video no listado de ≤ 3 min (dos fragmentos de su código que elige el profesor), solo si no hubo laboratorio para reponerla o el estudiante no pudo asistir |

Ponderación: **15 % del 3er parcial**. Entrega tardía dentro de las 72 h siguientes: máximo 80 %; después no se
recibe salvo justificante institucional. Una entrega tardía no tiene segunda entrega.

## 2. Dónde

Repositorio **privado** del equipo (el mismo de P4 y P5, con el profesor como colaborador), carpeta `practicas/P6/`:

```
practicas/P6/
  prelab/<alias>.md                 un archivo por integrante (§3)
  src/                              a_vectores.cu, a_vectores_numba.py, a_matmul_tiled.cu, a_matmul_numba.py,
                                    b_matmul_rect.cu y b_matmul_rect_numba.py (TODO corregidos),
                                    c_<nombre>.cu (tu Parte C; y c_<nombre>_numba.py si hiciste el espejo),
                                    las referencias *_cpu.c y common.cuh tal como vienen (si cambias una, dilo)
  tests/run_tests.sh                el del curso; puedes agregar casos propios (cuenta en la rúbrica)
  Makefile, graficar.py             los del curso
  notebook_colab.ipynb              EJECUTADO, con las salidas visibles (nvidia-smi, compilación, corridas, tablas)
  resultados/                       CSV (uno por sesión de medición), las tres PNG, entorno.txt; ver resultados/README.md
  REPORTE.md                        ≤ 3 páginas, plantilla en herramientas/plantilla-reporte-practica.md
```

El código se edita en el repositorio y se pega en el *notebook* (o se clona desde Colab); lo que cambies en Colab lo
copias de regreso y haces *commit* desde tu laptop. Cada integrante necesita ≥ 3 *commits* con cambios de código.
Al terminar: `git tag P6` y `git push --tags`. Se califica el *commit* etiquetado.

## 3. Pre-laboratorio (individual; 20 min; antes del martes 24 de noviembre, 08:30)

Archivo `practicas/P6/prelab/<alias>.md` (tu alias de Git, sin nombre completo). Plantilla:

```markdown
# Pre-laboratorio P6 · <alias>

## Verificación de GPU (obligatoria)
- Colab: GPU obtenida el <fecha y hora> · modelo según nvidia-smi: <Tesla T4 / ...> · compute_cap: <7.5>
- Kaggle (teléfono verificado): GPU obtenida el <fecha y hora> · modelo: <T4 / P100> · cuota semanal mostrada: <h>
- Si en alguna no pudiste: <plataforma, mensaje exacto y fecha>; lo reporto el martes 24 en la S02.

## Preguntas (README, sección "Pre-laboratorio")
1. ...
2. ...
3. ...
4. ...

## Lectura
Leí: notas-estudiante de S01 y S02, herramientas/colab-kaggle.md §2–§3. Lo que menos entendí: <una línea>

## Predicción (se compara en la Parte D)
- n a partir del cual la GPU gana a un núcleo de CPU en saxpy, SOLO kernel: n ≈ 2^__ porque ...
- n a partir del cual gana CON copias H2D/D2H: n ≈ 2^__ (o "nunca en el rango medido") porque ...
- Speedup esperado con n = 2^24: S_kernel ≈ __ y S_total ≈ __ porque ...
- Mejor tamaño de bloque para saxpy: __ hilos porque ...
```

La pregunta 1 de la recuperación de la S02 lo verifica. Quien no pudo obtener GPU en alguna plataforma lo escribe
en el archivo y lo dice al entrar al laboratorio: se le empareja con un equipo que sí la tenga.

## 4. Qué se revisa en cada laboratorio

**Lab 1 (martes 24 de noviembre).** Al minuto 80: las tablas de predicción de la Parte A (A.1 y A.7) llenas y
contrastadas con lo observado; `make test` en verde (los dos casos de la Parte B pueden estar en `PEND`);
`make test-b` en verde o, si no, los `TODO` que faltan identificados por número (lo que no quede se termina en casa
antes del martes 1 de diciembre). Mini-defensas, solo si hay más de 12 equipos: hoy se defiende la mitad de la lista
publicada al inicio del laboratorio. Mini-defensa (2 min por equipo, en orden al azar): una pregunta por integrante
sobre el código en pantalla ("¿qué hace esta línea?"); la segunda ("¿qué pasaría si la quito?") solo si la primera
falla; cuenta la mejor de las dos. Líneas preferidas: cada `__syncthreads()` y el `? … : 0.0f` de la carga de
`a_matmul_tiled.cu`, la guardia de escritura (Parte A y `TODO(4)` de la Parte B), el `cudaEventSynchronize` y el
`cudaGetLastError` tras el lanzamiento.

**Lab 2 (martes 1 de diciembre).** Punto de control (minuto 38–50): cada equipo proyecta **una** tabla de la Parte D
y la explica en 1 minuto. Tabla aceptable: dos tiempos (sin y con copias), mediana de 5 tras calentamiento, `T(1)`
declarado (referencia CPU de la misma máquina, `-O2`), GPU y fecha, al menos tres tamaños de bloque múltiplos de 32.
Mini-defensas de todos los equipos (con más de 12, de la mitad que no se defendió el 24), con las mismas reglas. Quien
pide responder por escrito lo hace en el momento (5 min, papel).

**Mini-defensa pendiente** (`docs/metodo/04-evaluacion.md` §5). Se repone en el siguiente laboratorio. Si ya no hay uno
antes del cierre (después del Lab 2 no hay otro) o el estudiante no puede asistir, envía un video no listado de ≤ 3 min
en el que explica dos fragmentos de su código que elige el profesor, a más tardar el **martes 15 de diciembre, 08:30**.

## 5. Lista de cotejo antes de entregar

- [ ] `make clean && make && make test` termina con código 0 y sin *warnings*, **y** `make test-b` también (los
      `TODO` de la Parte B corregidos en el `.cu` y en el espejo Numba, `TODO_LISTO` en 1/`True`, y `make notebook`
      corrido después de editar).
- [ ] `src/c_<nombre>.cu` compila con `nvcc -c -arch=sm_75` y con `-arch=sm_60`; su salida en GPU coincide con la
      referencia CPU en los tamaños que pide el README (exacta en histograma/reducción; con tolerancia en Jacobi).
- [ ] `notebook_colab.ipynb` está ejecutado: se ve `nvidia-smi` con la GPU, la compilación sin errores, `OK` en todas
      las verificaciones y las celdas de medición con sus tablas.
- [ ] `resultados/`: CSV con `origen=gpu`, barrido de bloque 32…1024 para los *kernels* de la Parte A y el de la
      Parte C, barrido `umbral` de `n`, filas `matmul_naive`/`matmul_tiled` con `n = 512, 1024, 2048` y tres `TILE`,
      filas `matmul_rect_*` de las tres formas de la Parte B; las tres PNG; `entorno.txt` con modelo de GPU y fecha.
- [ ] `REPORTE.md` ≤ 3 páginas con: entorno (GPU, fecha, CPU), decisiones de diseño con dato, predicción del pre-lab
      frente a lo medido, tabla, gráficas, las tres preguntas de interpretación de la Parte D respondidas con un
      número cada una, reflexión individual (una por integrante), bitácora de errores (≥ 3 entradas), reparto de
      trabajo (coincide con `git log`), declaración de uso de IA (cuatro líneas).
- [ ] Sin nombres completos ni correos en el repositorio; rutas relativas; imágenes del reporte visibles en GitHub.
- [ ] Etiqueta `P6` en el *commit* final.

## 6. Si no hay GPU

La correctitud de esta práctica se verifica **sin** GPU (`make test`, `make test-b`, CUDASIM) y nunca depende de la
cuota. Si Colab **y** Kaggle te niegan GPU en las 48 h previas al domingo 6 de diciembre:

1. Entrega a tiempo con la captura **fechada** del aviso de cuota (`herramientas/colab-kaggle.md` §9, "Captura 7")
   en `resultados/`, la Parte D marcada como "pendiente" en `REPORTE.md` y el CSV con las filas de GPU que sí
   alcanzaste (o vacío).
2. Avisa al profesor el mismo día por el canal del curso.
3. Completa la medición en cuanto haya cuota y a más tardar el **martes 15 de diciembre, 08:30**, sin penalización:
   nuevo *commit* con el CSV, las PNG, `entorno.txt` y la Parte D del reporte.

Antes de eso: cambia de plataforma (Colab y Kaggle no comparten cuota), reintenta en otro horario (madrugada u hora
de comida), y no dejes el cuaderno conectado sin usar (gasta cuota). Reparto recomendado en equipos de 3: una cuenta
mide, dos quedan de reserva para la última semana; nadie comparte cuentas ni crea cuentas adicionales.

## 7. Cómo se califica

1. El profesor clona el *commit* etiquetado y corre `make clean && make && make test` y `make test-b`; además corre
   los casos extra de calificación (`EXTRA=1 bash tests/run_tests.sh`: vectores con `n = 1` y `n = 1025` con bloque
   1024; mosaicos `17×17` con `TILE = 16` y `24×24` con `TILE = 8`; Parte B (`M×K×N`) con `1×37×3` y `17×33×5` con
   `TILE = 16`, y `33×8×17` y `12×20×30` con `TILE = 8`) y tu `src/c_<nombre>.cu` en Colab con los tamaños del README.
2. Lee `REPORTE.md` y abre el *notebook* ejecutado y las PNG.
3. Aplica `rubrica.md` criterio por criterio; el criterio "Proceso e integridad" se ajusta **por integrante** con la
   hoja de registro de las mini-defensas y `git log`.
4. Devuelve: salida de `run_tests.sh`, nivel por criterio, ≤ 2 líneas por criterio, y un documento grupal con los
   tres errores más frecuentes del grupo (a más tardar el jueves 10 de diciembre).
