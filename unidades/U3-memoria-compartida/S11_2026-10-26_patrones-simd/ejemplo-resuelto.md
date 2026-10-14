> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S11 · Ejemplo resuelto: reducción sobre arreglo, *scan* en dos fases y el reporte del vectorizador

Tres problemas cortos, en el orden en que se ven en clase (minutos 10–35). El código completo está en
`practica-guiada/` (`array_reduction.c`, `scan.c`, `scan_buggy.c`, `vec_kernels.c`, `saxpy_simd.c`); aquí se
muestran los fragmentos que importan. En cada pausa, **escribe tu respuesta antes de abrir la solución**.
Las salidas son corridas reales en la máquina de autoría (Xeon 2.8 GHz, 4 núcleos, gcc 13.3, `-O2`); los
tiempos cambian de máquina a máquina, los resultados numéricos no.

## Problema A · Histograma: reducción sobre un arreglo

**Problema.** `n = 2·10^7` valores en `[0, 1)`; contar cuántos caen en cada una de 16 casillas. Paralelizar
sin cambiar el resultado (los conteos son enteros: la igualdad debe ser exacta).

**Plan (3 líneas).** (1) Cada hilo recorre un bloque de valores. (2) Cada hilo cuenta en un histograma
**propio**, no en el compartido. (3) Al final se suman los 16 conteos de cada hilo al histograma global.
OpenMP 4.5 hace (2) y (3) por ti con una sección de arreglo en `reduction`.

```c
static void hist_redarr(const double *v, long n, long *hist, int nbins)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    /* hist[:nbins] es una sección de arreglo: "desde el inicio, nbins elementos". */
    #pragma omp parallel for reduction(+:hist[:nbins])
    for (long i = 0; i < n; i++) {
        int bin = (int)(v[i] * nbins);
        hist[bin]++;                           /* escribe en la copia privada del hilo */
    }
}

static void hist_local(const double *v, long n, long *hist, int nbins)   /* lo mismo, a mano */
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    #pragma omp parallel
    {
        long *local = calloc((size_t)nbins, sizeof *local);   /* privado: lo declara el hilo */
        #pragma omp for
        for (long i = 0; i < n; i++) {
            int bin = (int)(v[i] * nbins);
            local[bin]++;
        }
        #pragma omp critical
        for (int b = 0; b < nbins; b++)        /* nbins sumas por hilo, no una por elemento */
            hist[b] += local[b];
        free(local);
    }
}
```

**Salida real** (`./array_reduction 20000000 16 4`):

```
array_reduction: n=20000000 nbins=16 hilos=4
  primeras casillas (seq): 1250060 1249622 1251580 1250689 ...
  seq      mediana=0.0276 s
  redarr   mediana=0.0093 s  speedup=2.96
  local    mediana=0.0076 s  speedup=3.63
  histogramas identicos: si
CHECK OK
```

> **Pausa 1.** ¿Por qué `reduction(+:hist[:nbins])` y no `reduction(+:hist)`? ¿Qué le pasaría a cada hilo si
> escribiera `hist[bin]++` sobre el arreglo compartido sin cláusula alguna?
>
> <details><summary>Respuesta</summary>
>
> `hist` es un puntero; `reduction(+:hist)` reduciría **el puntero** (un entero), no lo que apunta. La sección
> `hist[:nbins]` le dice a OpenMP cuántos elementos privatizar e inicializar en 0 por hilo, y cuántos sumar al
> final. Sin cláusula, `hist[bin]++` sobre el compartido es una carrera (leer-modificar-escribir sin
> protección): conteos perdidos, distintos en cada corrida. Lo viste en S07 con ThreadSanitizer.
> </details>

> **Pausa 2.** En `hist_local`, ¿por qué el `critical` envuelve el ciclo de volcado **completo** y no está
> dentro del ciclo principal, alrededor de `hist[bin]++`? Piensa en cuántas veces se ejecuta cada cosa y en qué
> líneas de caché tocan los cuatro hilos.
>
> <details><summary>Respuesta</summary>
>
> Dentro del ciclo principal, el `critical` (o un `atomic`) se ejecutaría 2·10^7 veces y serializaría el
> trabajo; además las 16 casillas compartidas caben en 1–2 líneas de caché de 64 bytes, así que los cuatro
> núcleos se la arrebatarían en cada incremento (falso compartido y contención: idea errónea 14). Con el
> acumulador local cada hilo toca solo su memoria; el `critical` corre **4 veces en total** (una por hilo) y
> suma 16 números. Esa es la regla del patrón: acumula localmente, combina una vez. `reduction` hace
> exactamente eso por dentro.
> </details>

## Problema B · Suma de prefijos (*scan*) en dos fases

**Problema.** `y[i] = x[0] + x[1] + … + x[i]` para `n = 2^23` valores `double`. El ciclo secuencial
`y[i] = y[i-1] + x[i]` no se puede repartir tal cual (pregunta 5 de la recuperación).

**Plan (3 líneas).** (1) Cada hilo hace el *scan* de su bloque contiguo y anota el total del bloque.
(2) Un hilo convierte los `p` totales en desplazamientos: `offset[t] = total[0] + … + total[t−1]`.
(3) Cada hilo suma su desplazamiento a todo su bloque.

```c
#pragma omp parallel
{
    int tid = omp_get_thread_num(), nt = omp_get_num_threads();
    long lo = n * tid / nt, hi = n * (tid + 1) / nt;     /* bloque contiguo del hilo */

    double acc = 0.0;                                     /* Fase 1: scan local */
    for (long i = lo; i < hi; i++) { acc += x[i]; y[i] = acc; }
    block_sum[tid] = acc;
    #pragma omp barrier                                   /* la fase 2 necesita TODOS los totales */

    #pragma omp single                                    /* Fase 2: p números, un solo hilo */
    {
        double run = 0.0;
        for (int t = 0; t < nt; t++) { double tmp = block_sum[t]; block_sum[t] = run; run += tmp; }
    }                                                     /* barrera implícita al final de single */

    double offset = block_sum[tid];                       /* Fase 3: corrección del bloque */
    for (long i = lo; i < hi; i++) y[i] += offset;
}
```

**Salida real** (`./scan 8388608 4` y luego `./scan 8388608 1`):

```
scan: n=8388608 hilos=4
  seq  mediana=0.0150 s   y[n-1]=4194396.036010
  par  mediana=0.0079 s   y[n-1]=4194396.036010   speedup=1.89
  max|y_par - y_seq| = 2.873e-07 (en i=5214114)   relativo a la suma total = 6.850e-14
  identicos bit a bit: no   dentro de tolerancia 1e-12: si
CHECK OK
```

```
scan: n=8388608 hilos=1
  seq  mediana=0.0164 s   y[n-1]=4194396.036010
  par  mediana=0.0246 s   y[n-1]=4194396.036010   speedup=0.67
  max|y_par - y_seq| = 0.000e+00 (en i=0)   relativo a la suma total = 0.000e+00
  identicos bit a bit: si   dentro de tolerancia 1e-12: si
CHECK OK
```

> **Pausa 3.** ¿Qué pasaría si se quita el `#pragma omp barrier` entre la fase 1 y la fase 2? ¿Y por qué no hace
> falta una barrera explícita entre la fase 2 y la 3?
>
> <details><summary>Respuesta</summary>
>
> Sin la barrera, el hilo que ejecuta `single` podría leer `block_sum[t]` de un hilo que aún no terminó su
> fase 1: desplazamientos incorrectos y resultado incorrecto (carrera). Entre la fase 2 y la 3 no hace falta
> porque `single` lleva una **barrera implícita** al final (salvo que se escriba `nowait`): nadie empieza la
> fase 3 hasta que los desplazamientos están listos. Recuerda la idea errónea 12: `for`, `single` y `sections`
> sí tienen barrera al final.
> </details>

> **Pausa 4.** El programa reporta `max|y_par − y_seq| = 2.873e-07` con 4 hilos e `identicos bit a bit: si` con
> 1 hilo. ¿Es un error? ¿Cómo lo distingues de una carrera sin usar ThreadSanitizer?
>
> <details><summary>Respuesta</summary>
>
> No es error: el secuencial suma `x[0] + x[1] + … + x[i]` de izquierda a derecha; el paralelo suma
> `(x[lo] + … + x[i]) + offset`, otra agrupación, otro redondeo. La suma en punto flotante no es asociativa
> (idea errónea 10). Dos pistas lo separan de una carrera: la diferencia es **diminuta** respecto a la
> magnitud (6.850e-14 relativo a la suma total) y es **la misma** en cada corrida con el mismo número de hilos. Una carrera da
> diferencias grandes y distintas cada vez (abajo). Por eso las pruebas comparan con tolerancia relativa.
> </details>

> **Pausa 5.** El *speedup* con 4 hilos fue 1.89, lejos de 4, aunque las fases 1 y 3 son perfectamente
> paralelas y la fase 2 cuesta solo 4 sumas; con 1 hilo, el paralelo es **más lento** que el secuencial. ¿Qué lo
> limita?
>
> <details><summary>Respuesta</summary>
>
> El tráfico de memoria. El secuencial lee `x` y escribe `y` una vez (16 bytes por elemento). El paralelo lee
> `x`, escribe `y`, y en la fase 3 vuelve a leer y escribir `y`: 32 bytes por elemento, el doble. Con
> 2^23 elementos (64 MB por arreglo) nada cabe en caché y el ancho de banda de memoria, compartido por los 4
> núcleos, es el cuello. No es Amdahl (la parte secuencial es despreciable): es un límite de memoria, como
> en el falso compartido de S10 pero por volumen, no por coherencia. Con 1 hilo se ve en estado puro: mismo
> trabajo útil, el doble de tráfico, más lento. Con `n = 2^20` (8 MB por arreglo, caben en L3) el *speedup* con
> 4 hilos sube a 3.09: la misma lección que saxpy en L1 frente a RAM.
> </details>

### Variante que falla: `scan_buggy.c`

```c
y_bad[0] = x[0];
#pragma omp parallel for          /* INCORRECTO: la iteración i depende de la i-1 */
for (long i = 1; i < n; i++)
    y_bad[i] = y_bad[i - 1] + x[i];
```

Dos corridas con 4 hilos (`./scan_buggy 1000000 4`):

```
scan_buggy: n=1000000 hilos=4
  y_seq[n-1]=499991.298367   y_bad[n-1]=124627.779762   max|dif|=3.754e+05
  (con 1 hilo coincide; con 2 o mas hilos el resultado es incorrecto y cambia entre corridas)
```

```
scan_buggy: n=1000000 hilos=4
  y_seq[n-1]=499991.298367   y_bad[n-1]=124627.779762   max|dif|=3.754e+05
  (con 1 hilo coincide; con 2 o mas hilos el resultado es incorrecto y cambia entre corridas)
```

Y lo que dice ThreadSanitizer (`make tsan`, primeras líneas):

```
==================
WARNING: ThreadSanitizer: data race (pid=566)
  Write of size 8 at 0x7fcc2db6cd40 by main thread:
    #0 main._omp_fn.0 scan_buggy.c:48 (scan_buggy_tsan+0x13e5)
    #1 GOMP_parallel <null> (libgomp.so.1+0x18976)
    #2 __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58 (libc.so.6+0x2a1c9)

  Previous read of size 8 at 0x7fcc2db6cd40 by thread T1:
    #0 main._omp_fn.0 scan_buggy.c:48 (scan_buggy_tsan+0x13bf)
    #1 <null> <null> (libgomp.so.1+0x2279e)

  Location is heap block of size 800000 at 0x7fcc2db3c000 allocated by main thread:
    #0 malloc ../../../../src/libsanitizer/tsan/tsan_interceptors_posix.cpp:665 (libtsan.so.2+0x54b3f)
    #1 main scan_buggy.c:37 (scan_buggy_tsan+0x14fe)

  Thread T1 (tid=569, running) created by main thread at:
    #0 pthread_create ../../../../src/libsanitizer/tsan/tsan_interceptors_posix.cpp:1022 (libtsan.so.2+0x5ac1a)
    #1 <null> <null> (libgomp.so.1+0x22e1e)
    #2 __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58 (libc.so.6+0x2a1c9)

SUMMARY: ThreadSanitizer: data race scan_buggy.c:48 in main._omp_fn.0
==================
```

La diferencia es enorme y cambia entre corridas: eso es una carrera. Compárala con la de 2.873e-07 del *scan*
correcto. El mismo ciclo tampoco se vectoriza (Problema C): la dependencia es la misma, solo que entre
iteraciones consecutivas de un vector en lugar de entre hilos.

## Problema C · saxpy y el reporte del vectorizador

**Problema.** `y[i] = a·x[i] + y[i]` con `float`. Saber si GCC generó instrucciones SIMD y cuánto cambia el tiempo.

**Plan (3 líneas).** (1) Escribir el mismo ciclo tres veces: sin nada, con `restrict`, con `#pragma omp simd`.
(2) Compilar con `-fopt-info-vec-optimized -fopt-info-vec-missed` y leer línea por línea. (3) Medir las tres
versiones con el protocolo del curso en tamaños que caben en L1, L2, L3 y RAM.

```c
void saxpy_plain(float a, const float *x, float *y, long n)                       /* línea 18 */
{   for (long i = 0; i < n; i++) y[i] = a * x[i] + y[i]; }

void saxpy_restrict(float a, const float *restrict x, float *restrict y, long n)  /* línea 25 */
{   for (long i = 0; i < n; i++) y[i] = a * x[i] + y[i]; }

void saxpy_simd(float a, const float *x, float *y, long n)                        /* línea 34 */
{   #pragma omp simd
    for (long i = 0; i < n; i++) y[i] = a * x[i] + y[i]; }

void prefix_dep(double *a, const double *b, long n)                               /* línea 41 */
{   for (long i = 1; i < n; i++) a[i] = a[i - 1] + b[i]; }
```

**Salida real de `make report`** (parte de `vec_kernels.c`):

```
vec_kernels.c:18:24: missed: couldn't vectorize loop
vec_kernels.c:19:21: missed: not vectorized: no vectype for stmt: _4 = *_3;
 scalar_type: const float
vec_kernels.c:25:24: missed: couldn't vectorize loop
vec_kernels.c:26:21: missed: not vectorized: no vectype for stmt: _4 = *_3;
 scalar_type: const float
vec_kernels.c:34:21: optimized: loop vectorized using 16 byte vectors
vec_kernels.c:34:21: optimized: loop vectorized using 8 byte vectors
vec_kernels.c:41:24: missed: couldn't vectorize loop
vec_kernels.c:42:17: missed: not vectorized: no vectype for stmt: _5 = *_4;
 scalar_type: double
```

Solo `saxpy_simd` se vectorizó (SSE2: 16 bytes = 4 `float`; la línea de "8 byte vectors" es el epílogo para
los elementos sobrantes). `saxpy_plain` y `saxpy_restrict` generan **el mismo** código máquina (`objdump -d`
lo confirma): a `-O2`, `restrict` solo quita una razón para no vectorizar, no cambia el ciclo escalar. El mensaje `no vectype` es el último intento del compilador, no la causa; la causa
está en el volcado detallado (`gcc … -fdump-tree-vect-details -c vec_kernels.c` genera `vec_kernels.c.*.vect`):

```
vec_kernels.c:19:21: missed:   versioning for alias required: can't determine dependence between *_3 and *_6
vec_kernels.c:18:24: missed:   would need a runtime alias check
vec_kernels.c:25:24: missed:  some scalar iterations would need to be peeled
vec_kernels.c:25:24: missed:  Loop costings not worthwhile.
vec_kernels.c:41:24: note:   dependence distance  = 1.
vec_kernels.c:42:17: missed:   not vectorized, possible dependence between data-refs *_4 and *_8
```

**Salida real de `./saxpy_simd`** (`S_simd` compara contra el mejor de los dos tiempos escalares; que `plain_s`
y `restr_s` difieran entre sí con el mismo código muestra cuánto pesan la alineación del código y de los
datos en un ciclo de cuatro instrucciones):

```
saxpy: y = a*x + y, float, -O2, un solo hilo; 33554432 elementos por repeticion, 5 repeticiones intercaladas, mediana
         n   KB/arr  nivel |   plain_s   restr_s    simd_s |  S_simd |   GB/s
      4096       16     L1 |    0.0231    0.0137    0.0055 |    2.48 |   72.9   max|dif|=0.0e+00
     65536      256     L2 |    0.0215    0.0133    0.0054 |    2.44 |   73.9   max|dif|=0.0e+00
   1048576     4096  L2/L3 |    0.0225    0.0146    0.0100 |    1.46 |   40.3   max|dif|=0.0e+00
  16777216    65536    RAM |    0.0351    0.0388    0.0263 |    1.33 |   15.3   max|dif|=0.0e+00
S_simd = min(plain_s, restr_s) / simd_s (>1: simd mas rapido que el mejor escalar). GB/s: version simd.
CHECK OK
```

> **Pausa 6.** `saxpy_restrict` no tiene aliasing posible y aun así no se vectorizó a `-O2`. ¿Por qué? ¿Qué
> tres cosas distintas podrías hacer para que sí, y cuál cambia la **semántica** del programa?
>
> <details><summary>Respuesta</summary>
>
> A `-O2`, GCC 12+ vectoriza con el modelo de costo *very-cheap*: solo si el código vectorial sustituye por
> completo al escalar. Como `n` es desconocido, haría falta un epílogo escalar para los elementos sobrantes
> ("some scalar iterations would need to be peeled") y el modelo lo rechaza. Opciones: (a) `-O3` (modelo
> *dynamic*: genera epílogos y comprobaciones de aliasing en tiempo de ejecución; por eso `saxpy_plain` sí se
> vectoriza a `-O3`, "versioned … because of possible aliasing"); (b) `-fvect-cost-model=dynamic` con `-O2`;
> (c) `#pragma omp simd`. Solo (c) cambia la semántica: afirma que no hay dependencias. Es segura en saxpy
> y falsa en `prefix_dep`, donde produciría resultados incorrectos sin ningún aviso. El compilador decide
> con su modelo de costo; tú respondes por la promesa.
> </details>

> **Pausa 7.** En la tabla, `S_simd` es grande con `n = 4096` (16 KB por arreglo, L1) y cae con `n = 2^24`
> (64 MB, RAM). ¿Qué recurso satura en cada caso? ¿Qué predices para el ciclo interno de Jacobi con
> `n = 100000` y con `n = 4 000 000`?
>
> <details><summary>Respuesta</summary>
>
> En L1 el límite es el número de operaciones por ciclo de reloj: SIMD hace 4 a la vez y se nota (2.48×; el
> máximo teórico con SSE2 es 4). En RAM el límite es el ancho de banda (la columna GB/s se acerca al máximo de la máquina)
> y da igual cuántas operaciones haga el núcleo por instrucción: espera a la memoria. Con ese razonamiento,
> Jacobi con `n = 100000` (800 KB por arreglo, L2) debería ganar algo con `simd` y con `n = 4 000 000` (32 MB
> por arreglo), casi nada. La práctica guiada lo mide, y la primera mitad de la predicción falla por una
> razón que saxpy no tenía: la reducción `max` dentro del ciclo (fase Modificar, M1b).
> </details>
