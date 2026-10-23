# Rúbrica del repositorio (código V1·V2·V3) · 40 puntos

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · 40 de los 100 puntos del proyecto · versión 1.1 · 20 de octubre de 2026

## 1. Cómo se aplica

1. El profesor ejecuta `scripts/verificar_entrega.sh` sobre un clon limpio del repositorio (10 minutos, ver
   `reproducibilidad.md`) y después lee el código de las tres versiones, las pruebas, los CSV y la bitácora.
2. Cada criterio se ubica en **un** nivel según la evidencia observable de la tabla; el nivel fija los puntos. Un criterio
   ausente vale 0.
3. Los niveles valen 100 % · 80 % · 55 % · 20 % del peso del criterio (misma escala que las prácticas,
   `docs/metodo/03-plantilla-practica.md` §2).
4. C1–C5 son del equipo. **C6 se asigna por integrante** (`proyecto/README.md` §6): cada persona recibe el nivel más bajo
   que alcance cualquiera de sus dos evidencias, su historial de *commits* y la bitácora del equipo (que es común).
5. La defensa oral del jueves 10 de diciembre (rúbrica aparte, 15 puntos) aplica la prueba de propiedad; su resultado también
   baja C6 **del integrante** que no explica ni la línea de su parte firmada ni la de rescate (cuenta la mejor de las dos,
   `docs/metodo/05-politica-ia.md`; `proyecto/defensa/rubrica-defensa.md` §4.1; ver §4), o que falta a la defensa sin
   justificante (cuenta como fallar las dos, `docs/metodo/04-evaluacion.md` §3.2).

## 2. Pesos

| # | Criterio | Puntos | Ejemplar (100 %) | Competente (80 %) | En desarrollo (55 %) | Insuficiente (20 %) |
|---|---|---:|---:|---:|---:|---:|
| C1 | Correctitud y pruebas de V1/V2/V3 | 10 | 10.0 | 8.0 | 5.5 | 2.0 |
| C2 | Diseño paralelo de V2 (OpenMP) | 6 | 6.0 | 4.8 | 3.3 | 1.2 |
| C3 | Diseño paralelo de V3 (GPU) | 6 | 6.0 | 4.8 | 3.3 | 1.2 |
| C4 | Medición conforme al protocolo | 8 | 8.0 | 6.4 | 4.4 | 1.6 |
| C5 | Calidad y reproducibilidad del repositorio | 6 | 6.0 | 4.8 | 3.3 | 1.2 |
| C6 | Proceso: historial de *commits* del integrante y bitácora (por integrante) | 4 | 4.0 | 3.2 | 2.2 | 0.8 |
| | **Total** | **40** | 40.0 | 32.0 | 22.0 | 8.0 |

## 3. Niveles por criterio (evidencia observable)

### C1 · Correctitud y pruebas de V1/V2/V3 (10 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (10.0)** | `make test` termina con código 0. Las pruebas de V1 tienen los tres tipos de caso (pequeño verificable a mano, con referencia externa, invariante; `proyecto/README.md` §2). V2 coincide con V1 (misma `n` y semilla) dentro de una tolerancia declarada en el código con 1, 2, 4 y 8 hilos y ≥ 3 corridas por caso, para al menos tres tamaños incluido un caso borde (`n=1`, `n` no divisible entre hilos o el equivalente del problema). `tests/run_tests.sh` tiene **al menos dos casos propios** del equipo, derivados de su problema y comentados ("por qué importa"). El *notebook* muestra `PASS` de V3 contra V1 **en la misma sesión de Colab/Kaggle**, con un `n` que no es múltiplo del tamaño de bloque (la guarda de límites trabaja; el de la plantilla, 200000, cumple). Los programas rechazan argumentos inválidos con código distinto de 0 y mensaje en `stderr`. |
| **Competente (8.0)** | `make test` pasa con los tres tipos de caso de V1 y con V2 contra V1 en 1, 2, 4 y 8 hilos repetidos; *notebook* con `PASS`; pero no hay casos propios del equipo, o los que hay no dicen por qué importan. |
| **En desarrollo (5.5)** | V2 coincide con V1, pero V3 falla en algún caso, o no se verificó contra V1 en la misma sesión (solo "dio parecido"); o las pruebas pasan para un único tamaño, con un solo número de hilos o con una sola corrida; o falta alguno de los tres tipos de caso de V1; o la tolerancia no está declarada y se compara con igualdad exacta en punto flotante. |
| **Insuficiente (2.0)** | `make test` falla; el código no compila ni en la máquina del profesor ni en la demo (§4); o alguna versión produce resultados distintos de V1 sin explicación en la bitácora. |

### C2 · Diseño paralelo de V2 (OpenMP) (6 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (6.0)** | La región paralela corresponde a la partición y el mapeo de Foster descritos en el reporte y ataca la parte que domina el tiempo según el perfilado de V1. Alcance de variables explícito (`default(none)` o justificación equivalente por variable). `schedule` elegido y justificado con una medición propia o con el carácter uniforme/irregular de las iteraciones. Ninguna `critical`/`atomic` en el ciclo caliente sin justificación escrita; reducciones con `reduction` o acumuladores locales. Sin carreras: ThreadSanitizer limpio (comando en el README) o razonamiento de accesos por escrito en el código o la bitácora. V2 con 1 hilo no es más de 10 % más lenta que V1, o la diferencia se explica. |
| **Competente (4.8)** | Correcta y sin carreras. Una decisión (schedule, reducción o alcance) se tomó por defecto y no se justifica; o hay una ineficiencia identificada y explicada pero no corregida. |
| **En desarrollo (3.3)** | Funciona, pero la sincronización domina (sección crítica dentro del ciclo interno), el `schedule` no tiene relación con el problema, o se paralelizó una región que no es la que domina el tiempo de V1. |
| **Insuficiente (1.2)** | Paralelización incorrecta (carrera detectable con ThreadSanitizer o por lectura), inexistente, o sobre una región trivial (p. ej. solo la inicialización). |

### C3 · Diseño paralelo de V3 (GPU) (6 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (6.0)** | *Kernel* propio (CUDA C, Numba `@cuda.jit`, o CuPy `RawKernel`/`ElementwiseKernel`) con mapeo hilo→dato explícito y guarda de límites. Tamaño de bloque múltiplo de 32, justificado con al menos una comparación medida (p. ej. 128 vs 256 vs 512) en el CSV o la bitácora. Los datos suben al dispositivo una vez; no hay copias dentro del ciclo caliente, o se explica por qué no se pudo evitar. Se revisa `cudaGetLastError` (o la excepción equivalente) y se sincroniza antes de leer resultados. Memoria compartida y acceso coalescido se consideraron y la decisión está escrita, aunque sea "no aplica porque…". |
| **Competente (4.8)** | *Kernel* propio correcto, con bloque múltiplo de 32 y malla que cubre `n` con guarda de límites; tamaño de bloque fijo sin comparar; transferencias correctas pero no minimizadas; comprobación de errores presente. |
| **En desarrollo (3.3)** | V3 correcta pero construida solo con llamadas de biblioteca (`cupy.sum`, `cupy.dot`, `numpy`-sobre-GPU) sin *kernel* propio ni explicación de qué *kernel* corre debajo; o copia datos en cada iteración sin advertirlo; o sin verificación de errores. |
| **Insuficiente (1.2)** | V3 no corre, no coincide con V1, o es la V2 ejecutada en Colab sin usar la GPU. |

### C4 · Medición conforme al protocolo (8 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (8.0)** | `resultados/entorno.txt` y `entorno_gpu.txt` completos (CPU con núcleos físicos y lógicos, RAM, SO, compilador y banderas; GPU con modelo, driver y **fecha**). Compilación con `-O2`. Una ejecución de calentamiento y ≥ 5 repeticiones por configuración; se reporta la mediana con mínimo y máximo. `T(1)` ≥ 1 s. `T(1)` es la V1 (mejor secuencial); si además se reporta V2 con 1 hilo, se dice. Hilos 1, 2, 4, … hasta los núcleos físicos y uno más allá, declarado. GPU con **y** sin transferencias. Los CSV tienen la cabecera del protocolo y los generan `run_all.sh`, `herramientas/medir_proyecto.sh` y el *notebook*, no un editor. La predicción de *speedup* se escribió **antes** de medir (bitácora) y se compara. |
| **Competente (6.4)** | Protocolo completo con una omisión menor: falta mín/máx, o la configuración "uno más allá", o la predicción previa, o un dato del entorno (p. ej. RAM o fecha de la GPU). |
| **En desarrollo (4.4)** | Menos de 5 repeticiones; promedio en lugar de mediana con picos evidentes; sin calentamiento; `T(1)` < 1 s; GPU solo con o solo sin transferencias; o CSV reformateado a mano (formato distinto del que escriben `run_all.sh`, `medir_proyecto.sh` o el *notebook*) aunque sus valores se reproduzcan. |
| **Insuficiente (1.6)** | Sin mediciones reproducibles; `-O0`; tamaño cambiado entre configuraciones sin declararlo; *speedup* calculado contra la V2 con un hilo sin decirlo; o sin hardware. |

### C5 · Calidad y reproducibilidad del repositorio (6 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (6.0)** | En una máquina limpia, `git clone` + `make` + `make test` + `./run_all.sh --rapido` funcionan en ≤ 10 minutos **sin editar nada**. README con problema, datos (origen, tamaño, semilla), versiones (gcc, nvcc, paquetes de Python), y tabla "figura/tabla del PDF → comando → archivo". `Makefile` raíz con `all/run/test/clean`. Sin *warnings* con `-Wall -Wextra`. Identificadores en inglés, comentarios y mensajes en español. Sin binarios ni datos > 10 MB versionados (o script de descarga con suma SHA-256). *Notebook* de la V3 ejecutado, con salidas. `.gitignore` presente. |
| **Competente (4.8)** | Reproduce en ≤ 10 minutos con una intervención trivial que el README documenta (p. ej. `pip install matplotlib`); un elemento del README incompleto; algún *warning* aislado. |
| **En desarrollo (3.3)** | Reproduce solo tras editar rutas o el `Makefile`; o falta `run_all.sh` y hay que correr comandos a mano; o el *notebook* está sin salidas; o hay binarios versionados. |
| **Insuficiente (1.2)** | No compila en la máquina del profesor dentro de los 10 minutos, o el repositorio no corresponde al código que describe el reporte. |

### C6 · Proceso: historial de *commits* del integrante y bitácora (4 puntos, por integrante)

Evidencia del historial: `git log --author=<usuario> --format='%ad %s' --date=short entrega-final` y `git shortlog -sn
entrega-final`. El verificador imprime, por correo de autor, cuántos *commits* y en cuántas semanas distintas; cuáles
tienen cambios de código se revisa con `git log --stat --author=<usuario> entrega-final`.

| Nivel | Evidencia |
|---|---|
| **Ejemplar (4.0)** | El integrante tiene ≥ 3 *commits* con cambios de código (no solo README o formato) en ≥ 3 semanas distintas entre H1 y la entrega, con mensajes en español, en infinitivo, que describen el cambio; lo que el reparto del README §6 le atribuye coincide con sus *commits*. La bitácora del equipo tiene ≥ 5 entradas de errores fechadas y completas (qué falló, cómo se detectó, causa, qué se cambió, qué se aprendió), ≥ 1 medición descartada con su razón y ≥ 1 predicción comparada con el resultado; "qué no entendemos todavía" está escrito. |
| **Competente (3.2)** | El integrante tiene ≥ 3 *commits* con cambios de código, pero concentrados en ≤ 2 semanas; o la bitácora tiene 3–4 entradas completas, o le falta la medición descartada o la predicción. |
| **En desarrollo (2.2)** | El integrante tiene < 3 *commits* con cambios de código y el reparto del README explica por qué (p. ej. sus *commits* son de mediciones o del reporte); o sus mensajes no describen el cambio ("cambios", "final"); o la bitácora tiene menos de 3 entradas o entradas genéricas ("no funcionaba, lo arreglamos"). |
| **Insuficiente (0.8)** | Participación marginal **sin** explicación en el reparto (sin *commits* propios, o un solo volcado de archivos el último día); bitácora ausente; o en la defensa el integrante no explica ni la línea de su parte firmada ni la de rescate (pregunta 1 y rescate en Insuficiente; prueba de propiedad, `docs/metodo/05-politica-ia.md`); o faltó a la defensa sin justificante. |

## 4. Reglas que modifican la calificación

| Situación | Efecto |
|---|---|
| Entrega después del lunes 7 de diciembre 10:30 y hasta el jueves 10 de diciembre 10:30 | Calificación máxima 80 % de los 40 puntos (regla transversal) |
| Después de 72 h sin justificante institucional | No se recibe: 0 en los 40 puntos |
| No compila en la máquina del profesor en 10 minutos | C5 Insuficiente; C1–C4 se evalúan solo con lo que se pueda verificar en la demo en vivo de la defensa (si tampoco compila ahí, C1 Insuficiente) |
| Compila, pero `make test` falla | C1 Insuficiente; los demás criterios se evalúan con su evidencia (`reproducibilidad.md` §1) |
| Un integrante no explica en la defensa ni la línea de su parte firmada (pregunta 1) ni la de rescate | C6 Insuficiente **para ese integrante** (cuenta la mejor de las dos respuestas, `docs/metodo/05-politica-ia.md`); además aplica `proyecto/defensa/rubrica-defensa.md` §4.1 |
| Un integrante falta a la defensa sin justificante | C6 Insuficiente **para ese integrante**, como si hubiera fallado la pregunta 1 y la de rescate; además aplica `proyecto/defensa/rubrica-defensa.md` §4.2 |
| Mediciones que el flujo no puede producir: tiempos imposibles para el hardware de `entorno.txt` (p. ej. repeticiones idénticas en todos los dígitos, o *speedup* mayor que `p` sin verificación ni explicación), o CSV sin entorno ni comando que lo genere | C4 = 0 y se trata como integridad académica (`docs/metodo/04-evaluacion.md` §6) |
| Código idéntico entre equipos sin explicación | 0 en la entrega para todos los involucrados y reporte según reglamento |
| Uso de IA fuera del semáforo sin declarar (versión completa generada, texto sin revisar) | El criterio afectado baja a Insuficiente y se pregunta en la defensa |

## 5. Hoja de calificación (la llena el profesor; una por equipo)

| Equipo: `cp-6bm1-equipo__` | Commit evaluado: `_______` | Fecha de revisión: `__/12/2026` |
|---|---|---|

| Criterio | Nivel | Puntos | Evidencia observada (archivo, línea, comando, salida) |
|---|---|---:|---|
| C1 Correctitud y pruebas | | /10 | |
| C2 Diseño V2 | | /6 | |
| C3 Diseño V3 | | /6 | |
| C4 Medición | | /8 | |
| C5 Reproducibilidad | | /6 | |
| C6 Proceso (por integrante: `usuario` → nivel) | | /4 | |
| **Total** | | **/40** | |
| Ajustes de §4 | | | |
| Retroalimentación (3 líneas: lo mejor, lo que falta, qué revisar para la defensa) | | | |
