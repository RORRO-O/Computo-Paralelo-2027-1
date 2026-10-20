# H1 · Avance 1: V1 secuencial, diseño por Foster y perfil de línea base

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · H1 · Avance 1 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208 · 12 % del 2.º parcial · versión 1.1 · 20 de octubre de 2026

## 1. En una tabla

| Qué | Detalle |
|---|---|
| Fecha de entrega | **Jueves 29 de octubre de 2026.** Etiqueta `H1` en el repositorio antes de las **10:30**; recepción en clase (sesión S13) |
| Peso | **12 % del 2.º parcial** (`planeacion/mapa-evaluacion.md`). Rúbrica de 100 puntos; calificación del hito = puntos × 0.12 |
| Qué se entrega | V1 secuencial con pruebas y tamaño declarado · documento de diseño por el método de Foster con diagrama · perfil de línea base por secciones con fracción paralelizable y predicción de Amdahl · plan de V2 con riesgos · `reporte/H1.md` con "qué medimos, cómo y qué no entendemos todavía" |
| Dónde | Repositorio `cp-6bm1-equipoNN` con la estructura de `proyecto/README.md` §4 (la misma de la entrega final): la V1 vive en `v1/`, las pruebas en `tests/run_tests.sh` |
| Cómo se recibe | Ronda de 3 minutos por equipo con el repositorio abierto: dos preguntas fijas al equipo y una pregunta individual a cada integrante sobre la parte que firmó (§6). La sesión S13 combina la recepción con el repaso del Examen 2: si la ronda completa no cabe, el profesor anuncia el lunes 26 de octubre cuál de las variantes de §8 se usa (por ejemplo, la pregunta individual el jueves 5 de noviembre) |
| Retroalimentación | El mismo día: una nota del profesor en la lista rápida de la recepción y, si el profesor lo programa (§8), la lista de cotejo de §5 llena por otro equipo (`docs/metodo/04-evaluacion.md` §3.1). La rúbrica, por escrito, a más tardar el **jueves 5 de noviembre** |
| Entrega tardía | Etiqueta creada hasta 72 h después (domingo 1 de noviembre 10:30): máximo 80 %. Después no se recibe salvo justificante institucional |
| Tiempo estimado | 10–14 horas por equipo entre el 15 y el 28 de octubre, además de la Práctica 4 (carga semanal en `planeacion/calendario-27-1.md`). El taller del martes 27 de octubre (U3·S12) se dedica a esto |

## 2. Qué entregas

### 2.1 V1 secuencial funcionando, con pruebas y tamaño declarado

Carpeta `v1/` y pruebas en `tests/`, con:

- Código en C (C11) que compila **sin *warnings*** con `gcc -std=c11 -O2 -Wall -Wextra`. Si tu problema necesita
  `-lm` u otra biblioteca, va en el `Makefile`.
- `v1/Makefile` con `all`, `run`, `test`, `clean`, y `Makefile` en la raíz cuyo `make test` corre
  `tests/run_tests.sh` y termina con código 0 si todo pasa y distinto de 0 si algo falla (`docs/CONVENCIONES.md` §3).
- El contrato de los programas del proyecto (el de la entrega final; `proyecto/plantillas/README.md`): argumentos
  `[n] [semilla]`, con un tamaño por defecto que corre en menos de 5 s; salida `clave=valor` con
  `tiempo_s=<segundos>` (tiempo de la **región de interés**: no la lectura de datos ni la impresión) y
  `checksum=<valor>` (lo que las pruebas comparan). Esqueletos: `proyecto/plantillas/plantilla_main.c` o
  `proyecto/entrega-final/plantilla-repo/v1/main.c`.
- `tests/run_tests.sh` con al menos **tres casos de tipos distintos**, cada uno con tolerancia declarada:

| Tipo de caso | Qué verifica | Ejemplo de cómo se construye |
|---|---|---|
| Pequeño, verificable a mano | Que el algoritmo hace lo que dices | Entrada de 4–10 elementos cuyo resultado calculaste en papel y está escrito en el script |
| Con referencia externa | Que el resultado es correcto a escala | Solución analítica, resultado de una biblioteca de referencia (NumPy, BLAS, SciPy) guardado en `datos/`, o un archivo generado por otro método |
| Invariante o propiedad | Que no se rompió algo estructural | Conservación de una suma, simetría, idempotencia, cota conocida, resultado independiente del orden de entrada, misma semilla → mismo `checksum` |

- **Tamaño declarado.** En el `README.md` del repositorio va esta tabla, llena (la búsqueda del tamaño queda en la
  bitácora, sección "Búsqueda del tamaño declarado"):

```
| Nombre        | Valor(es) de los parámetros | T(1) con -O2 (mediana de 5) | Para qué se usa                    |
|---------------|-----------------------------|-----------------------------|------------------------------------|
| N_prueba      |                             | < 1 s                       | make test                          |
| N_declarado   |                             | 1–10 s (ideal 2–5 s)        | Todas las mediciones de V1, V2, V3 |
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

Ideas erróneas que este documento ataca: "aglomerar es juntar todo en un solo proceso" y "primero se programa y
luego se diseña" (`docs/metodo/01-marco-pedagogico.md`, Anexo A, 28 y 29).

### 2.3 Perfil de línea base por secciones · `resultados/perfil-v1.csv` y sección en `reporte/H1.md`

Divide la **región de interés** de V1 (lo que mide `tiempo_s`, es decir, `T(1)`) en **secciones** (núcleo 1,
núcleo 2, combinación, actualización de fronteras…) y mide cuánto tiempo toma cada una al tamaño declarado, con
`-O2`, mediana de 5 corridas con calentamiento. Así `f_p` y el *speedup* que medirás en H2 hablan del mismo tiempo.
La preparación y la lectura de datos, que quedan fuera de `tiempo_s`, se miden aparte y se reportan como fila
informativa: no entran en `f_p`. Dos formas aceptadas:

- **Instrumentar** (recomendada: mide exactamente lo que tú llamas sección): un acumulador por sección con el mismo
  reloj de `tiempo_s` (`clock_gettime(CLOCK_MONOTONIC, …)` en V1; nunca `clock()`), activado solo al compilar con
  `-DPERFIL` para que la salida normal no cambie. Fragmento compilado sin avisos con `-Wall -Wextra` en el entorno de
  autoría:

```c
#ifdef PERFIL
    double t_sec = 0.0, s_nucleo = 0.0, s_combinacion = 0.0;      /* un acumulador por sección */
#endif
    double t0 = wall_seconds();                                   /* región de interés = tiempo_s */
#ifdef PERFIL
    t_sec = wall_seconds();
#endif
    /* ... sección 1: núcleo ... */
#ifdef PERFIL
    s_nucleo += wall_seconds() - t_sec;
    t_sec = wall_seconds();
#endif
    /* ... sección 2: combinación ... */
#ifdef PERFIL
    s_combinacion += wall_seconds() - t_sec;
#endif
    double t1 = wall_seconds();
    printf("tiempo_s=%.6f\n", t1 - t0);
#ifdef PERFIL
    printf("seccion_nucleo_s=%.6f\n", s_nucleo);
    printf("seccion_combinacion_s=%.6f\n", s_combinacion);
#endif
```

  Se compila como `gcc -std=c11 -O2 -Wall -Wextra -DPERFIL … -o v1/v1_perfil` (agrega `v1/v1_perfil` al
  `.gitignore`) y estas líneas producen `resultados/perfil-v1.csv` con la mediana de 5 corridas por sección:

```bash
N=<N_declarado>
./v1/v1_perfil "$N" > /dev/null                                   # calentamiento: no se cuenta
for r in 1 2 3 4 5; do ./v1/v1_perfil "$N"; done | grep -E '^(tiempo_s|seccion_)' > perfil-crudo.txt
{
    echo "seccion,rep1,rep2,rep3,rep4,rep5,mediana_s"
    for k in $(cut -d= -f1 perfil-crudo.txt | sort -u); do
        reps=$(grep "^$k=" perfil-crudo.txt | cut -d= -f2 | paste -sd, -)
        mediana=$(grep "^$k=" perfil-crudo.txt | cut -d= -f2 | sort -g | sed -n 3p)
        echo "$k,$reps,$mediana"
    done
} > resultados/perfil-v1.csv
rm perfil-crudo.txt
```

  En el entorno de autoría, con un núcleo de 12 iteraciones de `sin`/`cos` por elemento y `n` = 4 000 000, el CSV
  quedó con `seccion_nucleo_s` = 0.909 s, `seccion_combinacion_s` = 0.005 s y `tiempo_s` = 0.914 s: las secciones
  suman 99.9 % de `T(1)`. Es una prueba de la receta: con `T(1) < 1 s`, ese `n` no serviría como `N_declarado`.
- **`gprof`**: compilar con `-pg`, correr y leer el perfil plano. Sirve si tus secciones son funciones. Declara que
  `gprof` muestrea tiempo de CPU y redondea; úsalo con el tamaño declarado, no con el de prueba.

Tabla obligatoria en `reporte/H1.md` (los tiempos salen del CSV):

```
| Sección (dentro de la región de interés) | Qué hace | Tiempo mediana (s) | % de T(1) | ¿Paralelizable? (sí / parcial / no) | Por qué |
|---|---|---|---|---|---|
| 1. |  |  |  |  |  |
| 2. |  |  |  |  |  |
| 3. |  |  |  |  |  |
| otros (no medido) |  |  |  | no |  |
| **Total T(1) = tiempo_s** |  |  | 100 % |  |  |
| Fuera de la región (informativo): preparación, lectura, impresión |  |  | — | — |  |
```

Reglas: la suma de las secciones medidas queda entre 90 % y 100 % de `T(1)` (lo que falte va en "otros"); se
miden al menos 3 secciones, o 2 si el problema solo tiene núcleo y combinación y así se explica; "paralelizable" se
decide con el diseño de Foster, no con el deseo; la fracción paralelizable se calcula **en tiempo**:
`f_p = Σ (% de las secciones marcadas sí) + Σ (parte estimada de las parciales)`. Idea errónea atacada: "la
fracción de Amdahl se mide en líneas de código" (Anexo A, 2).

Con `f_p` escribes la **predicción de Amdahl** que se compara en H2 (esto es tu "pre-mortem"; anótala también en la
sección "Predicciones vs. resultados" de la bitácora, con fecha):

```
S(p) = 1 / ((1 − f_p) + f_p / p)

| p | S(p) predicho | E(p) predicha |
|---|---|---|
| 2 |  |  |
| 4 |  |  |
| 8 |  |  |
```

Entorno declarado junto a la tabla: CPU (modelo, núcleos físicos/lógicos), RAM, sistema operativo, versión de
`gcc`, banderas, fecha, en `resultados/entorno.txt`. Lo escriben el `run_all.sh` de la raíz y
`herramientas/medir_proyecto.sh` (para medir `T(1)` de V1:
`./herramientas/medir_proyecto.sh -e V1 -n <N_declarado> -t 1 -o resultados/mediciones.csv -- ./v1/v1`).

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
| Integrante (usuario de GitHub) | Qué firmó (archivos, funciones, secciones) | Commits (hashes cortos) |
## Bitácora y declaración de IA
<enlaces a bitacora.md y declaracion-ia.md; número de entradas nuevas>
```

## 3. Formato de entrega y qué va a correr el profesor

1. Todo en el repositorio del equipo, en la estructura de `proyecto/README.md` §4.
2. Etiqueta anotada antes de las 10:30 del jueves 29 de octubre: `git tag -a H1 -m "Avance 1" && git push origin H1`.
3. El profesor ejecuta, sin ayuda del equipo:

```bash
git clone <repo> && cd <repo> && git checkout H1
cat README.md                         # ¿se entiende qué es, cómo se corre y cuál es el tamaño declarado?
make clean && make && make test       # ¿compila sin warnings? ¿código de salida 0? ¿PASS por caso?
./v1/v1 <N_declarado>                 # ¿imprime tiempo_s= y checksum=? ¿T(1) coincide en orden de magnitud con el perfil?
cat resultados/perfil-v1.csv resultados/entorno.txt
```

Si alguno de esos pasos falla por un detalle que se arregla en menos de 5 minutos (una ruta, un dato faltante),
el criterio correspondiente baja a Competente; si no se arregla, a En desarrollo o Insuficiente según la rúbrica.

## 4. Rúbrica · 100 puntos → 12 % del 2.º parcial

Niveles: Ejemplar = 100 % del peso · Competente = 80 % · En desarrollo = 55 % · Insuficiente = 20 % · pieza
ausente en la etiqueta = 0. Puntos del hito = Σ (peso × nivel). Calificación en el 2.º parcial = puntos × 0.12.

| Criterio | Peso | Ejemplar (100 %) | Competente (80 %) | En desarrollo (55 %) | Insuficiente (20 %) |
|---|---|---|---|---|---|
| **1. V1 correcta y reproducible** | 25 | Compila sin *warnings* con las banderas del curso; `make test` pasa con ≥ 3 casos de los tres tipos y tolerancia declarada; acepta `[n] [semilla]` e imprime `tiempo_s=` y `checksum=`; tamaño declarado con `T(1) ≥ 1 s` medido con el protocolo; `tiempo_s` no incluye lectura de datos ni impresión; el profesor corre los comandos de §3 sin preguntar nada | Compila y `make test` pasa con ≥ 2 casos; tamaño declarado con `T(1) ≥ 1 s`; un comando de §3 necesita un arreglo de < 5 min (dato no incluido, instrucción incompleta) | Compila; las pruebas verifican solo que termina o un único caso; o `T(1) < 1 s` al tamaño declarado; o el tamaño está fijo en el código; o la región medida incluye E/S | No compila, o `make test` falla, o no hay pruebas, o se entrega la versión paralela con un hilo como V1 |
| **2. Diseño por el método de Foster** | 25 | Cuatro etapas, cada una con decisión, alternativa descartada y lista de cotejo respondida con razones del problema (número de tareas en función de `n`, patrón de comunicación, qué comunicación elimina la aglomeración, mapeo a hilos y anticipo a GPU); diagrama con tareas, dependencias y grupos que coinciden con el código de V1 | Cuatro etapas y diagrama presentes y correctos; falta la alternativa descartada o la lista de cotejo en una etapa, o el mapeo a GPU | Etapas escritas como resumen del código ("el `for` se reparte") sin identificar tareas ni comunicación; o diagrama sin relación con las etapas; o aglomeración entendida como "juntar todo" | Falta alguna etapa, o el documento no corresponde al problema del equipo, o se escribió después de V2 (contradice el código) |
| **3. Perfil de línea base** | 25 | ≥ 3 secciones de la región de interés (o 2 con la razón) medidas al tamaño declarado con `-O2`, mediana de ≥ 5 corridas con calentamiento; suma entre 90 y 100 % de `T(1)` con "otros" explícito; cada sección marcada paralelizable/parcial/no con razón; `f_p` calculada en tiempo; predicción de Amdahl para 2, 4 y 8; entorno con CPU, núcleos físicos y lógicos, RAM, SO, compilador, banderas y fecha | Tabla completa y `f_p` correcta; falta la predicción para algún `p`, o un dato del entorno, o las repeticiones son < 5 y está declarado | Una sola corrida; o secciones que no suman 90–100 %; o `f_p` estimada por líneas de código o "a ojo"; o perfil con `-O0`; o entorno ausente | Sin tabla por secciones (solo el tiempo total), o perfil no reproducible con el código de la etiqueta |
| **4. Plan de V2 con riesgos** | 10 | Para cada sección paralelizable: construcción OpenMP, alcance de variables y `schedule` tentativo; *speedup* esperado con 4 hilos derivado de `f_p` y de otra causa física; ≥ 4 riesgos con nombres de variables o arreglos del problema, señal de detección y mitigación | Plan completo; los riesgos son los de la tabla de ejemplo, sin nombrar variables ni arreglos del problema | Plan sin alcance de variables ni expectativa numérica; riesgos sin señal de detección ni mitigación | Sin plan, o plan que contradice el perfil (paraleliza la sección que no pesa) |
| **5. Proceso e integridad (individual)** | 15 | *Commits* con cambios de código de todos los integrantes, repartidos en ≥ 2 semanas; bitácora con ≥ 3 entradas con fecha, síntoma, detección, causa y cambio; declaración de IA con las cuatro líneas y la verificación descrita; "qué no entendemos todavía" con ≥ 3 preguntas concretas; el integrante responde sin ayuda la pregunta sobre la parte que firmó | Todo presente; participación desigual explicada en el reparto; la respuesta individual es correcta con una reformulación del profesor | Bitácora con 1–2 entradas o sin detección ni causa ("no hubo errores"); declaración incompleta (falta una de las cuatro líneas, o "No usamos IA" sin la firma de todos); *commits* de una sola persona con el trabajo de todos; respuesta individual parcial (dice qué hace la línea, no por qué) | El integrante no puede explicar la parte que firmó en ninguna de sus dos oportunidades (`docs/metodo/05-politica-ia.md`); o no hay bitácora ni declaración |

Suma de pesos: 25 + 25 + 25 + 10 + 15 = **100**.

| Puntos del hito | 100 | 90 | 80 | 70 | 60 | 50 |
|---|---|---|---|---|---|---|
| En el 2.º parcial (× 0.12) | 12.0 | 10.8 | 9.6 | 8.4 | 7.2 | 6.0 |

El criterio 5 se asigna por integrante. Los criterios 1–4 son del equipo.

## 5. Lista de cotejo (autoevaluación antes de la etiqueta; cotejo entre pares el día de la recepción)

El equipo la marca antes de crear la etiqueta. Si el profesor programa el cotejo entre pares (§8), el día de la
recepción la llena otro equipo sobre su repositorio, en su laptop (sí / no + una línea por cada "no"): es la
retroalimentación del mismo día que pide `docs/metodo/04-evaluacion.md` §3.1.

**V1**
- [ ] `make clean && make` sin *warnings* con `-std=c11 -O2 -Wall -Wextra`.
- [ ] `make test` termina con código 0 y muestra `PASS` por caso; hay ≥ 3 casos de tipos distintos con tolerancia escrita.
- [ ] El programa acepta `[n] [semilla]`; `make run` usa el tamaño por defecto (< 5 s).
- [ ] Imprime `tiempo_s=` y `checksum=`, una clave por línea.
- [ ] Al tamaño declarado, `T(1) ≥ 1 s` (mediana de 5 con calentamiento, `-O2`).
- [ ] `tiempo_s` cubre solo la región de interés; la lectura de datos y la impresión quedan fuera.
- [ ] No usamos `clock()` para medir.

**Foster**
- [ ] Las cuatro etapas hablan de tareas y comunicación, no de ciclos.
- [ ] Cada etapa tiene al menos una alternativa descartada con razón.
- [ ] La lista de cotejo de cada etapa está respondida con sí/no y por qué.
- [ ] El diagrama muestra tareas, dependencias y grupos de aglomeración, y coincide con el código.

**Perfil**
- [ ] ≥ 3 secciones de la región de interés; la suma está entre 90 y 100 % de `T(1)`; "otros" aparece.
- [ ] `resultados/perfil-v1.csv` tiene las 5 repeticiones y la mediana de cada sección.
- [ ] `f_p` se calculó en tiempo, no en líneas.
- [ ] Hay predicción de Amdahl para 2, 4 y 8 hilos, también anotada con fecha en la bitácora.
- [ ] `resultados/entorno.txt` existe y dice CPU, núcleos físicos/lógicos, RAM, SO, `gcc`, banderas, fecha.

**Plan de V2**
- [ ] Cada sección paralelizable tiene construcción OpenMP, alcance de variables y `schedule` tentativo.
- [ ] Hay un *speedup* esperado con 4 hilos y dos razones (Amdahl + otra).
- [ ] ≥ 4 riesgos con señal de detección y mitigación, con nombres de variables reales.

**Proceso**
- [ ] Todos tienen *commits* con cambios de código en ≥ 2 semanas distintas.
- [ ] `bitacora.md` tiene ≥ 3 entradas con fecha `AAAA-MM-DD`, síntoma, detección, causa y cambio.
- [ ] `declaracion-ia.md` tiene la sección H1 completa, incluida "qué nos dijo mal".
- [ ] `reporte/H1.md` tiene "qué no entendemos todavía" con ≥ 3 preguntas concretas y el reparto (quién firmó qué).
- [ ] Cada integrante puede explicar en voz alta su parte y qué hace cada función del resto del código.
- [ ] `git tag -a H1` creado y empujado antes de las 10:30 del jueves 29 de octubre.

## 6. Qué preguntará el profesor en la recepción (3 minutos por equipo)

**Al equipo (siempre las mismas dos):**
1. "¿Qué midieron?" → se espera la tabla del perfil en pantalla, `T(1)`, `f_p` y la predicción de Amdahl.
2. "¿Qué no entienden todavía?" → se espera la lista de `reporte/H1.md`; una lista vacía cuenta en contra.

**A cada integrante, una pregunta individual sin ayuda del equipo.** El profesor elige al azar una pregunta del
banco que toque la parte que esa persona firmó en el reparto y la hace sobre su código (`docs/metodo/05-politica-ia.md`,
"Prueba de propiedad"). Si la respuesta falla, hace una segunda sobre otra línea de esa parte y cuenta la mejor de
las dos. Quien lo pida, sin dar razones, responde por escrito en el momento (5 min, papel, sin dispositivos).

| # | Pregunta | Qué evidencia se busca |
|---|---|---|
| 1 | Señala en el código la sección que más tiempo consume y di por qué consume tanto | Ubica el bloque; lo explica en términos de operaciones o accesos a memoria, no "porque es el ciclo grande" |
| 2 | ¿Qué es una tarea en su partición y cuántas hay para el tamaño declarado? | Da la unidad y el número (fórmula evaluada) |
| 3 | ¿Qué datos necesita una tarea de otra? ¿En V2 eso qué será? | Nombra el patrón de comunicación y lo traduce a compartida/reducción/barrera |
| 4 | ¿Por qué `f_p` se calcula en tiempo y no en líneas? | Explica que Amdahl habla de fracción del tiempo secuencial |
| 5 | Si `f_p` es la que reportaron, ¿cuál es la cota del *speedup* con infinitos hilos? | Calcula `1 / (1 − f_p)` |
| 6 | ¿Qué caso de prueba atraparía un error de índices en el borde? | Nombra el caso y qué compara |
| 7 | ¿Qué pasa con la medición si dejan la lectura del archivo dentro de la región cronometrada? | Explica que `T(1)` crece con una parte que no escala y el *speedup* aparente baja |
| 8 | ¿Por qué el tamaño declarado tiene que dar al menos 1 s? | Habla de sobrecarga vs trabajo y de resolución del reloj |
| 9 | ¿Qué riesgo del plan les preocupa más y cómo lo van a detectar? | Nombra el riesgo, la señal y la herramienta |
| 10 | ¿Qué variable será privada en la sección X y qué pasaría si fuera compartida? | Identifica una carrera concreta |
| 11 | ¿Qué les dijo la IA que resultó estar mal y cómo lo descubrieron? | Cita la declaración y el método de verificación |
| 12 | Muestra un *commit* tuyo y explica qué cambió | El historial coincide con el reparto declarado |

Regla de calificación del criterio 5 para esa persona: respuesta correcta sin ayuda → Ejemplar o Competente según
el resto de la evidencia; correcta con una reformulación → Competente; parcial → En desarrollo; no puede explicar lo
que firmó en ninguna de las dos oportunidades → Insuficiente.

## 7. Errores típicos (síntoma → primera pregunta que debes hacerte)

| Síntoma | Primera pregunta |
|---|---|
| `T(1)` da 0.02 s "porque así es el problema" | ¿Duplicaste el tamaño hasta pasar de 1 s? ¿Qué mides si tarda milisegundos: trabajo o sobrecarga? |
| El perfil suma 130 % de `T(1)` | ¿Anidaste secciones (la 2 dentro de la 1)? ¿Mediste una sección fuera de la región de interés y la sumaste? |
| El perfil suma 60 % de `T(1)` | ¿Qué hay en el 40 % restante: reservas de memoria, inicialización dentro de la región? Mídelo y ponlo como sección u "otros" |
| `f_p = 100 %` | ¿La combinación de resultados también es paralelizable? ¿Qué dice la etapa de comunicación de tu Foster? |
| El documento de Foster describe los `for` del código | ¿Cuál es la tarea? ¿Qué datos toca? ¿Con quién se comunica? Si no puedes responder sin mirar el código, no diseñaste: describiste |
| Las pruebas pasan pero solo imprimen "OK" | ¿Contra qué comparan? ¿Con qué tolerancia? ¿Fallarían si el resultado fuera el doble? Pruébalo |
| Mediste con `clock()` | ¿Qué mide `clock()` cuando haya 4 hilos? Cambia a `clock_gettime(CLOCK_MONOTONIC, …)` (V1) u `omp_get_wtime()` (V2) |
| Compilaste sin `-O2` para "ver mejor el *speedup*" | ¿Contra qué línea base se va a comparar V2? El protocolo lo invalida |
| El tamaño está en un `#define` | ¿Cómo va a correr `run_all.sh` con otro tamaño? Recíbelo en `argv[1]` |
| El programa imprime `T = 1.2 seg` | ¿Cómo lo va a leer `run_all.sh`? El contrato es `tiempo_s=1.2`, una clave por línea |
| "No tuvimos errores" en la bitácora | ¿Cuántas veces compiló sin errores a la primera? Registra el siguiente de inmediato |
| Un solo integrante tiene *commits* | ¿Cómo va a demostrar cada uno su parte en la recepción? Reparte y registra desde hoy |
| El plan de V2 paraleliza la sección 3 (5 % del tiempo) | ¿Qué dice el perfil? ¿Por qué no la sección 1? Si hay una razón (dependencias), escríbela |

## 8. Logística de la sesión (para el profesor)

La sesión S13 (jueves 29 de octubre) combina la recepción de H1 con el repaso de la Unidad III (examen de
práctica, corrección entre pares, calibración), según `planeacion/calendario-27-1.md`. Con ~12 equipos, la ronda
de 3 minutos requiere ~36 minutos, que no caben en los 20 minutos de recepción de la variante de S13
(`docs/metodo/02-plantilla-sesion.md` §2.5) sin recortar la corrección del examen de práctica (el examen se resuelve en casa, cronometrado, y en clase se
corrige: `docs/metodo/04-evaluacion.md` §4). Opciones, a decidir por el profesor y anunciar el lunes 26 de octubre
(S11); el plan de S13 está escrito para la A e indica cómo ajustarlo a B o C:

| Opción | Cómo | Costo |
|---|---|---|
| A | Repositorio evaluado con la etiqueta (criterios 1–4) fuera de clase; en clase solo la ronda de 90 s por equipo con las dos preguntas fijas (≈ 18 min) durante la corrección entre pares; la pregunta individual se hace el jueves 5 de noviembre (U4·S01) en los primeros 20 min, porque el martes 3 de noviembre es el Examen 2 | La pregunta individual llega una semana después; el criterio 5 se cierra ese día |
| B | Recepción completa (3 min por equipo) el martes 27 de octubre (S12, laboratorio + taller) para los equipos que ya tengan la etiqueta, y el jueves 29 solo para el resto | Dos fechas de recepción; la etiqueta de quienes se reciben el 27 se crea antes de las 08:30 de ese día |
| C | Recepción completa en clase (35 min) y corrección entre pares del examen de práctica recortada a las secciones I, II y V; las secciones III, IV y VI se corrigen en casa con la clave | Menos repaso guiado antes del Examen 2 del martes 3 de noviembre |

Con cualquier opción, la etiqueta `H1` y la retroalimentación escrita en ≤ 7 días (jueves 5 de noviembre) no
cambian. El cotejo entre pares de §5 no tiene minutos asignados en el plan de S13 y los repositorios son privados
(otro equipo solo los ve en la laptop de sus dueños): el profesor decide si se hace en clase (los equipos vecinos
intercambian laptops 5 minutos al final de la ronda) o si la retroalimentación del mismo día se limita a la nota de
la lista rápida de la recepción.
