# Rúbrica del repositorio (código V1·V2·V3) · 40 puntos

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · 40 de los 100 puntos del proyecto · versión 1.0 · 14 de octubre de 2026

## 1. Cómo se aplica

1. El profesor ejecuta `scripts/verificar_entrega.sh` sobre un clon limpio del repositorio (10 minutos, ver
   `reproducibilidad.md`) y después lee el código de las tres versiones, las pruebas, los CSV y la bitácora.
2. Cada criterio se ubica en **un** nivel según la evidencia observable de la tabla; el nivel fija los puntos. Un criterio
   ausente vale 0.
3. Los niveles valen 100 % · 80 % · 55 % · 20 % del peso del criterio (misma escala que las prácticas,
   `docs/metodo/03-plantilla-practica.md` §2).
4. La defensa oral del jueves 10 de diciembre (rúbrica aparte, 15 puntos) aplica la prueba de propiedad; su resultado también
   modifica el criterio C6 **del integrante** que no pueda explicar su código (ver §4).

## 2. Pesos

| # | Criterio | Puntos | Ejemplar (100 %) | Competente (80 %) | En desarrollo (55 %) | Insuficiente (20 %) |
|---|---|---:|---:|---:|---:|---:|
| C1 | Correctitud y pruebas de V1/V2/V3 | 10 | 10.0 | 8.0 | 5.5 | 2.0 |
| C2 | Diseño paralelo de V2 (OpenMP) | 6 | 6.0 | 4.8 | 3.3 | 1.2 |
| C3 | Diseño paralelo de V3 (GPU) | 6 | 6.0 | 4.8 | 3.3 | 1.2 |
| C4 | Medición conforme al protocolo | 8 | 8.0 | 6.4 | 4.4 | 1.6 |
| C5 | Calidad y reproducibilidad del repositorio | 6 | 6.0 | 4.8 | 3.3 | 1.2 |
| C6 | Proceso: historial de *commits* de todos y bitácora | 4 | 4.0 | 3.2 | 2.2 | 0.8 |
| | **Total** | **40** | 40.0 | 32.0 | 22.0 | 8.0 |

## 3. Niveles por criterio (evidencia observable)

### C1 · Correctitud y pruebas de V1/V2/V3 (10 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (10.0)** | `make test` termina con código 0. V2 y V3 coinciden con V1 (misma `n` y semilla) dentro de una tolerancia declarada en el código, para al menos tres tamaños incluido un caso borde (`n=1`, `n` no divisible entre hilos o el equivalente del problema). `tests/run_tests.sh` tiene **al menos dos casos propios** del equipo, derivados de su problema y comentados ("por qué importa"). El *notebook* muestra `PASS` de V3 contra V1 **en la misma sesión de Colab/Kaggle**. Los programas rechazan argumentos inválidos con código distinto de 0 y mensaje en `stderr`. |
| **Competente (8.0)** | `make test` pasa y V2/V3 coinciden con V1, pero solo con los casos de la plantilla o con casos propios sin justificar. *Notebook* con `PASS`. |
| **En desarrollo (5.5)** | V2 coincide con V1, pero V3 falla en algún caso, o no se verificó contra V1 en la misma sesión (solo "dio parecido"); o las pruebas pasan para un único tamaño; o la tolerancia no está declarada y se compara con igualdad exacta en punto flotante. |
| **Insuficiente (2.0)** | No compila, `make test` falla, o alguna versión produce resultados distintos de V1 sin explicación en la bitácora. |

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
| **Competente (4.8)** | *Kernel* propio correcto con lanzamiento razonable; tamaño de bloque fijo sin comparar; transferencias correctas pero no minimizadas; comprobación de errores presente. |
| **En desarrollo (3.3)** | V3 correcta pero construida solo con llamadas de biblioteca (`cupy.sum`, `cupy.dot`, `numpy`-sobre-GPU) sin *kernel* propio ni explicación de qué *kernel* corre debajo; o copia datos en cada iteración sin advertirlo; o sin verificación de errores. |
| **Insuficiente (1.2)** | V3 no corre, no coincide con V1, o es la V2 ejecutada en Colab sin usar la GPU. |

### C4 · Medición conforme al protocolo (8 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (8.0)** | `resultados/entorno.txt` y `entorno_gpu.txt` completos (CPU con núcleos físicos y lógicos, RAM, SO, compilador y banderas; GPU con modelo, driver y **fecha**). Compilación con `-O2`. Una ejecución de calentamiento y ≥ 5 repeticiones por configuración; se reporta la mediana con mínimo y máximo. `T(1)` ≥ 1 s. `T(1)` es la V1 (mejor secuencial); si además se reporta V2 con 1 hilo, se dice. Hilos 1, 2, 4, … hasta los núcleos físicos y uno más allá, declarado. GPU con **y** sin transferencias. Los CSV tienen la cabecera del protocolo y los generan `run_all.sh` y el *notebook*, no un editor. La predicción de *speedup* se escribió **antes** de medir (bitácora) y se compara. |
| **Competente (6.4)** | Protocolo completo con una omisión menor: falta mín/máx, o la configuración "uno más allá", o la predicción previa, o un dato del entorno (p. ej. RAM o fecha de la GPU). |
| **En desarrollo (4.4)** | Menos de 5 repeticiones; promedio en lugar de mediana con picos evidentes; sin calentamiento; `T(1)` < 1 s; GPU solo con o solo sin transferencias; o CSV editado a mano (formato distinto del que produce el flujo). |
| **Insuficiente (1.6)** | Sin mediciones reproducibles; `-O0`; tamaño cambiado entre configuraciones sin declararlo; *speedup* calculado contra la V2 con un hilo sin decirlo; o sin hardware. |

### C5 · Calidad y reproducibilidad del repositorio (6 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (6.0)** | En una máquina limpia, `git clone` + `make` + `make test` + `./run_all.sh --rapido` funcionan en ≤ 10 minutos **sin editar nada**. README con problema, datos (origen, tamaño, semilla), versiones (gcc, nvcc, paquetes de Python), y tabla "figura/tabla del PDF → comando → archivo". `Makefile` raíz con `all/run/test/clean`. Sin *warnings* con `-Wall -Wextra`. Identificadores en inglés, comentarios y mensajes en español. Sin binarios ni datos > 10 MB versionados (o script de descarga con suma SHA-256). *Notebook* de la V3 ejecutado, con salidas. `.gitignore` presente. |
| **Competente (4.8)** | Reproduce en ≤ 10 minutos con una intervención trivial que el README documenta (p. ej. `pip install matplotlib`); un elemento del README incompleto; algún *warning* aislado. |
| **En desarrollo (3.3)** | Reproduce solo tras editar rutas o el `Makefile`; o falta `run_all.sh` y hay que correr comandos a mano; o el *notebook* está sin salidas; o hay binarios versionados. |
| **Insuficiente (1.2)** | No compila en la máquina del profesor dentro de los 10 minutos, o el repositorio no corresponde al código que describe el reporte. |

### C6 · Proceso: historial de *commits* de todos y bitácora (4 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (4.0)** | `git shortlog -sn` muestra *commits* de **todos** los integrantes repartidos a lo largo del semestre (no un volcado el último día), con mensajes en español, en infinitivo, que describen el cambio. `bitacora.md` con ≥ 5 entradas fechadas y completas (qué falló, cómo se detectó, causa, qué se cambió, qué se aprendió), al menos una medición descartada con su razón y al menos una predicción comparada con el resultado. La sección "qué no entendemos todavía" está escrita. |
| **Competente (3.2)** | *Commits* de todos pero concentrados en pocos días; bitácora con ≥ 3 entradas completas. |
| **En desarrollo (2.2)** | Un integrante con participación marginal en el historial sin explicación en el README; o bitácora con entradas genéricas ("no funcionaba, lo arreglamos"). |
| **Insuficiente (0.8)** | Historial de una sola persona; bitácora ausente; o evidencia de código que el equipo no puede explicar (prueba de propiedad). |

## 4. Reglas que modifican la calificación

| Situación | Efecto |
|---|---|
| Entrega después del lunes 7 de diciembre 10:30 y hasta el jueves 10 de diciembre 10:30 | Calificación máxima 80 % de los 40 puntos (regla transversal) |
| Después de 72 h sin justificante institucional | No se recibe: 0 en los 40 puntos |
| No compila ni pasa `make test` en la máquina del profesor en 10 minutos | C5 Insuficiente; C1–C4 se evalúan solo con lo que se pueda verificar en la demo en vivo de la defensa |
| Un integrante no puede explicar en la defensa una línea que el equipo entregó | C6 Insuficiente **para ese integrante**; además aplica la rúbrica de defensa (`proyecto/defensa/`) |
| Mediciones que el flujo no puede producir (CSV con tiempos imposibles, formato ajeno a `run_all.sh`, sin entorno) | C4 = 0 y se trata como integridad académica (`docs/metodo/04-evaluacion.md` §6) |
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
| C6 Proceso (por integrante si difiere) | | /4 | |
| **Total** | | **/40** | |
| Ajustes de §4 | | | |
| Retroalimentación (3 líneas: lo mejor, lo que falta, qué revisar para la defensa) | | | |
