> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Índice de la unidad · S07–S13 · jueves 15 a jueves 29 de octubre de 2026 · lunes y jueves 10:30–12:00, martes 08:30–10:00 · Salón 3208 / Lab LS4 (Edificio 3)

# Unidad III · Programación en memoria compartida con OpenMP (segunda mitad)

Esta carpeta tiene las siete sesiones que van del **jueves 15 al jueves 29 de octubre de 2026** (S07–S13), la
guía de estudio del Examen 2 y los enlaces a la Práctica 4 y al hito H1 del proyecto. La primera mitad de la
unidad (1–13 de octubre: regiones paralelas, `parallel for`, alcance de variables, `reduction` y una primera
medición de *speedup*) se dio antes de este material y se da por sabida (`planeacion/calendario-27-1.md`,
supuesto 1).

| Si eres… | Empieza por… |
|---|---|
| Estudiante que va al día | La carpeta de la sesión de hoy: `retrieval-inicio.md` en clase, `notas-estudiante.md` y `tarea-espaciada.md` después |
| Estudiante que faltó | [§5 · Cómo recuperar una sesión perdida](#5-cómo-recuperar-una-sesión-perdida) |
| Estudiante que prepara el Examen 2 | [`guia-estudio-E2.md`](guia-estudio-E2.md) |
| Profesor que da la sesión | `plan-sesion.md` y `conceptests.md` de la carpeta ([§8](#8-para-el-profesor)) |

## 1. Objetivos de la unidad

Al terminar la unidad (jueves 29 de octubre) podrás, **sin computadora y en papel** salvo donde se indica:

1. **Diagnosticar** la condición de carrera de un fragmento OpenMP de 15 líneas o menos, nombrando la variable
   compartida que se escribe y los dos accesos sin orden, y **corregirla** con la construcción más barata que sea
   correcta (`reduction`, `atomic`, `critical` o candado, acumulador local), diciendo por qué descartas las otras
   dos. (S07)
2. **Predecir** la salida de un fragmento dado a partir del alcance de cada variable (`shared`, `private`,
   `firstprivate`, declarada adentro, implícita en una tarea) y de sus barreras (`barrier`, `nowait`, `single`,
   `master`). Justificas cada valor en una línea. (S07, S09)
3. **Escribir** el reparto de iteraciones de `schedule(static)` y `schedule(static, c)` para `n` y `p` dados, y
   **elegir** política y *chunk* para un ciclo nuevo a partir de la forma de su carga, con una tabla de tiempos
   medida que lo respalde. (S08)
4. **Paralelizar** una recursión o una lista enlazada con `task`, `taskwait` y corte, **contar** cuántas tareas
   se crean y **elegir** el corte con una medición. (S09; Práctica 4, Parte B)
5. **Medir** un programa con el protocolo del curso (en computadora: `-O2`, calentamiento, mediana de 5, mejor
   secuencial como `T(1)`) y **calcular** *speedup*, eficiencia, eficiencia débil, la cota de Amdahl con la
   fracción **medida en tiempo** y la fracción de Karp–Flatt, con dos decimales y a mano. (S10, S12; Práctica 4,
   Parte D)
6. **Identificar** cuál de cuatro causas limita la escalabilidad de un ciclo (fracción secuencial, ancho de banda,
   sobrecarga de regiones o tareas, falso compartido) a partir de una tabla, y **proponer** la corrección. (S10)
7. **Reconocer** en un ciclo la reducción sobre arreglo, el *scan*, el *stencil* y el *pipeline*; **decidir** si
   tiene dependencias entre iteraciones; y **justificar** si `omp simd` puede ayudar, con el reporte del
   compilador y la medición. (S11)
8. **Convertir** una V1 secuencial en un plan de V2: perfil por secciones, fracción paralelizable, lista de lo que
   lee y escribe el ciclo caliente y estrategia justificada con Foster. (S12; H1)
9. **Calibrar** tu juicio: anotar la calificación que esperas antes y después de un examen y compararla con la
   real. (S13; Examen 2)

## 2. Sesiones

Horario del grupo: lunes 10:30–12:00 y jueves 10:30–12:00 en el Salón 3208; martes 08:30–10:00 en el Lab LS4.
Cada carpeta tiene `plan-sesion.md`, `retrieval-inicio.md`, `notas-estudiante.md`, `ejemplo-resuelto.md`,
`conceptests.md`, `practica-guiada/` (código, `Makefile`, `tests/`), `exit-ticket.md` y `tarea-espaciada.md`.

| Sesión | Fecha y lugar | Tipo | Tema | Carpeta | Práctica guiada (PRIMM) |
|---|---|---|---|---|---|
| S07 | jueves 15 de octubre, 10:30 · 3208 | Contenido | Corrección en memoria compartida: condiciones de carrera, `critical`, `atomic`, candados, `barrier`, `nowait`; ThreadSanitizer. Se publica la Práctica 4 | [`S07_2026-10-15_sincronizacion/`](S07_2026-10-15_sincronizacion/) | [Histograma: de la carrera a la corrección](S07_2026-10-15_sincronizacion/practica-guiada/README.md) |
| S08 | lunes 19 de octubre, 10:30 · 3208 | Contenido | Planificación y balance de carga: `schedule(static/dynamic/guided, chunk)`, `runtime`, `collapse`; experimentos | [`S08_2026-10-19_planificacion/`](S08_2026-10-19_planificacion/) | [¿Qué hilo ejecuta qué iteración y cuánto tarda?](S08_2026-10-19_planificacion/practica-guiada/README.md) |
| S09 | martes 20 de octubre, 08:30 · LS4 | Laboratorio | Tareas (`task`, `taskwait`, `taskloop`, corte) + Práctica 4 · Laboratorio 1 (Partes A y B, mini-defensas) | [`S09_2026-10-20_tareas-lab1/`](S09_2026-10-20_tareas-lab1/) | [Mergesort con tareas: cuántas, quién y con qué corte](S09_2026-10-20_tareas-lab1/practica-guiada/README.md) |
| S10 | jueves 22 de octubre, 10:30 · 3208 | Contenido | Rendimiento: protocolo de medición, *speedup*/eficiencia/escalabilidad, Amdahl con datos medidos, Karp–Flatt, falso compartido, afinidad, sobrecarga | [`S10_2026-10-22_rendimiento/`](S10_2026-10-22_rendimiento/) | [Medir sin engañarse: falso compartido, sobrecarga y escalabilidad](S10_2026-10-22_rendimiento/practica-guiada/README.md) |
| S11 | lunes 26 de octubre, 10:30 · 3208 | Contenido | Patrones: reducción sobre arreglo, *scan*, *stencil* (Jacobi), *pipeline*; `omp simd` y vectorización | [`S11_2026-10-26_patrones-simd/`](S11_2026-10-26_patrones-simd/) | [Jacobi 1D con doble búfer, `reduction(max)` y `simd`](S11_2026-10-26_patrones-simd/practica-guiada/README.md) |
| S12 | martes 27 de octubre, 08:30 · LS4 | Laboratorio | Práctica 4 · Laboratorio 2 (Partes C y D, punto de control, mini-defensas) + taller "cómo paralelizar tu V1" | [`S12_2026-10-27_lab2-proyecto/`](S12_2026-10-27_lab2-proyecto/) | [¿Dónde está el tiempo? Perfilado por secciones y plan de la V2](S12_2026-10-27_lab2-proyecto/practica-guiada/README.md) |
| S13 | jueves 29 de octubre, 10:30 · 3208 | Repaso + hito | **H1 · Avance 1 del proyecto** en clase; repaso de la unidad: [examen de práctica](S13_2026-10-29_H1-repaso/examen-practica-U3.md), corrección entre pares, calibración | [`S13_2026-10-29_H1-repaso/`](S13_2026-10-29_H1-repaso/) | [Cazador de errores: tres programas, un error cada uno](S13_2026-10-29_H1-repaso/practica-guiada/README.md) (en casa) |
| — | lunes 2 de noviembre | Sin clase | Día de Muertos | — | — |
| E2 | martes 3 de noviembre, 08:30 · 3208 (o LS4) | **Examen** | **Examen departamental 2 · Unidad III** (versiones A/B, 80 min) | [`guia-estudio-E2.md`](guia-estudio-E2.md) | — |

Para correr una práctica guiada: `cd <carpeta>/practica-guiada && make && make test` (todas tienen `all`, `run`,
`test` y `clean`). El número de hilos se fija con `OMP_NUM_THREADS`.

## 3. Entregas, hitos y fechas

Ponderaciones del 2.º parcial según [`planeacion/mapa-evaluacion.md`](../../planeacion/mapa-evaluacion.md):
**supuestas por simetría con el 1.er parcial, por confirmar por el profesor.** Las reglas de entrega tardía y
segunda entrega son las de [`docs/metodo/04-evaluacion.md`](../../docs/metodo/04-evaluacion.md) §5.

### 3.1 Lo que cuenta para la calificación

| Entrega | Fecha límite | Peso | Dónde y cómo |
|---|---|---|---|
| **Práctica 4 · OpenMP** (en equipo) | **domingo 1 de noviembre, 23:59** (etiqueta `P4-entrega`) | **40 %** | [`practicas/P4-openmp/`](../../practicas/P4-openmp/README.md): enunciado, [`entrega.md`](../../practicas/P4-openmp/entrega.md) y [`rubrica.md`](../../practicas/P4-openmp/rubrica.md). Tardía hasta el miércoles 4 de noviembre, 23:59, con máximo 80 % y sin segunda entrega. Retroalimentación a más tardar el domingo 8 de noviembre. Segunda entrega solo si la primera obtiene < 70 %: dentro de los 7 días siguientes a la retroalimentación, con tope de 80 % |
| **Examen departamental 2** (individual) | **martes 3 de noviembre, 08:30–10:00** | **40 %** | Salón 3208 (o Lab LS4 con los equipos apagados). Calificación y clave a más tardar el martes 10 de noviembre; análisis de errores el jueves 12 de noviembre (U4 S04). Preparación: [`guia-estudio-E2.md`](guia-estudio-E2.md) |
| **H1 · Avance 1 del proyecto** (en equipo) | **jueves 29 de octubre**: etiqueta `H1` antes de las **10:30**; recepción en clase (S13) | **12 %** | [`proyecto/hitos/H1-avance-1.md`](../../proyecto/hitos/H1-avance-1.md): V1 secuencial, diseño de Foster, perfil por secciones y plan de V2. Tardía hasta el domingo 1 de noviembre, 10:30, con máximo 80 %. Rúbrica por escrito a más tardar el jueves 5 de noviembre |
| Tareas espaciadas y ejercicios | antes de la sesión indicada en cada `tarea-espaciada.md` (tabla 3.2) | 5 % | (entregadas a tiempo / total) × calidad promedio de 3 revisadas al azar. Se autocalifican con la clave al inicio de la sesión siguiente |
| *Exit tickets* y recuperación | cada sesión | 3 % | Por participación, no por acierto. Dos ausencias no descuentan |

### 3.2 Calendario de entregas de la unidad

| Fecha y hora | Qué se entrega | Archivo de referencia |
|---|---|---|
| lunes 19 de octubre, 10:30 | Tarea de S07 (`tareas/S07/`) | [S07 `tarea-espaciada.md`](S07_2026-10-15_sincronizacion/tarea-espaciada.md) |
| martes 20 de octubre, 08:30 | **Pre-laboratorio de la Práctica 4**, individual (`practicas/P4/prelab/`), faltes o no. La carpeta de la práctica quedó completa la noche del lunes 19; si casi nadie alcanzó a entregarlo, el plan de S09 prevé que el profesor anuncie al cierre una fecha nueva (propuesta: jueves 22 de octubre, 10:30). Vale la que se anuncie | [P4 `README.md`](../../practicas/P4-openmp/README.md), "Pre-laboratorio" |
| jueves 22 de octubre, 10:30 | Tareas de S08 (`tareas/S08.md`) y de S09 (`tareas/S09/`) | [S08](S08_2026-10-19_planificacion/tarea-espaciada.md) · [S09](S09_2026-10-20_tareas-lab1/tarea-espaciada.md) |
| lunes 26 de octubre, 10:30 | Tarea de S10 (`tareas/S10/`) | [S10 `tarea-espaciada.md`](S10_2026-10-22_rendimiento/tarea-espaciada.md) |
| martes 27 de octubre, 08:30 | Práctica 4, Partes A y B terminadas (`make test-a`, `make test-b` en `0 FAIL`); Parte C avanzada para el Laboratorio 2 | [P4 `entrega.md`](../../practicas/P4-openmp/entrega.md) §1 |
| martes 27 de octubre | Se publica el examen de práctica; se resuelve **en casa**, cronometrado a 40 min, antes del jueves 29 a las 10:30. No tiene peso: sirve para calibrar | [`examen-practica-U3.md`](S13_2026-10-29_H1-repaso/examen-practica-U3.md) |
| jueves 29 de octubre, 10:30 | **H1** (etiqueta `H1`). Tareas de S11 (`tareas/S11.md`) y de S12 (la parte 1a va dentro de H1) | [S11](S11_2026-10-26_patrones-simd/tarea-espaciada.md) · [S12](S12_2026-10-27_lab2-proyecto/tarea-espaciada.md) · [H1](../../proyecto/hitos/H1-avance-1.md) |
| domingo 1 de noviembre, 23:59 | **Práctica 4 completa** (etiqueta `P4-entrega`) | [P4 `entrega.md`](../../practicas/P4-openmp/entrega.md) |
| martes 3 de noviembre, 08:30 | Tarea de S13 (`tareas/S13/`) y **Examen 2** | [S13 `tarea-espaciada.md`](S13_2026-10-29_H1-repaso/tarea-espaciada.md) · [`guia-estudio-E2.md`](guia-estudio-E2.md) |
| jueves 5 de noviembre, 10:30 (U4 S01) | Pregunta individual de H1 (primeros 20 min) y pregunta posterior de la Práctica 4 a 2–3 equipos | [H1](../../proyecto/hitos/H1-avance-1.md) · [P4 `entrega.md`](../../practicas/P4-openmp/entrega.md) §1 |

Carga orientativa fuera de clase (`planeacion/calendario-27-1.md`): 3 h la semana del 15 al 18 de octubre, 5 h
la del 19 al 25 y 6 h la del 26 de octubre al 1 de noviembre (Parte D y reporte de P4, H1 y estudio del E2).

## 4. Requisitos de software

| Qué | Para qué en esta unidad | Notas |
|---|---|---|
| `gcc` con OpenMP (`-fopenmp`) | Todo el código: `gcc -std=c11 -O2 -Wall -Wextra -fopenmp` | El material se escribió y probó con gcc 13.3. El README del curso pide gcc ≥ 9; el `collapse(2)` sobre un ciclo triangular de S08 §6 necesita gcc ≥ 11 |
| ThreadSanitizer (`-fsanitize=thread`) | Localizar carreras (S07, S08, S09, S11, S12, S13: `make tsan`) | Viene con gcc en Linux. Con gcc da falsos positivos en código sincronizado por `libgomp` (S07 §2) |
| `make` y `bash` | `make`, `make test`, `tests/run_tests.sh`, `medir.sh` | Todas las carpetas con código tienen `all`, `run`, `test` y `clean` |
| Python 3 con `matplotlib` | Gráficas de *speedup* y eficiencia (S10 `graficar.py`; P4 `graficar.py`; `herramientas/graficar_speedup.py`) | Sin `matplotlib`, la gráfica se hace a mano con la tabla que imprime el programa |
| `git` | Repositorio privado del equipo: tareas, pre-lab, etiquetas `H1` y `P4-entrega` | Un *commit* por `TODO` resuelto, con autor real |
| `lscpu`, `nproc`, `uptime` | Declarar núcleos físicos y carga antes de medir (S10, S12) | Afinidad: `OMP_PROC_BIND=close OMP_PLACES=cores`; en macOS `OMP_PROC_BIND` no está soportado (S10 `practica-guiada/README.md`) |
| `objdump` (binutils) | S11: Investigar I5 y Modificar M1b (ver el ensamblador de `simd`) | Viene con `binutils`, que se instala junto con `gcc` |

Basta una laptop por pareja. Sin compilador, las fases Predecir e Investigar de PRIMM se hacen en papel con la
salida proyectada. El protocolo de medición está en
[`herramientas/protocolo-medicion.md`](../../herramientas/protocolo-medicion.md).

## 5. Cómo recuperar una sesión perdida

Regla del curso (`docs/metodo/04-evaluacion.md` §5 y `01-marco-pedagogico.md`, P10): todo el material es
autocontenido, y el *exit ticket* y la recuperación del día que faltaste se sustituyen **entregando la
`tarea-espaciada.md` de esa sesión en la fecha que ella indica** (tabla 3.2; casi siempre, el inicio de la sesión
siguiente). Cuenta como participación. Orden de trabajo (≈ 1.5 h, lo mismo que la clase):

| Paso | Archivo de la carpeta de la sesión | Tiempo | Qué haces |
|---|---|---|---|
| 1 | `notas-estudiante.md` | 10 min | Lee el concepto, la tabla principal y los errores frecuentes |
| 2 | `ejemplo-resuelto.md` | 20 min | Responde cada pausa ("¿por qué este paso?") **por escrito** antes de abrir su `<details>` |
| 3 | `practica-guiada/README.md` | 25–40 min | PRIMM completo: escribe las predicciones antes de compilar; `make test` debe pasar |
| 4 | `tarea-espaciada.md` | 20–40 min | Entrégala en el repositorio del equipo en la fecha que indica (tabla 3.2); sustituye *exit ticket* y recuperación |
| 5 (opcional) | `retrieval-inicio.md` y `exit-ticket.md` | 10 min | Contéstalos sin apuntes y corrige con la clave en `<details>`; así sabes si de verdad recuperaste la sesión |

Casos particulares:

- **Laboratorios (S09 y S12).** Las Partes de la Práctica 4 se siguen haciendo con tu equipo. El pre-laboratorio
  se entrega antes de la hora de la sesión, faltes o no. Si te tocaba **mini-defensa**, se hace en la siguiente
  sesión de laboratorio (para S09, el martes 27 de octubre; para S12, el martes 10 de noviembre) o en la reserva
  del martes 15 de diciembre (`04` §5); `03-plantilla-practica.md` §1 y el plan de S12 ofrecen en cambio un video
  de 3 minutos o menos, no listado. Pregunta al profesor cuál aplica.
- **S09.** Si ese día la Práctica 4 aún no estaba publicada, en su lugar se hicieron A′ y B′; lo que hayan dejado
  en `practicas/P4/lab1/` cuenta como avance de las Partes A y B (S09 `plan-sesion.md`, Plan B de P4, y
  `notas-estudiante.md`, primer párrafo).
- **S13.** El examen de práctica se hace en casa con la clave y la hoja de calibración se registra igual. **H1**
  con justificante institucional se recibe en la sesión siguiente al 100 %; sin justificante aplica la regla de
  72 h al 80 %. La pregunta individual de H1 es el jueves 5 de noviembre.
- **Asesoría.** Se da por protocolo: primero escribes qué intentaste y qué observaste (comando, salida, lo que
  esperabas); después se atiende.

## 6. Ideas erróneas del Anexo A que trabaja la unidad

Catálogo completo en [`docs/metodo/01-marco-pedagogico.md`](../../docs/metodo/01-marco-pedagogico.md),
Anexo A. Son las que alimentan los distractores de los ConcepTests, de los *exit tickets* y del Examen 2. La
guía de estudio las repasa con preguntas en su §4.

| # | Idea errónea | Lo correcto, en una línea | Dónde se trabaja |
|---|---|---|---|
| 1 | "Más hilos siempre es más rápido" | Lo limitan la fracción secuencial, la memoria, la sincronización y la creación de hilos | S08, S09, S10, S11 |
| 2 · 2b | "La fracción de Amdahl se mide en líneas" · "el *speedup* de la sección es el del programa" | Se mide en **tiempo** de la versión secuencial; se reporta el total | S10, S12 |
| 3 | "Eficiencia y *speedup* son lo mismo" | `E = S/p` | S10, S12 |
| 4 · 4b | "El superlineal es un error" · "una `f` de Karp–Flatt negativa demuestra algo del código" | Puede ser caché; se explica. `f < 0` solo dice que Amdahl no describe esos datos | S10 |
| 5 | "Medir una vez basta" / "se mide con `-O0`" | Mediana de ≥ 5 con calentamiento, `-O2` | S08, S10, S12 |
| 6 | "Escalabilidad fuerte y débil son sinónimos" | Fuerte: mismo `n`; débil: `n` crece con `p` | S10 |
| 7 · 7d | "Si salió bien, no hay carrera" · "índices `i` distintos nunca escriben la misma posición" | Una carrera es no determinista; la posición escrita (`hist[bin]`) puede coincidir | S07, S08, S09, S13 |
| 8 | "`critical` y `atomic` son equivalentes" | `atomic`: una actualización simple de una variable; `critical`: código arbitrario | S07, S11 |
| 9 | "`private` copia el valor inicial" | Queda indefinida; para copiar, `firstprivate` | S07, S13 |
| 10 · 10b | "`reduction` da exactamente lo mismo que la suma secuencial" · "`reduction` combina variables que van juntas" | En punto flotante se compara con tolerancia; cada variable se combina por separado | S07, S11, S13; P4 |
| 11 · 11b | "`dynamic` siempre gana" · "el reparto solo afecta la correctitud" | `dynamic` cuesta por *chunk*; el reparto fija el tiempo del hilo más lento | S08, S09, S13 |
| 12 | "Al final de `omp for` no hay barrera" | Sí la hay, salvo `nowait` | S07, S08 |
| 13 · 13b · 13c · 13d | "La tarea se ejecuta al crearse" · "con un hilo es una llamada directa" · "solo el `single` crea tareas" · "`taskwait` es una barrera de hilos" | Se encola; `taskwait` espera a las hijas directas, sin importar qué hilo las ejecute | S09 |
| 14 · 14b | "El falso compartido no existe" · "casillas distintas del mismo arreglo son carrera" | Casillas distintas no son carrera; comparten la línea de caché y se estorban | S10, S11 |
| 15 | "Lo declarado dentro de la región es compartido" | Es privado por alcance | S07, S09 |
| 28 · 29 | "Aglomerar es juntar todo" · "primero se programa y luego se diseña" | Aglomerar reduce sobrecarga sin perder paralelismo; primero se mide y se listan dependencias | S12; H1 |
| 30 · 30b · 30c | "Cualquier `for` se paraleliza" · "una recurrencia se arregla con `reduction`" · "`ordered` lo corrige sin costo" | Con dependencia entre iteraciones se cambia el algoritmo (*scan* en dos fases) | S07, S11, S13; P4 Parte C |
| 31 | "`clock()` mide tiempo de pared" / "`T(1)` es la paralela con 1 hilo" | `omp_get_wtime()`; `T(1)` es el mejor secuencial | S09, S10 |
| 32 | "Un `barrier` dentro de un `if` está bien" | Todos los hilos del equipo deben llegar a la misma barrera | S07, S13 |

## 7. Otros documentos que usa la unidad

- [`guia-estudio-E2.md`](guia-estudio-E2.md): temario con pesos, banco de 30 preguntas, plan de 5 días, día del
  examen y hoja de calibración.
- [`practicas/P4-openmp/`](../../practicas/P4-openmp/README.md): Práctica 4 (Partes A–D).
- [`proyecto/hitos/H1-avance-1.md`](../../proyecto/hitos/H1-avance-1.md): lo que pide H1.
- [`herramientas/protocolo-medicion.md`](../../herramientas/protocolo-medicion.md): cómo se mide en el curso.
- [`docs/metodo/05-politica-ia.md`](../../docs/metodo/05-politica-ia.md): semáforo de IA; la recuperación de
  inicio, los exámenes y la defensa oral son zona sin IA.

## 8. Para el profesor

- **Antes de cada sesión (20 min, `01-marco-pedagogico.md` §4):** leer completos `plan-sesion.md` y
  `conceptests.md`, correr `make test` de `practica-guiada/` en la máquina del salón y leer la clave del
  `exit-ticket.md`. Cada plan declara su nivel de andamiaje, sus ideas erróneas y su lista de errores esperados
  con la pregunta socrática.
- **Laboratorios:** S09 y S12 llevan mini-defensas y punto de control de la Práctica 4; el registro está en sus
  planes. S09 trae un Plan B por si `practicas/P4-openmp/` no estaba completa a las 08:00.
- **S13** combina la recepción de H1 (opción A de `proyecto/hitos/H1-avance-1.md` §8) con el repaso; el plan
  asume que el examen de práctica se publicó el martes 27 de octubre.
- **Examen 2:** tabla de especificaciones, versiones A/B, claves, instrucciones de aplicación, hoja de calibración
  y código verificado en `docente/examenes/E2/` (no se publica). La guía de estudio toma de ahí solo los pesos por
  tema, la estructura con los minutos sugeridos, las instrucciones de portada y el modelo de la hoja de
  calibración, sin ítems.
- **Registro:** `herramientas/seguimiento-grupo.csv` (la copia llena vive en `docente/`).
