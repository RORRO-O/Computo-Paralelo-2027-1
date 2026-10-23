> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Plan de paralelización V1 → V2 (plantilla por equipo)

Copia este archivo al repositorio de tu equipo (por ejemplo `proyecto/plan-V2.md`) y llénalo. No es un
documento "para inspirarse": cada tabla se entrega llena, con números medidos.

- **Secciones 0–2** se llenan en la sesión del martes 27 de octubre y se terminan como tarea; la sección 1 es
  exactamente el perfilado que pide `proyecto/hitos/H1-avance-1.md` (jueves 29 de octubre, en clase, 12 % del
  2.º parcial). No lo hagas dos veces: pega aquí la misma tabla que entregas en H1.
- **Secciones 3–5** son el plan de la V2 y se revisan en el taller del jueves 19 de noviembre; su resultado se
  evalúa en `proyecto/hitos/H2-avance-2.md` (lunes 23 de noviembre, en clase). La rúbrica vive allá; aquí solo
  se planea.

Regla de toda la plantilla: **las fracciones se miden en tiempo, nunca en líneas de código**, y todo tiempo es
la **mediana de 5 repeticiones con calentamiento, compilado con `-O2`** (`herramientas/protocolo-medicion.md`).

## 0. Identificación

| Campo | Valor |
|---|---|
| Proyecto (título corto) | |
| Repositorio (URL) | |
| *Commit* de la V1 que se perfiló (hash corto) | |
| Tamaño del problema que se usará para medir (debe dar T(1) ≥ 1 s) | |
| CPU (modelo, núcleos físicos / lógicos) | |
| RAM · sistema operativo · versión de gcc | |
| Banderas de compilación | `gcc -std=c11 -O2 -Wall -Wextra -fopenmp` |

## 1. Perfil por secciones de la V1

Instrumenta la V1 con un `omp_get_wtime()` entre sección y sección (como en `fases.c`). Una sección es una
fase con sentido para tu problema (leer datos, construir estructuras, ciclo principal, escribir resultados…).
Si una sección tarda menos del 1 % del total, fusiónala con la vecina.

| # | Sección (archivo:líneas) | Qué hace | Mediana (s) | Mín (s) | Máx (s) | Fracción del total | ¿Paralelizable? (sí / parcial / no) | Por qué |
|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | |
| 2 | | | | | | | | |
| 3 | | | | | | | | |
| 4 | | | | | | | | |
| | **Total** | | | | | 1.000 | | |

Con la tabla llena:

- Fracción paralelizable en tiempo: **f = Σ fracciones de las secciones marcadas "sí"** (las "parcial" se
  cuentan por la parte que sí se paraleliza; justifica el número): f = ______
- Cota de Amdahl (ley de Amdahl, Unidad I): S_max(p) = 1 / ((1 − f) + f / p)
  - S_max(2) = ______   S_max(4) = ______   S_max(∞) = 1 / (1 − f) = ______
- La primera sección que atacaremos es la **#____** porque tiene la mayor fracción paralelizable (no porque
  tenga más líneas ni porque "se vea pesada").
- Si S_max(4) < 2, escribe qué sección secuencial habría que repensar (algoritmo, formato de entrada,
  salida en bloque) antes de tocar OpenMP: __________________________________________

## 2. Dependencias de cada ciclo caliente

Por cada ciclo de la sección elegida (y de la siguiente, si hay tiempo), lista qué lee y qué escribe **cada
iteración**. Clasifica con esta tabla:

| Tipo | Cómo se reconoce | Cómo se resuelve en OpenMP |
|---|---|---|
| Independiente | Cada iteración escribe solo "su" elemento (`out[i] = …`) y lee datos que nadie escribe en el ciclo | `parallel for` (y `schedule` según el balance) |
| Reducción | Todas las iteraciones escriben la **misma** variable con `+`, `*`, `max`, `min`… (`acum += …`) | `reduction(op:var)` |
| Carrera potencial sobre estructura compartida | Varias iteraciones pueden escribir la misma celda de un arreglo o estructura (`hist[bin]++`, insertar en lista, contador global) | Copias privadas y combinar al final; `atomic` si la operación es simple; `critical` solo fuera del ciclo interno |
| Dependencia verdadera entre iteraciones | La iteración `i` necesita el resultado de la `i−1` (`a[i] = a[i−1] + …`, recurrencias, *scan*) | Cambiar el algoritmo (dos arreglos en un *stencil*, *scan* por bloques, S11) o no paralelizar ese ciclo |
| Entrada/salida | Lee archivo, imprime, escribe a disco | Se queda secuencial; se saca del ciclo o se hace en bloque |

| Ciclo (archivo:línea) | Variables que **lee** | Variables que **escribe** | Tipo (tabla de arriba) | Cómo lo resolveremos | ¿Verificado con TSan? |
|---|---|---|---|---|---|
| | | | | | |
| | | | | | |
| | | | | | |

## 3. Estrategia

Marca y justifica en una o dos líneas cada decisión. "Porque siempre es mejor" no es justificación.

- [ ] **Paralelismo de datos**: `parallel for` sobre el ciclo ______ (iteraciones independientes o con reducción).
- [ ] **Paralelismo de tareas**: `task` / `taskloop` porque el trabajo es recursivo o irregular: ______.
- [ ] ***Pipeline* / secciones**: fases distintas sobre datos distintos a la vez: ______.
- **`schedule`**: ______ (con `chunk` = ____). Las iteraciones son uniformes / desiguales porque ______; lo
  comprobaremos midiendo `static` contra `dynamic` (S08), no lo supondremos.
- **Ciclos anidados**: paralelizamos el externo / usamos `collapse(2)` porque ______.
- **Relación con el método de Foster (Unidad II)**:
  - Partición: la unidad de trabajo es ______ (una fila, una partícula, un bloque de iteraciones…).
  - Comunicación: las iteraciones comparten (leen) ______ y combinan (escriben) ______.
  - Aglomeración: agrupamos ______ iteraciones por hilo mediante ______ (chunk, bloques). Aglomerar **no** es
    juntar todo en un hilo: es reducir sobrecarga y sincronización sin perder paralelismo útil.
  - Mapeo: ______ hilos en ______ núcleos físicos; afinidad ______ (si aplica).
- **Qué NO vamos a paralelizar y por qué**: ______.

## 4. Plan de medición (se ejecuta para H2)

| Elemento | Nuestro plan |
|---|---|
| Tamaños del problema (≥ 2; el principal con T(1) ≥ 1 s) | |
| Hilos | 1, 2, 4 (núcleos físicos) y ____ declarado como sobre-suscripción/hyper-threading |
| Repeticiones | 1 de calentamiento + 5; se reporta mediana, mín y máx |
| Qué se cronometra | Región paralelizada **y** programa completo (ambos van en la tabla) |
| T(1) | La **V1** (mejor secuencial), no la V2 con un hilo; si reportamos la V2 con 1 hilo, lo decimos |
| Correctitud antes de medir | `make test`: V2 contra V1 con tolerancia ______ en flotantes, exacto en enteros |
| Carreras | Compilado una vez con `-fsanitize=thread -g -O1` (nunca se mide con TSan activo) |
| Tabla CSV (`resultados/`) | `config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia` |
| Gráfica | *Speedup* vs. hilos con la línea ideal S = p (`herramientas/graficar_speedup.py` o equivalente) |
| **Predicción escrita (antes de medir)** | Con 4 hilos esperamos S(4) ≈ ____ para la región y ≈ ____ para el programa completo, porque f = ____ y ______ |

## 5. Riesgos y pre-mortem

Imagina que es lunes 23 de noviembre, presentan la V2 y el *speedup* del programa completo es 1.1. Escriban
**tres** causas probables, la señal que las delataría antes, y qué harán esta semana para descartarlas.

| Causa probable | Señal temprana (qué medir o revisar) | Mitigación | Responsable |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

Riesgos que conviene considerar (no son los únicos): la sección secuencial pesa más de lo que creíamos;
el ciclo caliente tiene una dependencia verdadera; la memoria (no el cómputo) limita; falso compartido en
acumuladores por hilo; `critical` en el ciclo interno; el tamaño del problema es tan chico que medimos
sobrecarga; la V2 da resultados distintos a la V1 y nadie lo nota.

## 6. Reparto y bitácora

| Integrante (número de lista) | Responsable de | Fecha compromiso |
|---|---|---|
| | | |
| | | |
| | | |

La bitácora de errores (qué falló, por qué, cómo se detectó) se lleva desde hoy en el repositorio del equipo;
forma parte del reporte final (`docs/metodo/01-marco-pedagogico.md`, principio P9).

## Lista de cotejo antes de entregar

- [ ] Cada tiempo de la sección 1 es mediana de 5 repeticiones con calentamiento y `-O2`.
- [ ] f se calculó con tiempos; S_max(2) y S_max(4) están escritos.
- [ ] Cada ciclo de la sección 2 tiene variables leídas, escritas y tipo de dependencia.
- [ ] La estrategia nombra ciclo, cláusulas y `schedule`, y dice qué no se paraleliza.
- [ ] El plan de medición tiene predicción escrita **antes** de medir.
- [ ] Hay tres causas en el pre-mortem con su mitigación.
- [ ] Ningún nombre ni correo personal aparece en el archivo (solo números de lista).
