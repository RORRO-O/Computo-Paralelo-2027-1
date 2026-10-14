> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Práctica guiada S05 · ¿Cuándo conviene repartir? Escalabilidad y modelo de costo en MPI (PRIMM)

Trabajas en pareja (conductor/navegante, cambio a los 15 min) o con tu equipo de la Práctica 5. Lo que hagas
aquí es la plantilla de la **Parte D** de la P5: el mismo script, el mismo CSV, la misma gráfica.

## Qué hay en esta carpeta

| Archivo | Qué es |
|---|---|
| `jacobi_seq.c` | Jacobi 1D secuencial. Es el T(1) del protocolo y la referencia de correctitud. Imprime t_c ("ns por punto-iteración"). |
| `jacobi_mpi.c` | Jacobi 1D con halos (`Isend`/`Irecv`/`Waitall`, S04) con un número **fijo** de iteraciones: no lleva la prueba de convergencia con `Allreduce` de S04, para que la única comunicación por iteración sean los dos halos. Mide el tiempo total y, aparte, cuánto de cada iteración es cómputo y cuánto comunicación. |
| `pingpong.c` | Mide α (latencia) y β (ancho de banda) entre dos procesos y los ajusta a `T_com = α + m/β`. |
| `hybrid_min.c` | Mínimo MPI + OpenMP: cada proceso suma su bloque con hilos; `MPI_Init_thread`. |
| `escalado.sh` | Corre `jacobi_seq` y `jacobi_mpi` con p = 1, 2, 4 (y 8 sobre-suscrito, etiquetado); escribe `resultados/fuerte.csv`, `debil.csv`, `entorno.txt` y llama a `graficar.py`. |
| `graficar.py` | `fuerte.png` (*speedup* vs p con la línea ideal) y `debil.png` (eficiencia débil vs p). |
| `modelo.py` | El modelo de costo: predice *speedup* y calcula n* (punto de equilibrio) y n_E (eficiencia objetivo). |
| `tests/run_tests.sh` | `make test`: MPI contra secuencial con tolerancia, híbrido exacto, formato del CSV. |
| `resultados-ejemplo/` | Una corrida completa del entorno de autoría (VM de 4 núcleos), para comparar. |

## Antes de empezar (3 min)

```bash
make            # compila los cuatro programas sin warnings
make test       # ~30 s; debe terminar en "12 PASS, 0 FAIL"
nproc; lscpu | grep -E "Model name|Core|Thread"   # anota núcleos FÍSICOS: va en tu reporte
```

Si trabajas como `root` (contenedor), `tests/run_tests.sh` y `escalado.sh` exportan solos
`OMPI_ALLOW_RUN_AS_ROOT`. `MPIRUN_FLAGS` vale `--oversubscribe` por defecto para poder pedir p = 8 en 4
núcleos; eso **no** convierte la medición en válida: la etiqueta `mpi_oversub` existe para eso.

Regla del protocolo que hoy importa más: **cierra lo demás**. Con p = número de núcleos, un navegador con
video, otra corrida de un compañero en la misma máquina o un compilador en segundo plano le quita un núcleo a
un proceso MPI que está haciendo sondeo activo, y el *speedup* se desploma. `escalado.sh` imprime un aviso si
la carga del sistema es alta y la guarda en `entorno.txt`.

## Fase 1 · Predecir (por escrito, 3 min, antes de correr nada)

Si hiciste el ejercicio 3 de la tarea de S04, ya tienes la predicción de P2 (n = 10⁶, p = 4): cópiala tal cual
(no la "mejores") y llena las demás filas.

Datos: `jacobi_seq` tarda ≈ 0.8 ns por punto por iteración en una laptop reciente; un mensaje de 8 bytes
cuesta ≈ α (medio microsegundo, más o menos); cada proceso interior intercambia 2 halos por iteración.

| Pregunta | Tu predicción | Por qué |
|---|---|---|
| P1. n = 1 000 000: *speedup* con p = 2 | | |
| P2. n = 1 000 000: *speedup* con p = 4 | | |
| P3. n = 1 000: *speedup* con p = 2 | | |
| P4. n = 1 000: *speedup* con p = 4 | | |
| P5. ¿Quién tarda más: `jacobi_seq` o `jacobi_mpi` con p = 1? ¿Por cuánto? | | |
| P6. p = 8 en 4 núcleos, n = 1 000 000: ¿más o menos tiempo que p = 4? | | |
| P7. Escalabilidad débil con n/p = 250 000: ¿la eficiencia débil con p = 4 será mayor o menor que la eficiencia fuerte con p = 4? | | |

Pre-mortem (una línea): "La configuración que creo que va a salir peor es ______ porque ______".

## Fase 2 · Ejecutar (5 min)

```bash
make run                      # fuerte: N=1000000, ITERS=1200 ; débil: NLOCAL=250000 ; p = 1 2 4 + 8 oversub
cat resultados/fuerte.csv resultados/debil.csv resultados/entorno.txt
# abre resultados/fuerte.png y resultados/debil.png
N=1000 ITERS=100000 NLOCAL=1000 OVERSUB="" PLOT=0 OUT=resultados-chico ./escalado.sh    # el caso pequeño
```

Formato del CSV (el del protocolo; `hilos` son procesos en MPI):
`config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia`. En `fuerte.csv`, `speedup = T_seq/T(p)` y
`eficiencia = speedup/p`. En `debil.csv`, `eficiencia` es la **eficiencia débil** `T_seq(n_local)/T(p, p·n_local)` y
`speedup` es el *speedup* escalado `p × eficiencia` (Gustafson). La fila `seq` es `jacobi_seq`; `mpi,1` es
`jacobi_mpi` con un proceso (sin vecinos, pero con `Barrier`, `Waitall` y relojes).

<!-- SALIDA-AUTORIA -->

Marca en tu tabla de predicción qué acertaste y qué no. Lo que no acertaste es lo que vas a investigar.

## Fase 3 · Investigar (7 min)

Corre estas dos líneas y llena la tabla de rastreo con lo que imprime `jacobi_mpi` ("por iteración: cómputo …,
comunicación …, razón …"):

```bash
make run-fuerte NP=4 N=4000 ITERS=20000
make run-fuerte NP=4 N=1000000 ITERS=500
```

| n | n_local | cómputo por iteración | comunicación por iteración | razón cómputo/comunicación | *speedup* (T_seq/T₄) |
|---|---|---|---|---|---|
| 4 000 | | | | | |
| 1 000 000 | | | | | |

1. ¿Cuántas veces creció n? ¿Cuántas veces creció el cómputo por iteración? ¿Y la comunicación? Escribe la
   fórmula de la razón **del modelo** en función de n, p, t_c y α (2 mensajes de 8 bytes: no depende de n). Ahora
   mira lo que imprimió el programa: la "comunicación" con n = 10⁶ es decenas de microsegundos, no ~1 µs. ¿Qué
   mide en realidad `t1 − t0` en `jacobi_run`? (Pista: `MPI_Waitall` no regresa hasta que el vecino **envió**, y el
   vecino envía cuando terminó **su** cómputo de la iteración anterior.) ¿Qué pasa con ese tiempo si un proceso
   tarda un 10 % más que los demás en calcular?
2. En `jacobi_mpi.c`, localiza el `MPI_Barrier` y el `MPI_Reduce(..., MPI_MAX, ...)` del tiempo. ¿Por qué el tiempo
   de la corrida es el del proceso **más lento** y no el promedio? ¿Qué pasaría con el *speedup* si un proceso
   recibiera 2× más puntos que los demás?
3. Fila `mpi,1` contra `seq` en `fuerte.csv`: ¿cuál es más lenta y por cuánto? Enumera qué hace `jacobi_mpi` en
   cada iteración que `jacobi_seq` no hace (aunque los vecinos sean `MPI_PROC_NULL`). ¿Es ese costo constante o
   proporcional a n?
4. Fila `mpi_oversub,8`: compara `rep1…rep5` con los de `mpi,4`. ¿Cuál varía más? ¿Qué hace un proceso MPI mientras
   espera en `Waitall`, y qué le pasa al proceso que debería enviarle el halo si comparten núcleo?
5. `debil.csv`: con p = 4 el problema es 4× más grande que con p = 1. ¿Qué pregunta responde la eficiencia débil
   que no responde el *speedup* fuerte? ¿Cuál de las dos le interesa a quien quiere simular una malla 4× más fina
   en el mismo tiempo?
6. `make run-pingpong`: compara las columnas `T_ida(us)` y `modelo(us)`. ¿En qué tamaños el modelo de dos
   parámetros se equivoca más? ¿Importa eso para los halos de 8 bytes? ¿Importaría para halos 2D de 1 000 doubles?
7. `make run-hibrido` y luego `OMP_NUM_THREADS=4 mpirun --oversubscribe -np 2 ./hybrid_min`. ¿Cuántas unidades de
   ejecución pediste en cada caso? ¿Cuántos núcleos tienes? ¿Qué nivel pidió `MPI_Init_thread` y qué significa?

## Fase 4 · Modificar (objetivos verificables)

**M1 · Encuentra el n de equilibrio midiendo.** Busca el n a partir del cual p = 4 le gana a la secuencial. Ajusta
`ITERS` para que la secuencial tarde ≥ 0.1 s en cada tamaño (ITERS ≈ 2·10⁸ / n funciona):

```bash
for n in 1000 2000 4000 8000 16000; do
  echo "== n=$n"; make -s run-fuerte NP=4 N=$n ITERS=$((200000000 / n)) | grep -o "mediana=[0-9.]* s"
done
```

Criterio de "listo": una tabla n → *speedup* con el cruce por 1 localizado entre dos n consecutivos (en la VM
de autoría quedó entre 2 000 y 4 000; ver `ejemplo-resuelto.md`, Paso 5). Anota también la razón
cómputo/comunicación que imprime el programa en el cruce: según el modelo, en S = 1 vale exactamente `1/(p − 1)`
(0.33 con p = 4); el programa imprime algo menor (0.1–0.6) porque su "comunicación" incluye la espera en
`Waitall`. Compruébalo con el modelo de la Fase 5.

**M2 · Adapta `escalado.sh` a tu programa de la Práctica 5.** Copia el script a tu repositorio y cambia solo:
los nombres de los binarios en `run_seq`/`run_mpi`, los argumentos (tu programa debe imprimir una línea
`RESULT,...` con los mismos 13 campos, o adapta `reps_and_median`/`median_of`) y los tamaños por defecto para que
tu T(1) ≥ 1 s. Verificable: tu `fuerte.csv` y `debil.csv` tienen el encabezado del protocolo, 5 repeticiones por
fila y la fila p = 8 (si la incluyes) etiquetada `mpi_oversub`.

**M3 · Cede el núcleo al esperar (opcional).** Repite la fila p = 8 con
`MPIRUN_FLAGS="--oversubscribe --mca mpi_yield_when_idle 1" make run-fuerte NP=8`. Verificable: la mediana baja
respecto a la fila `mpi_oversub` original y lo explicas en dos líneas (los procesos que esperan dejan de consumir
el núcleo). Sigue siendo una medición sobre-suscrita: se reporta aparte.

## Fase 5 · Crear: estima con el modelo el n a partir del cual conviene usar 4 procesos

Con **tus** números: α y β de `make run-pingpong`, t_c de la línea "ns por punto-iteración" de `jacobi_seq`
(usa el n grande; t_c cambia cuando el bloque cabe en caché):

```bash
python3 modelo.py --alpha-us <α> --beta-gbps <β> --tc-ns <t_c> --p 4 --tabla
```

El modelo (una iteración): `T_1 = n·t_c`; `T_p = (n/p)·t_c + 2(α + 8/β)`. De ahí:
`n* = T_halo / (t_c·(1 − 1/p))` (S = 1) y `n_E = E·p·T_halo / (t_c·(1 − E))` (eficiencia E).

Criterio de "listo" (va en tu reporte de P5 como ejemplo de interpretación):

1. n* y n_E(50 %) calculados con tus parámetros, con el cálculo escrito.
2. Una tabla con n ∈ {n*/2, n*, 2n*, n_E} y, para cada uno, *speedup* predicho y *speedup* medido con p = 4
   (`make run-fuerte NP=4 N=<n> ITERS=<2·10⁸/n>`).
3. Tres líneas sobre por qué difieren: qué costo no está en el modelo (espera en `Waitall` cuando un proceso
   llega tarde, *jitter* del sistema, t_c distinto cuando n/p cabe en caché, los dos mensajes salen en paralelo y
   no en serie).

Extensión: repite para p = 2 y explica por qué n* cambia (el factor 1 − 1/p).

## Problemas comunes de entorno

| Mensaje / síntoma | Qué significa |
|---|---|
| `There are not enough slots available in the system` | Pides más procesos que *slots*; agrega `--oversubscribe` (y etiqueta la medición). |
| `mpirun has detected an attempt to run as root` | Exporta `OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1` (el script lo hace si `id -u` es 0). |
| Las 5 repeticiones de p = 4 difieren 3× y el *speedup* es ridículo | Hay otro programa usando CPU. Mira `entorno.txt` (`carga_promedio…`), cierra lo demás y repite. |
| `hybrid_min` tarda más con más hilos | `OMP_NUM_THREADS × np` supera los núcleos: sobre-suscripción. |
| `graficar.py` falla con `ModuleNotFoundError` | Falta matplotlib: `PLOT=0 ./escalado.sh` y grafica con `herramientas/graficar_speedup.py` o a mano. |

## Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, versión 4.x (mpi-forum.org): §"MPI and Threads"
  (`MPI_Init_thread` y los cuatro niveles), `MPI_Wtime`, `MPI_Waitall`.
- Documentación de Open MPI (docs.open-mpi.org): página de `mpirun` (`--oversubscribe`, `--bind-to`,
  `--map-by`) y el parámetro MCA `mpi_yield_when_idle`.
- Pacheco y Malensek, *An Introduction to Parallel Programming*, 2.ª ed., cap. 3 (MPI): secciones de
  rendimiento, *speedup*, eficiencia y escalabilidad; cap. 2 para Amdahl y Gustafson.
