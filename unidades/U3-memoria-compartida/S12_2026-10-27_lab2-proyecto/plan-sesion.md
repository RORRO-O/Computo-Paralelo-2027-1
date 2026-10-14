> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S12 · Práctica 4 · Laboratorio 2 (Partes C y D, punto de control, mini-defensas) + taller "cómo paralelizar tu V1"

Tipo: laboratorio (variante 2.1 de `docs/metodo/02-plantilla-sesion.md`), con el bloque de trabajo dividido en
**55 minutos de Práctica 4** (demostración, trabajo con mini-defensas, punto de control) y **25 minutos de taller
del proyecto** (de la V1 a la V2, rumbo a H1 y H2). Recuperación y *exit ticket* no se recortan.

## Objetivos (al terminar, el estudiante podrá…)

1. **Defender** en un minuto una medición de la Práctica 4 (tamaño, hilos, mediana de 5 repeticiones,
   *speedup*, eficiencia) y **responder** las dos preguntas de propiedad sobre una línea de su código. (evaluar)
2. **Instrumentar** un programa de tres fases con `omp_get_wtime()` y **producir** la tabla tiempo/fracción por
   sección. (aplicar)
3. **Calcular** la fracción paralelizable **en tiempo** a partir del perfil, la cota de Amdahl para 2 y 4 hilos,
   y **contrastarla** con el *speedup* medido de la región y del programa completo. (analizar)
4. **Clasificar** las dependencias de un ciclo caliente (independiente, reducción, carrera potencial,
   dependencia verdadera, E/S) y **elegir** una estrategia (`parallel for`/tareas, `schedule`) justificada
   con el método de Foster. (analizar)

Los objetivos 3 y 4 se verifican en el *exit ticket*; el 2 en el PRIMM (tabla de tres fases en pantalla) y en
la tarea 1a; el 1 en el punto de control y en las mini-defensas.

## Prerrequisitos y vínculo

- **Viene de:** S11 (lunes 26 de octubre): patrones (reducción manual, *scan*, *stencil*, *pipeline*) y
  `omp simd`. Y de S10 (jueves 22 de octubre): protocolo de medición, Amdahl medido, Karp–Flatt, falso compartido.
  Los equipos traen las Partes A y B de la Práctica 4 hechas (S09, martes 20 de octubre) y la Parte C avanzada.
- **Va hacia:** S13 (jueves 29 de octubre, 10:30, salón 3208): **H1 · Avance 1** (V1 secuencial + Foster +
  perfilado, 12 % del 2.º parcial) y repaso de la Unidad III con examen de práctica. **Práctica 4 vence el
  domingo 1 de noviembre a las 23:59** (40 % del 2.º parcial). Más adelante, **H2 · Avance 2** (lunes 23 de
  noviembre, en clase): V2 en memoria compartida con *speedup*.
- **Ideas erróneas que esta sesión ataca (Anexo A):** 2 ("la fracción de Amdahl se mide en líneas"),
  5 ("medir una vez basta / se mide con -O0"), 28 ("aglomerar es juntar todo en un solo proceso"),
  29 ("primero se programa y luego se diseña la descomposición").
- **Nivel de andamiaje:** por completar, con pistas (`07-guia-de-autoria.md`, §A.5): es la penúltima sesión de
  la unidad. El ejemplo resuelto es un problema con tres huecos (respuesta y pista selladas en `<details>`); la
  práctica guiada abrevia Predecir e Investigar (5 min entre ambas) para dar 10 minutos a Crear (la plantilla
  con la V1 propia).

| Idea errónea | Dónde aparece en la sesión |
|---|---|
| 2 | CT1 (distractor C); PRIMM Investigar (cálculo de f con tiempos); exit ticket 1 (distractores A y C); hueco 1 del ejemplo |
| 5 | Demostración del protocolo; punto de control (mediana de 5); `medir.sh`; exit ticket 1 (distractor D); CT3 de reserva |
| 28 | CT2 (distractor C); recuperación 3 (distractor A); plantilla §3 (aglomeración); tarea 2a |
| 29 | CT2 (distractor A); orden del PRIMM (predecir → medir → dependencias → pragma); plantilla §1–2 |

## Materiales

- Esta carpeta: `retrieval-inicio.md`, `conceptests.md`, `ejemplo-resuelto.md`, `practica-guiada/` (compilada
  antes de la sesión en la máquina del profesor: `make && make test`), `exit-ticket.md`, `tarea-espaciada.md`.
- Proyector, cronómetro visible, tarjetas con números de lista.
- Hoja de registro de mini-defensas (abajo, §"Registro"). Hoja de punto de control (una por equipo).
- `herramientas/protocolo-medicion.md` abierto en una pestaña. Enunciado y rúbrica de la Práctica 4
  (`practicas/P4-openmp/README.md`, `rubrica.md`) impresos o abiertos.
- Un cronómetro en el teléfono de cada equipo para el minuto del punto de control.

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar las cinco preguntas de `retrieval-inicio.md`. Cuatro minutos en silencio, sin apuntes. Al minuto 4
mostrar respuestas y pedir manos por pregunta; anotar el conteo de la 4 (protocolo) y la 5 (Amdahl).

- Si en S11 algún ítem de su sesión quedó bajo 60 %, hoy se repite con pista en lugar de la pregunta 1 o 2
  (`07-guia-de-autoria.md`, §A.8).
- Si la 4 queda por debajo del 60 %: en la demostración (5–12) se vota el CT3 de reserva (mediana contra
  promedio) y se recorre la tabla del protocolo renglón por renglón en vez de solo mostrarla.
- Si la 5 queda por debajo del 60 %: en 60–65 se hace el cálculo de Amdahl del ejemplo en el pizarrón, paso a
  paso, antes de votar CT1.

### 5–12 · Demostración del profesor: el protocolo en vivo y los errores de entorno

Frase de anclaje: "Hoy entregan evidencia, no números. Una medición sin repeticiones, sin `-O2` o sin T(1)
secuencial no es evidencia y no cuenta en la Parte D ni en H2."

1. (2 min) Recordatorio del protocolo con la tabla de `herramientas/protocolo-medicion.md` §2 proyectada:
   calentamiento, ≥ 5 repeticiones, mediana con mín y máx, `-O2`, región de interés, T(1) secuencial, hilos
   hasta los núcleos físicos. (Si la recuperación 4 quedó bajo 60 %, aquí se vota el CT3 de reserva.)
2. (3 min) En `practica-guiada/` ejecutar en vivo:
   ```bash
   make
   REPS=5 ./medir.sh ./ejemplo_perfil resumen "1 4" 2000000 48000 resumen dynamic
   ```
   Señalar en la salida: la corrida de calentamiento que no aparece, las 5 repeticiones resumidas en mediana
   [mín, máx], el *speedup* de la fase **y** del total, y que `OMP_NUM_THREADS` se fija por corrida.
3. (2 min) Errores de entorno que invalidan la Parte D (se dicen, no se demuestran): compilar sin `-O2` o con
   el binario de TSan; no exportar `OMP_NUM_THREADS` (el *runtime* usa todos los núcleos lógicos sin que se
   declare); medir con `time` el proceso completo y llamarlo "la región"; cambiar `n` entre configuraciones
   (eso es escalabilidad débil); tener el navegador o el antivirus trabajando mientras se mide.

### 12–45 · Trabajo por equipos en las Partes C y D + mini-defensas

Arranque (1 min): "Orden de trabajo sugerido: (1) `make test` de la Parte C; (2) si pasa, medir la Parte D con
el protocolo; (3) llenar la tabla y la gráfica; (4) escribir la interpretación. A las 09:15 cada equipo muestra
una medición." Los equipos que no tienen la Parte C correcta **no miden**: primero correctitud (la mitad de
la rúbrica depende de ello).

El profesor circula con la rúbrica de la Práctica 4 y hace una **mini-defensa de 2 minutos por equipo**
(12 equipos → 24 minutos; el resto del tiempo se dedica a quien está atorado). Protocolo de la mini-defensa,
según la prueba de propiedad de `docs/metodo/05-politica-ia.md` y `03-plantilla-practica.md` §2:

- Abrir el reparto de trabajo del `REPORTE.md` y elegir, **para cada integrante, una línea de la parte que
  firmó** (preferir una cláusula o una sincronización: `reduction(+:x)`, `schedule(dynamic, 64)`, `nowait`,
  `firstprivate(a)`, `atomic`, un `critical`, la posición de `omp_get_wtime()`, la corrida de calentamiento,
  la tolerancia del `make test`).
- **Pregunta 1 (una por integrante):** "¿qué hace esta línea?". **Pregunta 2, solo si la primera falla**, sobre
  otra línea suya: "¿qué pasa si la quito?". Cuenta la mejor de las dos. Quien lo pida responde por escrito en
  el momento (5 min, papel). No se acepta "la puso mi compañero".
- Si para H1 se eligió la **opción B** de `proyecto/hitos/H1-avance-1.md` §8 (recepción anticipada el 27 para
  quien ya tiene la etiqueta), esos equipos reciben en este bloque la ronda de H1 (3 min: dos preguntas fijas +
  una individual) en lugar de la mini-defensa de 2 min; con más de 6 equipos en esa situación el bloque no
  alcanza y conviene la opción A o C.
- Si la primera sale bien y hay tiempo, una pregunta sobre una **función ajena** ("¿qué hace y por qué está?")
  distingue Ejemplar de Competente en "Proceso e integridad" (rúbrica de `03` §2).
- Registrar en la hoja. Un "no" en la mejor de las dos baja "Proceso e integridad" **de ese integrante** a
  Insuficiente; se le dice en el momento. Quien no está hoy: mini-defensa pendiente en el siguiente
  laboratorio (martes 10 de noviembre) o video de ≤ 3 minutos no listado, según `03` §1 y `04` §5.

#### Registro de mini-defensas (una fila por integrante)

| Equipo | N.º de lista | Línea firmada | P1 "¿qué hace?" (B/P/N) | P2 "¿si la quito?" (solo si P1 falla) | Función ajena (opcional) | Mejor |
|---|---|---|---|---|---|---|
| | | | | | | |

#### Errores típicos de las Partes C y D, y la pregunta que se hace ante cada uno

| Error observado | Síntoma | Pregunta socrática |
|---|---|---|
| T(1) es la versión paralela con 1 hilo, sin declararlo | *Speedup* "demasiado bueno" o eficiencia > 1 | "¿Contra qué programa estás comparando? ¿Es el mejor secuencial que tienes?" |
| Medición con `-O0`, o con el binario de `-fsanitize=thread` | Tiempos 3–10× mayores que los de otros equipos | "Enséñame el comando con que compilaste este binario." |
| Una sola repetición, o promedio con un pico evidente | Tabla sin mín/máx; *speedup* que cambia al repetir | "¿Cuántas corridas hay detrás de este número? ¿Dónde están el mínimo y el máximo?" |
| Problema tan chico que T(1) < 0.1 s | *Speedup* < 1 con 2 hilos; mucha varianza | "¿Cuánto tarda la secuencial? Entonces, ¿estás midiendo trabajo o sobrecarga?" |
| El reloj incluye lectura de archivo o impresión | La región paralela "no escala" | "¿Dónde empieza y dónde termina tu reloj? ¿Qué hay adentro que nunca se va a paralelizar?" |
| `critical` dentro del ciclo interno (restricción de la Parte C) | Correcto pero más lento que secuencial | "¿Cuántas veces se ejecuta ese `critical`? ¿Qué alternativa deja a cada hilo trabajar solo y combinar al final?" |
| Acumuladores por hilo en un arreglo contiguo (falso compartido) | Escala bien a 2 hilos y mal a 4 | "¿Qué tan cerca en memoria están los acumuladores de hilos distintos? ¿Cuánto mide una línea de caché?" |
| *Speedup* superlineal sin explicación | S(4) > 4 | "¿Pasa `make test`? ¿Cuánto mide el conjunto de trabajo por hilo frente a la caché L2?" |
| `schedule` elegido sin evidencia | "Pusimos `dynamic` porque es mejor" | "¿Las iteraciones son uniformes? ¿Qué dio `static` con el mismo tamaño?" |
| Gráfica sin la línea ideal S = p o sin unidades | No se ve dónde deja de escalar | "¿Dónde está la línea ideal? ¿Qué eje es qué?" |
| `OMP_NUM_THREADS` sin exportar; o más hilos que núcleos físicos sin declararlo | Resultados no reproducibles entre máquinas | "¿Cuántos núcleos físicos tiene esta máquina? ¿Lo anotaste en la tabla?" |
| Resultado que cambia entre corridas (carrera que "a veces" sale bien) | `make test` pasa unas veces y otras no | "¿Lo compilaste con TSan? ¿Qué variable escriben dos hilos?" |
| Interpretación que describe sin explicar ("sube hasta 4 y ya") | Texto sin causa | "¿Qué fracción secuencial estimas con Karp–Flatt? ¿Crece con p? ¿Qué te dice eso?" |

### 45–60 · Punto de control: cada equipo muestra una medición y la explica en 1 minuto

Orden por sorteo con tarjetas. Cada equipo proyecta (o muestra en su pantalla) **una** tabla y habla
**un minuto** cronometrado, con este guion visible en el proyector:

1. Qué midieron (parte, función) y con qué tamaño; por qué ese tamaño (T(1) ≥ 1 s).
2. Hilos probados y hardware (núcleos físicos).
3. La fila clave: mediana T(1), mediana T(4), *speedup*, eficiencia.
4. ¿Coincidió con la predicción del pre-laboratorio? ¿Por cuánto?
5. Qué limita el *speedup* (fracción secuencial, memoria, sincronización, balance).

El profesor marca en la hoja del equipo cuatro casillas: mediana de ≥ 5 · T(1) secuencial declarado ·
`-O2` · interpretación con causa. Un equipo sin medición válida expone lo que tiene y recibe la pregunta
"¿qué les falta para que cuente?"; no se les da más tiempo de clase. Doce equipos × 1 min + cambios ≈ 15 min.
Si sobran minutos: ConcepTest CT1 aquí (y en 60–65 se va directo al ejemplo).

### 60–65 · Mini-lección: de la V1 a la V2 (ejemplo resuelto) + CT1

Proyectar la tabla del perfil de `ejemplo-resuelto.md` **sin** la columna de tiempos y preguntar al grupo:
"Carga de puntos, cómputo de seis rasgos con `sqrt`, `atan2` y `exp` en una función de 23 líneas, y un resumen
cuyo ciclo tiene 6 líneas y cuenta pares cercanos. ¿Cuál domina?". Manos. Luego mostrar la columna de tiempos.
Datos reales (`ejemplo-resuelto.md`, mediana de 5, 1 hilo): carga 0.019 s (1.5 %), cómputo 0.092 s (7 %),
resumen 1.154 s (91 %). Paralelizar el cómputo con 4 hilos: *speedup* total **1.08** (la variante que falla).
Paralelizar el resumen con `dynamic, 64`: fase 3.41, total **2.81** contra una cota de Amdahl de 3.16; con
`static`, fase 2.21 por el ciclo triangular. Mostrar las dos filas y decir en una frase por qué el total queda
debajo de la fase.

Regla en una frase: **"Primero se mide dónde está el tiempo, luego se listan las dependencias de ese ciclo,
y al final se escribe el pragma. La fracción de Amdahl se mide en segundos, no en líneas."**

**CT1** (perfil 0.25 / 1.20 / 0.05 s con 95 % de las líneas en cómputo): voto → si < 80 %, discusión en parejas
de 90 s → revoto → explicación con la suma fase por fase (0.25 + 0.30 + 0.05 = 0.60 s; S = 2.5).

### 65–73 · Taller: mini PRIMM de perfilado (`practica-guiada/fases.c`), abreviado

Parejas dentro de cada equipo (conductor/navegante; el tercer integrante abre `plan-paralelizacion-V2.md` y
va llenando la sección 0 con los datos de su proyecto). Predecir e Investigar van abreviados a propósito
(andamiaje por completar, `07` §A.5): el tiempo largo es para Crear.

| Min | Fase PRIMM | Qué hacen | Criterio de "listo" |
|---|---|---|---|
| 65–66 | Predecir | Leen el encabezado de `fases.c`; escriben qué fase domina y su porcentaje | Predicción escrita |
| 66–67 | Ejecutar | `make` y `OMP_NUM_THREADS=1 ./fases` (≈ 1.5 s); comparan con la predicción | Tabla de tiempos a la vista |
| 67–69 | Investigar | Calculan f y S_max(4); dicen qué escribe cada iteración en la línea 79 (`sum += p`) y qué pasaría con la 94 (`hist[bin]++`); el resto de Investigar queda para la tarea | f y S_max(4) escritos; `sum` identificada como reducción |
| 69–73 | Modificar | Completan `TODO(1)` (línea 65), `make test` y lanzan `make medir` (1/2/4 hilos; tarda ≈ 30 s y lo leen mientras pasan a Crear) | `make test` pasa; S de la fase y del total anotados |

Si un equipo trae su V1 compilando, puede saltar "Modificar" e ir directo a instrumentar su V1 (Crear).

### 73–83 · Crear: la plantilla con la V1 propia (10 min)

Cada equipo abre `plan-paralelizacion-V2.md` y llena la **sección 1** con su V1: nombra sus secciones, decide
dónde van los `omp_get_wtime()` y, si la V1 compila, mide una primera vez (sin las 5 repeticiones todavía) para
tener un orden de magnitud por sección y un f provisional. Después empieza la **sección 2** con el ciclo que
domina: qué lee y qué escribe cada iteración. El profesor hace rondas de 2 minutos por equipo con dos preguntas
fijas (`02` §2.4): **"¿qué midieron?"** y **"¿qué no entienden todavía?"**; a quien ya tiene f le pregunta la
cota S_max(4) y qué sección atacará primero. Equipo sin V1: hace las secciones 1–3 sobre `fases.c`.

Criterio de "listo" al minuto 83: secciones de la V1 nombradas con un tiempo (aunque sea de una corrida) y el
ciclo dominante con sus variables leídas y escritas. Lo que falte es la tarea 1a.

#### Errores esperados en el PRIMM y la pregunta que se hace

| Error | Pregunta |
|---|---|
| Predicen que domina la carga "porque es entrada/salida" | "¿Cuántas operaciones hace la carga por registro? ¿Y el cómputo? Cuenta el ciclo interno." |
| Calculan f con la corrida de 4 hilos | "¿De qué versión son los tiempos que usa Amdahl? ¿Qué pasó con el total al cambiar de hilos?" |
| Olvidan `reduction(+:sum)`; `make test` falla y la suma sale ≈ ¼ de la correcta (sobrevive la parcial de un hilo) y cambia entre corridas | "¿Cuántas iteraciones escriben `sum`? ¿Qué le pasa a una variable que escriben todos los hilos? Compílalo con `make tsan`, córrelo con n chico y busca el aviso en que **dos hilos trabajadores** escriben `sum += p`; los avisos entre el hilo principal y un trabajador son ruido de `libgomp` (S07)." |
| Ponen el `pragma` en el ciclo interno `j` | "¿Las iteraciones de `j` son independientes? ¿Cuántas veces se crearía el equipo de hilos?" |
| Agregan `private(p, v)` por miedo | "¿Dónde están declaradas `p` y `v`? ¿Qué alcance tiene una variable declarada dentro del ciclo?" |
| Corren `make medir` sin completar el TODO; *speedup* 1.0 | "Lee la línea `hilos_en_computo`. ¿Qué dice?" |
| Esperan S_total ≈ 4 y obtienen ≈ 2.5–3 | "¿Qué fracción quedó secuencial? ¿Cuánto vale 1/(1 − f)? ¿Y el *speedup* de la fase sola?" |
| Pasan `4` como argumento creyendo que son hilos | "¿Qué dice el encabezado del archivo sobre los argumentos? ¿Y sobre los hilos?" |
| Reportan la fracción de carga como "paralelizable porque `strtod` es por línea" | "¿Y la lectura del archivo real de tu V1, también se reparte? ¿Qué parte de la carga sí y cuál no?" |

### 83–85 · CT2 (un solo voto)

**CT2** (primer paso de V1 a V2): un solo voto con tarjetas; se discute en parejas solo si el acierto queda
entre 30 % y 80 % (`07` §A.7); explicación en 60 segundos: "medir, listar dependencias, y hasta entonces el
pragma". Si sobra un minuto, dos equipos elegidos con tarjeta dicen en 20 segundos: "nuestro punto caliente
probable es ___ y su dependencia principal es ___".

### 85–90 · Cierre

*Exit ticket* (`exit-ticket.md`), en papel, individual. Mientras escriben, anuncios (también en el proyector):

- **Práctica 4: domingo 1 de noviembre, 23:59**, en el repositorio del equipo (40 % del 2.º parcial). Quien no
  estuvo en su mini-defensa: video de ≤ 3 minutos no listado, o mini-defensa pendiente en el laboratorio del
  martes 10 de noviembre (`03` §1, `04` §5).
- **H1 · Avance 1: jueves 29 de octubre, en clase** (12 % del 2.º parcial); lo que pide está en
  `proyecto/hitos/H1-avance-1.md`. La sección 1 de la plantilla de hoy es el perfilado de H1.
- Tarea espaciada (`tarea-espaciada.md`): perfil de la V1 (1a) + elección justificada (1b) + intercalado +
  preparación del repaso; 1b, 2 y 3 se autocalifican al inicio de S13. **Examen 2: martes 3 de noviembre,
  08:30.** Como S13 coincide con H1, el examen de práctica se resuelve en casa cronometrado y en clase se
  corrige (`04` §4): anunciar aquí dónde está publicado y para cuándo.

## Diferenciación

- **Apoyo (quien no arranca).** El mismo ejemplo con una pista sellada: en `ejemplo-resuelto.md` cada hueco
  tiene una "Pista" en `<details>` que se abre antes que la respuesta; en el PRIMM, la pareja que no identifica
  la reducción abre la pista del hueco 2 del ejemplo (es el mismo patrón `count++` / `sum += p`). En el
  laboratorio: equipo sin Parte C correcta → mide la Parte A con el protocolo (ya funciona) para practicar la
  Parte D y llegar con tabla al punto de control; la Parte C se termina en casa. En el taller: equipo sin V1 →
  plantilla completa sobre `fases.c` (secciones 1–3) con fecha compromiso de su V1.
- **Ampliación (quien termina).** El problema sin ejemplo: instrumentar su V1 directamente, sin pasar por
  `fases.c`, y entregar f y S_max(4) antes del minuto 83; o, sobre `ejemplo_perfil.c`, predecir y medir el
  modo `ambas` y explicar con Amdahl por qué gana tan poco respecto a `resumen`. Laboratorio: Karp–Flatt para 2
  y 4 hilos y decir si la sobrecarga crece. Variantes de Crear con una restricción más: (a) quitar la región
  de calentamiento de `fases.c` y medir cuánto cuesta crear el equipo de hilos en su máquina; (b) paralelizar
  el `strtod` de la carga por bloques y medir si la fracción secuencial baja.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 (defender medición, propiedad) | Hoja del punto de control: 4 casillas por equipo. Registro de mini-defensas: proporción de "bien" por integrante. Alerta si más del 30 % de los equipos no trae mediana de 5. |
| 2 (instrumentar) | En el PRIMM, pantallas con la tabla de tres fases; tarea 1 con la V1 instrumentada. |
| 3 (f, Amdahl, contraste) | CT1 (revoto ≥ 80 %); exit ticket 1 y 2a; tabla predicción vs. medición del PRIMM. |
| 4 (dependencias y estrategia) | CT2 (un voto, ≥ 80 %); exit ticket 2b; sección 2 de la plantilla en la tarea 1a; elección justificada de la tarea 1b. |

## Notas post-sesión

- (se llenan después) Equipos sin medición válida en el punto de control: ___ de ___.
- Mini-defensas con "no": ___ integrantes (repetir el jueves 29).
- ConcepTest con peor primer voto y por qué: ___.
- Error más frecuente del *exit ticket* (abre S13): ___.
- ¿Alcanzó el tiempo del taller (60–85)? ¿Crear tuvo sus 10 minutos? Si no, ¿qué se recorta la próxima vez?: ___.
