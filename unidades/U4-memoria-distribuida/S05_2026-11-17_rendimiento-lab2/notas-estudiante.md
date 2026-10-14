> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · Notas: rendimiento en MPI

Palabras clave: latencia (*latency*) α · ancho de banda (*bandwidth*) β · razón cómputo/comunicación ·
escalabilidad fuerte (*strong scaling*) · escalabilidad débil (*weak scaling*) · sobre-suscripción
(*oversubscription*) · híbrido MPI+OpenMP · `MPI_Init_thread`.

## 1. Cuánto cuesta un mensaje

Un mensaje de m bytes tarda, en primera aproximación,

```
T_com(m) = α + m / β
```

α es la **latencia**: lo que cuesta un mensaje aunque no lleve nada (preparar, señalizar, copiar la cabecera).
β es el **ancho de banda**: a qué velocidad fluyen los bytes una vez que el mensaje arrancó. Se miden con el
*ping-pong* de S02: α ≈ tiempo de ida de un mensaje de 8 bytes; β ≈ m / (T(m) − α) con m grande (1 MiB).

Dos regímenes:
- mensajes pequeños (los halos de Jacobi 1D: 8 bytes): `m/β` es despreciable, **cuesta α** sin importar m;
- mensajes grandes (una fila de 1 MiB): α es despreciable, **cuesta m/β**.

El modelo lineal de dos parámetros falla en tamaños intermedios (cambios de protocolo interno, cachés). Sirve
para decidir, no para predecir al 5 %. Los valores dependen de la máquina: en tu reporte usas **los que mediste
tú** con la misma herramienta, y declaras el hardware.

## 2. Razón cómputo/comunicación: por qué el *speedup* depende de n

Jacobi 1D con p procesos, por iteración y por proceso interior:

```
cómputo       = (n/p) · t_c           t_c: tiempo por punto (lo imprime jacobi_seq)
comunicación  = 2 · (α + 8/β) ≈ 2α    dos halos de 8 bytes; NO depende de n
razón         = (n/p) · t_c / (2α)    crece linealmente con n
```

Tiempo con p procesos: `T_p = (n/p)·t_c + 2α`; secuencial: `T_1 = n·t_c`. De ahí:

- **Punto de equilibrio** (S = 1): `n* = 2α / (t_c · (1 − 1/p))`.
- **n para eficiencia E**: `n_E = E·p·2α / (t_c · (1 − E))`.

Con α = 0.5 µs, t_c = 0.8 ns y p = 4: n* ≈ 1 µs / 0.6 ns ≈ **1 700 puntos**; n_E(50 %) ≈ 4·1 µs/0.8 ns =
**5 000 puntos**. Por debajo de n*, cuatro procesos tardan **más** que uno. Eso no es un error del programa:
es la comunicación dominando al cómputo (idea errónea 21: "la comunicación es gratis"; e idea 1: "más procesos
siempre es más rápido").

## 3. Escalabilidad fuerte y débil (no son sinónimos: idea errónea 6)

| | Qué se fija | Qué crece | Qué se reporta | Pregunta que responde | Ley |
|---|---|---|---|---|---|
| **Fuerte** | n | p | *speedup* `S = T_seq(n)/T(p,n)`, eficiencia `S/p` | ¿Cuánto más rápido resuelvo **el mismo** problema? | Amdahl |
| **Débil** | n/p | p y n | eficiencia débil `E_w = T_seq(n/p)/T(p,n)`; *speedup* escalado `p·E_w` | ¿Qué tan grande puedo resolver **en el mismo tiempo**? | Gustafson |

En Jacobi 1D la escalabilidad débil es casi perfecta en el modelo: el cómputo por proceso no cambia y la
comunicación tampoco. Lo que la rompe en la práctica es el ancho de banda de memoria compartido entre los
procesos del mismo nodo, y cualquier desbalance.

Las dos tablas usan el CSV del protocolo (`config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia`), con 5
repeticiones tras calentamiento, mediana, `-O2`, T(1) = el mejor secuencial, y el hardware declarado.

## 4. Sobre-suscripción (idea errónea 20)

Más procesos que núcleos físicos. Un proceso MPI que espera un mensaje hace **sondeo activo**: consume su
núcleo mientras espera. Si dos procesos comparten núcleo, el que espera le roba tiempo al que debería producir
el dato. Resultado: tiempos más altos y mucho más variables. Sirve para **probar correctitud** con más rangos de
los que tienes; **no sirve para medir**. Si lo reportas, va aparte y etiquetado (`mpi_oversub` en nuestro CSV).
El mismo efecto aparece, con p = núcleos, si hay cualquier otro programa activo en la máquina: por eso el
protocolo pide cerrar lo demás, y `escalado.sh` guarda la carga del sistema en `entorno.txt`.

## 5. Híbrido MPI + OpenMP (panorama)

Dos niveles: MPI entre procesos (uno por nodo o por *socket*), OpenMP entre hilos dentro de cada proceso. Ahorra
mensajes y memoria duplicada (menos halos, menos copias) y usa la memoria compartida donde existe. Se compila
con `mpicc -fopenmp` y se arranca con `OMP_NUM_THREADS=h mpirun -np p`, cuidando `p × h ≤ núcleos`.

`MPI_Init_thread(&argc, &argv, pedido, &provisto)` sustituye a `MPI_Init` y declara cómo van a convivir los
hilos con MPI:

| Nivel | Quién llama a MPI |
|---|---|
| `MPI_THREAD_SINGLE` | Un solo hilo en el proceso |
| `MPI_THREAD_FUNNELED` | Varios hilos, pero **solo el principal** llama a MPI (nuestro patrón) |
| `MPI_THREAD_SERIALIZED` | Cualquier hilo, pero nunca dos a la vez |
| `MPI_THREAD_MULTIPLE` | Cualquier hilo, concurrentemente (más caro) |

Siempre se revisa `provisto`: la biblioteca puede dar menos de lo pedido.

## 6. Ejemplo resumido (detalle y pausas en `ejemplo-resuelto.md`)

<!-- SALIDA-AUTORIA -->

## 7. Errores frecuentes

| Error | Corrección |
|---|---|
| "Son solo 8 bytes, la comunicación no cuenta" | 8 bytes cuestan α completa (~medio microsegundo); 1 000 puntos de cómputo cuestan menos que eso. |
| Calcular el *speedup* contra `mpirun -np 1` | T(1) es el **mejor secuencial**. Si usas la versión MPI con un proceso, lo declaras y reportas ambas. |
| Llamar "fuerte" a una tabla donde n crece con p | Eso es escalabilidad débil; se reporta eficiencia débil, no *speedup*. |
| Meter p = 8 (en 4 núcleos) en la curva de *speedup* | Es sobre-suscripción: aparte y etiquetado. |
| "Con p = 4 y n = 1 000 tarda más: el programa está mal" | Es lo que predice el modelo: n < n*. Revisa la razón cómputo/comunicación. |
| Medir con otros programas abiertos y una sola repetición | 5 repeticiones + calentamiento + mediana; cierra lo demás; anota la carga. |
| Híbrido sin `OMP_NUM_THREADS` | Cada proceso crea tantos hilos como núcleos: p × núcleos unidades de ejecución. |

## 8. Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard* (mpi-forum.org): capítulo "MPI and Threads"
  (`MPI_Init_thread`), `MPI_Wtime`, `MPI_Waitall`.
- Documentación de Open MPI (docs.open-mpi.org): `mpirun` (`--oversubscribe`, `--map-by`, `--bind-to`);
  parámetro MCA `mpi_yield_when_idle`.
- Pacheco y Malensek, *An Introduction to Parallel Programming*, 2.ª ed.: cap. 2 (Amdahl, Gustafson,
  escalabilidad) y cap. 3 (MPI: rendimiento, *speedup* y eficiencia de programas MPI).
