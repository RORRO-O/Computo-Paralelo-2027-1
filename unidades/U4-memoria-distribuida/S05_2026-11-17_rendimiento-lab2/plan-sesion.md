> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · Rendimiento en MPI: modelo de costo, escalabilidad fuerte y débil, sobre-suscripción; MPI+OpenMP (panorama) · Práctica 5 · Laboratorio 2

**Tipo:** laboratorio (variante 2.1 adaptada): recuperación 5 min · mini-lección 25 min · 50 min de Práctica 5
Lab 2 con punto de control y mini-defensas · *exit ticket*.

## Objetivos (al terminar, el estudiante podrá…)

1. **Calcular** el costo de un mensaje con `T_com = α + m/β` a partir de α y β medidos con el *ping-pong*, y
   **predecir** con ese modelo el *speedup* de Jacobi 1D para un n dado. (aplicar)
2. **Medir** escalabilidad fuerte (n fijo) y débil (n/p fijo) con el protocolo del curso, **producir** el CSV y la
   gráfica, y **etiquetar aparte** las mediciones sobre-suscritas. (aplicar / analizar)
3. **Explicar**, con la razón cómputo/comunicación por iteración, por qué el *speedup* depende de n, y
   **estimar** el n mínimo a partir del cual conviene usar p procesos. (analizar / evaluar)
4. **Describir** el modelo híbrido MPI+OpenMP: compilar y ejecutar un programa con ambos niveles e identificar
   qué pide `MPI_Init_thread`. (comprender)

Los objetivos 1–3 se evalúan en el *exit ticket* (P1 → obj. 3; P2a → obj. 1 y 3; P2b → obj. 2) y en el punto de
control de la P5. El objetivo 4 se verifica con `make run-hibrido` en la práctica y en la recuperación de S06.

## Prerrequisitos y vínculo

- **Viene de:** S04 (jueves 12 de noviembre): descomposición de dominio, halos en Jacobi 1D, `Isend`/`Irecv`/
  `Waitall`. También S02 (lunes 9 de noviembre): *ping-pong* con latencia y ancho de banda; U3 S10: protocolo
  de medición, Karp–Flatt; U1: Amdahl, Gustafson, eficiencia.
- **Va hacia:** S06 (jueves 19 de noviembre): cierre de la Unidad IV y taller hacia H2 (V2 con *speedup*);
  Práctica 5 (vence domingo 22 de noviembre, 23:59); U5 S04 (rendimiento en GPU: el mismo razonamiento con
  transferencias en vez de mensajes).
- **Ideas erróneas que ataca (Anexo A):** **21** ("la comunicación es gratis") · **20** ("más procesos que
  núcleos siempre está bien") · **6** ("fuerte y débil son sinónimos") · **1** ("más procesos siempre es más
  rápido"). Dónde aparece cada una: 21 → CT1, *exit ticket* P1/P2a, fase Investigar; 20 → CT3, fila `mpi_oversub`
  del script, *exit ticket* P2b; 6 → CT2, las dos tablas del script; 1 → CT1 distractor A, fase Predecir con n
  pequeño.

## Materiales

- Esta carpeta completa; `practica-guiada/` compilada en la máquina del profesor **antes** de la sesión
  (`make && make test`, ~30 s) y una corrida completa de `make run` ya hecha (toma ~1 min; los PNG se proyectan
  sin esperar). `practica-guiada/resultados-ejemplo/` tiene la corrida del entorno de autoría por si falla la local.
- Proyector, cronómetro visible, tarjetas con números de lista, rúbrica de P5 impresa (para las mini-defensas).
- Cada equipo: su repositorio de P5 con las Partes A–C funcionando (requisito para medir la Parte D) y
  `nproc`/`lscpu` a la mano para declarar los núcleos físicos.
- Pizarrón: dejar escrito desde el inicio el encabezado del CSV del protocolo y las dos fechas de entrega.

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar `retrieval-inicio.md` (5 preguntas). A los 4 min, respuestas; manos por pregunta.
- Si la P1 o la P2 (halos, `Waitall`) quedan < 60 %: proyectar `jacobi_mpi.c` líneas del intercambio de halos
  (`Irecv`, `Irecv`, `Isend`, `Isend`, `Waitall`) y rastrear 2 minutos con tres procesos en el pizarrón. Se toman
  de la mini-lección, no del cierre.
- Si la P4 (columnas del CSV) falla: el encabezado queda escrito en el pizarrón toda la sesión.

### 5–8 · Objetivos y anclaje

Frase de arranque: "El jueves medimos cuánto tarda un mensaje (*ping-pong*) y escribimos Jacobi con halos. Hoy
juntamos las dos cosas: ¿cuándo vale la pena repartir un problema entre procesos? La respuesta es un número, y
hoy lo van a calcular para su propio programa de la Práctica 5." Conectar con el *exit ticket* de S04 (error
más frecuente: se anota aquí: ______). Leer los 4 objetivos. Mostrar en qué parte de la rúbrica de P5 entra
cada uno ("Medición" 20 % e "Interpretación" 20 %).

### 8–33 · Mini-lección (25 min) con ConcepTests 1 y 2

**8–14 · Modelo de costo con los números del *ping-pong*.** Correr en vivo `make run-pingpong`
(`mpirun -np 2 ./pingpong`, ~15 s). Mientras corre, escribir `T_com(m) = α + m/β`. Leer de la salida: α ≈ fila
de 8 bytes; β ≈ ajustado con 1 MiB. Pensar en voz alta: "Para 8 bytes, m/β es ~0.005 µs: no se ve. Para 1 MiB,
α no se ve. Dos regímenes." Decir explícitamente: *los números de hoy son de esta máquina; en su reporte usan
los del laboratorio donde midieron, con la misma herramienta y declarando el hardware*. Mostrar la columna
`modelo(us)`: el modelo lineal de dos parámetros falla en los tamaños intermedios (1 KiB–64 KiB): es una
aproximación, suficiente para decidir, no para predecir al 5 %.

**14–19 · Razón cómputo/comunicación con Jacobi.** En el pizarrón, por iteración y por proceso interior:
cómputo = (n/p)·t_c; comunicación = 2 mensajes de 8 bytes ≈ 2α (constante, **no depende de n**). Con
t_c ≈ 0.8 ns (lo imprime `jacobi_seq`: "ns por punto-iteración") y α ≈ 0.5 µs:

| n | cómputo con p=4 | comunicación | razón | *speedup* esperado |
|---|---|---|---|---|
| 1 000 | 250 ns | ~1 µs | 0.25 | < 1 |
| 100 000 | 25 µs | ~1 µs | 25 | ≈ 3.8 |
| 1 000 000 | 250 µs | ~1 µs | 250 | ≈ 4 (si la memoria no limita) |

**ConcepTest 1 (minuto ~17)**: n = 1 000, ¿*speedup* con 4? Voto → si < 80 % discusión en parejas → revoto.
Guion en `conceptests.md`. Regla en una frase: "la comunicación por iteración es fija; el cómputo es n/p; por eso
hay un n mínimo".

**19–26 · Escalabilidad fuerte y débil; sobre-suscripción.** Proyectar `resultados/fuerte.csv` y `debil.csv` de la
corrida previa (o `resultados-ejemplo/`). Señalar: misma cabecera que el protocolo; en débil, n crece con p y la
columna `eficiencia` es la **eficiencia débil** `T(1,n)/T(p,p·n)`; la columna `speedup` ahí es el *speedup*
escalado (Gustafson). Mostrar las dos gráficas (`fuerte.png`, `debil.png`): la línea ideal, los puntos medidos y
el punto hueco naranja de p = 8 ("p > núcleos"). Explicar la sobre-suscripción con una pregunta: "¿qué hace un
proceso MPI mientras espera un halo?" (sondeo activo: consume el núcleo). Con 8 procesos en 4 núcleos los que
esperan le quitan CPU a los que calculan. Mostrar también la línea `carga_promedio_1min_antes_de_medir` de
`entorno.txt`: con p = núcleos, **cualquier** otro programa activo (navegador, otra corrida de un compañero en
la misma máquina) produce el mismo efecto que sobre-suscribir. Es la razón del paso 1.5 del protocolo.
**ConcepTest 2 (minuto ~25)**: leer la tabla de escalabilidad débil. Regla: "fuerte: n fijo, se reporta
*speedup*; débil: n/p fijo, se reporta eficiencia débil; las dos van etiquetadas".

**26–31 · Híbrido MPI+OpenMP en 5 minutos.** Correr `make run-hibrido` (`OMP_NUM_THREADS=2 mpirun -np 2
./hybrid_min`). Leer la salida: 2 procesos × 2 hilos = 4 unidades de ejecución, nivel `MPI_THREAD_FUNNELED`
pedido y provisto. Proyectar las 12 líneas centrales de `hybrid_min.c`: `MPI_Init_thread` (en vez de
`MPI_Init`) pide un nivel: SINGLE < FUNNELED < SERIALIZED < MULTIPLE; con FUNNELED solo el hilo principal llama a
MPI, que es lo que hace el patrón "OpenMP adentro, MPI afuera". Para qué sirve: un proceso por nodo (o por
*socket*) y hilos adentro reduce mensajes y memoria duplicada (halos). Cerrar con la advertencia práctica:
`OMP_NUM_THREADS × np ≤ núcleos`, si no, sobre-suscripción otra vez. Es panorama: no entra en P5; sí puede entrar
en la discusión del reporte final del proyecto.

**31–33 · Arranque de la práctica.** Instrucciones: parejas o equipos de P5; `practica-guiada/README.md`
abierto; primero la hoja de predicción (fase P), después `make run` con los tamaños del README. Recordar los
roles conductor/navegante y el cambio a los 15 min.

### 33–85 · Práctica 5 · Laboratorio 2 (52 min): PRIMM con el script + mediciones de la Parte D

**33–48 · Predecir → Ejecutar → Investigar (15 min)** con `practica-guiada/`:
- *Predecir* (3 min, por escrito): *speedup* con 2 y 4 procesos para n = 1 000 000 y para n = 1 000; ¿cuál
  será mayor, T(seq) o T(mpi, p=1)?; ¿qué pasa con p = 8?
- *Ejecutar* (5 min): `make run` (tamaños por defecto, ~1 min en 4 núcleos) y
  `N=1000 ITERS=100000 NLOCAL=1000 OVERSUB="" PLOT=0 OUT=resultados-chico ./escalado.sh`. Comparar con la
  predicción.
- *Investigar* (7 min): preguntas del README sobre la línea "razón cómputo/comunicación" que imprime
  `jacobi_mpi` (correr `make run-fuerte NP=4 N=4000 ITERS=20000` y `... N=1000000 ITERS=500`), y sobre la
  fila `mpi_oversub`.

**48–68 · Modificar = aplicar a la Parte D de la P5 (20 min).** Cada equipo copia `escalado.sh` a su repositorio
de P5 y lo adapta a su programa (cambiar los nombres de los binarios y los argumentos; conservar el encabezado
del CSV y las 5 repeticiones). Corren fuerte y débil con **sus** tamaños (T(1) ≥ 1 s). Mientras tanto, el
profesor circula con la rúbrica y hace las **mini-defensas**: 2 min por equipo, **dos preguntas a cada
integrante** sobre su propio código de P5 ("¿qué hace esta línea?", "¿qué pasa si la quito?"); candidatas: la
`MPI_Barrier` antes de `MPI_Wtime`, el `MPI_Waitall`, el `MPI_Reduce` con `MPI_MAX` del tiempo, el reparto con
residuo. Se anota en la rúbrica impresa quién no pudo explicar su código (criterio "Proceso e integridad").
Cambio de roles conductor/navegante al minuto 55.

**68–80 · Punto de control (12 min).** Cada equipo, en 1 minuto, muestra su tabla de escalabilidad fuerte y su
tabla débil (o la de la práctica guiada si la suya aún no sale) y responde: "¿dónde deja de escalar y por qué?"
Orden por tarjeta de lista. El profesor anota en la tabla de abajo. **ConcepTest 3 (minuto ~75)** cuando aparezca
la primera tabla con p = 8 mezclado (aparece siempre).

**80–85 · Transferencia (5 min, se recorta si el punto de control se alarga).** Fase *Crear*: con sus α y t_c,
`python3 modelo.py --alpha-us <α> --beta-gbps <β> --tc-ns <t_c> --p 4` para obtener n* y n_E(50 %); verificar
con una corrida de `jacobi_mpi` cerca de n*. Criterio de "listo": una línea en su reporte con n* calculado y
el *speedup* medido cerca de n*. Quien no arranca: usar los números del ejemplo resuelto. Quien termina: repetir
con p = 2 y explicar por qué n* es distinto (el factor 1 − 1/p).

### 85–90 · Cierre

*Exit ticket* en papel (`exit-ticket.md`): 2 preguntas + confianza. Anuncios, escritos en el pizarrón:
- **Práctica 5**: vence el **domingo 22 de noviembre de 2026, 23:59**, en el repositorio del equipo (Parte D
  con las dos tablas, CSV + PNG, `REPORTE.md` con la razón cómputo/comunicación y la fila sobre-suscrita aparte).
- **H2 · Avance 2 del proyecto**: **lunes 23 de noviembre, en clase** (V2 memoria compartida + *speedup* con el
  protocolo). El taller del jueves 19 es para dejarlo listo.
- Tarea espaciada (`tarea-espaciada.md`): antes del jueves 19 de noviembre, 10:30.

## Lista de errores esperados en la práctica (y la pregunta que se hace ante cada uno)

| Síntoma | Pregunta socrática |
|---|---|
| El *speedup* con p = núcleos es muy bajo (incluso < 1 con n grande) y las 5 repeticiones varían 3× | "¿Qué dice `carga_promedio_1min_antes_de_medir` en `entorno.txt`? ¿Qué hace un proceso MPI mientras espera un halo? ¿Qué más está corriendo en esta máquina?" |
| Calculan el *speedup* contra `mpi,1` en vez de `seq` | "¿Contra qué T(1) dice el protocolo? ¿Qué diferencia ves entre las filas `seq` y `mpi,1`? ¿A qué se debe?" |
| Tamaño tan chico que T_seq < 0.1 s ("así corre rápido") | "Con una corrida de 20 ms, ¿qué estás midiendo: el trabajo o el arranque? ¿Qué pide el protocolo para T(1)?" |
| La fila p = 8 va en la curva junto con 1, 2, 4; "MPI escala mal" | "¿Cuántos núcleos tiene cada proceso con p = 8? ¿Qué etiqueta trae esa fila en el CSV?" |
| En su tabla de P5 cambian n entre configuraciones y la llaman "fuerte" | "En tu tabla, ¿qué columna se quedó fija: n o n/p? ¿Qué experimento es entonces?" |
| `mpirun` dice "There are not enough slots available" | "¿Cuántos slots detecta `mpirun` y cuántos pediste? ¿Qué bandera declara que sabes que estás sobre-suscribiendo?" |
| En el híbrido, sin `OMP_NUM_THREADS`, 2 procesos × 4 hilos en 4 núcleos | "¿Cuántas unidades de ejecución pediste en total? ¿Cuántos núcleos hay?" |
| *Speedup* > p con p = 2 y n grande | "¿Cuántos bytes ocupa n/p doubles? ¿Cabe en la caché L2 de esta CPU? ¿Qué dice el protocolo sobre reportar superlineal?" |
| "El programa está mal, con p = 4 y n = 1 000 tarda más" | "¿Qué imprime la razón cómputo/comunicación? ¿Es un error del programa o es exactamente lo que predice el modelo?" |
| `make run` falla como root (`OMPI_ALLOW_RUN_AS_ROOT`) o sin `--oversubscribe` | "¿Qué usuario eres? ¿Qué exporta `tests/run_tests.sh` en ese caso?" |

## Diferenciación

- **Apoyo (quien no arranca):** usar la hoja de predicción con los números del ejemplo resuelto ya llenos para
  n = 1 000 000 y pedir solo la fila de n = 1 000; para la Parte D, entregar `escalado.sh` con los nombres de sus
  binarios ya cambiados (solo tienen que ajustar los argumentos).
- **Ampliación (quien termina):** (a) correr con `--mca mpi_yield_when_idle 1` la fila p = 8 y explicar la
  diferencia (los procesos que esperan ceden el núcleo); (b) medir el híbrido con `OMP_NUM_THREADS=2 -np 2` vs.
  `OMP_NUM_THREADS=1 -np 4` en `hybrid_min` con n = 2²⁶ − 1 y explicar qué comunicación se ahorra; (c) repetir el
  escalado fuerte con N = 10⁷ y decidir si el límite es comunicación o ancho de banda de memoria (pista: t_c
  cambia con n).

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 (modelo de costo) | En la hoja de predicción: T₄ escrito como dos sumandos; en *exit ticket* P2a: n* ≈ 1 333 con el cálculo |
| 2 (fuerte/débil, oversub aparte) | En el punto de control: dos tablas con la etiqueta correcta; la fila p = 8 separada o ausente; CT2 y CT3 ≥ 80 % en el revoto |
| 3 (razón cómputo/comunicación) | En Investigar: explican por qué la razón cambia ~250× entre n = 4 000 y n = 10⁶ con p = 4; *exit ticket* P1 nombra las dos cantidades |
| 4 (híbrido) | `make run-hibrido` corrido por el equipo; alguien dice qué nivel pidió `MPI_Init_thread` y por qué FUNNELED basta |

Registro del punto de control (llenar en clase):

| Equipo | Tabla fuerte | Tabla débil | p = 8 aparte | Explica dónde deja de escalar | Mini-defensa: quién no explicó su código |
|---|---|---|---|---|---|
| | | | | | |

## Notas post-sesión

- (se llenan después) qué falló, qué cambiar, error más frecuente del *exit ticket*, % de CT1/CT2/CT3, equipos
  que no llegaron con Partes A–C listas.
