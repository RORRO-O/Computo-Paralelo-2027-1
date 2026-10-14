# H2 · Avance 2: V2 en memoria compartida con *speedup* medido

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · H2 · Avance 2 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208 · 15 puntos del proyecto (el proyecto es 40 % del 3.er parcial)

## 1. En una tabla

| Qué | Detalle |
|---|---|
| Fecha de entrega | **Lunes 23 de noviembre de 2026.** Etiqueta `H2` en el repositorio antes de las **10:30**; recepción en clase (sesión U5·S01) |
| Peso | **15 puntos** de los 100 del proyecto (`planeacion/mapa-evaluacion.md`). Rúbrica de 100 puntos; puntos del proyecto = puntos de la rúbrica × 0.15 |
| Qué se entrega | V2 con OpenMP correcta frente a V1 con pruebas · tabla de *speedup* y eficiencia con 1, 2, 4 y 8 hilos según el protocolo · Karp–Flatt y comparación con la fracción estimada en H1 · decisiones de `schedule` y sincronización justificadas con mediciones · bitácora actualizada · `reporte/H2.md` con "qué medimos, cómo y qué no entendemos todavía" y el plan de V3 |
| Cómo se recibe | Ronda de 3 minutos por equipo con la gráfica de *speedup* en pantalla: dos preguntas fijas al equipo y una individual a cada integrante (sección 6) |
| Retroalimentación | Por escrito, con la rúbrica, a más tardar el **lunes 30 de noviembre** |
| Entrega tardía | Etiqueta creada hasta 72 h después (jueves 26 de noviembre 10:30): máximo 80 %. Después no se recibe salvo justificante |
| Fechas vecinas | Práctica 5 vence el **domingo 22 de noviembre 23:59**, la noche anterior. Planea terminar V2 en la semana del 9 de noviembre y usar el taller del jueves 19 de noviembre (U4·S06) para cerrar mediciones |

## 2. Qué entregas

### 2.1 V2 con OpenMP, correcta frente a V1

Carpeta `src/v2/` con:

- El **mismo algoritmo** que V1, paralelizado con OpenMP. Si para paralelizar cambiaste el algoritmo (otro orden de
  acumulación, otra estructura de datos), lo declaras y, si el cambio también acelera la versión secuencial,
  actualizas V1: la línea base sigue siendo el mejor secuencial disponible (protocolo §3).
- Compila sin *warnings* con `gcc -std=c11 -O2 -Wall -Wextra -fopenmp`. `Makefile` con `all`, `run`, `test`, `clean`.
- `tests/run_tests.sh` que **compara contra la salida de V1** con tolerancia declarada, para `OMP_NUM_THREADS`
  = 1, 2, 4 y 8, y repite cada caso **al menos 3 veces**: una carrera es no determinista y "salió bien una vez" no
  es evidencia (Anexo A, 7). En punto flotante, `reduction` cambia el orden de las sumas: la tolerancia se
  justifica (Anexo A, 10).
- **Evidencia de búsqueda de carreras**, una de dos (las dos en Ejemplar):
  - ThreadSanitizer con tamaño de prueba: `gcc -std=c11 -O1 -g -fopenmp -fsanitize=thread …` y la salida (o su
    resumen) en la bitácora. Aviso: la `libgomp` de `gcc` no está instrumentada y TSan puede reportar avisos falsos en
    barreras y `reduction`; distingue los avisos que señalan **tus** variables de los que señalan la biblioteca, y
    documenta cuáles son cuáles.
  - Análisis de accesos: tabla con cada variable compartida dentro de la región paralela, quién la lee, quién la
    escribe y qué la protege (`private`, `firstprivate`, `reduction`, `atomic`, `critical`, índice disjunto).
- El programa acepta el tamaño por línea de comandos, imprime `RESULTADO` y `TIEMPO_S`, y respeta `OMP_NUM_THREADS`
  (no fijes `num_threads(4)` en el código).

### 2.2 Tabla de *speedup* y eficiencia con el protocolo · `resultados/mediciones.csv`

Generada con `run_all.sh` (plantilla en `proyecto/plantillas/`), al **tamaño declarado en H1** (si cambió, se
justifica), con calentamiento y 5 repeticiones:

```bash
./run_all.sh -e V1 -n <N_declarado> -t 1         -o resultados/mediciones.csv -- ./src/v1/<programa>
./run_all.sh -e V2 -n <N_declarado> -t "1 2 4 8" -o resultados/mediciones.csv -- ./src/v2/<programa>
python3 herramientas/graficar_proyecto.py resultados/mediciones.csv --titulo "<problema>"
```

Reglas del protocolo que más se olvidan:

- `T(1)` es **V1**, no V2 con un hilo. La fila `V2,1` también se reporta: la diferencia con V1 es la sobrecarga de
  OpenMP, y es un dato.
- Hilos: 1, 2, 4, 8 hasta el número de núcleos **físicos** de la máquina y uno más allá, declarado como
  sobre-suscripción o *hyper-threading*. Con 4 núcleos físicos, la fila de 8 se marca así.
- Una sola máquina por tabla. El entorno va en `resultados/entorno.txt` (lo escribe `run_all.sh`).
- Gráfica `speedup.png` con la línea ideal `S = p`; opcional `eficiencia.png`.

Tabla en `reporte/H2.md` (la imprime `graficar_proyecto.py`; pega la salida):

```
Tamaño del problema n = ____; línea base T(1) = V1 = ____ s. Máquina: ____ (núcleos físicos: __).

| Versión | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |
|---|---|---|---|---|---|---|---|
| V1 | 1 |  |  |  | 1.00 | 1.00 | — |
| V2 | 1 |  |  |  |  |  | — |
| V2 | 2 |  |  |  |  |  |  |
| V2 | 4 |  |  |  |  |  |  |
| V2 | 8 (*) |  |  |  |  |  |  |
(*) sobre-suscripción / hyper-threading: la máquina tiene __ núcleos físicos.
```

### 2.3 Karp–Flatt y comparación con la fracción estimada en H1

Para cada `p > 1`, la fracción secuencial que **explica** el *speedup* medido es

```
f(p) = (1/S(p) − 1/p) / (1 − 1/p)
```

En H1 estimaste `f_p` (fracción paralelizable en tiempo), es decir, una fracción secuencial `f_H1 = 1 − f_p`.
Llena y comenta:

```
| p | S(p) medido | f(p) Karp–Flatt | f_H1 = 1 − f_p | S(p) predicho en H1 (Amdahl) | Diferencia S medido − S predicho |
|---|---|---|---|---|---|
| 2 |  |  |  |  |  |
| 4 |  |  |  |  |  |
| 8 |  |  |  |  |  |

Lectura (elige la que corresponde y argumenta con los números):
- f(p) ≈ f_H1 y constante en p  → Amdahl explica el resultado; el perfil de H1 era bueno.
- f(p) crece con p              → hay sobrecarga que crece con los hilos: sincronización, falso compartido,
                                   creación de hilos, ancho de banda de memoria. ¿Cuál? ¿Qué experimento lo muestra?
- f(p) < f_H1                    → el perfil sobreestimó la parte secuencial, o hay efecto de caché (más hilos,
                                   más caché total). ¿Cómo lo verificas?
- f(p) < 0                       → speedup superlineal. Se explica (caché) y se verifica correctitud; no se celebra
                                   (Anexo A, 4).
```

Y el texto mínimo de interpretación del protocolo (3–6 líneas): dónde deja de escalar, por qué, y si coincide con la
predicción que escribiste en H1 antes de medir.

### 2.4 Decisiones de `schedule` y sincronización, justificadas con mediciones

Mínimo **dos decisiones con experimento**, una de planificación y una de sincronización o alcance de variables.
Cada experimento sigue el protocolo (mismo tamaño, 5 repeticiones, mediana); puede hacerse solo con 4 hilos si lo
declaras. Formato:

```
| Decisión | Opciones medidas | Mediana con 4 hilos (s) por opción | Elegida | Por qué (ligado al perfil y a Foster) | Costo de la descartada |
|---|---|---|---|---|---|
| Planificación del ciclo principal | static · dynamic,chunk=__ · guided | | | | |
| Acumulación del resultado | reduction · atomic · critical · acumuladores locales + combinación | | | | |
| (opcional) Acomodo de datos / falso compartido | sin padding · con padding · variable local por hilo | | | | |
| (opcional) collapse / anidamiento | sin collapse · collapse(2) | | | | |
```

Idea errónea atacada: "`schedule(dynamic)` siempre gana" y "`critical` y `atomic` son equivalentes" (Anexo A, 11
y 8). Un `critical` dentro del ciclo interno sin discusión baja el criterio 4.

### 2.5 Bitácora de errores actualizada

Al menos **3 entradas nuevas** desde H1, con la estructura de la plantilla. Lo que se espera ver en V2: la primera
carrera que encontraron, un resultado que cambiaba entre corridas, un *speedup* que no tenía sentido y qué lo
explicó, una medición descartada y por qué.

### 2.6 Lo que todo hito pide · `reporte/H2.md`

```markdown
# H2 · Avance 2 · Equipo NN · <problema>
> Etiqueta: H2 · Fecha de la etiqueta: · Máquina de medición: ver resultados/entorno.txt

## Qué medimos
<tabla de 2.2 y gráfica speedup.png>
## Cómo lo medimos
<comandos exactos (run_all.sh), repeticiones, hilos, núcleos físicos, banderas, qué quedó fuera de la región>
## Karp–Flatt y comparación con H1
<tabla de 2.3 y la lectura elegida, con números>
## Decisiones de diseño
<tabla de 2.4>
## Qué no entendemos todavía (mínimo 3 preguntas concretas)
1.
2.
3.
## Hacia V3 (≤ 10 líneas)
Plataforma: [ ] CUDA C  [ ] Numba CUDA  [ ] CuPy · Dónde: [ ] Colab  [ ] Kaggle  [ ] GPU propia (modelo: __)
Qué sección del perfil va al kernel: __ · Qué calcula un hilo: __ · Qué datos se transfieren y cuántas veces: __
Riesgo principal: __
## Reparto de trabajo en este hito
| Integrante (usuario de GitHub) | Qué hizo | Commits (hashes cortos) |
## Bitácora y declaración de IA
<enlaces; número de entradas nuevas; sección H2 de declaracion-ia.md>
```

## 3. Formato de entrega y qué va a correr el profesor

1. Etiqueta anotada antes de las 10:30 del lunes 23 de noviembre: `git tag -a H2 -m "Avance 2" && git push origin H2`.
2. El profesor ejecuta, sin ayuda del equipo:

```bash
git clone <repo> && cd <repo> && git checkout H2
cd src/v2 && make && make test                       # ¿sin warnings? ¿compara contra V1 con 1, 2, 4, 8 hilos? ¿código 0?
OMP_NUM_THREADS=4 make run                           # ¿RESULTADO coincide con V1? ¿TIEMPO_S es coherente con la tabla?
cd ../.. && head -n 8 resultados/mediciones.csv && cat resultados/entorno.txt
./run_all.sh -e V2 -n <N_declarado> -t "1 4" -o verificacion/mediciones.csv -- ./src/v2/<programa>   # ¿reproduce el orden de magnitud?
```

La verificación del profesor se hace en otra máquina; se espera el mismo **comportamiento** (forma de la curva),
no los mismos números.

## 4. Rúbrica · 100 puntos → 15 puntos del proyecto

Niveles: Ejemplar = 100 % del peso · Competente = 80 % · En desarrollo = 55 % · Insuficiente = 20 % · pieza
ausente en la etiqueta = 0. Puntos de la rúbrica = Σ (peso × nivel). Puntos del proyecto = puntos de la rúbrica × 0.15.

| Criterio | Peso | Ejemplar (100 %) | Competente (80 %) | En desarrollo (55 %) | Insuficiente (20 %) |
|---|---|---|---|---|---|
| **1. Correctitud de V2 frente a V1** | 25 | `make test` compara contra V1 con tolerancia justificada para 1, 2, 4 y 8 hilos y repite ≥ 3 veces cada caso; evidencia de carreras por TSan **y** análisis de accesos por variable; resultados dentro de la tolerancia en todas las corridas; mismo algoritmo que V1 o cambio declarado y aplicado también a V1; respeta `OMP_NUM_THREADS` | Pruebas pasan con todos los hilos y repeticiones; evidencia de carreras por un solo método; tolerancia declarada | Pruebas con un solo número de hilos, o una sola repetición, o tolerancia sin justificar, o diferencias "pequeñas" sin explicación, o número de hilos fijo en el código | Resultados distintos entre corridas sin explicación, o `make test` falla, o *warnings*, o V2 resuelve otro problema u otro tamaño |
| **2. Medición conforme al protocolo** | 25 | Tabla con 1, 2, 4, 8 hilos (hasta núcleos físicos + 1, declarado), mediana de ≥ 5 con calentamiento, `-O2`, tamaño igual al de H1 o cambio justificado, `T(1)` = V1 con la fila `V2,1` aparte, mín y máx, entorno completo (CPU, núcleos físicos/lógicos, RAM, SO, compilador, banderas, fecha), gráfica con línea ideal, CSV y `run_all.sh` que lo regenera | Tabla y gráfica correctas; falta un dato del entorno, o la fila `V2,1`, o mín/máx; reproducible | < 5 repeticiones, o sin calentamiento, o `T(1)` tomado de V2 con un hilo sin decirlo, o tamaño distinto entre configuraciones, o sin gráfica, o dos máquinas en una tabla | Sin tabla, o medido con `-O0`, o no reproducible (el *script* no existe o no corre con el repositorio de la etiqueta) |
| **3. Análisis: Karp–Flatt y comparación con H1** | 20 | `f(p)` correcta para cada `p > 1`; comparación numérica con `1 − f_p` de H1 y con el `S(p)` predicho; explicación de la diferencia con una causa verificable (sobrecarga creciente, ancho de banda, falso compartido, desbalance) apoyada en un experimento o en la tabla de decisiones; identifica dónde deja de escalar; contrasta con la predicción escrita antes de medir | `f(p)` correcta y comparación hecha; explicación plausible sin experimento que la apoye | `f(p)` calculada pero no interpretada, o comparación con H1 ausente, o explicación genérica ("por la sobrecarga") sin ligarla a los números | `f(p)` mal calculada (p. ej., con `S` respecto a `V2,1`), o sin análisis, o conclusiones que contradicen la tabla |
| **4. Decisiones de diseño justificadas con evidencia** | 15 | ≥ 2 decisiones (planificación y sincronización/alcance) con alternativas medidas bajo el protocolo y tabla comparativa; la elección coincide con la evidencia; se explica el costo de la descartada en términos del modelo (costo por *chunk*, contención, orden de redondeo); sin sincronización innecesaria en el ciclo interno | ≥ 2 decisiones con evidencia; una alternativa medida fuera de protocolo y declarado, o explicación del costo incompleta | Decisiones declaradas sin experimento ("usamos `dynamic` porque es mejor"), o una sola decisión, o `critical` en el ciclo interno sin discusión | Sin decisiones documentadas, o decisiones contradichas por sus propias mediciones sin comentario |
| **5. Proceso e integridad (individual)** | 15 | *Commits* de todos desde H1; bitácora con ≥ 3 entradas nuevas reales (una carrera, un resultado inestable o una medición descartada, con detección y cambio); declaración de IA sección H2 completa incluida "qué nos dijo mal"; "qué no entendemos todavía" con ≥ 3 preguntas concretas; plan de V3 con plataforma, *kernel* y datos a transferir; cada integrante responde correctamente su pregunta individual | Todo presente; participación desigual explicada; respuesta individual correcta con una pista | Bitácora o declaración de trámite; *commits* concentrados en una persona; plan de V3 sin *kernel* ni datos; respuesta individual parcial | El integrante no puede explicar la parte que firmó; o declaración ausente; o evidencia de entrega sin comprensión |

Suma de pesos: 25 + 25 + 20 + 15 + 15 = **100**.

| Puntos de la rúbrica | 100 | 90 | 80 | 70 | 60 | 50 |
|---|---|---|---|---|---|---|
| Puntos del proyecto (× 0.15) | 15.0 | 13.5 | 12.0 | 10.5 | 9.0 | 7.5 |

El criterio 5 se asigna por integrante. Los criterios 1–4 son del equipo.

## 5. Lista de cotejo de autoevaluación (antes de crear la etiqueta)

**Correctitud**
- [ ] `make clean && make` sin *warnings* con `-std=c11 -O2 -Wall -Wextra -fopenmp`.
- [ ] `make test` compara contra V1 con tolerancia escrita y justificada, con 1, 2, 4 y 8 hilos, ≥ 3 repeticiones cada uno.
- [ ] Corrimos TSan con tamaño de prueba y anotamos en la bitácora qué avisos son nuestros y cuáles de `libgomp`.
- [ ] Tenemos la tabla de accesos: cada variable compartida, quién lee, quién escribe, qué la protege.
- [ ] El número de hilos viene de `OMP_NUM_THREADS`; no hay `num_threads(...)` fijo.
- [ ] Si cambiamos el algoritmo respecto a V1, lo declaramos y V1 sigue siendo el mejor secuencial.

**Medición**
- [ ] Tamaño declarado igual al de H1 (o cambio justificado por escrito).
- [ ] `resultados/mediciones.csv` tiene filas `V1,1` y `V2,1`, `V2,2`, `V2,4`, `V2,8` con 5 repeticiones.
- [ ] La fila de 8 (o la que exceda los núcleos físicos) está marcada como sobre-suscripción.
- [ ] `resultados/entorno.txt` dice CPU, núcleos físicos/lógicos, RAM, SO, `gcc`, banderas, fecha.
- [ ] `speedup.png` tiene la línea ideal, ejes con unidades y el `n` en el subtítulo.
- [ ] `run_all.sh` regenera el CSV completo desde cero.
- [ ] Ninguna medición descartada se borró; están en la bitácora.

**Análisis**
- [ ] `f(p)` calculada con `S` respecto a V1 para `p` = 2, 4, 8.
- [ ] Comparación numérica con `1 − f_p` y con el `S(p)` predicho en H1.
- [ ] La lectura elegida (Amdahl / sobrecarga creciente / caché / superlineal) está argumentada con los números.
- [ ] Decimos dónde deja de escalar y por qué.

**Decisiones**
- [ ] Una decisión de planificación con ≥ 2 opciones medidas.
- [ ] Una decisión de sincronización o alcance con ≥ 2 opciones medidas.
- [ ] No hay `critical` en el ciclo interno, o está discutido con números.

**Proceso**
- [ ] Todos tienen *commits* desde el 29 de octubre.
- [ ] Bitácora con ≥ 3 entradas nuevas; declaración de IA sección H2 completa.
- [ ] `reporte/H2.md` tiene "qué no entendemos todavía" (≥ 3) y "Hacia V3" lleno.
- [ ] Cada integrante puede explicar cualquier `#pragma` del repositorio y qué pasaría si se quita.
- [ ] `git tag -a H2` creado y empujado antes de las 10:30 del lunes 23 de noviembre.

## 6. Qué preguntará el profesor en la recepción (3 minutos por equipo)

**Al equipo (siempre las mismas dos):**
1. "¿Qué midieron?" → gráfica de *speedup* en pantalla, `T(1)`, `S(4)`, `E(4)`, `f(4)`.
2. "¿Qué no entienden todavía?" → la lista de `reporte/H2.md`.

**A cada integrante, una pregunta de este banco, al azar (sin ayuda del equipo):**

| # | Pregunta | Qué evidencia se busca |
|---|---|---|
| 1 | ¿Por qué este `schedule` y no otro? ¿Qué medición lo respalda? | Cita la tabla de decisiones y la razón (iteraciones uniformes o no, costo por *chunk*) |
| 2 | Señala una variable privada de la región paralela y di qué pasaría si fuera compartida | Describe la carrera concreta y su síntoma |
| 3 | ¿Qué pasa si quito este `reduction` y pongo `+=` directo? | Carrera; resultado incorrecto y no determinista; TSan lo señala |
| 4 | ¿Cuánto vale `f` de Karp–Flatt con 4 hilos y qué significa? | Da el número y lo lee como fracción secuencial efectiva |
| 5 | ¿Por qué el *speedup* con 8 hilos es menor (o igual) que con 4? | Núcleos físicos, memoria, sincronización; cita el entorno |
| 6 | ¿Por qué `T(1)` es V1 y no V2 con un hilo? ¿Cuánto difieren en su tabla? | Define *speedup* correctamente y da la sobrecarga medida |
| 7 | ¿`atomic` o `critical` aquí? ¿Por qué? | Operación simple sobre una variable vs región arbitraria; costo |
| 8 | ¿Qué aviso de TSan era de ustedes y cuál de `libgomp`? ¿Cómo lo distinguieron? | Cita la bitácora |
| 9 | ¿La fracción secuencial que midieron coincide con la de H1? Si no, ¿qué la explica? | Compara números y da una causa verificable |
| 10 | ¿Hay barrera al final de este `omp for`? ¿La necesitan? | Barrera implícita salvo `nowait`; justifica |
| 11 | ¿Qué calculará un hilo de la GPU en V3 y qué datos viajarán? | Coincide con "Hacia V3" |
| 12 | Muestra un *commit* tuyo posterior al 29 de octubre y explica qué cambió | El historial coincide con el reparto |

Regla de calificación: respuesta correcta → criterio 5 en Ejemplar o Competente según el resto de la evidencia;
parcial → En desarrollo; no puede explicar lo que firmó → Insuficiente para esa persona.

## 7. Errores típicos (síntoma → primera pregunta que debes hacerte)

| Síntoma | Primera pregunta |
|---|---|
| *Speedup* de 1.9 con 2 hilos, 3.9 con 4, 7.8 con 8 en una laptop de 4 núcleos | ¿Contra qué comparaste? ¿V2 con 1 hilo? ¿La máquina tiene 8 núcleos físicos? Revisa `entorno.txt` |
| *Speedup* superlineal | ¿Verificaste correctitud con 8 hilos? ¿Cabe el problema por hilo en caché L2 y el total no? Explícalo o no lo reportes |
| El resultado cambia en el 4.º decimal entre corridas | ¿Es orden de redondeo de `reduction` (tolerancia) o una carrera (TSan)? No lo decidas a ojo |
| TSan reporta 200 avisos | ¿Cuántos apuntan a tus líneas y cuántos a `libgomp`? Filtra y documenta |
| `make test` pasa con 4 hilos y falla con 2 | ¿Hay una suposición sobre el número de hilos (arreglo de tamaño 4, índice por `omp_get_thread_num()` sin tamaño dinámico)? |
| `f(p)` crece de 0.05 a 0.40 entre 2 y 8 hilos | ¿Qué crece con los hilos: sincronización, falso compartido, tráfico de memoria? Mide la sección sola |
| `dynamic` es más lento que `static` "y no sabemos por qué" | ¿Las iteraciones son uniformes? ¿Qué `chunk` usaste? Costo por *chunk* vs balance |
| Eficiencia 0.5 con 2 hilos en la sección "perfectamente paralela" | ¿Dos hilos escriben en la misma línea de caché (falso compartido)? Prueba acumuladores locales |
| La curva sube hasta 4 y baja con 8 | ¿Cuántos núcleos físicos tienes? ¿Marcaste la fila de 8 como sobre-suscripción? |
| El tamaño cambió respecto a H1 "porque así escala mejor" | ¿Declaraste el cambio? ¿Repetiste el perfil de V1 al nuevo tamaño? Si no, la comparación con H1 no vale |
| La gráfica no tiene línea ideal ni unidades | ¿Cómo se ve a simple vista cuánto falta para lo ideal? Usa `graficar_proyecto.py` |
| `num_threads(4)` en el código | ¿Cómo va a medir `run_all.sh` con 1, 2 y 8? Quítalo y usa `OMP_NUM_THREADS` |

## 8. Logística de la sesión (para el profesor)

La sesión U5·S01 (lunes 23 de noviembre) combina la recepción de H2 con el inicio de la Unidad V (arquitectura GPU,
modelo CUDA, suma de vectores en Colab), según `planeacion/calendario-27-1.md`. La ronda de 3 minutos por equipo
(~36 minutos con 12 equipos) deja ~50 minutos para la sesión de contenido, que en la plantilla base ocupa 90.
Opciones, a decidir por el profesor y anunciar el jueves 19 de noviembre (U4·S06):

| Opción | Cómo | Costo |
|---|---|---|
| A | Criterios 1–4 evaluados con la etiqueta fuera de clase; en clase ronda de 90 s por equipo con las dos preguntas fijas (≈ 18 min) durante la práctica guiada de suma de vectores; la pregunta individual se hace en el laboratorio del martes 24 de noviembre (U5·S02) en los primeros 25 min | La pregunta individual llega un día después; el laboratorio de P6 pierde 25 min |
| B | Recepción completa el jueves 19 de noviembre (U4·S06, taller hacia H2) para los equipos que ya tengan la etiqueta, y el lunes 23 solo para el resto | Dos fechas; la etiqueta de quienes se reciben el 19 se crea antes de las 10:30 de ese día; el taller pierde parte de su función de cierre |
| C | Sesión de contenido reducida a 55 min (sin reto de transferencia; suma de vectores como tarea en Colab) y 35 min de recepción | Primer contacto con CUDA más corto, compensado en el laboratorio del martes 24 |

Con cualquier opción, la etiqueta `H2` y la retroalimentación escrita en ≤ 7 días (lunes 30 de noviembre) no
cambian.
