> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S06 · Cazador de errores MPI + taller de mediciones hacia H2

Dos partes. La **Parte 1** es una actividad PRIMM corta: tres programas MPI con un error cada uno; predices el
síntoma, lo ves, lo explicas, lo corriges y creas un cuarto programa con error para tu pareja. En clase caben las
fases Predecir y Ejecutar (9 minutos); Investigar, Modificar y Crear se terminan como ejercicio 1 de
`tarea-espaciada.md`. La **Parte 2** es el taller del proyecto: lista de cotejo de lo que debe quedar cerrado hoy
para H2 (lunes 23 de noviembre), el revisor automático de tablas de *speedup* y la lista de revisión por pares.

Trabajo en parejas (conductor/navegante). Todo lo que anotes va en una hoja con los dos números de lista; se
entrega con el *exit ticket*.

## Archivos

| Archivo | Qué es |
|---|---|
| `ejemplo_columna_split.c` | Ejemplo resuelto de la mini-lección: `MPI_Type_vector` para enviar una columna y `MPI_Comm_split` para un comunicador por fila. `--sin-commit` reproduce la variante que falla |
| `caza1_orden_send_buggy.c` | Cazador 1 · intercambio cruzado entre parejas de procesos. Un error |
| `caza2_bcast_solo_raiz_buggy.c` | Cazador 2 · repartir un vector y sumarlo. Un error |
| `caza3_recv_corto_buggy.c` | Cazador 3 · reunir bloques balanceados en el rango 0. Un error |
| `revisar_mediciones.py` | Revisor de un CSV de mediciones contra el protocolo: recalcula mediana, *speedup*, eficiencia y Karp–Flatt; lista errores y avisos; `--png` grafica |
| `ejemplo_mediciones_ok.csv` | Tabla de ejemplo que cumple el protocolo (valores construidos para el ejercicio, **no medidos**) |
| `ejemplo_mediciones_mal.csv` | Tabla de ejemplo con cinco errores del protocolo plantados a propósito (también construida) |
| `Makefile` | `make`, `make run`, `make test`, `make clean` + `make sintomas`, `make listo`, `make revisar` |
| `tests/run_tests.sh` | Verificación automática. `make test` pasa con el material tal cual; `make listo` pasa **solo** cuando tus tres correcciones (y tu caza4) existen y funcionan |

Compila con `make` (`mpicc -std=c11 -O2 -Wall -Wextra`). Si tu MPI no acepta `--oversubscribe` (MPICH):
`make MPIRUN_FLAGS="" test`. Los programas que pueden colgarse se corren siempre bajo `timeout 10`.

Convención de los cuatro cazadores: el rango 0 imprime `VERIFICACION OK` al final si todo salió bien y
`VERIFICACION FAIL` si el resultado es incorrecto. Un programa que se cuelga o aborta no imprime nada de eso.

---

## Parte 1 · Cazador de errores (PRIMM)

### Fase 1 · Predecir (4 min, sin ejecutar nada)

Lee los tres `*_buggy.c` (cada uno cabe en una pantalla). Para cada uno escribe en la hoja:

| | ¿Qué línea tiene el error? | Síntoma que predices al correr con `-np 4` y el `n` por defecto | ¿Depende de `n`? ¿Cómo? |
|---|---|---|---|
| caza1 | | ☐ se cuelga ☐ aborta con error ☐ termina con `FAIL` ☐ termina `OK` | |
| caza2 | | ☐ se cuelga ☐ aborta con error ☐ termina con `FAIL` ☐ termina `OK` | |
| caza3 | | ☐ se cuelga ☐ aborta con error ☐ termina con `FAIL` ☐ termina `OK` | |

Pistas de lectura (no respuestas): en caza1 fíjate en el **orden** de las dos llamadas y recuerda qué promete
`MPI_Send` (S02). En caza2, ¿**quién** llama a la colectiva? En caza3 compara la fórmula del tamaño que usa el que
envía con la que usa el que recibe.

- **P1.** caza1 con `n = 100`: ¿mismo síntoma que con `n = 1 000 000`? ____
- **P2.** caza2 con `n = 100`: ¿se cuelga, aborta o termina? Si termina, ¿qué imprime `suma=`? ____
- **P3.** caza3 con `n = 8` y 4 procesos: ¿funciona? ¿Y con `n = 10`? ____

### Fase 2 · Ejecutar (5 min)

```bash
make
make sintomas                                   # los tres, con -np 4, n por defecto, timeout 10 s
mpirun --oversubscribe -np 4 ./caza1_orden_send_buggy 100
mpirun --oversubscribe -np 4 ./caza2_bcast_solo_raiz_buggy 100
mpirun --oversubscribe -np 4 ./caza3_recv_corto_buggy 8
mpirun --oversubscribe -np 4 ./caza3_recv_corto_buggy 10
```

Marca ✓/✗ en tu tabla. Salida real del entorno de autoría (Open MPI 4.1.6, 4 núcleos):

```
== caza1_orden_send_buggy (-np 4, timeout 10 s) ==
   -> código de salida 124  (124/137 = no terminó en 10 s; 0 = terminó; otro = abortó)
== caza2_bcast_solo_raiz_buggy (-np 4, timeout 10 s) ==
   -> código de salida 124
== caza3_recv_corto_buggy (-np 4, timeout 10 s) ==
[vm:13067] *** An error occurred in MPI_Recv
[vm:13067] *** reported by process [1610350593,0]
[vm:13067] *** MPI_ERR_TRUNCATE: message truncated
[vm:13067] *** MPI_ERRORS_ARE_FATAL (processes in this communicator will now abort,
   -> código de salida 15
```

Con los tamaños pequeños:

```
caza1: n=100 doubles (0.0 MB por mensaje), 4 procesos
VERIFICACION OK                                  <- "funciona"... por suerte
caza2: n=100, 4 procesos, suma=1200, esperada=4950
VERIFICACION FAIL                                <- termina, pero mal
caza3: n=8, 4 procesos, elementos reunidos=8, suma=36, esperada=36
VERIFICACION OK                                  <- "funciona"... porque 8 es divisible entre 4
```

Si `mpirun` se queda colgado **después** de imprimir el error de caza3, es el lanzador al limpiar los procesos;
Ctrl-C y repite. El código de salida distinto de 0 ya es el síntoma.

### Fase 3 · Investigar (10 min; en casa si no alcanza)

- **I1. El umbral de caza1.** Corre `caza1_orden_send_buggy` con `n` = 400, 500, 505, 508 y 600 (con `timeout
  10`). ¿A partir de qué `n` se cuelga? Multiplica por 8 bytes. ¿Qué cantidad conocida de S02 te recuerda?
  Escribe con tus palabras qué garantiza `MPI_Send` y qué **no** garantiza. ¿Es correcto un programa que
  "funciona hasta `n = 505`"?
- **I2. caza2 con `n = 100` termina con `suma=1200`.** ¿De dónde sale 1200? (Pista: ¿qué contiene `x` en los
  rangos 1, 2 y 3? ¿Qué índices suma el rango 0 con el reparto cíclico?) Comprueba tu cuenta con `n = 8`.
  ¿Por qué con `n = 100` termina y con `n = 1 048 576` se cuelga? ¿Dónde está detenido cada proceso en el
  segundo caso? (Pista: ¿qué hacen los rangos 1–3 cuando terminan `MPI_Reduce`, y a quién esperan?)
- **I3. caza3: la cuenta en `MPI_Recv` es una capacidad.** Con `n = 10` y 4 procesos, llena la tabla:

  | rango | elementos que **envía** (`block_size`) | elementos que el rango 0 **espera** (`n / size`) | ¿truncamiento? |
  |---|---|---|---|
  | 1 | | | |
  | 2 | | | |
  | 3 | | | |

  ¿Por qué `n = 8` no falla? ¿Y `n = 5`? ¿Qué habría pasado si el receptor hubiera pedido **más** elementos de
  los enviados (p. ej. `n`)? ¿Cómo sabría cuántos llegaron de verdad? (S02: `MPI_Get_count`.)
- **I4. Los seis errores clásicos.** En `notas-estudiante.md` §4 hay una tabla con seis errores. Asigna a cada
  cazador su fila. Quedan tres filas sin cazador: para cada una escribe en una línea **qué síntoma** tendría.

### Fase 4 · Modificar (10 min; en casa si no alcanza)

Para cada cazador: copia el archivo sin el sufijo `_buggy`, corrige **solo lo necesario** y verifica.

```bash
cp caza1_orden_send_buggy.c caza1_orden_send.c            # igual para caza2 y caza3
# ... corrige ...
make listo
```

Objetivos verificables (lo que `make listo` comprueba):

- **M1.** `caza1_orden_send` termina con `VERIFICACION OK` con `n = 1 000 000` y 4 procesos, y también con 2.
  Hay al menos tres correcciones válidas (S02 §5): elige una y escribe en un comentario por qué funciona para
  **cualquier** `n`. No vale bajar `n`.
- **M2.** `caza2_bcast_solo_raiz` da `OK` con `n = 1 048 576` (4 procesos) y con `n = 1000` (3 procesos). La
  corrección es de **una línea de posición**. Escribe la regla general en el comentario.
- **M3.** `caza3_recv_corto` da `OK` con 4 procesos y `n` = 10, 7 y 8, y con 3 procesos y `n = 7`. Dos
  correcciones válidas: que el receptor use la misma fórmula que el emisor, o que reciba con capacidad `n` y
  pregunte con `MPI_Get_count` cuántos llegaron. Si eliges la segunda, ¿qué cambia en `offset`?

`make test` sigue pasando mientras no tengas las correcciones (las marca `SKIP`); `make listo` solo pasa cuando
las tres existen y funcionan.

### Fase 5 · Crear (en casa; ejercicio 1 de la tarea)

Escribe **un cuarto programa con error** para que tu pareja lo cace. Reglas:

1. Nombre `caza4_<tema>_buggy.c` (p. ej. `caza4_etiquetas_buggy.c`). ≤ 60 líneas. Compila sin *warnings*.
   El rango 0 imprime `VERIFICACION OK`/`FAIL` al final, como los otros tres.
2. El error es **uno** de los tres clásicos que no tienen cazador todavía: etiquetas (o fuente, o comunicador)
   cruzadas · `MPI_Finalize` con mensajes pendientes o colectiva llamada por un subconjunto distinto de "solo
   la raíz" · usar el rango como índice de un arreglo sin verificar `p` (p. ej. un arreglo de tamaño 4 con
   `-np 6`). Si quieres, el error de "imprimir desde todos los rangos sin orden": entonces el síntoma debe ser
   verificable (compara la salida con el orden esperado y escribe `FAIL` si no coincide).
3. Encabezado con la **ficha** (comentario de 4 líneas, sellada: tu pareja la lee **después** de cazar):
   ```
   /* FICHA (no leer antes de cazar)
    * Síntoma esperado con -np 4: ...
    * Idea errónea del Anexo A o error clásico: ...
    * Pista (una línea): ...
    * Corrección (una línea): ... */
   ```
4. El síntoma debe ser **reproducible**: 3 de 3 corridas con `timeout 10` muestran lo mismo (cuelgue, aborto o
   `FAIL`). Un error que "a veces" se ve también vale, si la ficha dice con qué `n` o con qué `-np` se ve siempre.

Tu pareja crea `caza4_<tema>.c` corregido. **Criterio de "listo"** para la pareja: `make listo` termina en
`0 FAIL` (compila sin *warnings*, el `_buggy` muestra síntoma, el corregido dice `OK`), la ficha coincide con lo
que la pareja encontró, y cada uno puede decir en voz alta qué regla del estándar violaba el otro.

---

## Parte 2 · Taller del proyecto rumbo a H2 (50 min)

H2 se recibe el **lunes 23 de noviembre de 2026, en clase** (etiqueta `H2` antes de las 10:30; 15 puntos del
proyecto). La rúbrica completa, la lista de autoevaluación y el banco de preguntas están en
`proyecto/hitos/H2-avance-2.md`; aquí no se repiten. Lo de hoy es cerrar lo que todavía se pueda **medir y
revisar** con el equipo junto y el profesor pasando. La Práctica 5 vence el **domingo 22 de noviembre a las
23:59**: reparte el fin de semana con eso en mente.

### 2.1 Lista de cotejo del taller (qué debe quedar hecho hoy)

Marca en orden; el profesor pregunta por el número en el que vas.

| # | Hecho hoy | Dónde está la regla |
|---|---|---|
| 1 | `make test` de V2 compara contra V1 con `OMP_NUM_THREADS` = 1, 2, 4, 8 y repite ≥ 3 veces; pasa en la máquina de medición | H2 §2.1 |
| 2 | `resultados/mediciones.csv` tiene las filas `V1,1`, `V2,1`, `V2,2`, `V2,4`, `V2,8` con 5 repeticiones al `N_declarado` de H1, generadas con `run_all.sh` (`proyecto/plantillas/`) | H2 §2.2; protocolo §2 |
| 3 | `python3 revisar_mediciones.py resultados/mediciones.csv --nucleos <físicos>` termina con `0 errores`; los avisos están anotados | esta carpeta |
| 4 | La tabla de Karp–Flatt está llena para p = 2, 4, 8 y comparada con `1 − f_p` de H1; elegida una de las cuatro lecturas, con números | H2 §2.3 |
| 5 | Hay **dos** decisiones con experimento (planificación y sincronización/alcance), medidas con el protocolo, en la tabla de H2 §2.4 | H2 §2.4 |
| 6 | La tabla de *speedup* fue revisada por **otro equipo** con la lista 2.3 y las observaciones están atendidas o anotadas | hoy |
| 7 | `reporte/H2.md` tiene "Qué no entendemos todavía" con ≥ 3 preguntas concretas y el plan de V3 (plataforma, qué calcula un hilo, qué datos viajan) | H2 §2.6 |
| 8 | Bitácora con ≥ 3 entradas nuevas desde H1; sección H2 de `declaracion-ia.md` con "qué nos dijo mal" | H2 §2.5 |

Si llegas al 8 antes de tiempo: ensaya la ronda de recepción (3 min, gráfica en pantalla, las dos preguntas
fijas y una del banco por integrante, H2 §6).

### 2.2 Protocolo aplicado al proyecto, en una pantalla

```
Tamaños    N_prueba (T(1) < 1 s, para make test)  ·  N_declarado (1–10 s con -O2, el de H1; es el de TODA la tabla)
Hilos      1, 2, 4 ... hasta los núcleos FÍSICOS, y uno más allá marcado como sobre-suscripción (nproc cuenta lógicos: lscpu)
Corridas   1 de calentamiento (no cuenta) + 5 cronometradas por configuración; se reporta la MEDIANA (y mín, máx)
Línea base T(1) = V1 (el mejor secuencial), nunca V2 con 1 hilo; la fila V2,1 se reporta aparte: es la sobrecarga de OpenMP
Cálculos   S = T(1)/T(p)  ·  E = S/p  ·  f(p) = (1/S − 1/p)/(1 − 1/p); si f crece con p, hay sobrecarga que crece con los hilos
Tabla      config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia(,min_s,max_s)  +  entorno.txt (CPU, núcleos, RAM, SO, gcc, flags, fecha)
Gráfica    speedup vs hilos con la línea ideal S = p; un color por versión; n y máquina en el pie
Texto      3–6 líneas: dónde deja de escalar, por qué, y si coincide con la predicción escrita ANTES de medir
```

Prueba el revisor con los dos CSV de ejemplo antes de usarlo con el tuyo:

```bash
python3 revisar_mediciones.py ejemplo_mediciones_ok.csv  --nucleos 4 --png speedup_ejemplo.png
python3 revisar_mediciones.py ejemplo_mediciones_mal.csv --nucleos 4
```

Salida real sobre el CSV correcto (recorta la tabla y pégala tal cual en `reporte/H2.md`):

```
| Versión | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |
|---|---|---|---|---|---|---|---|
| V1 | 1 | 2.405 | 2.398 | 2.421 | 1.000 | 1.000 | — |
| V2 | 1 | 2.489 | 2.471 | 2.502 | 0.966 | 0.966 | — |
| V2 | 2 | 1.288 | 1.277 | 1.302 | 1.867 | 0.934 | 0.071 |
| V2 | 4 | 0.712 | 0.705 | 0.731 | 3.378 | 0.844 | 0.061 |
| V2 | 8 | 0.715 | 0.698 | 0.741 | 3.364 | 0.420 | 0.197 |

AVISO A1  fila V2,8: 8 hilos en una máquina de 4 núcleos físicos: márcala como sobre-suscripción / hyper-threading ...
Resumen: 0 errores, 1 avisos
```

Sobre el CSV con errores el revisor reporta `5 errores, 3 avisos` (E1, E6, E2, E3, E5 y avisos A4, A2, A1).
**Antes de correrlo**, encuentra los cinco a ojo: es exactamente lo que harás con la tabla de otro equipo.

### 2.3 Revisión por pares de la tabla de *speedup* (8 min por tabla)

Intercambia tu tabla (CSV + gráfica + las 3–6 líneas de interpretación) con el equipo vecino. El revisor
automático ya vio los números; tú revisas lo que él no puede. Marca ✓ / ✗ / "no se puede saber" y escribe una
observación por ✗.

| # | Pregunta de revisión | Qué evidencia buscas |
|---|---|---|
| 1 | ¿`T(1)` es el **mejor secuencial** (V1 con `-O2`), no V2 con un hilo? | Fila `V1,1` en el CSV; `speedup` de `V2,1` distinto de 1.000; `Makefile` de V1 con `-O2` |
| 2 | ¿Es la **mediana** de ≥ 5 repeticiones con calentamiento, al mismo `n` en todas las filas? | Columnas `rep1..rep5` llenas; `mediana_s` coincide; columna `n` constante; `run_all.sh` en el repo |
| 3 | ¿Está calculado **Karp–Flatt** para p = 2, 4, 8 y comparado con la fracción de H1? | Tabla de H2 §2.3 con números, no solo la fórmula |
| 4 | ¿**Explican dónde deja de escalar** y por qué, con una causa verificable? | Texto de 3–6 líneas que nombra la causa (fracción secuencial, memoria, sincronización, falso compartido, desbalance) y la liga a un número o experimento, no "por la sobrecarga" |
| 5 | ¿La fila que excede los núcleos físicos está **marcada** y no se usa para concluir? | `entorno.txt` dice núcleos físicos; la tabla tiene el asterisco; la conclusión usa p ≤ físicos |
| 6 | ¿La gráfica tiene línea ideal, ejes con unidades, `n` y máquina en el pie, y la predicción previa aparece en el texto? | `speedup.png`; frase "antes de medir esperábamos…" |

Devuelve la hoja. El equipo revisado anota en su bitácora qué cambió a raíz de la revisión (o por qué no).

### 2.4 Las dos preguntas del profesor en cada ronda

1. **"¿Qué midieron?"** → muestran la gráfica y dicen `T(1)`, `S(4)`, `E(4)` y `f(4)` de memoria.
2. **"¿Qué no entienden todavía?"** → leen una pregunta concreta de `reporte/H2.md` (si no hay ninguna escrita, ese
   es el primer pendiente del equipo).

---

## Uso de IA en esta práctica

🟢 Pedirle que explique con otras palabras la semántica de `MPI_Send` o qué es la firma de un tipo derivado.
🟡 Pedirle que revise tu `caza4_*_buggy.c` y te diga si el síntoma es reproducible (tú lo verificas con 3
corridas y lo declaras). 🔴 Pegar un `*_buggy.c` y pedir "corrígelo": la corrección sin la regla no sirve en el
examen ni en la defensa. 🔴 "Mejorar" la tabla de mediciones con la IA: inventar o seleccionar corridas tiene la
misma consecuencia que el plagio (`proyecto/README.md` §5).
