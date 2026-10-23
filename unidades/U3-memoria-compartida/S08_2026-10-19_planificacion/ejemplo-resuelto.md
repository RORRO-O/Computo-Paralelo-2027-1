> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S08 · Ejemplo resuelto: el ciclo triangular y la política que lo balancea

El código completo está en `practica-guiada/unbalanced.c` (medición) y `practica-guiada/schedule_map.c`
(mapas). Aquí se muestran solo los fragmentos que importan. Las salidas son reales: 4 hilos, gcc 13, `-O2`.
Las tablas de tiempos se obtuvieron en una **máquina virtual de autoría con 4 vCPU que entrega solo ~2
núcleos efectivos a 4 hilos** (medido: 4 hilos con trabajo idéntico tardan 1.6–1.8× lo que 1 hilo), por lo
que los *speedups* absolutos salen bajos y varios quedan por debajo de 1; el orden relativo entre políticas
es el que importa aquí. Antes de la sesión se regeneran con `make tabla` en una máquina física con 4 núcleos
libres (`uptime` < 1) y se sustituyen.
Lee cada **pausa** antes de abrir su respuesta.

## Problema

Calcular `S = Σ_{i=0}^{n−1} Σ_{j=0}^{i−1} 1 / (1 + i·j)` con n = 40 000 y 4 hilos, con el mejor *speedup*
posible respecto a la versión secuencial. El ciclo interno tiene `i` iteraciones: la iteración `i` del ciclo
externo cuesta `i` divisiones. La última cuesta 40 000 veces más que la segunda.

## Plan (3 líneas)

1. Paralelizar el ciclo externo con `parallel for` + `reduction(+ : acc)` (S07) y medir con `static`.
2. Predecir el reparto con un mapa de n = 16 y calcular cuánto trabajo recibe cada hilo; medir.
3. Probar `static,1`, `dynamic,16` y `guided,16`; elegir con la tabla, no con la intuición.

## Código comentado (fragmentos de `unbalanced.c`)

```c
/* Trabajo de la iteración i: i divisiones. Idéntico en secuencial y paralelo. */
static inline double triangular_item(long i)
{
    double s = 0.0;
    for (long j = 0; j < i; j++)
        s += 1.0 / (1.0 + (double)i * (double)j);
    return s;
}

/* Versión secuencial: la referencia contra la que se calcula el speedup. */
static double run_seq(enum kernel_id k, long n)
{
    double acc = 0.0;
    for (long i = 0; i < n; i++)
        acc += item(k, i, n);
    return acc;
}

/* Versión paralela. schedule(runtime): la política se fija desde fuera del
 * código con omp_set_schedule() o con la variable de entorno OMP_SCHEDULE,
 * así un mismo binario mide todas las políticas. */
static double run_par(enum kernel_id k, long n)
{
    double acc = 0.0;
    #pragma omp parallel for schedule(runtime) reduction(+ : acc)
    for (long i = 0; i < n; i++)
        acc += item(k, i, n);
    return acc;
}
```

```c
/* En main(), para cada política pedida en la línea de comandos: */
omp_set_schedule(pol[p].kind, pol[p].chunk);   /* p. ej. (omp_sched_dynamic, 16) */
double p_med = timed(run_par, k, n, reps, &p_min, &p_max, &p_val);
/* verificación contra la secuencial con tolerancia relativa 1e-9 */
```

```c
/* Medición según el protocolo: 1 calentamiento + reps repeticiones, mediana. */
static double timed(double (*volatile fn)(enum kernel_id, long), enum kernel_id k, long n,
                    int reps, double *t_min, double *t_max, double *result)
{
    double times[MAX_REPS];
    *result = fn(k, n);                 /* calentamiento, no cuenta */
    for (int r = 0; r < reps; r++) {
        double t0 = omp_get_wtime();
        *result = fn(k, n);
        times[r] = omp_get_wtime() - t0;
    }
    qsort(times, (size_t)reps, sizeof times[0], cmp_double);
    *t_min = times[0]; *t_max = times[reps - 1];
    return times[reps / 2];
}
```

### Pausa 1 · ¿Por qué `reduction(+ : acc)` y no `#pragma omp atomic` sobre `acc`?

<details>
<summary>Respuesta</summary>

Con `atomic`, cada una de las n iteraciones externas haría una operación atómica sobre la misma variable
compartida: funciona, pero serializa la suma y añade tráfico de caché. `reduction` da a cada hilo una copia
privada de `acc`, suma en privado y combina **una vez** al final. Es lo que vimos en S07 y en la sesión de
`reduction`. Consecuencia: el orden de las sumas cambia y el resultado en punto flotante difiere en los últimos
bits; por eso la verificación usa tolerancia relativa (idea errónea 10 del Anexo A).

</details>

## Paso 1 · `schedule(static)`: predecir el reparto antes de medir

Mapa real con n = 16 y 4 hilos (`OMP_NUM_THREADS=4 ./schedule_map 16 static`; el costo de la iteración i se
modela como i+1 unidades):

```
i =               | 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
static            | 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 | iters:  4  4  4  4 | trabajo:  10  26  42  58
```

Cada hilo recibe 4 iteraciones, pero el hilo 3 hace 58 unidades y el hilo 0 solo 10.

### Pausa 2 · Con n grande, ¿cuántas veces más trabaja el hilo 3 que el hilo 0? ¿Qué *speedup* máximo permite eso?

<details>
<summary>Respuesta</summary>

El bloque k (k = 0, 1, 2, 3) cubre las iteraciones de k·n/4 a (k+1)·n/4 − 1 y su trabajo es
∝ ((k+1)² − k²) = 2k + 1: los bloques pesan 1, 3, 5 y 7. El hilo 3 hace **7 veces** el trabajo del hilo 0 y
**7/16** del total. El ciclo termina cuando él termina: T₄ ≈ (7/16)·T₁, así que el *speedup* no puede pasar
de 16/7 ≈ **2.3**, aunque haya 4 hilos y el trabajo total sea el mismo. Esto no lo explica Amdahl (no hay
parte secuencial): es **desbalance de carga**, y la barrera implícita al final del `for` lo hace visible.

</details>

## Paso 2 · `schedule(static, 1)`: mismo costo cero, mejor balance

```
static,1          | 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 | iters:  4  4  4  4 | trabajo:  28  32  36  40
```

(Salida real de `./schedule_map 16 static 1`.) El reparto cíclico da a cada hilo iteraciones baratas y caras
alternadas: 28 contra 40 en vez de 10 contra 58. Sigue siendo `static`: se decide antes de empezar y no
cuesta nada en ejecución.

### Pausa 3 · ¿Por qué `static,1` balancea tan bien el ciclo triangular y, sin embargo, no es la respuesta universal?

<details>
<summary>Respuesta</summary>

Porque la carga triangular es **monótona**: crece de manera suave con i. Al intercalar iteraciones, cada
hilo recibe una muestra "representativa" de todo el rango y las sumas se parecen (difieren a lo más en una
iteración cara). Falla cuando la carga no es monótona ni predecible (Mandelbrot: todas las filas pesadas
están juntas en el centro, aunque `static,1` también lo reparte razonablemente), cuando el costo de cada
iteración varía entre corridas, o cuando el acceso a memoria se beneficia de iteraciones contiguas (caché):
`static,1` destruye esa localidad. Para esos casos están `dynamic` y `guided`.

</details>

## Paso 3 · Medir las cuatro políticas con el protocolo

```bash
OMP_NUM_THREADS=4 ./unbalanced triangular 40000 static static,1 static,64 dynamic dynamic,16 guided,16
```

Secuencial (referencia): mediana **1.0571 s** (mín 1.0097  máx 1.8642); n = 40 000  4 hilos  mediana de 5 repeticiones tras 1 calentamiento.

| Política | Mediana (s) | Mín (s) | Máx (s) | *Speedup* | Eficiencia | Verif. |
|---|---|---|---|---|---|---|
| `static` | 0.8774 | 0.7480 | 0.9194 | 1.20 | 0.30 | OK |
| `static,1` | 0.8103 | 0.5589 | 0.8616 | 1.30 | 0.33 | OK |
| `static,64` | 0.5789 | 0.5501 | 0.6929 | 1.83 | 0.46 | OK |
| `dynamic` | 0.7205 | 0.6498 | 0.7993 | 1.47 | 0.37 | OK |
| `dynamic,16` | 0.7500 | 0.6517 | 0.8493 | 1.41 | 0.35 | OK |
| `guided,16` | 0.7820 | 0.6479 | 0.8767 | 1.35 | 0.34 | OK |

Lectura de la tabla:

- `static` es la más lenta de las políticas: es el límite de la pausa 2 (en una máquina libre su *speedup*
  se queda cerca de 2.3; aquí, con otros procesos compitiendo por los núcleos, todos los *speedups* bajan,
  pero `static` sigue al final).
- `static,1`, `static,64`, `dynamic,16` y `guided,16` balancean; las diferencias entre ellas son del orden del
  ruido: mira las columnas `min_s` y `max_s` antes de declarar un ganador. En una corrida previa con la
  máquina libre (n = 20 000, 3 repeticiones) salieron `static` 0.111 s, `static,1` 0.073 s, `dynamic,16`
  0.066 s y `guided,16` 0.072 s: la misma conclusión, con *speedups* cercanos a 4 para las balanceadas.
- `dynamic` sin *chunk* (= `dynamic,1`) también balancea, pero paga 40 000 pedidos al contador compartido;
  aquí cada iteración cuesta microsegundos, así que el pago casi no se nota. En el siguiente ejemplo sí se nota.

### Pausa 4 · ¿Por qué el *speedup* se calcula contra `run_seq` y no contra `run_par` con `OMP_NUM_THREADS=1`?

<details>
<summary>Respuesta</summary>

Porque el protocolo del curso define T(1) como el **mejor programa secuencial**. La versión paralela con 1 hilo
incluye la creación del equipo de hilos, la reducción y el despacho de `schedule`; en este ciclo cuesta casi lo
mismo (medido: 1.080 s con 1 hilo contra 1.104 s secuencial; la diferencia está dentro del ruido), pero en
ciclos con sincronización fina puede ser mucho más lenta y
el *speedup* "contra 1 hilo" saldría inflado. Si se reporta contra 1 hilo se dice explícitamente y se dan
ambas cifras.

</details>

### Pausa 5 · ¿Por qué el puntero a función de `timed` es `volatile`?

<details>
<summary>Respuesta</summary>

`run_seq` no tiene efectos secundarios y depende solo de sus argumentos. GCC con `-O2` lo detecta y
**reutiliza el resultado de la primera llamada** en lugar de repetirla: la primera versión de este programa
medía 0.0000 s para la secuencial y daba *speedups* de 0.00. Al llamar a través de un puntero `volatile`, el
compilador no puede suponer que la función es la misma y hace cada llamada. Es un error de medición clásico;
otro remedio es que la función produzca un efecto observable (escribir en un arreglo `volatile`). Anótalo en
tu bitácora de errores: "tiempo secuencial sospechosamente pequeño → revisar que el compilador no eliminó
el trabajo".

</details>

## Variante que falla · carga uniforme con `schedule(dynamic)`

El mismo programa, núcleo `uniform` (8 000 000 iteraciones de ~50 ns cada una):

```bash
OMP_NUM_THREADS=4 ./unbalanced uniform 8000000 static static,1 dynamic dynamic,1024 guided,64
```

Secuencial (referencia): mediana **0.5634 s** (mín 0.5406  máx 1.1872); n = 8 000 000  4 hilos  mediana de 5 repeticiones tras 1 calentamiento.

| Política | Mediana (s) | Mín (s) | Máx (s) | *Speedup* | Eficiencia | Verif. |
|---|---|---|---|---|---|---|
| `static` | 0.7693 | 0.6266 | 1.3241 | 0.73 | 0.18 | OK |
| `static,1` | 0.8983 | 0.7860 | 0.9856 | 0.63 | 0.16 | OK |
| `dynamic` | 1.2940 | 0.8911 | 2.6348 | 0.44 | 0.11 | OK |
| `dynamic,1024` | 0.4916 | 0.4604 | 0.5039 | 1.15 | 0.29 | OK |
| `guided,64` | 0.4840 | 0.3786 | 0.5120 | 1.16 | 0.29 | OK |

`dynamic` sin *chunk* termina **más lento que la versión secuencial** (también en la máquina libre: 0.70 s
contra 0.13 s de `static` en la corrida previa de 3 repeticiones): 8 000 000 pedidos de una iteración a un
contador compartido por 4 hilos. Con `dynamic,1024` el número de pedidos baja a 7 813 y el costo desaparece. Es la idea errónea 11 en números: `dynamic` no "siempre gana"; gana cuando hay desbalance que
corregir y el *chunk* es razonable.

### Pausa 6 · Con los datos de esta tabla, estima cuánto cuesta un pedido de *chunk*.

<details>
<summary>Respuesta</summary>

Tiempo extra total ≈ T(`dynamic`) − T(`static`). Lo pagan 4 hilos en paralelo, así que el tiempo de
procesador gastado es ≈ 4 × ese extra, repartido entre 8 000 000 pedidos. Con los números de la tabla sale
del orden de **cientos de nanosegundos por pedido** bajo competencia de 4 hilos: varias veces el costo de la
iteración misma. Regla: el trabajo de un *chunk* debe ser **mucho mayor** (≥ 100×) que ese costo.

</details>

## Segunda variante que falla · `nowait` con `dynamic` (`nowait_buggy.c`)

```
$ OMP_NUM_THREADS=4 ./nowait_buggy 2000 static
n=2000 hilos=4 política=static -> b[i] incorrectas: 0 de 2000
$ OMP_NUM_THREADS=4 ./nowait_buggy 2000 dynamic
n=2000 hilos=4 política=dynamic -> b[i] incorrectas: 3 de 2000
```

Dos ciclos `omp for` dependientes (`b[i] = 2 * a[i]`) separados por `nowait`. Con `schedule(static)` idéntico
en ambos y el mismo n, la especificación garantiza que la iteración i la ejecuta el mismo hilo en los dos
ciclos: el `nowait` es seguro. Con `dynamic` no hay garantía: un hilo entra al segundo ciclo mientras otro
sigue escribiendo `a[]`. En nuestras corridas salen 2 o 3 valores mal; en otra máquina pueden salir 0, y el
programa seguiría estando mal (idea errónea 7). ThreadSanitizer (`make tsan`) lo reporta así (recortado):

```
WARNING: ThreadSanitizer: data race
  Read of size 4 ... by thread T1:
    #0 main._omp_fn.0 nowait_buggy.c:59      <- b[i] = 2 * a[i];
  Previous write of size 4 ... by thread T3:
    #0 main._omp_fn.0 nowait_buggy.c:54      <- a[i] = i;
...
n=2000 hilos=4 política=dynamic -> b[i] incorrectas: 0 de 2000
```

Fíjate en la última línea: bajo TSan la corrida salió "bien" (0 incorrectas) y aun así el detector encontró
la carrera, porque razona sobre accesos sin sincronización, no sobre si el error se manifestó. TSan imprime
además uno o dos reportes más, que involucran el ciclo de verificación del hilo principal (línea 78) y el
`free(a)` final (línea 82), ambos fuera de la región paralela; el de la línea 78 aparece también con la
variante `static`. Son **falsos positivos**: la libgomp de Ubuntu no está instrumentada y TSan no ve la
barrera del final de la región. Regla para leerlo: un reporte real involucra dos accesos dentro de la región
paralela (aquí `main._omp_fn.0`).

## Qué te llevas

1. Predice el mapa con `static` antes de medir; calcula el trabajo por hilo, no el número de iteraciones.
2. Carga uniforme → `static`. Carga desigual → `static,c` pequeño si es monótona; `dynamic,c` o `guided,c` si
   es concentrada o impredecible. El *chunk* se elige para que pedirlo sea despreciable.
3. La barrera implícita al final del `for` es la que convierte el desbalance en tiempo perdido; quitarla con
   `nowait` solo es seguro cuando la especificación lo garantiza.
4. Toda afirmación de "más rápido" viene con una tabla de mediana, mínimo y máximo.
