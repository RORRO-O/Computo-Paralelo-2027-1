> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Índice de la unidad · S01–S06 · jueves 5 a jueves 19 de noviembre de 2026 · lunes y jueves 10:30–12:00, martes 08:30–10:00 · Salón 3208 / Lab LS4 (Edificio 3)

# Unidad IV · Programación en memoria distribuida con MPI

Esta carpeta tiene las seis sesiones que van del **jueves 5 al jueves 19 de noviembre de 2026** (S01–S06) y los
enlaces a la Práctica 5 y al hito H2 del proyecto. La unidad recorre el arco de siempre
(`docs/metodo/01-marco-pedagogico.md` §3.2): **concepto** (S01: procesos que no comparten memoria) →
**herramienta** (S02–S04: punto a punto, colectivas, halos) → **rendimiento** (S05: modelo de costo y
escalabilidad) → **proyecto** (S06: taller rumbo a H2). Lo que se ve aquí entra en el **Examen 3** (martes 8 de
diciembre), junto con la Unidad V.

| Si eres… | Empieza por… |
|---|---|
| Estudiante que va al día | La carpeta de la sesión de hoy: `retrieval-inicio.md` en clase; `notas-estudiante.md` y `tarea-espaciada.md` después |
| Estudiante que faltó | [§5 · Cómo recuperar una sesión perdida](#5-cómo-recuperar-una-sesión-perdida) |
| Estudiante que hace la Práctica 5 | [`practicas/P5-mpi/README.md`](../../practicas/P5-mpi/README.md) y el calendario de [§3.2](#32-calendario-de-la-unidad-fecha-por-fecha) |
| Estudiante que prepara el Examen 3 | [§3.3](#33-examen-3), la [guía de estudio del Examen 3](../U5-gpu/guia-estudio-E3.md) y el [examen de práctica de las Unidades IV–V](../U5-gpu/S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) |
| Profesor que da la sesión | `plan-sesion.md` y `conceptests.md` de la carpeta ([§8](#8-para-el-profesor)) |

## 1. Objetivos de la unidad

Al terminar la unidad (jueves 19 de noviembre) podrás, **sin computadora y en papel** salvo donde se indica:

1. **Explicar**, con un diagrama y un fragmento de código, por qué dos procesos MPI no comparten variables, y
   **predecir** la salida de un programa SPMD de 15 líneas o menos: cuántas líneas imprime con `-np p`, qué vale
   una variable global en cada rango y si el orden está garantizado. (S01)
2. **Calcular**, para `n` no múltiplo de `p`, los índices de cada rango con reparto por bloques con residuo
   (`start`, `count`) y con reparto cíclico, y **escribir** a partir de ellos las cuentas y desplazamientos de
   `MPI_Scatterv`/`MPI_Gatherv`, en elementos. (S01, S03, S04)
3. **Escribir** `MPI_Send`/`MPI_Recv` completos con etiqueta y `MPI_Status`, obtener la cuenta recibida con
   `MPI_Get_count`, **explicar** por qué dos `Send` cruzados terminan con mensajes chicos y se interbloquean con
   grandes, y **corregir** el intercambio con orden por paridad, `MPI_Sendrecv` o `MPI_Isend`/`MPI_Irecv`/`MPI_Waitall`.
   (S02, S04)
4. **Elegir** la colectiva adecuada (`Bcast`, `Scatter(v)`, `Gather(v)`, `Reduce`, `Allreduce`, `Allgather`,
   `Barrier`) respondiendo "¿quién tiene el dato antes y quién lo necesita después?", **escribir** la llamada y
   **predecir** los dos síntomas de una colectiva que no llaman todos: cuelgue o resultado incorrecto sin aviso.
   (S03, S06)
5. **Programar** en computadora una descomposición de dominio con celdas fantasma (Jacobi 1D o calor 1D),
   `MPI_PROC_NULL` en las orillas, paro global con `MPI_Allreduce(MPI_MAX)` y reconstrucción con `MPI_Gatherv`, y
   **verificarla** contra la secuencial: mismas iteraciones y valores con tolerancia, con `make test`. (S04;
   Práctica 5, Parte C)
6. **Estimar** α y β con un *ping-pong*, **usar** `T_com = α + m/β` para calcular el `n*` a partir del cual
   conviene usar `p` procesos y **predecir** el *speedup*; en computadora, **medir** escalabilidad fuerte y
   débil con el protocolo del curso, con la fila sobre-suscrita aparte y etiquetada. (S02, S05; Práctica 5,
   Parte D)
7. **Explicar** dónde deja de escalar una tabla de mediciones MPI con la razón cómputo/comunicación y un dato
   medido, y **distinguir** escalabilidad fuerte (`n` fijo, *speedup*) de débil (`n/p` fijo, eficiencia
   débil). (S05)
8. **Describir** qué resuelven `MPI_Type_vector` y `MPI_Comm_split`, qué pide `MPI_Init_thread` en un programa
   híbrido MPI+OpenMP, y **predecir** qué procesos deben llamar a una colectiva sobre un comunicador derivado.
   (S05, S06; panorama)
9. **Diagnosticar** en un programa MPI de 60 líneas o menos cuál de los siete errores clásicos tiene, **predecir**
   su síntoma (cuelgue, aborto, `FAIL` o "funciona por suerte") y **corregirlo** citando la regla que violaba. (S06)
10. **Aplicar** el protocolo de medición a la tabla de *speedup* de la V2 del proyecto (`T(1)` = V1, mediana de 5,
    `n` fijo, fila sobre-suscrita aparte, Karp–Flatt) y **detectar** sus violaciones en la tabla de otro equipo.
    (S06; H2)

## 2. Sesiones

Horario del grupo: lunes y jueves 10:30–12:00 en el Salón 3208; martes 08:30–10:00 en el Lab LS4. Cada carpeta
tiene `plan-sesion.md`, `retrieval-inicio.md`, `notas-estudiante.md`, `ejemplo-resuelto.md`, `conceptests.md`,
`practica-guiada/` (código, `Makefile`, `tests/`), `exit-ticket.md` y `tarea-espaciada.md`.

| Sesión | Fecha y lugar | Tipo | Tema | Carpeta | Práctica guiada (PRIMM) |
|---|---|---|---|---|---|
| S01 | jueves 5 de noviembre, 10:30 · 3208 | Contenido | Modelo de memoria distribuida y SPMD: `MPI_Init`, `Comm_rank`, `Comm_size`, `Finalize`; compilar y ejecutar; reparto por bloques y cíclico; Foster aplicado a procesos; `MPI_Wtime`. **Se publica la Práctica 5** | [`S01_2026-11-05_modelo-spmd/`](S01_2026-11-05_modelo-spmd/) | [Hola con rangos y suma distribuida](S01_2026-11-05_modelo-spmd/practica-guiada/README.md) |
| S02 | lunes 9 de noviembre, 10:30 · 3208 | Contenido | Punto a punto: `Send`/`Recv`, etiquetas, `Status`, `Get_count`; qué promete `MPI_Send` e interbloqueo; *ping-pong* para latencia y ancho de banda | [`S02_2026-11-09_punto-a-punto/`](S02_2026-11-09_punto-a-punto/) | [Anillo, *ping-pong* e intercambio cruzado](S02_2026-11-09_punto-a-punto/practica-guiada/README.md) |
| S03 | martes 10 de noviembre, 08:30 · LS4 | Laboratorio | Colectivas (`Bcast`, `Scatter`, `Gather`, `Reduce`, `Allreduce`, `Allgather`, `Barrier`) y producto matriz-vector distribuido + **Práctica 5 · Laboratorio 1** (Partes A y B, mini-defensas). **Pre-lab de P5** | [`S03_2026-11-10_colectivas-lab1/`](S03_2026-11-10_colectivas-lab1/) | [Producto matriz-vector con colectivas](S03_2026-11-10_colectivas-lab1/practica-guiada/README.md) (PRIMM corto) |
| S04 | jueves 12 de noviembre, 10:30 · 3208 | Contenido | Descomposición de dominio: celdas fantasma en Jacobi 1D, `MPI_PROC_NULL`, `Sendrecv` e `Isend`/`Irecv`/`Waitall`, paro global con `Allreduce`, `Gatherv`; balance de carga (bloques frente a cíclico). **Retroalimentación del Examen 2** | [`S04_2026-11-12_descomposicion-halos/`](S04_2026-11-12_descomposicion-halos/) | [Jacobi 1D con celdas fantasma](S04_2026-11-12_descomposicion-halos/practica-guiada/README.md) |
| — | lunes 16 de noviembre | Sin clase | Revolución Mexicana | — | — |
| S05 | martes 17 de noviembre, 08:30 · LS4 | Laboratorio | Rendimiento en MPI: modelo `α + m/β`, razón cómputo/comunicación, escalabilidad fuerte y débil, sobre-suscripción; MPI+OpenMP (panorama) + **Práctica 5 · Laboratorio 2** (Parte D, punto de control, mini-defensas) | [`S05_2026-11-17_rendimiento-lab2/`](S05_2026-11-17_rendimiento-lab2/) | [¿Cuándo conviene repartir? Escalabilidad y modelo de costo](S05_2026-11-17_rendimiento-lab2/practica-guiada/README.md) |
| S06 | jueves 19 de noviembre, 10:30 · 3208 | Taller | Cierre de la unidad: tipos derivados y comunicadores (panorama), siete errores clásicos de MPI; **taller del proyecto rumbo a H2** (V2 con *speedup*) | [`S06_2026-11-19_cierre-taller-H2/`](S06_2026-11-19_cierre-taller-H2/) | [Cazador de errores MPI + taller de mediciones hacia H2](S06_2026-11-19_cierre-taller-H2/practica-guiada/README.md) |

Para correr una práctica guiada: `cd <carpeta>/practica-guiada && make && make test` (todas tienen `all`, `run`,
`test` y `clean`). El número de procesos se fija con `NP` (`make run NP=4`; en S05, `make run` corre el estudio
completo con `escalado.sh` y `NP` se usa en `make run-fuerte`); los `Makefile` ya pasan `--oversubscribe` en
`MPIRUN_FLAGS`. Los `SKIP` que ves al inicio son los `TODO`, las correcciones (S06) y la fase
Crear que completas tú.

## 3. Entregas, hitos y fechas

Ponderaciones del 3.er parcial según [`planeacion/mapa-evaluacion.md`](../../planeacion/mapa-evaluacion.md):
Examen 3, 30 %; Práctica 5, 15 %; Práctica 6, 15 %; proyecto integrador, 40 % (H2 vale 15 de sus 100 puntos).
En el 3.er parcial las tareas espaciadas y los *exit tickets* **no tienen peso propio**
([`docs/metodo/04-evaluacion.md`](../../docs/metodo/04-evaluacion.md) §1): se entregan igual, se registran, y el
examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del Examen 3 toman ítems de las tareas.
Las reglas de entrega tardía y segunda entrega son las de `04-evaluacion.md` §5.

### 3.1 Lo que cuenta para la calificación

| Entrega | Fecha límite | Peso | Dónde y cómo |
|---|---|---|---|
| **Práctica 5 · MPI** (en equipo, 2–3 integrantes) | **domingo 22 de noviembre, 23:59** (etiqueta `P5-entrega`) | **15 %** del 3.er parcial | [`practicas/P5-mpi/`](../../practicas/P5-mpi/README.md): enunciado, [`entrega.md`](../../practicas/P5-mpi/entrega.md) y [`rubrica.md`](../../practicas/P5-mpi/rubrica.md). Pre-laboratorio individual antes del martes 10 de noviembre, 08:30. Mini-defensas en los laboratorios del 10 y del 17. Tardía hasta el miércoles 25 de noviembre, 23:59, con máximo 80 % y sin segunda entrega. Retroalimentación a más tardar el domingo 29 de noviembre. Segunda entrega solo si la primera obtiene < 70 %: dentro de los 7 días siguientes a la retroalimentación, con tope de 80 % |
| **H2 · Avance 2 del proyecto** (en equipo) | **lunes 23 de noviembre**: etiqueta `H2` antes de las **10:30**; recepción en clase (U5·S01) | **15 puntos** del proyecto (el proyecto es 40 % del 3.er parcial) | [`proyecto/hitos/H2-avance-2.md`](../../proyecto/hitos/H2-avance-2.md): V2 con OpenMP correcta frente a V1, tabla de *speedup* y eficiencia con el protocolo, Karp–Flatt, decisiones justificadas y `reporte/H2.md`. Tardía hasta el jueves 26 de noviembre, 10:30, con máximo 80 %. Rúbrica por escrito a más tardar el lunes 30 de noviembre |
| **Examen departamental 3** (individual) | **martes 8 de diciembre, 08:30–10:00** | **30 %** del 3.er parcial | Ver §3.3 |

**Hitos del proyecto dentro de la unidad.** Ningún hito vence entre el 5 y el 19 de noviembre. La unidad
prepara **H2**, que vence el lunes 23 de noviembre al abrir la Unidad V; H2 recomienda terminar la V2 en la
semana del 9 de noviembre y usar el taller de S06 para cerrar mediciones (`H2-avance-2.md` §1). Lo que sí ocurre
en la unidad: la rúbrica escrita de **H1** se devuelve a más tardar el jueves 5 de noviembre, y el jueves 19 de
noviembre (S06) el profesor anuncia cómo se recibe H2 (opciones A/B/C de `H2-avance-2.md` §8; con la B, los
equipos que ya tengan la etiqueta `H2` antes de las 10:30 de ese día se reciben en S06).

### 3.2 Calendario de la unidad, fecha por fecha

| Fecha y hora | Qué pasa o qué se entrega | Archivo de referencia |
|---|---|---|
| jueves 5 de noviembre, 10:30 (S01) | Se publica la **Práctica 5**. Rúbrica escrita de H1 (a más tardar). La Unidad III programa ese día la pregunta individual de H1 (opción A de H1 §8: primeros 20 min) y la pregunta posterior de la Práctica 4 a 2–3 equipos (5 min) | [P5 `README.md`](../../practicas/P5-mpi/README.md) · [H1](../../proyecto/hitos/H1-avance-1.md) §8 · [P4 `entrega.md`](../../practicas/P4-openmp/entrega.md) §1 |
| domingo 8 de noviembre | Retroalimentación de la Práctica 4 (a más tardar) | [P4 `entrega.md`](../../practicas/P4-openmp/entrega.md) §1 |
| lunes 9 de noviembre, 10:30 (S02) | Tarea de S01 (papel o `tareas/U4-S01.md`) | [S01 `tarea-espaciada.md`](S01_2026-11-05_modelo-spmd/tarea-espaciada.md) |
| martes 10 de noviembre, 08:30 (S03) | **Pre-laboratorio de la Práctica 5**, individual, en `practicas/P5/prelab/prelab-<alias>.md` del repositorio del equipo, **faltes o no**. Laboratorio 1: Partes A y B (en clase, solo el `TODO(1)` de la B; los `TODO(2)`–`(5)` en casa). Calificación y clave del Examen 2 (a más tardar) | [P5 `README.md`](../../practicas/P5-mpi/README.md), "Pre-laboratorio" · [P5 `entrega.md`](../../practicas/P5-mpi/entrega.md) §1 |
| jueves 12 de noviembre, 10:30 (S04) | Tareas de S02 (`tarea-S02.md` + `ring_laps.c`) y de S03 (`tarea-S03.md`). Análisis de errores del Examen 2 en clase | [S02](S02_2026-11-09_punto-a-punto/tarea-espaciada.md) · [S03](S03_2026-11-10_colectivas-lab1/tarea-espaciada.md) |
| martes 17 de noviembre, 08:30 (S05) | Tarea de S04 (`tareas/U4-S04/`; el ejercicio 3 es la predicción de la Parte D). Llegar con las Partes A–C de P5 funcionando y con `nproc`/`lscpu` a la mano para declarar los núcleos físicos. Laboratorio 2: Parte D, punto de control y mini-defensas pendientes | [S04 `tarea-espaciada.md`](S04_2026-11-12_descomposicion-halos/tarea-espaciada.md) · [P5 `entrega.md`](../../practicas/P5-mpi/entrega.md) §1 |
| jueves 19 de noviembre, 10:30 (S06) | Tarea de S05 (`tareas/U4-S05.md`, con la tabla de *speedup* de la V2 tal como esté). Taller hacia H2; anuncio de la opción de recepción de H2 | [S05 `tarea-espaciada.md`](S05_2026-11-17_rendimiento-lab2/tarea-espaciada.md) · [H2](../../proyecto/hitos/H2-avance-2.md) §8 |
| domingo 22 de noviembre, 23:59 | **Práctica 5 completa** (etiqueta `P5-entrega`; `make test-entrega` en `0 FAIL`) | [P5 `entrega.md`](../../practicas/P5-mpi/entrega.md) §3–§4 |
| lunes 23 de noviembre, 10:30 (U5·S01) | **H2** (etiqueta antes de las 10:30). Tarea de S06 (`tareas/U4-S06/`). Pregunta posterior de la Práctica 5 a 2–3 equipos. Se publica la Práctica 6 | [S06 `tarea-espaciada.md`](S06_2026-11-19_cierre-taller-H2/tarea-espaciada.md) · [U5·S01](../U5-gpu/S01_2026-11-23_H2-modelo-cuda/) |
| miércoles 25 de noviembre, 23:59 | Último momento para la entrega tardía de P5 (máximo 80 %) | [P5 `entrega.md`](../../practicas/P5-mpi/entrega.md) §1 |
| domingo 29 de noviembre | Retroalimentación de la Práctica 5 (a más tardar) | [P5 `entrega.md`](../../practicas/P5-mpi/entrega.md) §1 |

Cada `tarea-espaciada.md` dice en su encabezado dónde se entrega; la tabla copia lo que dice cada una. Carga
orientativa fuera de clase (`planeacion/calendario-27-1.md`): 3 h la semana del 2 al 8 de noviembre (pre-lab de
P5, tarea), 5 h la del 9 al 15 (P5, Partes A–C) y 6 h la del 16 al 22 (P5, Parte D y reporte; H2).

### 3.3 Examen 3

| | |
|---|---|
| Fecha | **martes 8 de diciembre de 2026, 08:30–10:00** (Salón 3208, o Lab LS4 con los equipos apagados y filas alternas) |
| Cubre | **Unidades IV–V** (MPI y GPU), con 10–20 % de unidades previas integrado en los problemas (eficiencia, Amdahl, protocolo de medición), no en una sección aparte |
| Formato | Versiones A/B, 80 minutos efectivos, 100 puntos, individual, sin dispositivos; hoja de calibración aparte (no afecta la calificación). Zona sin IA |
| Preparación | Las tareas espaciadas de U4–U5 (de ahí salen ítems); la [guía de estudio](../U5-gpu/guia-estudio-E3.md) (temario con pesos, banco de preguntas con respuesta y plan de repaso); el [examen de práctica](../U5-gpu/S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) del jueves 3 de diciembre (U5·S06), con la misma estructura y su clave; los ConcepTests de cada sesión, con su respuesta y el origen de cada distractor |
| Devolución | Calificación y clave en ≤ 7 días; la reserva del lunes 14 de diciembre está prevista para la retroalimentación |

De esta unidad, el examen de práctica pregunta por la semántica de `MPI_Send` y el interbloqueo (I.1), el modelo
de costo de Jacobi 1D con halos y el `n` a partir del cual conviene usar 4 procesos (I.2, V.a), la salida y los
errores de programas con colectivas (II.1, III.1), un `Scatter` + `Reduce` por completar (IV.a) y la elección
entre OpenMP, MPI y GPU con dos datos numéricos (VI).

## 4. Requisitos de software

| Qué | Para qué en esta unidad | Notas |
|---|---|---|
| Open MPI o MPICH (`mpicc`, `mpirun`) | Todo el código MPI: `mpicc -std=c11 -O2 -Wall -Wextra`; `mpirun -np p` | El material se escribió y probó con Open MPI 4.1.6 y gcc 13.3. Instalación (S01): `sudo apt install openmpi-bin libopenmpi-dev` en Ubuntu/Debian/WSL; `brew install open-mpi` en macOS. Con MPICH, `--oversubscribe` no existe: `make MPIRUN_FLAGS= test` |
| `--oversubscribe` | Correr más procesos que núcleos para **probar** la lógica | Ya va en `MPIRUN_FLAGS` de cada `Makefile`. Sirve para probar, no para medir (idea errónea 20): la Parte D de P5 etiqueta esa fila `mpi_oversub` |
| Variables para correr como root (contenedores) | Open MPI se niega a correr como root | `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`. Todos los `tests/run_tests.sh` de la unidad y de P5 lo hacen solos (también los `Makefile` de S05, S06 y P5); para `mpirun` en una terminal nueva, expórtalas tú |
| `gcc` con OpenMP (`-fopenmp`) | Las versiones secuenciales; el híbrido MPI+OpenMP de S05 (`make run-hibrido`) y la extensión opcional de P5 | `OMP_NUM_THREADS × np ≤ núcleos`, o vuelves a sobre-suscribir |
| `make`, `bash` y `timeout` (coreutils) | `make test`; las pruebas de S01–S06 y P5 usan `timeout` para detectar cuelgues (código 124) | Un programa colgado se mata con `Ctrl+C` |
| `ompi_info` | Ver el límite *eager* de tu instalación (S02, S03, S06): `ompi_info --param btl vader --level 4 \| grep eager_limit` | Solo Open MPI; con MPICH se omite y se busca el umbral corriendo |
| Python 3 con `matplotlib` | Gráficas: perfil de Jacobi (S04 `graficar_perfil.py`), escalabilidad (S05 y P5 `graficar.py`) | `modelo.py` (S05, P5) y `revisar_mediciones.py` (S06) corren sin `matplotlib`; el revisor solo omite la gráfica |
| `lscpu`, `nproc`, `uptime` | Declarar núcleos físicos y carga antes de medir (S05, S06, P5 `entorno.txt`) | Mide con la máquina lo más vacía posible (`herramientas/protocolo-medicion.md`) |
| `git` | Repositorio privado del equipo: pre-lab, tareas, etiquetas `P5-entrega` y `H2` | Nada de nombres completos ni rutas absolutas en el repositorio |

Basta una laptop por pareja; las salidas de referencia del material son de una máquina virtual de 4 núcleos. Sin
MPI instalado, las fases Predecir e Investigar de PRIMM se hacen en papel con la salida proyectada. Cómo se mide
en el curso: [`herramientas/protocolo-medicion.md`](../../herramientas/protocolo-medicion.md).

## 5. Cómo recuperar una sesión perdida

Regla del curso ([`docs/metodo/04-evaluacion.md`](../../docs/metodo/04-evaluacion.md) §5 y
[`01-marco-pedagogico.md`](../../docs/metodo/01-marco-pedagogico.md), P10): todo el material es autocontenido, y el
*exit ticket* y la recuperación del día que faltaste se sustituyen **entregando la `tarea-espaciada.md` de esa
sesión antes de la sesión siguiente**. Cuenta como participación (sin peso propio en el 3.er parcial, §3). Orden
de trabajo (≈ 1.5 h, lo mismo que la clase):

| Paso | Archivo de la carpeta de la sesión | Tiempo | Qué haces |
|---|---|---|---|
| 1 | `notas-estudiante.md` | 10–15 min | Lee el concepto, la tabla principal y los errores frecuentes |
| 2 | `ejemplo-resuelto.md` | 15–20 min | Responde cada pausa ("¿por qué este paso?") **por escrito** antes de abrir su `<details>` |
| 3 | `practica-guiada/README.md` | 30–40 min | PRIMM completo: escribe las predicciones antes de correr; `make test` debe pasar los `TODO` que completes |
| 4 | `tarea-espaciada.md` | 20–40 min | Entrégala antes de la sesión siguiente, donde indica su encabezado; sustituye *exit ticket* y recuperación |
| 5 (opcional) | `retrieval-inicio.md` y `exit-ticket.md` | 10 min | Contéstalos sin apuntes y corrige con la clave en `<details>`; así sabes si de verdad recuperaste la sesión |

Lo particular de cada sesión:

| Si faltaste a… | Además de los pasos 1–4 |
|---|---|
| S01 (jueves 5) | Ese día se publicó la Práctica 5: lee su enunciado y entrega el **pre-laboratorio antes del martes 10 de noviembre, 08:30**. El Lab 1 da por hecho el reparto por bloques con residuo (`start`, `count`): `MPI_Scatterv` lo usa en la Parte A. El reparto cíclico (`TODO(1)` de la práctica guiada) reaparece en la Parte C.2 de P5 y en el CT3 de S04. Si ese día te tocaba la pregunta individual de H1, pregunta al profesor cuándo se repone |
| S02 (lunes 9) | La tarea de S02 fija su entrega el jueves 12 de noviembre (S04), pero para sustituir el *exit ticket* `04` §5 pide entregarla antes de la sesión siguiente: entrégala antes del martes 10, 08:30, y cumples las dos reglas. De S02 necesitas entender α y β del *ping-pong*: S05 construye con ellos el modelo de costo, y la Parte D de P5 vuelve a medirlos en tu máquina con `d_pingpong` |
| S03 (martes 10, Lab 1) | El pre-lab se entrega antes de las 08:30 **faltes o no**. Las Partes A y B de P5 las haces con tu equipo (`make test-a`, `bash tests/run_tests.sh b`). Si te tocaba **mini-defensa**: `P5-mpi/entrega.md` §3 pide, a quien no estuvo en la suya, un video de 3 minutos o menos enlazado en `REPORTE.md`; `04` §5 permite además reponerla en la siguiente sesión de laboratorio (martes 17) o en la reserva del martes 15 de diciembre. Graba el video de todos modos; el profesor confirma si además te la hace en persona |
| S04 (jueves 12) | Ese día fue el análisis de errores del Examen 2: la calificación y la clave se publican a más tardar el martes 10 de noviembre (`04` §2.3) y el examen se devuelve en asesoría. El ejercicio 3 de la tarea es la predicción de la Parte D de P5: hazlo antes del martes 17 |
| S05 (martes 17, Lab 2) | La Parte D de P5 se mide en casa con `escalado.sh` y el mismo protocolo; [`resultados-ejemplo/`](S05_2026-11-17_rendimiento-lab2/practica-guiada/resultados-ejemplo/) trae la corrida de referencia para comparar. Mini-defensa pendiente: el siguiente laboratorio es U5·S02 (martes 24 de noviembre), después de la fecha límite de P5, así que el video de `entrega.md` §3 va en `REPORTE.md` antes del domingo 22, 23:59 (la reposición presencial que permite `04` §5 sería ese martes 24 o la reserva del martes 15 de diciembre; el profesor confirma cuál) |
| S06 (jueves 19) | Haz la Parte 1 del README (los tres cazadores). La Parte 2 (taller de H2: lista de cotejo, revisor de mediciones y revisión por pares) hazla con tu equipo antes del lunes 23 de noviembre; pregúntale a tu equipo qué opción de recepción de H2 se anunció |

**H2 con inasistencia.** Hito con justificante institucional: se recibe en la sesión siguiente al 100 %; sin
justificante aplica la regla de 72 h al 80 % (`04` §5).

**Asesoría.** Se da por protocolo: primero escribes qué intentaste y qué observaste (comando, salida, lo que
esperabas); después se atiende.

## 6. Ideas erróneas del Anexo A que trabaja la unidad

Catálogo completo en [`docs/metodo/01-marco-pedagogico.md`](../../docs/metodo/01-marco-pedagogico.md), Anexo A.
Son las que alimentan los distractores de los ConcepTests, de los *exit tickets* y del Examen 3. Si una de ellas
te suena razonable, vuelve a la sesión que la trabaja.

| # | Idea errónea | Lo correcto, en una línea | Dónde se trabaja |
|---|---|---|---|
| 16 | "Los procesos MPI comparten memoria" | Cada proceso tiene su espacio de direcciones; todo intercambio es un mensaje, y un mensaje es una copia | S01 (`hello_rank`, CT1), S02 (CT1-D), S03 (CT1-B, CT3) |
| 17 | "`MPI_Send` siempre regresa de inmediato" / "siempre bloquea hasta que el otro recibe" | Solo promete que tu búfer se puede reutilizar; depende del tamaño y del *buffering*: dos `Send` cruzados pueden interbloquearse | S02 (`cross_exchange_buggy`, CT1), S04 (CT1), S06 (`caza1`, CT3); P5 pre-lab |
| 18 | "Solo el proceso raíz llama a `MPI_Bcast`" | Todas las colectivas las llaman **todos** los procesos del comunicador; si uno falta, cuelgue o basura sin aviso | S03 (`matvec_bcast_buggy`, CT1), S04 (CT2), S06 (`caza2`, CT1) |
| 19 | "El rango 0 tiene que ser el maestro" | Es una convención: cualquier rango puede combinar | S01 (CT3, M2), S02 (CT2-C), S03 (M2) |
| 20 | "Más procesos que núcleos siempre está bien" | La sobre-suscripción cambia las mediciones; sirve para probar, se declara y se mide aparte | S04 (I6), S05 (CT3, fila `mpi_oversub`); P5 Parte D |
| 21 | "La comunicación es gratis comparada con el cómputo" | `T_com = α + m/β`: cada mensaje paga α; con `n` pequeño o un reparto caro, la comunicación domina | S02 (CT3, *ping-pong*), S03 (CT2, medición), S04 (CT3), S05 (CT1); P5 Parte D |
| 1 | "Más hilos (procesos) siempre es más rápido" | Por debajo de `n*` cuatro procesos tardan más que uno; la comunicación por iteración no baja con `p` | S01 (I6), S03 (CT2-D), S05 (CT1-A), S06 (CT2-C) |
| 6 | "Escalabilidad fuerte y débil son sinónimos" | Fuerte: `n` fijo, se reporta *speedup*; débil: `n/p` fijo, se reporta eficiencia débil | S05 (CT2), S06 (recuperación) |
| 5 | "Medir una vez basta" / "se mide con `-O0`" | Mediana de ≥ 5 repeticiones tras calentamiento, con `-O2` | S06 (CT2, revisor de mediciones) |
| 31 | "El *speedup* se calcula contra la versión paralela con 1 hilo (o `mpirun -np 1`)" | `T(1)` es el mejor secuencial: `referencia_secuencial`/`seq` en MPI, V1 en el proyecto | S01 (notas §7), S05, S06 (revisor `E1`/`E6`, CT2-A) |
| 10 | "La reducción da exactamente lo mismo que la suma secuencial" | Otro orden de suma cambia el redondeo: se compara con tolerancia | S03 (tolerancia de `make test`) |
| 28 | "Aglomerar es juntar todo en un solo proceso" | Es agrupar tareas para bajar la comunicación sin perder paralelismo (`n` tareas → `p` bloques) | S01 (recuperación, tabla de Foster), S04 (recuperación, pausa 1, CT3) |

Las sesiones proponen además variantes que todavía no están en el Anexo A y que el profesor puede incorporar si
aparecen en los *exit tickets*:

- **De la 16:** 16b "`MPI_Barrier` sincroniza la memoria" (S01 CT1-C y CT3-C); 16c "`n/p` reparte todo el
  arreglo" (S01 CT2-A y CT2-D); 16d "bloques y cíclico asignan los mismos índices" (S01 CT2-C).
- **De la 17:** 17b "el interbloqueo depende de cuántas parejas hay" (S06 CT3-D).
- **De la 18:** 18b "una colectiva es sobre todos los procesos del programa" y 18c "sin raíz no hay espera" (S06
  CT1-A y CT1-C); "MPI detecta las colectivas mal emparejadas" (S03 CT1-D, S04 CT2-D) y su pariente "MPI detecta
  etiquetas cruzadas" (S06 *exit ticket* 1-A).
- **De la 19:** 19b, "con `-np 3` el último rango es el 3": confunde la cantidad de procesos con la identidad del
  rango (S01 CT3-D).
- **De la 21 y la 6:** "el *speedup* es una constante del programa, no depende de `n`" (S05 CT1-B).
- **Sin número todavía:** "`MPI_PROC_NULL` es un proceso que no responde" (S04 CT1-D); "el algoritmo exige celdas
  contiguas" (S04 CT3-C); "si una medición da *speedup* < 1, el problema no es paralelizable" (S03 CT2-B); "las
  etiquetas no emparejan" (S06 *exit ticket* 1-C).

## 7. Otros documentos que usa la unidad

- [`practicas/P5-mpi/`](../../practicas/P5-mpi/README.md): Práctica 5 (Partes A–D), con
  [`entrega.md`](../../practicas/P5-mpi/entrega.md), [`rubrica.md`](../../practicas/P5-mpi/rubrica.md) y
  [`resultados/README.md`](../../practicas/P5-mpi/resultados/README.md).
- [`proyecto/hitos/H2-avance-2.md`](../../proyecto/hitos/H2-avance-2.md): lo que pide H2 y cómo se recibe.
- [`herramientas/protocolo-medicion.md`](../../herramientas/protocolo-medicion.md): cómo se mide en el curso;
  [`herramientas/plantilla-reporte-practica.md`](../../herramientas/plantilla-reporte-practica.md): plantilla del
  `REPORTE.md` de P5.
- [`docs/metodo/05-politica-ia.md`](../../docs/metodo/05-politica-ia.md): semáforo de IA; recuperación, *exit
  tickets*, mini-defensas y exámenes son zona sin IA. La tabla aplicada a P5 está en su README.
- [`planeacion/calendario-27-1.md`](../../planeacion/calendario-27-1.md) y
  [`planeacion/mapa-evaluacion.md`](../../planeacion/mapa-evaluacion.md): fechas y ponderaciones del semestre.
- Unidad anterior: [`U3-memoria-compartida/`](../U3-memoria-compartida/README.md). Unidad siguiente:
  [`U5-gpu/`](../U5-gpu/README.md) (empieza el lunes 23 de noviembre con H2).

## 8. Para el profesor

- **Antes de cada sesión (20 min, `01-marco-pedagogico.md` §4):** leer completos `plan-sesion.md` y
  `conceptests.md`, correr `make test` de `practica-guiada/` en la máquina del salón y leer la clave del
  `exit-ticket.md`. Cada plan declara sus ideas erróneas y su lista de errores esperados con la pregunta
  socrática; S01–S04 traen además las soluciones de sus `TODO` (S05 no tiene `TODO`; los cazadores de S06 no traen
  solución escrita: las correcciones válidas están en la fase Modificar de su README y en la columna "Regla del
  estándar" de `notas-estudiante.md` §4). S03–S06 declaran su nivel de andamiaje; S01 y S02 no.
- **Estado esperado de `make test` al llegar** (sin los `TODO` resueltos; verificado el 20 de octubre de 2026 en el
  entorno de autoría con Open MPI 4.1.6, gcc 13.3 y `--oversubscribe`, sin *warnings*):

| Carpeta | Tipo (`02-plantilla-sesion.md`) | Andamiaje (`07` §A.5) | `make test` | Qué preparar además |
|---|---|---|---|---|
| S01 | Contenido, 90 min | Completo; PRIMM en cinco fases (el plan no lo declara) | 15 PASS, 0 FAIL, 2 SKIP | Diagrama de dos memorias en el pizarrón; anuncio de P5. El guion ocupa los 90 min y no reserva los 20 de la pregunta individual de H1 (opción A de H1 §8) ni los 5 de la pregunta posterior de P4: si se hacen ese día, decidir antes qué bloque se recorta (nunca la recuperación ni el *exit ticket*, `01` §4) |
| S02 | Contenido, 90 min | Completo; PRIMM en cinco fases (el plan no lo declara) | 9 PASS, 0 FAIL, 4 SKIP | Confirmar que `cross_exchange_buggy 1000000` se cuelga en la máquina del salón; límite *eager* con `ompi_info` |
| S03 | Laboratorio con constructo nuevo (§2.1) | Completo; PRIMM corto de 20 min | 15 PASS, 0 FAIL, 3 SKIP | `make run-buggy N=8` y `N=1024`; caja de pre-labs; rúbrica de P5 impresa; lista de mini-defensas si hay más de 12 equipos |
| S04 | Contenido con 10 min de retroalimentación del E2 | Con pistas; el desvanecimiento va en la práctica guiada | 7 PASS, 0 FAIL, 3 SKIP | Los 3 ítems peor contestados del Examen 2 con su estadística (`docente/examenes/E2/`) |
| S05 | Laboratorio (§2.1) | Con pistas | 12 PASS, 0 FAIL | Una corrida previa de `make run` (~1 min) para proyectar `fuerte.png` y `debil.png`; rúbrica impresa |
| S06 | Taller de proyecto (§2.4) | Con pistas; los cazadores no traen solución | 22 PASS, 0 FAIL, 4 SKIP | Decidir la opción de recepción de H2 (`H2-avance-2.md` §8) para anunciarla; `make revisar` y `ejemplo_mediciones_mal.csv` listos |
| P5 | Práctica | — | 16 PASS, 0 FAIL, 20 PEND, 1 SKIP (recién clonada) | Al calificar: `make test-entrega PARTE_C=heat` (o `primes`) |

- **Laboratorios (S03 y S05):** llevan punto de control y mini-defensas de P5 (una pregunta por integrante; la
  segunda solo si la primera falla); el registro está en cada plan. S03 trae un plan B si `practicas/P5-mpi/` no
  estuviera publicada.
- **Práctica 5:** la solución de referencia y los casos de calificación están en `docente/practicas/P5/` (no se
  publica). La retroalimentación sigue el formato mínimo de `04-evaluacion.md` §3.1.
- **Examen 3:** tabla de especificaciones, versiones A/B, claves, instrucciones de aplicación y hoja de calibración
  en `docente/examenes/E3/` (no se publica).
- **Registro:** `herramientas/seguimiento-grupo.csv` (la copia llena vive en `docente/`). S03 y S06 dicen qué datos
  se anotan ese día; los demás planes los piden en "Notas post-sesión".
