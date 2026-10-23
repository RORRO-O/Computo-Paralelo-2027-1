> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · Notas: memoria distribuida y el modelo SPMD

Lectura de 15 minutos. Si faltaste, léela, estudia `ejemplo-resuelto.md` y haz `practica-guiada/` completa.

## 1. Dos formas de organizar la memoria

```
MEMORIA COMPARTIDA (OpenMP, Unidad III)          MEMORIA DISTRIBUIDA (MPI, Unidad IV)

 hilo 0   hilo 1   hilo 2   hilo 3            proceso 0   proceso 1   proceso 2   proceso 3
   |        |        |        |               +-------+   +-------+   +-------+   +-------+
   +--------+--------+--------+               | total |   | total |   | total |   | total |
            |                                 | a[]   |   | a[]   |   | a[]   |   | a[]   |
   +-------------------+                      +---+---+   +---+---+   +---+---+   +---+---+
   | una sola memoria  |                          |           |           |           |
   | total, a[], ...   |                          +-----------+-----+-----+-----------+
   +-------------------+                                            |
 todos leen y escriben las mismas               red (o canal local): los datos viajan en MENSAJES
 variables; el riesgo es la carrera             explícitos; nadie "ve" la memoria de otro
```

En memoria distribuida (*distributed memory*) **no existe** una variable que dos procesos vean a la vez.
Todo intercambio de datos es un mensaje que un proceso envía y otro recibe. Esto vale aunque los procesos
corran en la misma laptop: `mpirun` lanza procesos distintos, cada uno con su espacio de direcciones
(compruébalo con el `pid` que imprime `hello_rank`).

## 2. Procesos y hilos

| | Hilo (OpenMP) | Proceso (MPI) |
|---|---|---|
| Memoria | Compartida con los demás hilos del mismo proceso | Propia; ningún otro proceso la ve |
| Cómo nacen | `#pragma omp parallel` dentro del programa (*fork-join*) | `mpirun -np p` lanza `p` copias del ejecutable |
| Identidad | `omp_get_thread_num()` | `MPI_Comm_rank()` → *rango* (*rank*) |
| Comunicación | Leer y escribir variables compartidas (y sincronizar) | Mensajes: `MPI_Send`/`MPI_Recv` (S02), colectivas (S03) |
| Dónde corren | Una máquina | Una o muchas máquinas (clúster) |
| Error típico | Condición de carrera | Suponer memoria compartida; interbloqueo (S02) |

## 3. SPMD: un programa, muchos procesos

MPI usa el estilo SPMD (*single program, multiple data*): se compila **un** ejecutable y `mpirun` lo lanza
`p` veces. Las copias son idénticas hasta que preguntan su rango; a partir de ahí el código se ramifica:
`if (rank == 0) {...}`. Así, el mismo archivo contiene lo que hace "el que combina" y lo que hacen los demás.
Que el rango 0 combine es una **convención**, no una regla de MPI: cualquier rango puede hacerlo.

## 4. Las cuatro llamadas de hoy

| Llamada | Qué hace | Cuándo |
|---|---|---|
| `MPI_Init(&argc, &argv)` | Arranca el entorno MPI | Primera llamada MPI del programa |
| `MPI_Comm_size(MPI_COMM_WORLD, &size)` | ¿Cuántos procesos hay? (`p`) | Después de `Init` |
| `MPI_Comm_rank(MPI_COMM_WORLD, &rank)` | ¿Cuál soy yo? Entero en `0..size-1` | Después de `Init` |
| `MPI_Finalize()` | Cierra el entorno MPI | Última llamada MPI; después solo `return` |

`MPI_COMM_WORLD` es el **comunicador** (*communicator*) que contiene a todos los procesos lanzados por
`mpirun`. Un comunicador es un grupo de procesos con un contexto de comunicación; en S06 verás cómo crear
otros. En Open MPI (y en la práctica en todas las implementaciones) todos los procesos reciben los mismos
`argc`/`argv`: si pasas `n` por línea de comandos, todos lo leen. El estándar no lo garantiza; por eso el código
portable hace que el rango 0 lea los parámetros y los reparta con `MPI_Bcast` (S03).

```c
#include <mpi.h>
#include <stdio.h>
int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    printf("Hola desde el proceso %d de %d\n", rank, size);   /* la ejecutan los 'size' procesos */
    MPI_Finalize();
    return 0;
}
```

## 5. Compilar y ejecutar

```bash
mpicc -std=c11 -O2 -Wall -Wextra -o hello_rank hello_rank.c   # mpicc = gcc + rutas y bibliotecas de MPI
mpirun -np 4 ./hello_rank                                      # 4 procesos
mpirun --oversubscribe -np 6 ./hello_rank                      # más procesos que núcleos (solo para probar)
```

`mpirun -np p` crea los `p` procesos y les reenvía la salida estándar. Si pides más procesos que núcleos,
Open MPI se niega salvo con `--oversubscribe`; se permite para probar la lógica, **no** para medir tiempos
(idea errónea 20: la sobre-suscripción cambia las mediciones).

## 6. La salida se intercala y no tiene orden

Dos corridas reales de `mpirun -np 4 ./hello_rank` en la misma máquina, una tras otra:

```
Hola desde el proceso 0 de 4 (pid 23276, nodo vm)     Hola desde el proceso 3 de 4 (pid 23295, nodo vm)
Hola desde el proceso 1 de 4 (pid 23277, nodo vm)     [rango 3] counter = 4
[rango 1] counter = 2                                  [rango 3] soy el ultimo rango; ...
Hola desde el proceso 2 de 4 (pid 23278, nodo vm)     Hola desde el proceso 0 de 4 (pid 23292, nodo vm)
[rango 2] counter = 3                                  [rango 0] counter = 1
Hola desde el proceso 3 de 4 (pid 23282, nodo vm)     [rango 0] soy el rango 0; ...
[rango 0] counter = 1                                  Hola desde el proceso 1 de 4 (pid 23293, nodo vm)
[rango 0] soy el rango 0; ...                          [rango 1] counter = 2
[rango 3] counter = 4                                  Hola desde el proceso 2 de 4 (pid 23294, nodo vm)
[rango 3] soy el ultimo rango; ...                     [rango 2] counter = 3
```

Mismo programa, mismo `-np`, distinto orden. Cada proceso escribe cuando el sistema operativo lo
programa; `mpirun` reenvía lo que llega. Reglas: (1) nunca dependas del orden de impresión entre rangos;
(2) una `MPI_Barrier` antes del `printf` **no** ordena nada (después de la barrera vuelven a competir);
(3) si necesitas salida ordenada, que imprima un solo rango con datos que le enviaron los demás (S02).

## 7. Medir tiempo: `MPI_Wtime` y `MPI_Barrier`

```c
MPI_Barrier(MPI_COMM_WORLD);        /* alinea el arranque de todos */
double t0 = MPI_Wtime();            /* segundos (double) desde un instante arbitrario */
/* ... trabajo + combinación en el rango 0 ... */
double t1 = MPI_Wtime();            /* en el rango 0, después de recibir todo */
if (rank == 0) printf("tiempo = %.6f s\n", t1 - t0);
```

`MPI_Wtime` es reloj de pared por proceso; se reportan diferencias. El protocolo del curso aplica igual:
`-O2`, calentamiento, 5 repeticiones, mediana, y `T(1)` es el **programa secuencial** (`referencia_secuencial`),
no el MPI con `-np 1`. Con `n = 10` mides sobrecarga de arranque, no trabajo; usa tamaños donde la secuencial
tarde ≥ 1 s.

## 8. Repartir índices sin un arreglo compartido

Como nadie ve el arreglo completo, cada proceso calcula **qué índices le tocan** y genera o lee solo esos.
Sea `q = n / p` y `r = n % p`.

| Reparto | Índices del rango `k` | Cuándo conviene |
|---|---|---|
| **Bloques con residuo** | `start = k·q + min(k, r)`, `count = q + (k < r ? 1 : 0)`, índices `start .. start+count-1` | Datos contiguos: buena localidad de caché; es lo usual con arreglos |
| **Cíclico** | `k, k+p, k+2p, …` mientras `< n` | Cuando el costo por elemento crece con `i` (triángulos, cargas desiguales) |

Con `n = 10`, `p = 4` (salida real de `suma_distribuida`):

| Rango | Bloques (`q=2`, `r=2`) | Cíclico |
|---|---|---|
| 0 | {0, 1, 2} | {0, 4, 8} |
| 1 | {3, 4, 5} | {1, 5, 9} |
| 2 | {6, 7} | {2, 6} |
| 3 | {8, 9} | {3, 7} |

Si usas `n / p` para todos (sin residuo), los últimos `r` índices no los suma nadie: `suma_distribuida_buggy`
da 483.600 en lugar de 548.500 con `-np 4`, y "sale bien" con `-np 5`. Que salga bien una vez no es evidencia.

## 9. Del método de Foster a los procesos

| Etapa (Unidad II) | En la suma distribuida |
|---|---|
| Partición | `n` tareas: "sumar el elemento `i`" |
| Comunicación | Cada suma parcial debe llegar a quien combina: `p − 1` mensajes |
| Aglomeración | Agrupar las `n` tareas en `p` bloques contiguos de ≈ `n/p` (reduce mensajes de `n` a `p − 1`) |
| Mapeo | Bloque `k` → proceso de rango `k` |

Aglomerar **no** es juntar todo en un proceso (idea 28): es bajar la comunicación sin perder el paralelismo
que los `p` procesos pueden usar. En MPI, aglomeración y mapeo se escriben a mano: la fórmula del reparto.

## 10. Ejemplo resuelto en una pantalla (detalle en `ejemplo-resuelto.md`)

```c
block_range(n, rank, size, &start, &end);            /* aglomeración + mapeo */
for (long long i = start; i < end; i++) local_sum += element(i);
double total = local_sum;                             /* cada rango tiene SU total */
if (rank != 0)
    MPI_Send(&local_sum, 1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);        /* 1 double al rango 0 */
else
    for (int src = 1; src < size; src++) {
        double partial;
        MPI_Recv(&partial, 1, MPI_DOUBLE, src, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        total += partial;
    }
if (rank == 0) printf("suma total = %.3f\n", total);
```

Salida real de `mpirun -np 4 ./suma_distribuida 10 bloques`: parciales 179.600 + 206.700 + 97.300 + 64.900 y
`suma total = 548.500`, igual que `./referencia_secuencial 10`. En los rangos 1, 2 y 3, `total` vale solo su
parcial: nadie les mandó nada.

## 11. Errores frecuentes

| Síntoma | Causa | Qué revisar |
|---|---|---|
| El rango 0 imprime una suma que no coincide con la secuencial | Residuo `n % p` sin repartir | ¿Los tamaños de los bloques suman `n`? Prueba con `n` que no sea múltiplo de `p` |
| "Mi variable cambió en un proceso y no en otro" | Memoria no compartida (idea 16) | ¿Qué mensaje lleva ese dato? Si no hay, no viaja |
| El programa se queda colgado | Un `Recv` espera un mensaje que nadie envía (o viceversa) | Cuenta envíos y recepciones por rango; detalle en S02 |
| Salida "desordenada" o mezclada | Normal: procesos independientes | No dependas del orden; imprime desde un solo rango |
| `There are not enough slots available` | Más procesos que núcleos | `--oversubscribe` (solo para probar lógica) |
| `mpirun` se niega a correr como root | Protección de Open MPI | `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1` |
| `mpi.h: No such file or directory` o `undefined reference to MPI_Init` | Compilaste con `gcc` | Usa `mpicc` |
| Tiempos iguales o peores con más procesos | Problema pequeño: mides el arranque | Tamaño con `T(1) ≥ 1 s`; protocolo completo |

## 12. Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, versión 4.1 (mpi-forum.org): capítulos
  "Process Initialization, Creation, and Management" (`MPI_Init`, `MPI_Finalize`), "Groups, Contexts,
  Communicators, and Caching" (`MPI_Comm_rank`, `MPI_Comm_size`) y "MPI Environmental Management" (`MPI_Wtime`).
- Documentación de Open MPI (docs.open-mpi.org): páginas de `mpirun` (opciones `-np`, `--oversubscribe`,
  `--bind-to`) y de cada función (`man MPI_Init`, `man MPI_Comm_rank`).
- P. Pacheco y M. Malensek, *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022,
  capítulo 3 ("Distributed-Memory Programming with MPI"): inicio con MPI, SPMD, reparto por bloques y
  cíclico, y evaluación de desempeño de programas MPI.
