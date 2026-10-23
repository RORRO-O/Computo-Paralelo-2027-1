# Calendario de sesiones · 15 de octubre – 17 de diciembre de 2026

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Horario: lunes 10:30–12:00 · martes 08:30–10:00 · jueves 10:30–12:00 · Salón 3208 / Lab LS4 (Edificio 3)

Fuente de fechas: calendario del grupo (hitos, exámenes y suspensiones ya registrados por el profesor).
Días sin clase: lunes 2 de noviembre (Día de Muertos) y lunes 16 de noviembre (Revolución Mexicana).

## Supuestos (confirmar o corregir)

1. La Unidad III (memoria compartida / OpenMP) inició el jueves 1 de octubre, después del Examen 1, y lleva seis
   sesiones (1, 5, 6, 8, 12 y 13 de octubre) que cubrieron el modelo de memoria compartida, regiones paralelas,
   `parallel for`, alcance de variables (`shared`/`private`/`firstprivate`), `reduction` y una primera
   medición de *speedup*. Las sesiones de este calendario se numeran S07–S13 por continuidad. Si algún tema de
   S07–S09 ya se vio, se usa su material como repaso y se adelanta el resto.
2. Las unidades IV y V son memoria distribuida (MPI) y GPU (CUDA), en ese orden, porque el Examen 3 cubre
   "Unidades IV–V" y la V3 del proyecto usa GPU en Colab/Kaggle.
3. El 2º parcial pondera 40 % examen · 40 % Práctica 4 · 20 % otros (H1 incluido), por simetría con el 1º.
4. Las sesiones del 14, 15 y 17 de diciembre siguen en el horario del grupo pero son posteriores a la "última
   sesión del curso" (10 de diciembre); se usan como reserva.

## Unidad III · Programación en memoria compartida (segunda mitad)

| # | Fecha | Tipo | Tema | Entregas / hitos | Carpeta |
|---|---|---|---|---|---|
| S07 | jue 15 oct 10:30 | Contenido | Corrección en memoria compartida: condiciones de carrera, `critical`, `atomic`, candados, `barrier`, `nowait`; ThreadSanitizer | Se publica Práctica 4 | `unidades/U3-memoria-compartida/S07_2026-10-15_sincronizacion/` |
| S08 | lun 19 oct 10:30 | Contenido | Planificación y balance de carga: `schedule(static/dynamic/guided, chunk)`, `collapse`, experimentos | Tarea espaciada | `.../S08_2026-10-19_planificacion/` |
| S09 | mar 20 oct 08:30 | Laboratorio | Práctica 4 · Lab 1: pre-lab, Partes A y B; paralelismo de tareas (`task`, `taskwait`, `taskloop`) con recursión | Pre-lab P4 | `.../S09_2026-10-20_tareas-lab1/` |
| S10 | jue 22 oct 10:30 | Contenido | Rendimiento: protocolo de medición, *speedup*/eficiencia/escalabilidad, Amdahl con datos, falso compartido, afinidad, sobrecarga | — | `.../S10_2026-10-22_rendimiento/` |
| S11 | lun 26 oct 10:30 | Contenido | Patrones: reducción manual, *scan*, *stencil* (Jacobi), *pipeline*; `omp simd` y vectorización | — | `.../S11_2026-10-26_patrones-simd/` |
| S12 | mar 27 oct 08:30 | Laboratorio | Práctica 4 · Lab 2: Partes C y D, punto de control, mini-defensas; taller: cómo paralelizar la V1 del proyecto | — | `.../S12_2026-10-27_lab2-proyecto/` |
| S13 | jue 29 oct 10:30 | Repaso + hito | **H1 · Avance 1 del proyecto** (V1 secuencial + Foster + perfilado). Repaso Unidad III: examen de práctica, corrección entre pares, calibración | H1 (en clase) · **P4: domingo 1 nov 23:59** | `.../S13_2026-10-29_H1-repaso/` |
| — | lun 2 nov | Sin clase | Día de Muertos | — | — |
| E2 | mar 3 nov 08:30 | **Examen** | **Examen departamental 2 · Unidad III** (versiones A/B, 80 min) | — | `docente/examenes/E2/` |

## Unidad IV · Programación en memoria distribuida (MPI)

| # | Fecha | Tipo | Tema | Entregas / hitos | Carpeta |
|---|---|---|---|---|---|
| S01 | jue 5 nov 10:30 | Contenido | Modelo de memoria distribuida y SPMD; `MPI_Init`, `Comm_rank`, `Comm_size`; compilar y ejecutar; mapeo del método de Foster a procesos | Se publica Práctica 5 | `unidades/U4-memoria-distribuida/S01_2026-11-05_modelo-spmd/` |
| S02 | lun 9 nov 10:30 | Contenido | Comunicación punto a punto: `Send`/`Recv`, etiquetas, `Status`, semántica de bloqueo e interbloqueo; *ping-pong* para latencia y ancho de banda | — | `.../S02_2026-11-09_punto-a-punto/` |
| S03 | mar 10 nov 08:30 | Laboratorio | Práctica 5 · Lab 1; colectivas: `Bcast`, `Scatter`, `Gather`, `Reduce`, `Allreduce`, `Barrier`; producto matriz-vector distribuido | Pre-lab P5 | `.../S03_2026-11-10_colectivas-lab1/` |
| S04 | jue 12 nov 10:30 | Contenido | Descomposición de dominio: distribución de datos, intercambio de halos (Jacobi 1D), `Isend`/`Irecv`/`Wait`, balance de carga | Retroalimentación E2 | `.../S04_2026-11-12_descomposicion-halos/` |
| — | lun 16 nov | Sin clase | Revolución Mexicana | — | — |
| S05 | mar 17 nov 08:30 | Laboratorio | Práctica 5 · Lab 2: mediciones, punto de control; rendimiento en MPI: modelo latencia + ancho de banda, escalabilidad fuerte y débil, sobre-suscripción; MPI+OpenMP híbrido (panorama) | — | `.../S05_2026-11-17_rendimiento-lab2/` |
| S06 | jue 19 nov 10:30 | Taller | Cierre de Unidad IV: tipos derivados y comunicadores (panorama), errores clásicos; taller del proyecto hacia H2 (V2 con *speedup*) | **P5: domingo 22 nov 23:59** | `.../S06_2026-11-19_cierre-taller-H2/` |

## Unidad V · Programación de GPU (CUDA en Colab/Kaggle)

| # | Fecha | Tipo | Tema | Entregas / hitos | Carpeta |
|---|---|---|---|---|---|
| S01 | lun 23 nov 10:30 | Contenido + hito | **H2 · Avance 2 del proyecto** (V2 memoria compartida + *speedup*). Arquitectura GPU vs CPU, SIMT, modelo CUDA: anfitrión/dispositivo, *kernels*, hilos/bloques/malla; suma de vectores en Colab | H2 (en clase) · Se publica Práctica 6 | `unidades/U5-gpu/S01_2026-11-23_H2-modelo-cuda/` |
| S02 | mar 24 nov 08:30 | Laboratorio | Práctica 6 · Lab 1; jerarquía de memoria: global, compartida, registros, constante; acceso coalescido; multiplicación de matrices ingenua vs. por mosaicos (*tiling*) | Pre-lab P6 | `.../S02_2026-11-24_memoria-tiling-lab1/` |
| S03 | jue 26 nov 10:30 | Contenido | Sincronización y reducción en GPU: `__syncthreads`, atómicas, reducción en árbol, *warps* y divergencia; verificación contra CPU | — | `.../S03_2026-11-26_sincronizacion-reduccion/` |
| S04 | lun 30 nov 10:30 | Contenido | Rendimiento en GPU: transferencias H2D/D2H, eventos, ocupación, tamaño de bloque, *streams* (panorama), *roofline* simple; perfilado en Colab | — | `.../S04_2026-11-30_rendimiento-gpu/` |
| S05 | mar 1 dic 08:30 | Laboratorio | Práctica 6 · Lab 2: mediciones y punto de control; taller V3 del proyecto (portar la V2 a GPU; alternativas Numba/CuPy) | — | `.../S05_2026-12-01_lab2-taller-V3/` |
| S06 | jue 3 dic 10:30 | Repaso | Repaso Unidades IV–V: examen de práctica, corrección entre pares, calibración; lista de cotejo de la entrega final | **P6: domingo 6 dic 23:59** | `.../S06_2026-12-03_repaso-E3/` |

## Cierre

| # | Fecha | Tipo | Tema | Entregas / hitos | Carpeta |
|---|---|---|---|---|---|
| C1 | lun 7 dic 10:30 | Taller | **Entrega final del proyecto** (V1·V2·V3 + reporte PDF) en el repositorio antes de las 10:30; taller de ensayo de defensa con lista de cotejo entre equipos | Entrega final | `proyecto/` |
| E3 | mar 8 dic 08:30 | **Examen** | **Examen departamental 3 · Unidades IV–V** (versiones A/B, 80 min) | — | `docente/examenes/E3/` |
| C2 | jue 10 dic 10:30 | Defensa | **Defensa oral**: 12 min por equipo + demo en vivo + preguntas individuales; cierre del curso | Defensa | `proyecto/defensa/` |

## Reserva

| Fecha | Uso previsto |
|---|---|
| lun 14 dic 10:30 | Retroalimentación del Examen 3 y del proyecto; publicación de calificaciones preliminares |
| mar 15 dic 08:30 | Defensas pendientes por causa justificada; segunda entrega de P6 si aplica |
| jue 17 dic 10:30 | Cierre administrativo; orientación para ETS a quien lo requiera |

## Carga por semana (orientativa, por estudiante, fuera de clase)

| Semana | Horas | Qué |
|---|---|---|
| 15–18 oct | 3 | Pre-lab P4, tarea espaciada |
| 19–25 oct | 5 | P4 Partes A–C, tarea |
| 26 oct – 1 nov | 6 | P4 Parte D y reporte, H1, estudio para E2 |
| 2–8 nov | 3 | Pre-lab P5, tarea |
| 9–15 nov | 5 | P5 Partes A–C |
| 16–22 nov | 6 | P5 Parte D y reporte, H2 |
| 23–29 nov | 5 | Pre-lab P6, P6 Partes A–B, V3 |
| 30 nov – 6 dic | 7 | P6 Partes C–D, V3, reporte final, estudio para E3 |
| 7–10 dic | 3 | Ensayo de defensa |
