# H1 · Avance 1: V1 secuencial, diseño por Foster y perfil de línea base

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · H1 · Avance 1 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208 · 12 % del 2.º parcial

## 1. En una tabla

| Qué | Detalle |
|---|---|
| Fecha de entrega | **Jueves 29 de octubre de 2026.** Etiqueta `H1` en el repositorio antes de las **10:30**; recepción en clase (sesión S13) |
| Peso | **12 % del 2.º parcial** (`planeacion/mapa-evaluacion.md`). Rúbrica de 100 puntos; calificación del hito = puntos × 0.12 |
| Qué se entrega | V1 secuencial con pruebas y tamaño declarado · documento de diseño por el método de Foster con diagrama · perfil de línea base por secciones con fracción paralelizable · plan de V2 con riesgos · `reporte/H1.md` con "qué medimos, cómo y qué no entendemos todavía" |
| Cómo se recibe | Ronda de 3 minutos por equipo con el repositorio abierto: dos preguntas fijas al equipo y una pregunta individual a cada integrante (sección 6) |
| Retroalimentación | Por escrito, con la rúbrica, a más tardar el **jueves 5 de noviembre** |
| Entrega tardía | Etiqueta creada hasta 72 h después (domingo 1 de noviembre 10:30): máximo 80 %. Después no se recibe salvo justificante |
| Tiempo estimado | 10–14 horas por equipo entre el 15 y el 28 de octubre, además de la Práctica 4 (ver carga semanal en `planeacion/calendario-27-1.md`) |

## 2. Qué entregas

### 2.1 V1 secuencial funcionando, con pruebas y tamaño declarado

Carpeta `src/v1/` con:

- Código en C (C11) que compila **sin *warnings*** con `gcc -std=c11 -O2 -Wall -Wextra`. Si tu problema necesita
  `-lm` u otra biblioteca, va en el `Makefile`.
- `Makefile` con `all`, `run`, `test`, `clean`. `make test` termina con código 0 si todo pasa y distinto de 0 si algo
  falla (`docs/CONVENCIONES.md` §3).
- El tamaño del problema llega por **línea de comandos** y hay un tamaño por defecto que corre en menos de 5 s.
- El programa imprime `RESULTADO <valor>` (o escribe la salida en un archivo que las pruebas comparan) y
  `TIEMPO_S <segundos>` con el tiempo de la **región de interés**: no la lectura de datos ni la impresión. Esqueleto
  en `proyecto/plantillas/plantilla_main.c`.
- `tests/run_tests.sh` con al menos **tres casos de tipos distintos**, cada uno con tolerancia declarada:

| Tipo de caso | Qué verifica | Ejemplo de cómo se construye |
|---|---|---|
| Pequeño, verificable a mano | Que el algoritmo hace lo que dices | Entrada de 4–10 elementos cuyo resultado calculaste en papel y está escrito en el script |
| Con referencia externa | Que el resultado es correcto a escala | Solución analítica, resultado de una biblioteca de referencia (NumPy, BLAS, SciPy) guardado en `datos/`, o un archivo generado por otro método |
| Invariante o propiedad | Que no se rompió algo estructural | Conservación de una suma, simetría, idempotencia, cota conocida, resultado independiente del orden de entrada |

- **Tamaño declarado.** En el `README.md` del repositorio va esta tabla, llena:

```
| Nombre        | Valor(es) de los parámetros | T(1) con -O2 (mediana de 5) | Para qué se usa                    |
|---------------|-----------------------------|-----------------------------|------------------------------------|
| N_prueba      |                             | < 1 s                       | make test                          |
| N_declarado   |                             | ≥ 1 s (ideal 2–10 s)        | Todas las mediciones de V1, V2, V3 |
```

Si tu problema tiene varios parámetros (tamaño de malla e iteraciones, por ejemplo), se declaran todos; la
columna `n` del CSV lleva el principal.

### 2.2 Documento de diseño por el método de Foster · `reporte/diseno-foster.md`

Cuatro etapas, en este orden, antes de escribir V2. El documento describe **tareas**, no ciclos: "una tarea por
fila de la matriz de salida" en lugar de "el `for` de afuera se reparte". Copia esta estructura y llénala:

```markdown
# Diseño paralelo por el método de Foster · <nombre del problema>

## 0. El problema en una frase y su tamaño declarado
<entrada, salida, N_declarado>

## 1. Partición
- Tipo de descomposición: [ ] de dominio (datos)  [ ] funcional (cómputo)  [ ] mixta. Por qué:
- Qué es una tarea: <unidad mínima de cómputo + datos que toca>
- Número de tareas en función del tamaño: <fórmula, p. ej. n² tareas para n×n>
- Alternativa descartada y por qué:
- Lista de cotejo (sí/no + razón):
  - ¿Hay al menos un orden de magnitud más tareas que hilos/procesos previstos?
  - ¿Las tareas tienen tamaño comparable? Si no, ¿cómo lo compensas?
  - ¿Evitas cómputo y almacenamiento redundantes?
  - ¿El número de tareas crece con el tamaño del problema?

## 2. Comunicación
- Qué datos necesita cada tarea de otras tareas: <patrón: local / global; estructurado / no; estático / dinámico>
- En memoria compartida (V2) esto se vuelve: <variables compartidas, reducciones, barreras>
- En GPU (V3) esto se vuelve: <memoria global / compartida, sincronización por bloque, transferencias>
- Lista de cotejo:
  - ¿Todas las tareas comunican aproximadamente lo mismo?
  - ¿Cada tarea se comunica solo con pocas vecinas?
  - ¿Las comunicaciones pueden ocurrir en paralelo, o hay un cuello de botella (p. ej., una variable global)?
  - ¿El cómputo de una tarea puede avanzar mientras otras comunican?

## 3. Aglomeración
- Cómo agrupas tareas y en cuántos grupos: <p. ej., bloques de filas contiguas; chunks de k iteraciones>
- Qué comunicación desaparece al agrupar y qué paralelismo se pierde:
- Cómputo replicado (si lo hay) y por qué conviene:
- Lista de cotejo:
  - ¿Redujo la aglomeración el costo de comunicación/sincronización?
  - ¿El número de grupos sigue creciendo con el tamaño del problema?
  - ¿Los grupos tienen costo similar?
  - ¿Sigue siendo posible cambiar el número de hilos sin reescribir el código?

## 4. Mapeo
- Grupos → hilos de OpenMP: <estático / dinámico; `schedule` tentativo y por qué>
- Grupos → bloques e hilos de CUDA (anticipo para V3): <qué calcula un hilo, qué calcula un bloque>
- Balance de carga esperado y cómo lo vas a medir:

## 5. Diagrama
<ASCII o imagen en reporte/figuras/. Muestra tareas, dependencias o comunicación, y los grupos de la aglomeración>
```

Esqueleto de diagrama en ASCII, por si no usas imagen:

```
 datos de entrada ──► [ tarea 1 ] ──┐
                      [ tarea 2 ] ──┼──► ( reducción / combinación ) ──► salida
                      [ tarea 3 ] ──┤        ▲
                      [   ...   ] ──┘        │ dependencia: <cuál>
                      └─ grupo A ─┘ └─ grupo B ─┘   ← aglomeración
```

Idea errónea que este documento ataca: "aglomerar es juntar todo en un solo proceso" y "primero se programa y
luego se diseña" (`docs/metodo/01-marco-pedagogico.md`, Anexo A, 28 y 29).

### 2.3 Perfil de línea base por secciones · `resultados/perfil-v1.csv` y sección en `reporte/H1.md`

Divide V1 en **secciones** (lectura/preparación, núcleo 1, núcleo 2, combinación, escritura…) y mide cuánto
tiempo toma cada una al tamaño declarado, con `-O2`, mediana de 5 corridas con calentamiento. Dos formas aceptadas:

- **Instrumentar**: acumuladores por sección con `omp_get_wtime()` o `clock_gettime(CLOCK_MONOTONIC, …)`
  alrededor de cada bloque (el esqueleto de `plantilla_main.c` muestra la función de reloj). Es la forma
  recomendada: mide exactamente lo que tú llamas sección.
- **`gprof`**: compilar con `-pg`, correr y leer el perfil plano. Sirve si tus secciones son funciones. Declara que
  `gprof` muestrea tiempo de CPU y redondea; úsalo con tamaño declarado, no con el de prueba.

Tabla obligatoria (en el CSV y en `reporte/H1.md`):

```
| Sección | Qué hace | Tiempo mediana (s) | % del total | ¿Paralelizable? (sí / parcial / no) | Por qué |
|---|---|---|---|---|---|
| 1. |  |  |  |  |  |
| 2. |  |  |  |  |  |
| 3. |  |  |  |  |  |
| otros (no medido) |  |  |  | no |  |
| **Total T(1)** |  |  | 100 % |  |  |
```

Reglas: la suma de las secciones medidas debe quedar entre 90 % y 100 % del total (lo que falte va en "otros");
"paralelizable" se decide con el diseño de Foster, no con el deseo; la fracción paralelizable se calcula **en
tiempo**: `f_p = Σ (% de las secciones marcadas sí) + Σ (parte estimada de las parciales)`. Idea errónea atacada:
"la fracción de Amdahl se mide en líneas de código" (Anexo A, 2).

Con `f_p` escribes la **predicción de Amdahl** que se compara en H2 (esto es tu "pre-mortem"):

```
S(p) = 1 / ((1 − f_p) + f_p / p)

| p | S(p) predicho | E(p) predicha |
|---|---|---|
| 2 |  |  |
| 4 |  |  |
| 8 |  |  |
```

Entorno declarado junto a la tabla: CPU (modelo, núcleos físicos/lógicos), RAM, sistema operativo, versión de
`gcc`, banderas, fecha. `run_all.sh` lo genera en `resultados/entorno.txt`.

### 2.4 Plan de V2 con riesgos · sección en `reporte/H1.md`

```
## Plan de V2
| Sección (del perfil) | Construcción OpenMP prevista | Variables compartidas / privadas / de reducción | schedule tentativo y por qué |
|---|---|---|---|
|  |  |  |  |

Speedup esperado con 4 hilos: ____ porque f_p = ____ (Amdahl) y además ____ (memoria, sincronización, desbalance).

## Riesgos (mínimo 4)
| Riesgo | Señal con la que lo detectaríamos | Mitigación concreta | Quién lo vigila |
|---|---|---|---|
| Carrera en <variable>                    | TSan con N_prueba; resultado distinto entre corridas | Acumuladores locales + reduction | |
| Falso compartido en <arreglo>            | Speedup < 1.5 con 4 hilos en una sección "perfecta" | Padding o variable local por hilo | |
| Desbalance (iteraciones desiguales)      | Eficiencia cae con static                             | Medir static vs dynamic con chunk | |
| Memoria: ancho de banda                  | Speedup se estanca en 2 sin sincronización           | Reordenar accesos; medir con tamaño menor | |
| E/S dentro de la región medida           | T(1) no baja aunque el núcleo escale                  | Sacar E/S de la región de interés | |
```

Las filas anteriores son los riesgos típicos; sustitúyelos por los de **tu** problema con las variables y
arreglos reales.

### 2.5 Lo que todo hito pide · `reporte/H1.md`

```markdown
# H1 · Avance 1 · Equipo NN · <problema>
> Etiqueta: H1 · Fecha de la etiqueta: · Máquina(s) de medición: ver resultados/entorno.txt

## Qué medimos
<T(1) al tamaño declarado; perfil por secciones; f_p; predicción de Amdahl>
## Cómo lo medimos
<comandos exactos; repeticiones; reloj; banderas; qué quedó fuera de la región de interés>
## Qué no entendemos todavía (mínimo 3 preguntas concretas)
1. <p. ej. "No sabemos si la sección 2 está limitada por memoria o por cómputo; ¿cómo se distingue?">
2.
3.
## Diseño por Foster
<enlace a reporte/diseno-foster.md y las dos decisiones más importantes en dos líneas>
## Plan de V2 y riesgos
<tablas de 2.4>
## Reparto de trabajo en este hito
| Integrante (usuario de GitHub) | Qué hizo | Commits (hashes cortos) |
## Bitácora y declaración de IA
<enlaces a bitacora-errores.md y declaracion-ia.md; número de entradas nuevas>
```

## 3. Formato de entrega y qué va a correr el profesor

1. Todo en el repositorio del equipo, en la estructura de `proyecto/README.md` §4.
2. Etiqueta anotada antes de las 10:30 del jueves 29 de octubre: `git tag -a H1 -m "Avance 1" && git push origin H1`.
3. El profesor ejecuta, sin ayuda del equipo:

```bash
git clone <repo> && cd <repo> && git checkout H1
cat README.md                      # ¿se entiende qué es, cómo se corre y cuál es el tamaño declarado?
cd src/v1 && make && make test     # ¿compila sin warnings? ¿código de salida 0?
make run                           # ¿imprime RESULTADO y TIEMPO_S? ¿T(1) coincide en orden de magnitud con el perfil?
cat ../../resultados/perfil-v1.csv ../../resultados/entorno.txt
```

Si alguno de esos pasos falla por un detalle que se arregla en menos de 5 minutos (una ruta, un dato faltante),
el criterio correspondiente baja a Competente; si no se arregla, a En desarrollo o Insuficiente según la rúbrica.

## 4. Rúbrica · 100 puntos → 12 % del 2.º parcial

Niveles: Ejemplar = 100 % del peso · Competente = 80 % · En desarrollo = 55 % · Insuficiente = 20 % · pieza
ausente en la etiqueta = 0. Puntos del hito = Σ (peso × nivel). Calificación en el 2.º parcial = puntos × 0.12.

| Criterio | Peso | Ejemplar (100 %) | Competente (80 %) | En desarrollo (55 %) | Insuficiente (20 %) |
|---|---|---|---|---|---|
| **1. V1 correcta y reproducible** | 25 | Compila sin *warnings* con las banderas del curso; `make test` pasa con ≥ 3 casos de los tres tipos y tolerancia declarada; tamaño por línea de comandos; tamaño declarado con `T(1) ≥ 1 s` medido con el protocolo; región de interés bien delimitada (sin E/S); el README permite correr todo sin preguntar | Compila y `make test` pasa con ≥ 2 casos; tamaño declarado con `T(1) ≥ 1 s`; falta un detalle de reproducibilidad que el profesor subsana en < 5 min (dato no incluido, instrucción incompleta) | Compila; las pruebas verifican solo que termina o un único caso; o `T(1) < 1 s` al tamaño declarado; o el tamaño está fijo en el código; o la región medida incluye E/S | No compila, o `make test` falla, o no hay pruebas, o se entrega la versión paralela con un hilo como V1 |
| **2. Diseño por el método de Foster** | 25 | Cuatro etapas con decisión, alternativa descartada y lista de cotejo respondida con razones ligadas al problema (tareas en función de n, patrón de comunicación, costo de aglomerar, mapeo a hilos y anticipo a GPU); diagrama coherente con el código de V1 | Cuatro etapas y diagrama presentes y correctos; alternativas o lista de cotejo incompletas, o el mapeo a GPU ausente | Etapas escritas como resumen del código ("el `for` se reparte") sin identificar tareas ni comunicación; o diagrama sin relación con las etapas; o aglomeración entendida como "juntar todo" | Falta alguna etapa, o el documento no corresponde al problema del equipo, o se escribió después de V2 (contradice el código) |
| **3. Perfil de línea base** | 25 | ≥ 3 secciones medidas al tamaño declarado con `-O2`, mediana de ≥ 5 corridas con calentamiento; suma entre 90 y 100 % del total con "otros" explícito; cada sección marcada paralelizable/parcial/no con razón; `f_p` calculada en tiempo; predicción de Amdahl para 2, 4 y 8; entorno completo | Tabla completa y `f_p` correcta; falta la predicción para algún `p`, o un dato del entorno, o las repeticiones son < 5 y está declarado | Una sola corrida; o secciones que no suman; o `f_p` estimada por líneas de código o "a ojo"; o perfil con `-O0`; o entorno ausente | Sin tabla por secciones (solo el tiempo total), o perfil no reproducible con el código de la etiqueta |
| **4. Plan de V2 con riesgos** | 10 | Para cada sección paralelizable: construcción OpenMP, alcance de variables y `schedule` tentativo; *speedup* esperado con 4 hilos derivado de `f_p` y de otra causa física; ≥ 4 riesgos propios del problema con señal de detección y mitigación concretas | Plan completo; riesgos genéricos pero pertinentes al problema | Plan sin alcance de variables ni expectativa numérica; riesgos sin señal de detección ni mitigación | Sin plan, o plan que contradice el perfil (paraleliza la sección que no pesa) |
| **5. Proceso e integridad (individual)** | 15 | *Commits* de todos los integrantes repartidos en ≥ 2 semanas; bitácora con ≥ 3 entradas reales (síntoma, detección, causa, cambio); declaración de IA completa incluida la línea "qué nos dijo mal"; "qué no entendemos todavía" con ≥ 3 preguntas concretas; cada integrante responde correctamente su pregunta individual en la recepción | Todo presente; participación desigual explicada en el reparto; respuesta individual correcta con una pista del profesor | Bitácora o declaración de trámite ("no hubo errores", "no usamos IA" sin más); *commits* de una sola persona con el trabajo de todos; respuesta individual parcial | El integrante no puede explicar la parte que firmó; o declaración ausente; o evidencia de entrega sin comprensión |

Suma de pesos: 25 + 25 + 25 + 10 + 15 = **100**.

| Puntos del hito | 100 | 90 | 80 | 70 | 60 | 50 |
|---|---|---|---|---|---|---|
| En el 2.º parcial (× 0.12) | 12.0 | 10.8 | 9.6 | 8.4 | 7.2 | 6.0 |

El criterio 5 se asigna por integrante. Los criterios 1–4 son del equipo.

## 5. Lista de cotejo de autoevaluación (antes de crear la etiqueta)

**V1**
- [ ] `make clean && make` sin *warnings* con `-std=c11 -O2 -Wall -Wextra`.
- [ ] `make test` termina con código 0 y muestra `PASS` por caso; hay ≥ 3 casos de tipos distintos con tolerancia escrita.
- [ ] El programa acepta el tamaño por línea de comandos; `make run` usa el tamaño por defecto (< 5 s).
- [ ] Al tamaño declarado, `T(1) ≥ 1 s` (mediana de 5 con calentamiento, `-O2`).
- [ ] `TIEMPO_S` cubre solo la región de interés; la lectura de datos y la impresión quedan fuera.
- [ ] No usamos `clock()` para medir.

**Foster**
- [ ] Las cuatro etapas hablan de tareas y comunicación, no de ciclos.
- [ ] Cada etapa tiene al menos una alternativa descartada con razón.
- [ ] La lista de cotejo de cada etapa está respondida con sí/no y por qué.
- [ ] El diagrama muestra tareas, dependencias y grupos de aglomeración, y coincide con el código.

**Perfil**
- [ ] ≥ 3 secciones; la suma está entre 90 y 100 % del total; "otros" aparece.
- [ ] `f_p` se calculó en tiempo, no en líneas.
- [ ] Hay predicción de Amdahl para 2, 4 y 8 hilos.
- [ ] `resultados/entorno.txt` existe y dice CPU, núcleos físicos/lógicos, RAM, SO, `gcc`, banderas, fecha.

**Plan de V2**
- [ ] Cada sección paralelizable tiene construcción OpenMP, alcance de variables y `schedule` tentativo.
- [ ] Hay un *speedup* esperado con 4 hilos y dos razones (Amdahl + otra).
- [ ] ≥ 4 riesgos con señal de detección y mitigación, con nombres de variables reales.

**Proceso**
- [ ] Todos tienen *commits* en ≥ 2 semanas distintas.
- [ ] `bitacora-errores.md` tiene ≥ 3 entradas con síntoma, detección, causa y cambio.
- [ ] `declaracion-ia.md` tiene la sección H1 completa, incluida "qué nos dijo mal".
- [ ] `reporte/H1.md` tiene "qué no entendemos todavía" con ≥ 3 preguntas concretas.
- [ ] Cada integrante puede explicar en voz alta cualquier archivo del repositorio.
- [ ] `git tag -a H1` creado y empujado antes de las 10:30 del jueves 29 de octubre.

## 6. Qué preguntará el profesor en la recepción (3 minutos por equipo)

**Al equipo (siempre las mismas dos):**
1. "¿Qué midieron?" → se espera la tabla del perfil en pantalla, `T(1)`, `f_p` y la predicción de Amdahl.
2. "¿Qué no entienden todavía?" → se espera la lista de `reporte/H1.md`; una lista vacía cuenta en contra.

**A cada integrante, una pregunta de este banco, elegida al azar (sin ayuda del equipo):**

| # | Pregunta | Qué evidencia se busca |
|---|---|---|
| 1 | Señala en el código la sección que más tiempo consume y di por qué consume tanto | Ubica el bloque; lo explica en términos de operaciones o accesos a memoria, no "porque es el ciclo grande" |
| 2 | ¿Qué es una tarea en su partición y cuántas hay para el tamaño declarado? | Da la unidad y el número (fórmula evaluada) |
| 3 | ¿Qué datos necesita una tarea de otra? ¿En V2 eso qué será? | Nombra el patrón de comunicación y lo traduce a compartida/reducción/barrera |
| 4 | ¿Por qué `f_p` se calcula en tiempo y no en líneas? | Explica que Amdahl habla de fracción del tiempo secuencial |
| 5 | Si `f_p` es la que reportaron, ¿cuál es la cota del *speedup* con infinitos hilos? | Calcula `1 / (1 − f_p)` |
| 6 | ¿Qué caso de prueba atraparía un error de índices en el borde? | Nombra el caso y qué compara |
| 7 | ¿Qué pasa con la medición si dejan la lectura del archivo dentro de la región cronometrada? | Explica la inflación del tiempo secuencial y del *speedup* aparente |
| 8 | ¿Por qué el tamaño declarado tiene que dar al menos 1 s? | Habla de sobrecarga vs trabajo y de resolución del reloj |
| 9 | ¿Qué riesgo del plan les preocupa más y cómo lo van a detectar? | Nombra el riesgo, la señal y la herramienta |
| 10 | ¿Qué variable será privada en la sección X y qué pasaría si fuera compartida? | Identifica una carrera concreta |
| 11 | ¿Qué les dijo la IA que resultó estar mal y cómo lo descubrieron? | Cita la declaración y el método de verificación |
| 12 | Muestra un *commit* tuyo y explica qué cambió | El historial coincide con el reparto declarado |

Regla de calificación: respuesta correcta → criterio 5 en Ejemplar o Competente según el resto de la evidencia;
respuesta parcial → En desarrollo; no puede explicar lo que firmó → Insuficiente para esa persona.

## 7. Errores típicos (síntoma → primera pregunta que debes hacerte)

| Síntoma | Primera pregunta |
|---|---|
| `T(1)` da 0.02 s "porque así es el problema" | ¿Duplicaste el tamaño hasta pasar de 1 s? ¿Qué mides si tarda milisegundos: trabajo o sobrecarga? |
| El perfil suma 130 % del total | ¿Anidaste secciones (la 2 dentro de la 1)? ¿El total se midió aparte con el mismo reloj? |
| El perfil suma 60 % del total | ¿Qué hay en el 40 % restante: E/S, reservas de memoria, inicialización? Mídelo y ponlo en "otros" |
| `f_p = 100 %` | ¿La lectura de datos, la reserva de memoria y la combinación de resultados también son paralelizables? ¿Qué dice la etapa de comunicación de tu Foster? |
| El documento de Foster describe los `for` del código | ¿Cuál es la tarea? ¿Qué datos toca? ¿Con quién se comunica? Si no puedes responder sin mirar el código, no diseñaste: describiste |
| Las pruebas pasan pero solo imprimen "OK" | ¿Contra qué comparan? ¿Con qué tolerancia? ¿Fallarían si el resultado fuera el doble? Pruébalo |
| Mediste con `clock()` | ¿Qué mide `clock()` cuando haya 4 hilos? Cambia a `omp_get_wtime()` o `clock_gettime` |
| Compilaste sin `-O2` para "ver mejor el *speedup*" | ¿Contra qué línea base se va a comparar V2? El protocolo lo invalida |
| El tamaño está en un `#define` | ¿Cómo va a correr `run_all.sh` con otro tamaño? Pásalo por `argv` |
| "No tuvimos errores" en la bitácora | ¿Cuántas veces compiló sin errores a la primera? Registra el siguiente de inmediato |
| Un solo integrante tiene *commits* | ¿Cómo va a demostrar cada uno su parte en la recepción? Reparte y registra desde hoy |
| El plan de V2 paraleliza la sección 3 (5 % del tiempo) | ¿Qué dice el perfil? ¿Por qué no la sección 1? Si hay una razón (dependencias), escríbela |

## 8. Logística de la sesión (para el profesor)

La sesión S13 (jueves 29 de octubre) combina la recepción de H1 con el repaso de la Unidad III (examen de
práctica, corrección entre pares, calibración), según `planeacion/calendario-27-1.md`. Con ~12 equipos, la ronda
de 3 minutos requiere ~36 minutos, que no caben en la variante de repaso de `docs/metodo/02-plantilla-sesion.md`
§2.2 sin recortar el examen de práctica. Opciones, a decidir por el profesor y anunciar el lunes 26 de octubre (S11):

| Opción | Cómo | Costo |
|---|---|---|
| A | Repositorio evaluado con la etiqueta (criterios 1–4) fuera de clase; en clase solo la ronda de 90 s por equipo con las dos preguntas fijas (≈ 18 min) durante la corrección entre pares; la pregunta individual se hace el jueves 5 de noviembre (U4·S01) en los primeros 20 min, porque el martes 3 de noviembre es el Examen 2 | La pregunta individual llega una semana después |
| B | Recepción completa (3 min por equipo) el martes 27 de octubre (S12, laboratorio + taller) para los equipos que ya tengan la etiqueta, y el jueves 29 solo para el resto | Dos fechas de recepción; la etiqueta de quienes se reciben el 27 se crea antes de las 08:30 de ese día |
| C | Recortar el examen de práctica de 40 a 25 min y dedicar 35 min a la recepción | Menos repaso antes del Examen 2 del martes 3 de noviembre |

Con cualquier opción, la etiqueta `H1` y la retroalimentación escrita en ≤ 7 días (jueves 5 de noviembre)
no cambian.
