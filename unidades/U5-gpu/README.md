> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Índice de la unidad · S01–S06 · lunes 23 de noviembre a jueves 3 de diciembre de 2026 · Salón 3208 / Lab LS4 (Edificio 3)

# Unidad V · Programación de GPU con CUDA (Colab/Kaggle)

Esta carpeta tiene las seis sesiones que van del **lunes 23 de noviembre al jueves 3 de diciembre de 2026**
(S01–S06), los enlaces a la Práctica 6 y al proyecto (recepción de H2 y construcción de la V3) y la
[guía de estudio del Examen 3](guia-estudio-E3.md). La unidad recorre el arco de siempre
(`docs/metodo/01-marco-pedagogico.md` §3.2): **concepto** (S01: por qué GPU, SIMT y el modelo CUDA) →
**herramienta** (S02–S03: memoria compartida, mosaicos, barreras, atómicas y reducción) → **rendimiento** (S04:
eventos, transferencias, ocupación, *roofline*) → **proyecto** (S05: taller de la V3) → **repaso** (S06). Lo que se
ve aquí entra en el **Examen 3** (martes 8 de diciembre, 08:30), junto con la Unidad IV.

La GPU vive en la nube (Colab o Kaggle). La **correctitud** de todo lo que haces en la unidad se verifica **sin**
GPU (`make test`, `nvcc -c` y el simulador de Numba); la GPU solo se necesita para **medir**. Nadie depende de una
cuota que no controla (`docs/metodo/04-evaluacion.md` §5).

| Si eres… | Empieza por… |
|---|---|
| Estudiante que va al día | La carpeta de la sesión de hoy: `retrieval-inicio.md` en clase; `notas-estudiante.md` y `tarea-espaciada.md` después |
| Estudiante que faltó | [§5 · Cómo recuperar una sesión perdida](#5-cómo-recuperar-una-sesión-perdida) |
| Estudiante que hace la Práctica 6 | [`practicas/P6-gpu/README.md`](../../practicas/P6-gpu/README.md) y el calendario de [§3.2](#32-calendario-de-la-unidad-fecha-por-fecha) |
| Estudiante que hoy no tiene GPU | [§4 · Requisitos de software](#4-requisitos-de-software), fila "Sin GPU" |
| Estudiante que prepara el Examen 3 | [`guia-estudio-E3.md`](guia-estudio-E3.md) y el [examen de práctica](S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) de S06 |
| Profesor que da la sesión | `plan-sesion.md` y `conceptests.md` de la carpeta ([§8](#8-para-el-profesor)) |

## 1. Objetivos de la unidad

Al terminar la unidad (jueves 3 de diciembre) podrás, **sin computadora y en papel** salvo donde se indica:

1. **Explicar** con los números de una Tesla T4 (40 SM, *warps* de 32, 2560 "núcleos CUDA") por qué una GPU
   está orientada a rendimiento y no a latencia, y **justificar** por qué lanzar 16 millones de hilos es normal y no
   un error. (S01)
2. **Calcular**, dados `n` y el tamaño de bloque, el número de bloques con redondeo hacia arriba, el índice global
   de cualquier hilo y los hilos ociosos, y **escribir** la guardia que impide que escriban; en una malla 2D
   aplanada, **calcular** el índice lineal de una celda y el `blockIdx`/`threadIdx` que la procesa. (S01, S05)
3. En computadora, **compilar, ejecutar y verificar** un *kernel* CUDA C en Colab o Kaggle y su espejo en Numba con
   `NUMBA_ENABLE_CUDASIM=1`, revisando `cudaGetLastError()`/`cudaDeviceSynchronize()` **y** comparando contra la
   CPU con tolerancia; **mostrar** con un ejemplo propio que "no dio error" no es "es correcto". (S01–S05)
4. **Clasificar** los espacios de memoria de la GPU (registros, compartida, global, constante) por alcance, vida y
   latencia relativa; **decidir**, leyendo la expresión de índice, si un acceso de un *warp* es coalescido, y
   **reescribirlo** para que lo sea. (S02)
5. **Calcular** las lecturas a memoria global de la multiplicación ingenua y por mosaicos para `n` y `TILE` dados,
   y **explicar** qué protege cada `__syncthreads()` y por qué los hilos de borde cargan ceros en lugar de hacer
   `return`. (S02; Práctica 6, Partes A y B)
6. **Explicar** qué sincroniza `__syncthreads()` (el bloque, no la GPU) y cómo se combinan resultados entre
   bloques; **contar** las atómicas globales, los niveles y los *warps* divergidos de cada versión de la reducción
   y **elegir** la adecuada con un dato; **diagnosticar** una carrera en memoria compartida y un árbol con bloque
   que no es potencia de 2. (S03)
7. En computadora, **medir** con `cudaEvent_t` las copias H2D, el *kernel* y la copia D2H por separado con el
   protocolo del curso, y **determinar** con una tabla a partir de qué `n` conviene la GPU con y sin copias. (S04;
   Práctica 6, Parte D)
8. **Explicar** un barrido de tamaño de bloque con *warps*, bloques residentes por SM y ocupación, y **clasificar**
   un *kernel* como limitado por memoria o por cómputo con su intensidad aritmética. (S04)
9. **Planear y justificar** el porte de la V2 del proyecto a GPU en seis pasos (identificar, aplanar, mapear, mover
   una vez, verificar contra la V1, medir) y **distinguir** lo que cuenta como V3 de lo que no. (S05)
10. **Localizar y corregir** en código MPI y CUDA corto errores que no producen mensaje (colectiva que llama solo
    la raíz, *kernel* sin guardia, reducción sin barrera), **resolver** en 40 minutos un examen con la estructura del
    Examen 3 y **calcular** tu brecha de calibración. (S06)

## 2. Sesiones

Horario del grupo: lunes y jueves 10:30–12:00 en el Salón 3208; martes 08:30–10:00 en el Lab LS4. Cada carpeta
tiene `plan-sesion.md`, `retrieval-inicio.md`, `notas-estudiante.md`, `ejemplo-resuelto.md`, `conceptests.md`,
`practica-guiada/` (código, `Makefile`, `tests/` y `notebook_colab.ipynb`), `exit-ticket.md` y `tarea-espaciada.md`.

| Sesión | Fecha y lugar | Tipo | Tema | Carpeta | Práctica guiada (PRIMM) |
|---|---|---|---|---|---|
| S01 | lunes 23 de noviembre, 10:30 · 3208 | Contenido + hito | **Recepción de H2** (20 min). CPU orientada a latencia vs. GPU orientada a rendimiento; SIMT, *warps* y SM; modelo CUDA: anfitrión/dispositivo, *kernel*, hilos/bloques/malla, índice global, guardia; suma de vectores en Colab. **Se publica la Práctica 6** | [`S01_2026-11-23_H2-modelo-cuda/`](S01_2026-11-23_H2-modelo-cuda/) | [Suma de vectores en CUDA](S01_2026-11-23_H2-modelo-cuda/practica-guiada/README.md) |
| S02 | martes 24 de noviembre, 08:30 · LS4 | Laboratorio (constructo nuevo) | Jerarquía de memoria (registros, compartida, global, constante), acceso coalescido, multiplicación ingenua vs. por mosaicos (*tiling*) + **Práctica 6 · Laboratorio 1** (Partes A y B, mini-defensas). **Pre-lab de P6** | [`S02_2026-11-24_memoria-tiling-lab1/`](S02_2026-11-24_memoria-tiling-lab1/) | [Multiplicación de matrices: ingenua vs. por mosaicos](S02_2026-11-24_memoria-tiling-lab1/practica-guiada/README.md) (PRIMM corto) |
| S03 | jueves 26 de noviembre, 10:30 · 3208 | Contenido | `__syncthreads()` y su alcance, atómicas y contención, reducción en árbol en tres versiones, *warps* y divergencia, histograma privado por bloque; verificar contra la CPU con tolerancia o exacto | [`S03_2026-11-26_sincronizacion-reduccion/`](S03_2026-11-26_sincronizacion-reduccion/) | [Reducción en tres versiones e histograma con atómicas](S03_2026-11-26_sincronizacion-reduccion/practica-guiada/README.md) |
| S04 | lunes 30 de noviembre, 10:30 · 3208 | Contenido | Rendimiento en GPU: eventos `cudaEvent_t`, transferencias H2D/D2H, umbral de tamaño, tamaño de bloque y ocupación, memoria *pinned* y *streams* (panorama), *roofline* simple, perfilado con `nsys` en Colab | [`S04_2026-11-30_rendimiento-gpu/`](S04_2026-11-30_rendimiento-gpu/) | [¿Cuánto tarda de verdad mi *kernel*?](S04_2026-11-30_rendimiento-gpu/practica-guiada/README.md) |
| S05 | martes 1 de diciembre, 08:30 · LS4 | Laboratorio + taller | **Práctica 6 · Laboratorio 2** (Parte D, punto de control, mini-defensas) + **taller V3**: portar la V2 a GPU (aplanar, mapear, mover una vez, verificar, medir; qué cuenta como V3) | [`S05_2026-12-01_lab2-taller-V3/`](S05_2026-12-01_lab2-taller-V3/) | [Mini PRIMM "aplanar y mapear" + plantilla del plan V3](S05_2026-12-01_lab2-taller-V3/practica-guiada/README.md) ([`plan-V3.md`](S05_2026-12-01_lab2-taller-V3/practica-guiada/plan-V3.md)) |
| S06 | jueves 3 de diciembre, 10:30 · 3208 | Repaso | Repaso de Unidades IV–V: [examen de práctica](S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) (40 min, 60 puntos), corrección entre pares, cazador de errores, calibración; lista de cotejo de la entrega final entre equipos; anuncio del formato de la defensa | [`S06_2026-12-03_repaso-E3/`](S06_2026-12-03_repaso-E3/) | [Cazador de errores de Unidades IV–V](S06_2026-12-03_repaso-E3/practica-guiada/README.md) |

Para correr una práctica guiada **sin GPU**: `cd <carpeta>/practica-guiada && make && make test` (todas tienen
`all`, `run`, `test` y `clean`). `make` compila los `.cu` con `nvcc -c` si tienes `nvcc` y las referencias en C con
`gcc`; `make test` corre las referencias y los espejos en Numba con el simulador. `make run` necesita GPU: en clase
se usa el `notebook_colab.ipynb` de cada carpeta. En S06 hay además `make cazar`, `make run-mpi` y `make
run-examen`. Los `SKIP` que ves al inicio son sobre todo las fases Modificar y Crear que completas tú; los demás
dicen en su línea qué falta (por ejemplo, en S05, la GPU para `make run`).

## 3. Entregas, hitos y fechas

Ponderaciones del 3.er parcial según [`planeacion/mapa-evaluacion.md`](../../planeacion/mapa-evaluacion.md):
Examen 3, 30 %; Práctica 5, 15 %; Práctica 6, 15 %; proyecto integrador, 40 % (de sus 100 puntos: H2, 15; repositorio
de la entrega final, 40; reporte, 30; defensa, 15). En el 3.er parcial las tareas espaciadas y los *exit tickets*
**no tienen peso propio** ([`docs/metodo/04-evaluacion.md`](../../docs/metodo/04-evaluacion.md) §1): se entregan
igual, se registran, y el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del Examen 3 toman
ítems de las tareas. Entrega tardía y segunda entrega: `04-evaluacion.md` §5.

### 3.1 Lo que cuenta para la calificación

| Entrega | Fecha límite | Peso | Dónde y cómo |
|---|---|---|---|
| **Práctica 6 · GPU** (en equipo, 2–3 integrantes, los de P4 y P5) | **domingo 6 de diciembre, 23:59** (etiqueta `P6`) | **15 %** del 3.er parcial | [`practicas/P6-gpu/`](../../practicas/P6-gpu/README.md): enunciado, [`entrega.md`](../../practicas/P6-gpu/entrega.md) y [`rubrica.md`](../../practicas/P6-gpu/rubrica.md). Pre-laboratorio individual antes del martes 24 de noviembre, 08:30, con la **verificación de GPU en Colab y en Kaggle**. Lab 1 (24 de noviembre): Partes A y B; Parte C entre el 25 y el 30 de noviembre; Lab 2 (1 de diciembre): Parte D, punto de control y mini-defensas. Tardía hasta el miércoles 9 de diciembre, 23:59, con máximo 80 % y sin segunda entrega. Retroalimentación a más tardar el jueves 10 de diciembre. Segunda entrega solo si la primera obtiene < 70 %: hasta el martes 15 de diciembre, 08:30, con tope de 80 %. Sin GPU en las 48 h previas: captura fechada del aviso de cuota y medición pendiente, que se completa a más tardar el martes 15 de diciembre, 08:30, sin penalización (`entrega.md` §6) |
| **H2 · Avance 2 del proyecto** (en equipo) | **lunes 23 de noviembre**: etiqueta `H2` antes de las **10:30**; recepción en clase (S01) | **15 puntos** del proyecto | [`proyecto/hitos/H2-avance-2.md`](../../proyecto/hitos/H2-avance-2.md): V2 con OpenMP correcta frente a V1, tabla de *speedup* y eficiencia con el protocolo, Karp–Flatt, decisiones justificadas y `reporte/H2.md` con "Hacia V3". Tardía hasta el jueves 26 de noviembre, 10:30, con máximo 80 %. Lista de cotejo rápida el mismo día; rúbrica por escrito a más tardar el lunes 30 de noviembre. La pregunta individual sigue la opción anunciada el jueves 19 de noviembre (`H2-avance-2.md` §8; el plan de S01 está escrito con la opción A: se hace durante la práctica guiada y las que falten, al inicio de S02) |
| **Examen departamental 3** (individual) | **martes 8 de diciembre, 08:30–10:00** | **30 %** del 3.er parcial | Ver §3.3 y la [guía de estudio](guia-estudio-E3.md) |
| **Entrega final del proyecto** (en equipo; justo después de la unidad) | **lunes 7 de diciembre, 10:30** (etiqueta `entrega-final`) | **40 + 30 puntos** del proyecto | [`proyecto/entrega-final/README.md`](../../proyecto/entrega-final/README.md): V1·V2·V3 + `reporte/reporte.pdf`. La [lista de cotejo](../../proyecto/entrega-final/lista-cotejo-entrega.md) se aplica entre equipos en S06. Tardía hasta el jueves 10 de diciembre, 10:30, con máximo 80 % |
| **Defensa oral** (en equipo, preguntas individuales) | **jueves 10 de diciembre, 10:30** | **15 puntos** del proyecto; ajusta la calificación individual | [`proyecto/defensa/`](../../proyecto/defensa/logistica-defensa.md): el profesor anuncia el formato a más tardar en S06 (jueves 3 de diciembre) |

**Hitos del proyecto dentro de la unidad.** H2 se recibe el primer día de la unidad (lunes 23 de noviembre, S01).
Ningún otro hito vence entre el 23 de noviembre y el 3 de diciembre, pero la **V3 se construye aquí**: el primer
*kernel* en S01, la reducción para normas y residuos en S03, la medición con y sin copias en S04 y el plan de porte
en el taller de S05 (`plan-V3.md`). La V3 se mide **en la semana del 30 de noviembre**, no el fin de semana del 5–6
de diciembre (`04-evaluacion.md` §5). En S06 cada equipo revisa el repositorio de otro con la lista de cotejo de la
entrega final, que vence el lunes 7 de diciembre a las 10:30; la defensa es el jueves 10.

### 3.2 Calendario de la unidad, fecha por fecha

| Fecha y hora | Qué pasa o qué se entrega | Archivo de referencia |
|---|---|---|
| lunes 23 de noviembre, 10:30 (S01) | **H2** (etiqueta antes de las 10:30). Tarea de U4·S06. Se publica la **Práctica 6** | [H2](../../proyecto/hitos/H2-avance-2.md) · [P6 `README.md`](../../practicas/P6-gpu/README.md) |
| martes 24 de noviembre, 08:30 (S02) | **Pre-laboratorio de la Práctica 6**, individual, en `practicas/P6/prelab/<alias>.md` del repositorio del equipo, **faltes o no**, con la verificación de GPU en Colab y Kaggle. Tarea de S01 (`tareas/U5-S01.md`). Laboratorio 1: Partes A y B; mini-defensas (la mitad de los equipos si hay más de 12) | [P6 `README.md`](../../practicas/P6-gpu/README.md), "Pre-laboratorio" · [P6 `entrega.md`](../../practicas/P6-gpu/entrega.md) §3–§4 · [S01 `tarea-espaciada.md`](S01_2026-11-23_H2-modelo-cuda/tarea-espaciada.md) |
| miércoles 25 de noviembre, 23:59 | Último momento para la entrega tardía de P5 (máximo 80 %) | [P5 `entrega.md`](../../practicas/P5-mpi/entrega.md) §1 |
| 25–30 de noviembre | Parte C de la Práctica 6 (≈ 3 h; histograma y reducción, *stencil* de Jacobi o el *kernel* caliente del proyecto) | [P6 `README.md`](../../practicas/P6-gpu/README.md), Parte C |
| jueves 26 de noviembre, 10:30 (S03) | Tarea de S02 (`tarea-S02.md` en el repositorio del equipo, o en papel). Cierra la ventana de entrega tardía de H2 | [S02 `tarea-espaciada.md`](S02_2026-11-24_memoria-tiling-lab1/tarea-espaciada.md) |
| domingo 29 de noviembre | Retroalimentación de la Práctica 5 (a más tardar) | [P5 `entrega.md`](../../practicas/P5-mpi/entrega.md) §1 |
| lunes 30 de noviembre, 10:30 (S04) | Tarea de S03 (`tareas/U5-S03.md`, con el CSV del *notebook* si lo corriste en GPU). Rúbrica escrita de H2 (a más tardar) | [S03 `tarea-espaciada.md`](S03_2026-11-26_sincronizacion-reduccion/tarea-espaciada.md) |
| martes 1 de diciembre, 08:30 (S05) | Tarea de S04 (`practicas/P6/resultados/tarea-S04.md`, uno por integrante: el pre-mortem y la primera fila de la Parte D). Laboratorio 2: Parte D, punto de control, mini-defensas pendientes; taller V3 | [S04 `tarea-espaciada.md`](S04_2026-11-30_rendimiento-gpu/tarea-espaciada.md) · [P6 `entrega.md`](../../practicas/P6-gpu/entrega.md) §4 |
| jueves 3 de diciembre, 10:30 (S06) | Tarea de S05 (`tareas/U5-S05.md` en el repositorio del equipo: ejercicio 1 en equipo, 2 y 3 individuales). Examen de práctica; cotejo de la entrega final; anuncio del formato de la defensa | [S05 `tarea-espaciada.md`](S05_2026-12-01_lab2-taller-V3/tarea-espaciada.md) · [examen de práctica](S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) |
| domingo 6 de diciembre, 23:59 | **Práctica 6 completa** (etiqueta `P6`) | [P6 `entrega.md`](../../practicas/P6-gpu/entrega.md) §2 y §5 |
| lunes 7 de diciembre, 10:30 (C1) | **Entrega final del proyecto** (etiqueta `entrega-final`). Tarea de S06 (`tareas/U5-S06.md`). Un integrante de 2–3 equipos explica qué cambió en su P6 desde el laboratorio (5 min). Se confirma el aula del Examen 3 | [entrega final](../../proyecto/entrega-final/README.md) · [S06 `tarea-espaciada.md`](S06_2026-12-03_repaso-E3/tarea-espaciada.md) |
| martes 8 de diciembre, 08:30 | **Examen 3** (Unidades IV–V) | [guía de estudio](guia-estudio-E3.md) |
| miércoles 9 de diciembre, 23:59 | Último momento para la entrega tardía de P6 (máximo 80 %) | [P6 `entrega.md`](../../practicas/P6-gpu/entrega.md) §1 |
| jueves 10 de diciembre, 10:30 (C2) | **Defensa oral**. Retroalimentación de la P6 (a más tardar). Cierra la entrega tardía del proyecto | [defensa](../../proyecto/defensa/logistica-defensa.md) |
| lunes 14 de diciembre, 10:30 | Reserva: retroalimentación del Examen 3 y del proyecto | [calendario](../../planeacion/calendario-27-1.md), "Reserva" |
| martes 15 de diciembre, 08:30 | Reserva: segunda entrega de P6 (si aplica), mediciones de GPU pendientes por cuota (P6 y V3), mini-defensas y defensas pendientes por causa justificada | [P6 `entrega.md`](../../practicas/P6-gpu/entrega.md) §1 y §6 |

Cada `tarea-espaciada.md` dice en su encabezado dónde se entrega y la tabla copia lo que dice cada una. Carga
orientativa fuera de clase (`planeacion/calendario-27-1.md`): 5 h la semana del 23 al 29 de noviembre (pre-lab de
P6, Partes A–B, V3) y 7 h la del 30 de noviembre al 6 de diciembre (P6 Partes C–D, V3, reporte final, estudio para
el Examen 3).

### 3.3 Examen 3

| | |
|---|---|
| Fecha | **martes 8 de diciembre de 2026, 08:30–10:00** (Salón 3208, o Lab LS4 con los equipos apagados y filas alternas; el aula se confirma el lunes 7) |
| Cubre | **Unidades IV–V** (MPI y GPU), con 10–20 % de unidades previas **integrado** en los problemas (*speedup*, eficiencia, Amdahl, Karp–Flatt, carreras), no en una sección aparte |
| Formato | Versiones A/B, 80 minutos efectivos, 100 puntos, seis secciones, individual, sin dispositivos ni hoja de fórmulas; hoja de calibración aparte (no afecta la calificación). Zona sin IA |
| Preparación | [`guia-estudio-E3.md`](guia-estudio-E3.md): temario con peso por tema, 30 preguntas de recuperación con respuesta, plan de 5 días. El [examen de práctica](S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) de S06 y su clave. Las tareas espaciadas de U4–U5 (de ahí salen ítems) y los ConcepTests de cada sesión |
| Devolución | Calificación y clave en ≤ 7 días; la reserva del lunes 14 de diciembre está prevista para la retroalimentación |

## 4. Requisitos de software

| Qué | Para qué en esta unidad | Notas |
|---|---|---|
| Cuenta de Google con **Colab** | Ejecutar y **medir** en GPU: el `notebook_colab.ipynb` de cada práctica guiada y de la P6 | *Entorno de ejecución → Cambiar tipo de entorno de ejecución → T4 GPU*. La cuota es dinámica y desconecta tras ~90 min sin actividad: mide en sesiones cortas y guarda al terminar. Paso a paso en [`herramientas/colab-kaggle.md`](../../herramientas/colab-kaggle.md) |
| Cuenta de **Kaggle** con teléfono verificado | Alternativa a Colab (T4 x2 o P100; 30 h por semana) | Sin teléfono verificado no hay GPU. Con P100 se compila con `-arch=sm_60` (la celda `ARCH` del *notebook* lo detecta). El pre-lab de P6 pide verificar **las dos** antes del martes 24 de noviembre |
| `nvcc` (CUDA 12) | Compilar los `.cu` | En Colab y Kaggle ya viene. Local es opcional y sin GPU solo compila: `nvcc -c -arch=sm_75 archivo.cu`. El material se verificó con `nvcc` 12.0 para `sm_75` y `sm_60` |
| Python 3 con `numba` y `numpy` | Espejos de los *kernels*; con `NUMBA_ENABLE_CUDASIM=1` corren en la CPU y verifican la **lógica** sin GPU | `pip install numba numpy`. Probado con Numba 0.68. El simulador ejecuta cada hilo en Python: usa `n ≤ 10 000` y matrices de 64 o menos; sus tiempos no significan nada, pero revisa los límites de cada acceso (la GPU no) |
| `nbformat` | `make test` valida que cada `notebook_colab.ipynb` esté bien formado y sincronizado con los fuentes | `pip install nbformat` |
| `matplotlib` | Gráficas: S04 (`graficar.py`) y P6 Parte D (`graficar.py`) | `pip install matplotlib` |
| `gcc` 13, `make`, `bash`, `timeout` | Referencias en CPU (`*_cpu.c`, `-O2`) y `make test` | Las mismas de U3–U4 |
| Open MPI (`mpicc`, `mpirun`) | Solo S06: el cazador 1 y los ítems MPI del examen de práctica (`make run-mpi`, `make run-examen`) | Como en U4: `--oversubscribe` ya va en el `Makefile`; como root, `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1` |
| `nsys` (en Colab) | S04, Investigar 5 (opcional): tablas de tiempo por *kernel* y por copia | `ncu` suele estar bloqueado en Colab (`ERR_NVGPUCTRPERM`); entonces se mide con eventos |
| `git` | Repositorio privado del equipo: pre-lab, tareas, etiquetas `H2`, `P6` y `entrega-final` | Nada de nombres completos ni rutas absolutas en el repositorio |
| **Sin GPU** (laptop, LS4, o Colab sin cuota) | Predecir, Investigar, Modificar y la correctitud de todo: `make test`, `make sim` (S01, S03 y P6), CUDASIM | Vuelve a pedir GPU en 1–2 horas o cambia de plataforma (Colab y Kaggle no comparten cuota); no dejes el cuaderno conectado esperando |

Basta una laptop por pareja. Las salidas "reales" del material son de una máquina de 4 núcleos sin GPU (C, Open MPI
y el simulador); las de GPU dicen "esperada en una T4" cuando no se pudieron ejecutar en la autoría. Cómo se mide en
el curso: [`herramientas/protocolo-medicion.md`](../../herramientas/protocolo-medicion.md).

## 5. Cómo recuperar una sesión perdida

Regla del curso ([`docs/metodo/04-evaluacion.md`](../../docs/metodo/04-evaluacion.md) §5 y
[`01-marco-pedagogico.md`](../../docs/metodo/01-marco-pedagogico.md), P10): todo el material es autocontenido, y el
*exit ticket* y la recuperación del día que faltaste se sustituyen **entregando la `tarea-espaciada.md` de esa
sesión antes de la sesión siguiente**. Cuenta como participación (sin peso propio en el 3.er parcial, §3). Orden
de trabajo (≈ 1.5 h, lo mismo que la clase):

| Paso | Archivo de la carpeta de la sesión | Tiempo | Qué haces |
|---|---|---|---|
| 1 | `notas-estudiante.md` | 10–15 min | Lee el concepto, la tabla principal y los errores frecuentes |
| 2 | `ejemplo-resuelto.md` | 15–20 min | Responde cada pausa ("¿por qué este paso?") **por escrito** antes de abrir su `<details>`; en S04 y S06 llena primero los huecos |
| 3 | `practica-guiada/README.md` | 30–40 min | PRIMM completo: escribe las predicciones antes de correr. Sin GPU: `make test` y los espejos con `NUMBA_ENABLE_CUDASIM=1`; con GPU, el `notebook_colab.ipynb` de la carpeta |
| 4 | `tarea-espaciada.md` | 20–40 min | Entrégala antes de la sesión siguiente, donde indica su encabezado; sustituye *exit ticket* y recuperación |
| 5 (opcional) | `retrieval-inicio.md` y `exit-ticket.md` | 10 min | Contéstalos sin apuntes y corrige con la clave en `<details>`; así sabes si de verdad recuperaste la sesión |

Lo particular de cada sesión:

| Si faltaste a… | Además de los pasos 1–4 |
|---|---|
| S01 (lunes 23) | Ese día se recibió **H2**: con justificante institucional se recibe en la sesión siguiente al 100 %; sin justificante, hasta el jueves 26 de noviembre, 10:30, con máximo 80 %. Si te tocaba la pregunta individual de H2, pregunta al profesor cuándo se repone (el plan prevé completar las pendientes al inicio de S02). Ese día se publicó la **Práctica 6**: entrega el pre-laboratorio, con la verificación de GPU, antes del **martes 24 de noviembre, 08:30**, y la tarea de S01 también antes de esa hora |
| S02 (martes 24, Lab 1) | El pre-lab se entrega antes de las 08:30 **faltes o no**. La memoria compartida y los mosaicos son constructo nuevo: haz el `ejemplo-resuelto.md` **completo** antes de la Parte A.7 de P6. Las Partes A y B las terminas con tu equipo antes del Lab 2 (`make test`, `make test-b`). Mini-defensa pendiente: `04` §5 la pasa a la siguiente sesión de laboratorio (martes 1 de diciembre) o a la reserva del martes 15 de diciembre; el README de P6 pide un video de 3 minutos o menos a quien no estuvo en la suya. Pregunta al profesor cuál aplica |
| S03 (jueves 26) | El Crear de la práctica guiada (histograma privado por bloque, `TODO(1)`) es el ejercicio 1 de la tarea si no se terminó en clase. Entrega la tarea antes del lunes 30 de noviembre, 10:30. La Parte C de P6 puede usar el histograma o la reducción de esta sesión |
| S04 (lunes 30) | La tarea produce el pre-mortem y la primera fila de la Parte D de P6: es la entrada del Lab 2 **del día siguiente** (martes 1 de diciembre, 08:30). Si no consigues GPU esa noche, usa las salidas esperadas del README de la práctica guiada y mide en cuanto haya cuota |
| S05 (martes 1 de diciembre, Lab 2) | La Parte D se mide en casa con el *notebook* de P6 y el mismo protocolo; revisa tu tabla con el criterio del punto de control (`entrega.md` §4). Mini-defensa pendiente: ya no hay otro laboratorio; queda la reserva del martes 15 de diciembre o el video de P6. Llena con tu equipo las secciones 1–5 de [`plan-V3.md`](S05_2026-12-01_lab2-taller-V3/practica-guiada/plan-V3.md); las 6–9 están en la tarea |
| S06 (jueves 3 de diciembre) | Haz el [examen de práctica](S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) **en casa, cronometrado (40 min)**, con las casillas A y B de su hoja de calibración, y corrígelo después con su clave (`04` §5). Aplica tú la [lista de cotejo de la entrega final](../../proyecto/entrega-final/lista-cotejo-entrega.md) a tu repositorio (o `proyecto/entrega-final/scripts/verificar_entrega.sh` sobre un clon limpio). Pregunta a tu equipo qué formato de defensa se anunció |

**Hito, práctica o examen con inasistencia.** Hito con justificante institucional: se recibe en la sesión siguiente
al 100 %; sin justificante aplica la regla de 72 h al 80 %. La Práctica 6 es de equipo y su fecha no se mueve por
una inasistencia individual (`04` §5). La reposición del Examen 3 no está escrita en `04-evaluacion.md`: si es tu
caso, avisa al profesor con tu justificante lo antes posible.

**Asesoría.** Se da por protocolo: primero escribes qué intentaste y qué observaste (comando, salida, GPU asignada,
lo que esperabas); después se atiende.

## 6. Ideas erróneas del Anexo A que trabaja la unidad

Catálogo completo en [`docs/metodo/01-marco-pedagogico.md`](../../docs/metodo/01-marco-pedagogico.md), Anexo A.
Son las que alimentan los distractores de los ConcepTests, de los *exit tickets* y del Examen 3. Si una de ellas
te suena razonable, vuelve a la sesión que la trabaja.

| # | Idea errónea | Lo correcto, en una línea | Dónde se trabaja |
|---|---|---|---|
| 22 | "Un hilo de CUDA equivale a un núcleo de CPU" | Miles de hilos ligeros en *warps* de 32 (SIMT); el control de flujo es del *warp* y el SM cambia de *warp* para ocultar la latencia | S01 (notas §1–2, CT1), S04 (CT1-A), S05 (CT2-D, CT3-A) |
| 23 | "La memoria global es tan rápida como la compartida" | Uno a dos órdenes de magnitud de diferencia; por eso el *tiling* reutiliza datos del bloque | S02 (mini-lección, CT1-d, I2.4), S05 (notas §5) |
| 24 | "Las transferencias `cudaMemcpy` no cuentan en el tiempo" | Cuentan y a menudo dominan (≈ 97 % en `saxpy`); se reporta **con y sin** copias | S03 (CT3, I5), S04 (ejemplo resuelto forma 4, CT1-C, CT3-A), S05 (CT1-A, `copiar_cada_iter=1`); P6 Partes A y D |
| 25 · 25b · 25c | "`__syncthreads()` sincroniza toda la GPU" · "si toda la malla cabe, sincroniza todos los bloques" · "dentro del *kernel* se puede llamar a `cudaDeviceSynchronize()`" | La barrera es del **bloque**; entre bloques solo sincroniza el fin del *kernel* (o se combina con atómicas) | S02 (CT3-b), S03 (CT1, I3), S05 (CT1-D), S06 (CT3-D); P6 Parte A |
| 26 | "Cualquier tamaño de bloque funciona igual" | Múltiplos de 32, ≤ 1024 hilos, ocupación; el barrido decide | S01 (CT2-D), S02 (CT1-c, `TILE=64`), S04 (CT2-C, Investigar 3, *exit ticket* 1), S06 (CT2-C, variante 26b) |
| 27 | "Si el *kernel* no da error, el resultado es correcto" | `cudaGetLastError`/`cudaDeviceSynchronize` solo ven lanzamientos inválidos y accesos ilegales; se compara contra la CPU | S01 (CT3, `grid = 3`), S02 (I3, CT3-a), S03 (I4, `block = 96`), S05 (CT2), S06 (CT2-D, `caza2`) |
| 33 | "El *kernel* terminó cuando regresa la llamada" | El lanzamiento es asíncrono: sin sincronizar, el tiempo medido es ≈ 0 | S01 (notas §6), S04 (ejemplo resuelto forma 1, CT1-B); P6 pre-lab 2 |
| 34 | "No hace falta comprobar `idx < n`" | La malla casi siempre excede `n`; sin guardia hay escrituras fuera de rango que "a veces funcionan" | S01 (I3), S02 (bordes), S05 (CT3, `-DSIN_GUARDIA`), S06 (CT2, `caza2`) |
| 7 · 7e | "Si salió bien una vez, no hay carrera" · "si el resultado cambia entre corridas, hay carrera" | Cinco `OK` no prueban nada; y una `atomicAdd` de `float` cambia por **orden**, no por carrera | S02 (CT3-a), S03 (CT2-C, I3), S06 (CT3-A, `caza3`) |
| 8b | "Las atómicas son gratis" | Son correctas, no gratis: sobre una dirección se serializan; se reduce en el bloque y se hace una por bloque | S03 (CT3-C, P1) |
| 10 · 10c | "La reducción da exactamente lo mismo que la secuencial" · "la referencia es la suma en `float`" | Otro orden cambia el redondeo; se compara con tolerancia contra una referencia **más** precisa (`double`) | S03 (CT2-A/D, recuperación 4) |
| 32 | "Una barrera dentro de un `if` está bien si algún hilo la ejecuta" | Todos los hilos del bloque llegan a la misma `__syncthreads()`: va fuera del `if` y sin `return` antes | S02 (errores esperados), S03 (pausa 3), S06 (CT3-C) |
| 1 | "Más hilos siempre es más rápido" | Lo limitan las copias, el costo de lanzar, la ocupación y la fracción secuencial | S01 (recuperación 4), S04 (CT1-A, CT2-A) |
| 5 | "Medir una vez basta" / "se mide con `-O0`" | Calentamiento (contexto de CUDA, JIT de Numba), mediana de ≥ 5, `-O2` | S04 (CT1-D, CT2-A, CT3-D), S05 (CT1-A/C) |
| 21 | "La comunicación es gratis comparada con el cómputo" (de U4, ahora por PCIe) | Cada copia paga latencia + bytes/ancho de banda; con *kernels* cortos domina | S03 (CT3-D), S05 (tarea, ejercicio 2) |

Las sesiones proponen además variantes que todavía no están en el Anexo A y que el profesor puede incorporar si
aparecen en los *exit tickets*: "la GPU completa sola el trabajo que no cubre la malla" y "`threadIdx.x` es el índice
global" (S01 CT2-A y CT2-C), y confundir tiempo de compilación con tiempo de ejecución (S01 CT3-D); "índices de hilo
consecutivos ⇒ direcciones consecutivas", "la compartida es una copia única de la matriz", "cada hilo carga el
mosaico completo" y confundir el manejo de bordes con la sincronización (S02 CT1-a, CT2-a, CT2-d y CT3-d); 18d y 26b
(S06, `conceptests.md`).

## 7. Otros documentos que usa la unidad

- [`practicas/P6-gpu/`](../../practicas/P6-gpu/README.md): Práctica 6 (pre-laboratorio y Partes A–D), con
  [`entrega.md`](../../practicas/P6-gpu/entrega.md), [`rubrica.md`](../../practicas/P6-gpu/rubrica.md) y
  [`resultados/README.md`](../../practicas/P6-gpu/resultados/README.md) (esquema del CSV).
- [`guia-estudio-E3.md`](guia-estudio-E3.md): guía pública del Examen 3.
- [`proyecto/hitos/H2-avance-2.md`](../../proyecto/hitos/H2-avance-2.md) (H2), [`proyecto/README.md`](../../proyecto/README.md)
  (qué es una V3 válida), [`proyecto/medicion-en-el-proyecto.md`](../../proyecto/medicion-en-el-proyecto.md) (V1 vs.
  V2 vs. V3, transferencias), [`proyecto/entrega-final/`](../../proyecto/entrega-final/README.md) y
  [`proyecto/defensa/`](../../proyecto/defensa/logistica-defensa.md).
- [`herramientas/colab-kaggle.md`](../../herramientas/colab-kaggle.md): cuentas, GPU, cuota y capturas;
  [`herramientas/protocolo-medicion.md`](../../herramientas/protocolo-medicion.md): cómo se mide;
  [`herramientas/plantilla-reporte-practica.md`](../../herramientas/plantilla-reporte-practica.md): plantilla del
  `REPORTE.md` de P6.
- [`docs/metodo/05-politica-ia.md`](../../docs/metodo/05-politica-ia.md): semáforo de IA; recuperación, *exit
  tickets*, mini-defensas y exámenes son zona sin IA. La tabla aplicada a P6 está en su README.
- [`planeacion/calendario-27-1.md`](../../planeacion/calendario-27-1.md) y
  [`planeacion/mapa-evaluacion.md`](../../planeacion/mapa-evaluacion.md): fechas y ponderaciones del semestre.
- Unidad anterior: [`U4-memoria-distribuida/`](../U4-memoria-distribuida/README.md). Después de esta unidad vienen
  el cierre (lunes 7: entrega final y ensayo de defensa; martes 8: Examen 3; jueves 10: defensa) y la reserva del 14,
  15 y 17 de diciembre.

## 8. Para el profesor

- **Antes de cada sesión (20 min, `01-marco-pedagogico.md` §4):** leer completos `plan-sesion.md` y
  `conceptests.md`, correr `make test` de `practica-guiada/` en la máquina del salón y leer la clave del
  `exit-ticket.md`. **En esta unidad, además, comprobar ese día que Colab asigna GPU**: los planes piden la GPU
  asignada desde las 10:15 (S01, S03, S06) o antes de las 10:30 (S04); si no hay, Plan B con CUDASIM y las salidas
  esperadas (`02-plantilla-sesion.md` §2.7). Cada plan declara su nivel de andamiaje, sus ideas erróneas, su lista
  de errores esperados con la pregunta socrática y las soluciones de los `TODO` en `<details>`.
- **Estado esperado de `make test` al llegar** (sin los `TODO` resueltos; verificado el 20 de octubre de 2026 en una
  copia limpia de cada carpeta, sin GPU, con gcc 13.3, `nvcc` 12.0, Numba 0.68 con CUDASIM y Open MPI 4.1.6):

| Carpeta | Tipo (`02-plantilla-sesion.md`) | Andamiaje (`07` §A.5) | `make test` | Qué preparar además |
|---|---|---|---|---|
| S01 | Contenido con recepción de H2 (20 min) | Completo; PRIMM en cinco fases | 12 PASS, 0 FAIL, 4 SKIP | Lista de cotejo rápida de H2 impresa (una fila por equipo); decidir cuándo va la pregunta individual; Colab con GPU desde las 10:15 |
| S02 | Laboratorio con constructo nuevo (§2.1) | Completo; PRIMM corto de 20 min | 21 PASS, 0 FAIL | `make test` y el *notebook* ejecutados la víspera (la tabla de tiempos del día); rúbrica de P6 impresa; registro del pre-lab; lista de mini-defensas si hay más de 12 equipos |
| S03 | Contenido | Completo (segunda sesión de contenido) | 18 PASS, 0 FAIL, 2 SKIP | *Notebook* ejecutado hasta la sección 3; fila de 8 casillas y un *warp* dibujados en el pizarrón |
| S04 | Contenido | Por completar (3 huecos en el ejemplo); PRIMM abreviado | 15 PASS, 0 FAIL | GPU asignada antes de las 10:30; si no, se proyectan las salidas esperadas del README |
| S05 | Laboratorio (§2.1) + taller de proyecto (§2.4) | Ejemplo completo; el desvanecimiento va en la práctica guiada | 11 PASS, 0 FAIL, 2 SKIP | Celda "Medir" del *notebook* ejecutada antes de clase; hoja de registro de mini-defensas; rúbrica de P6 |
| S06 | Repaso previo a examen (§2.2) + 10 min de lista de cotejo | Por completar; PRIMM abreviado | 21 PASS, 0 FAIL, 0 SKIP | 35 exámenes de práctica sin clave y 18 claves en sobre cerrado; 18 boletas de cotejo; opción de defensa decidida (se publica ese día en un *issue*) |
| P6 | Práctica | — | 29 PASS, 0 FAIL, 2 PEND, 2 SKIP (recién clonada; los `PEND` son la Parte B) | Al calificar: `make test-b` y `EXTRA=1 bash tests/run_tests.sh` (`entrega.md` §7) |

- **Laboratorios (S02 y S05):** llevan punto de control y mini-defensas de P6 (una pregunta por integrante; la
  segunda solo si la primera falla); el banco de preguntas y el registro están en cada plan. S02 trae un plan B si
  `practicas/P6-gpu/` no estuviera publicada.
- **Práctica 6:** la solución de referencia y los casos de calificación están en `docente/practicas/P6/` (no se
  publica). La retroalimentación sigue el formato mínimo de `04-evaluacion.md` §3.1.
- **Examen 3:** tabla de especificaciones, versiones A/B, claves, código de los ítems, instrucciones de aplicación y
  hoja de calibración en `docente/examenes/E3/` (no se publica). La guía pública toma de ahí solo los pesos por tema
  y la estructura de la portada.
- **Registro:** `herramientas/seguimiento-grupo.csv` (la copia llena vive en `docente/`). Cada plan dice qué datos
  se anotan ese día.
