> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S08 · Planificación y balance de carga: `schedule(static/dynamic/guided, chunk)`, `runtime`/`OMP_SCHEDULE`, `collapse`

Tipo: Contenido (estructura base de 90 min). Este guion debe bastar para que otro profesor dé la sesión.

## Objetivos (al terminar, el estudiante podrá…)

1. **Predecir** qué hilo ejecuta cada iteración de un `parallel for` con n iteraciones y p hilos bajo
   `schedule(static)` y `schedule(static, c)`, y **explicar** por qué con `dynamic` y `guided` no es
   predecible (nivel: comprender / aplicar). Se evalúa en el *exit ticket* 2b y en el ConcepTest 1.
2. **Medir** con el protocolo del curso el tiempo de un ciclo desbalanceado con 4 hilos bajo al menos tres
   políticas y **explicar** la diferencia en términos de trabajo por hilo, barrera implícita y costo por
   *chunk* (nivel: analizar). Se evalúa en la fase Investigar (I3) y en el ConcepTest 2.
3. **Elegir y justificar** la política y el *chunk* para un ciclo nuevo a partir de la forma de su carga
   (uniforme, creciente, irregular, concentrada) (nivel: evaluar). Se evalúa en la fase Crear y en el *exit
   ticket* 1 y 2a.
4. **Aplicar** `collapse(2)` a un ciclo anidado y **explicar** cuándo aporta (ciclo externo con pocas
   iteraciones) (nivel: aplicar). Se evalúa en la fase Ejecutar (P3) y Modificar (M3).

## Prerrequisitos y vínculo

- Viene de: S07 · jueves 15 de octubre de 2026 (carreras, `critical`/`atomic`, `barrier`, `nowait`,
  ThreadSanitizer) y de las sesiones del 1 al 13 de octubre (`parallel for`, alcance de variables, `reduction`).
- Va hacia: S09 · martes 20 de octubre de 2026, 08:30–10:00 (tareas `task`/`taskwait`/`taskloop` y
  Práctica 4 · Lab 1; el pre-lab de P4 se entrega al inicio). Más adelante: S10 (jueves 22 de octubre,
  rendimiento y falso compartido) y la V2 del proyecto (H2, lunes 23 de noviembre), donde el `schedule` del
  ciclo principal es la primera decisión de rendimiento.
- Ideas erróneas del Anexo A que esta sesión ataca: **11** ("`dynamic` siempre gana"; ConcepTest 2, fase
  Investigar I3, *exit ticket* 1), **12** ("al final de `omp for` no hay barrera"; recuperación 2, ConcepTest
  3, `nowait_buggy.c`), **1** ("más hilos siempre es más rápido"; pausa 2 del ejemplo: 4 hilos y *speedup*
  2.3 por desbalance; distractor D del ConcepTest 2). De paso: 7 ("salió bien una vez"), 5 (medir una vez /
  con la máquina ocupada) y 10 (`reduction` y tolerancia).

## Materiales

- Archivos de esta carpeta; proyector; cronómetro visible; tarjetas con números de lista.
- Máquina del salón con gcc ≥ 11 y OpenMP; `make` ya ejecutado en `practica-guiada/` **antes** de la sesión
  (`make clean && make && make test` → `22 PASS, 0 FAIL`). Verificar `uptime` < 1 antes de medir en vivo y
  regenerar las tablas de `ejemplo-resuelto.md` y `notas-estudiante.md` con `make tabla` en esa máquina: las
  publicadas vienen de una máquina virtual que no entrega 4 núcleos reales (varios *speedups* quedan < 1).
- Pizarrón: 16 cuadritos dibujados en una fila (para el mapa) y una cuadrícula de 3 × 6 (para `collapse`).
- Hojas del *exit ticket* (una por estudiante) y la lista de errores esperados impresa (sección 35–65).

## Guion minuto a minuto

### 0–5 Recuperación

Proyectar `retrieval-inicio.md` (5 preguntas). Individual, sin apuntes. Al minuto 4 mostrar las respuestas y
pedir manos por pregunta; anotar el conteo de la pregunta 2 (barrera implícita) y de la 5 (quién termina al
último en el ciclo triangular).

- Si < 60 % acierta la pregunta 2: en el bloque siguiente dibujar los 4 hilos llegando a la línea de la
  barrera y repetir "el ciclo termina cuando termina el más lento" (2 min; se descuentan de Transferencia).
- La pregunta 5 se retoma textualmente en el minuto 13: su respuesta es el mapa `static`.

### 5–10 Objetivos y anclaje

Autocalificación de la tarea de S07 (venció hoy a las 10:30) con su clave en `<details>`: 2 min; el profesor
registra la entrega, no el acierto. Frase de apertura (ajustar el hueco con el *exit ticket* de S07): "El jueves,
el error más frecuente en el *exit ticket* fue ______ [si no se revisó: 'creer que al final del `for` no hay
barrera']. Hoy esa barrera es la protagonista: es la que convierte un mal reparto en tiempo perdido."

Leer los 4 objetivos en voz alta. Vínculo con el proyecto: "En la V2 de su proyecto (H2, lunes 23 de
noviembre) van a tener **un** ciclo principal. La cláusula `schedule` es la decisión más barata y de mayor
efecto que tomarán sobre él; hoy aprenden a tomarla con una tabla y no con una corazonada."

### 10–35 Instrucción explícita I (ejemplo resuelto + ConcepTest 1)

Pensar en voz alta con `ejemplo-resuelto.md` proyectado. Tiempos:

- **10–13 Problema y plan.** Suma triangular con n = 40 000. Decir lo que se mira: "la iteración i cuesta i
  divisiones; la última cuesta 40 000 veces más que la segunda". Decir lo que se descarta: "no voy a tocar
  el código del cuerpo; la decisión es el reparto".
- **13–18 Mapa `static` (paso 1).** Correr en vivo `OMP_NUM_THREADS=4 ./schedule_map 16 static`. Pintar el
  mapa en los 16 cuadritos. Preguntar al azar (tarjeta): "¿cuántas unidades hace el hilo 3? ¿y el 0?" (58 y
  10). **Pausa 2** en voz alta: bloques de peso 1, 3, 5, 7 → el hilo 3 hace 7/16 del total → *speedup*
  máximo 16/7 ≈ 2.3 **con 4 hilos**. Subrayar: "esto no es Amdahl; no hay código secuencial; es desbalance
  más barrera" (idea errónea 1).
- **18–22 Mapa `static,1` (paso 2).** Antes de correr, pedir que escriban el mapa en su cuaderno (30 s).
  Correr `./schedule_map 16 static 1`. Trabajo 28/32/36/40. **Pausa 3**: "¿por qué funciona tan bien aquí?
  ¿cuándo no?" (carga monótona sí; concentrada o impredecible, no; destruye localidad).
- **22–27 Medir (paso 3).** Correr `OMP_NUM_THREADS=4 ./unbalanced triangular 40000 static static,1 dynamic,16
  guided,16` (≈ 30 s; si la máquina está cargada, proyectar la tabla de `notas-estudiante.md` §4 y decirlo).
  Leer la tabla columna por columna: mediana, luego mín/máx ("¿es ruido o es diferencia?"), luego *speedup*,
  luego `verif`. **Pausa 4** (contra la secuencial, no contra 1 hilo) y **Pausa 5** (puntero `volatile`:
  "el primer intento de este programa midió 0.0000 s para la secuencial; ¿qué pasó?").
- **27–32 ConcepTest 1** (`conceptests.md`): iteraciones del hilo 1 con `static,2`. Voto → parejas → revoto
  → explicación con la línea `static,2` del mapa real. Esperado 50–60 % en el primer voto.
- **32–35 Variante que falla.** Proyectar la tabla del núcleo `uniform` (`dynamic` más lento que la
  secuencial). Una frase: "`dynamic` no es gratis: cada iteración pide permiso a un contador compartido".
  No explicar más: lo van a medir ellos en I3.

### 35–65 Práctica guiada PRIMM (`practica-guiada/README.md`)

**Arranque (1 min).** "Parejas. Conductor teclea, navegante lee el README y anota. Cambio de rol a las 11:20
(yo lo anuncio). Fase 1 **sin tocar la máquina**: 8 minutos. Hoja con los dos números de lista; se entrega
con el *exit ticket*."

**Hitos de tiempo que se anuncian en voz alta:** 11:13 → deben estar en Ejecutar; 11:20 → cambio de rol, deben
estar en Investigar; 11:28 → deben estar en Modificar (M1 es obligatorio; M2 y M3 si alcanza); 11:35 → puesta
en común.

**Circular con esta lista. Ante cada error, la pregunta, no la respuesta:**

| Error esperado | Pregunta socrática |
|---|---|
| Predicen `static,2` como bloques contiguos de 4 | "¿Cuántos bloques de 2 hay? Repártelos como cartas: 0, 1, 2, 3, 0, … ¿A quién le toca el bloque de 10 y 11?" |
| Esperan que el mapa `dynamic` sea igual en cada corrida (o se asustan porque cambió) | "¿Quién decide qué hilo toma la siguiente iteración? ¿Cuándo lo decide: al compilar, al arrancar o mientras corre?" |
| Mapa todo ceros / una sola fila de trabajo | "¿Cuántos hilos tiene el equipo? ¿Qué imprime la primera línea (`hilos=`)? ¿Pusiste `OMP_NUM_THREADS=4`?" |
| En I3 todos los tiempos salen parecidos o `static` pierde contra todo | "¿Qué dice `uptime`? Si los 4 núcleos ya estaban ocupados, ¿qué mediste?" |
| Concluyen "entonces `dynamic` siempre" después del triangular (idea 11) | "¿Qué viste en `uniform`? ¿Cuánto cuesta una iteración ahí y cuánto cuesta pedirla?" |
| En I3(c) estiman el costo por *chunk* sin multiplicar por los 4 hilos | "El tiempo extra que mediste, ¿lo pagó un hilo o los cuatro a la vez?" |
| Con `dynamic`, `nowait_buggy` les sale 0 incorrectas y concluyen que está bien (idea 7) | "¿Qué garantiza la especificación para `static`? ¿Dice lo mismo de `dynamic`? Si no lo dice, ¿qué prueba una corrida buena?" |
| Toman el reporte de TSan sobre la línea 78 (ciclo de verificación) o la 82 (`free`) como la carrera | "¿Esa línea está dentro o fuera de la región paralela? ¿Aparece también con `static`? ¿Qué no puede ver TSan de libgomp?" |
| En M2 modifican `run_par` en lugar de `triangular_item` | "¿Qué parte del programa define cuánto cuesta una iteración y cuál define quién la ejecuta?" |
| En M3 esperan que `collapse(2)` mejore 4 × 4 con 4 hilos | "¿Cuántos trozos de trabajo había antes y cuántos después? Si ya eran 4 iguales para 4 hilos, ¿qué puede mejorar?" |
| Olvidan revertir M2 y `make test` sigue pasando, así que no se dan cuenta | "¿Qué verifica `make test`: tiempos o resultados? ¿Por qué la prueba no puede detectar que cambiaste el costo?" |
| `guided` reparte muy desigual en el mapa (incluso un hilo con 0) | "¿De qué tamaño es el primer bloque de `guided` con 16 iteraciones y 4 hilos? ¿Quién pudo tomar el segundo bloque antes de que los demás despertaran?" |

**Qué hacer a los 15 min (11:20).** Anunciar el cambio de rol. Preguntar a dos parejas al azar su respuesta
a P2 (política de `runtime` sin `OMP_SCHEDULE`): la mayoría dirá `static`; la respuesta real en GCC es
`dynamic,1`. Guardar el dato para la puesta en común.

### 65–75 Puesta en común + ConcepTest 2

Mostrar tres hallazgos (sin nombres), uno por minuto:

1. **Determinismo.** Fila `static` idéntica en todas las parejas; fila `dynamic` distinta entre parejas y
   entre corridas. "Con `static` puedes razonar antes de ejecutar; con `dynamic` solo puedes medir."
2. **El costo del *chunk*.** Una tabla de I3 de alguna pareja: `dynamic,1` más lento que la secuencial;
   `dynamic,256`–`4096` iguala a `static`. Pedir a la pareja su estimación de ns por pedido.
3. **`runtime` sin `OMP_SCHEDULE` = `dynamic,1` en GCC.** "Es decisión de la implementación. Siempre impriman
   `omp_get_schedule()`."

**ConcepTest 2** (minuto 68–72): carga uniforme, ¿qué política gana? Esperado 55–65 %. Si hay tiempo (72–75),
**ConcepTest 3** (`nowait` + `dynamic` + "salió bien 5 veces"); si no, se deja indicado para la tarea.

**Regla general, en una frase, escrita en el pizarrón:** "Uniforme → `static`. Desigual → `static,c` si es
monótona; `dynamic,c` o `guided,c` si es concentrada o impredecible. El *chunk*, tal que pedirlo sea
despreciable. Y siempre: medir."

### 75–85 Transferencia (fase Crear)

**Reto:** agregar el núcleo `primes` a `unbalanced.c` (README, fase 5): predicción escrita → código → tabla →
3 líneas de justificación.

**Criterio de "listo":** compila sin *warnings*; `make test` en `0 FAIL`; la columna `verif` dice `OK` en
todas las políticas; la justificación nombra la forma de la carga **y** el costo del *chunk*; la predicción
está escrita antes de la tabla. Resultado esperado: 148 933 primos menores que 2 000 000.

**Extensión para quien termina:** recorrer el rango al revés (`n − 1 − i`), de modo que las iteraciones
caras queden al principio; predecir y comprobar qué pasa con `guided`.

**Apoyo para quien no arranca:** darle la firma `static inline double primes_item(long i)` y la frase "un
número es primo si ningún d con 3 ≤ d ≤ √i lo divide; trata aparte 0, 1, 2 y los pares"; que empiece por
agregar el caso en `item()` devolviendo 0.0 y vea que compila; luego la función.

Quien se atoró en PRIMM termina M1 (quitar el `nowait`) en vez de Crear; lo demás va a la tarea.

### 85–90 Cierre

Repartir `exit-ticket.md` (2 preguntas + confianza). Recoger junto con la hoja de la pareja.

Anuncios, con fecha:

- **Pre-laboratorio de la Práctica 4: mañana martes 20 de octubre, 08:30, al inicio del Lab 1** (S09).
- Tarea espaciada de hoy (`tarea-espaciada.md`), individual: `tareas/<usuario-github>/U3-S08.md` en el repositorio
  del equipo antes de mañana martes 20 de octubre, 08:30 (inicio de S09); se autocalifica en los minutos 5–10 de S09.
- Práctica 4 completa: domingo 1 de noviembre, 23:59 (40 % del 2º parcial).

## Diferenciación

- **Apoyo (quien no arranca en Predecir):** entregarle la fila `static` ya llena y pedirle solo `static,2` y
  `static,5`; para `dynamic` aceptar "no se puede saber" con la razón. En Investigar, limitarse a I1, I3 e I5.
- **Ampliación (quien termina):** (a) la extensión del rango invertido en Crear; (b) correr
  `./unbalanced mandelbrot 1000 static static,125 guided,1 guided,8` y explicar por qué `static,125` (8 bloques
  de 125 filas repartidos cíclicamente: cada hilo recibe una franja de borde y una del centro) debe rendir mejor
  que `static` (dos hilos cargan con todo el centro), y por qué `guided,8` supera a `guided,1`; (c) medir
  `collatz` y argumentar si una carga irregular pero sin patrón está "desbalanceada" en bloques grandes.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 Predecir `static`/`static,c` | Tabla de rastreo de la pareja (filas `static`, `static,2`, `static,5` correctas) y ConcepTest 1 ≥ 80 % en el revoto; *exit ticket* 2b |
| 2 Medir y explicar | Tabla de I3 con la estimación de ns por pedido y la frase "`dynamic,1` más lento que la secuencial"; ConcepTest 2 ≥ 80 % en el revoto |
| 3 Elegir y justificar | Predicción + tabla + 3 líneas de la fase Crear; *exit ticket* 1 y 2a (nombra la forma de la carga) |
| 4 `collapse` | P3 y M3 correctas en la hoja (hilos ociosos sin `collapse`; celdas por hilo con `collapse` + `static`) |

Semáforo de la sesión: si el ConcepTest 2 queda por debajo de 50 % tras el revoto, abrir S10 (jueves 22 de
octubre) con la tabla del núcleo `uniform` y el cálculo del costo por *chunk* antes de hablar de falso
compartido.

## Notas post-sesión

- (se llenan después) Qué falló:
- Qué cambiar:
- Error más frecuente del *exit ticket*:
- % de aciertos en el primer voto de cada ConcepTest (pasar al registro de `conceptests.md`):
