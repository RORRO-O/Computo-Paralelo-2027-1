> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S11 · Notas: patrones de paralelismo y vectorización con `omp simd`

**Lo que debes poder hacer al terminar:** reconocer en un ciclo cuál de cuatro patrones es (reducción sobre
arreglo, *scan*, *stencil*, *pipeline*), paralelizarlo con la herramienta correcta, verificarlo contra la
versión secuencial, y leer el reporte del vectorizador para saber si el compilador generó instrucciones SIMD.

## 1. Cuatro patrones

| Patrón | Forma del ciclo | Qué lo complica | Herramienta en OpenMP |
|---|---|---|---|
| Reducción sobre arreglo | `hist[f(x[i])]++` | Muchos hilos escriben en pocas casillas compartidas | `reduction(+:hist[:nbins])` (OpenMP 4.5+) o acumuladores locales + volcado |
| Suma de prefijos (*scan*) | `y[i] = y[i-1] + x[i]` | Dependencia acarreada por el ciclo: `i` necesita `i−1` | Dos fases: sumas por bloque, luego corrección |
| *Stencil* (Jacobi) | `u_new[i] = f(u[i-1], u[i], u[i+1])` | Hay que leer valores viejos mientras se escriben nuevos | Doble búfer + intercambio de punteros; convergencia con `reduction(max:…)` |
| *Pipeline* | Etapas distintas sobre un flujo de datos | Paralelismo entre etapas, no entre datos | Tareas con dependencias (`task depend`), o colas; natural en MPI |

### 1.1 Reducción sobre un arreglo

`reduction(+:hist[:nbins])` da a cada hilo una **copia privada** del arreglo inicializada en 0; cada hilo
acumula en la suya; al cerrar la región OpenMP suma las copias en la original. Es exactamente lo que harías a
mano: arreglo local por hilo y un `critical` **una vez por hilo** para volcarlo. Lo que no debes hacer:
`atomic` o `critical` sobre la casilla compartida **por cada elemento**: convierte el ciclo en una pelea por
1–2 líneas de caché (falso compartido y contención). Con enteros el resultado es exacto en cualquier versión.

### 1.2 *Scan* en dos fases

El ciclo secuencial no se reparte: cada iteración depende de la anterior (si lo intentas con `parallel for`,
el resultado es incorrecto y ThreadSanitizer lo reporta: `scan_buggy.c`). La solución cambia el algoritmo:

```
x:        [ bloque 0 ][ bloque 1 ][ bloque 2 ][ bloque 3 ]      p = 4 hilos
Fase 1:   scan local de cada bloque en paralelo; total_t = suma del bloque t
Fase 2:   un hilo: offset_0 = 0, offset_t = total_0 + … + total_{t−1}   (p números, O(p))
Fase 3:   cada hilo suma offset_t a todo su bloque, en paralelo
```

Cuesta leer `x` una vez y escribir `y` dos veces: 1.5× el tráfico de memoria del secuencial. Por eso el
*speedup* está lejos de 4 aunque el paralelismo sea perfecto (en la máquina de autoría: 1.89 con
4 hilos y `n = 2^23`; con 1 hilo el paralelo es más lento que el secuencial). Y como las sumas se agrupan en otro orden, el resultado difiere del secuencial en el redondeo
(max|dif| ≈ 2.873e-07 con `double`): **se compara con tolerancia, no con `==`.**

### 1.3 *Stencil* de Jacobi con doble búfer

```c
while (iter < max_iter && diff >= tol) {
    diff = 0.0;
    #pragma omp parallel for reduction(max:diff)
    for (long i = 1; i < n - 1; i++) {
        u_new[i] = 0.5 * (u[i-1] + u[i+1]);        /* lee solo de u, escribe solo en u_new */
        double d = fabs(u_new[i] - u[i]);
        if (d > diff) diff = d;
    }
    double *tmp = u; u = u_new; u_new = tmp;       /* intercambio de punteros, O(1): no se copia nada */
    iter++;
}
```

Tres cosas que observar. (1) Como ninguna iteración lee lo que otra escribe en el mismo paso, el reparto entre
hilos es libre y el resultado es **idéntico** al secuencial: la misma aritmética por punto y un `max`, que no
depende del orden. (2) El número de iteraciones también es idéntico. (3) Cada iteración es una región paralela
(reparto + barrera + combinación del `max`): con `n` pequeño ese costo fijo supera el trabajo y el paralelo
pierde; con `n` grande gana hasta que lo frena el ancho de banda de memoria. Este mismo código es la base de la
Práctica 5 (Jacobi con MPI e intercambio de halos) y de la V2 de varios proyectos.

### 1.4 *Pipeline* (solo panorama)

```
paso →        1     2     3     4     5     6
leer         D1    D2    D3    D4
procesar           D1    D2    D3    D4
escribir                 D1    D2    D3    D4
```

Tres etapas, cada una en un hilo. Lleno el *pipeline*, sale un dato por paso: el *speedup* máximo es el número
de etapas y lo limita la etapa más lenta. En OpenMP se programa con tareas y cláusulas `depend`; en MPI
(Unidad IV) cada etapa es un proceso que recibe, procesa y envía. No lo programarás hoy; sí debes reconocerlo.

## 2. Vectorización: `#pragma omp simd`

**Qué es.** Una instrucción SIMD opera sobre varios datos a la vez (SSE2: 16 bytes = 4 `float` o 2 `double`;
AVX2: 32 bytes; AVX-512: 64). Es paralelismo **dentro de un núcleo**, distinto del paralelismo entre hilos; se
combinan: `#pragma omp parallel for simd` reparte el ciclo entre hilos y vectoriza el trozo de cada uno.

**Qué hace la directiva.** `#pragma omp simd` no es una petición: es una **promesa** de que las iteraciones son
independientes (y de que las reducciones que declares se combinan al final). El compilador deja de analizar
dependencias y aliasing y vectoriza. Si la promesa es falsa (`a[i] = a[i-1] + …`), el resultado queda mal sin
aviso.

**Cómo saber qué pasó.** Compila con `-fopt-info-vec-optimized -fopt-info-vec-missed` (o `make report`).
Cada línea trae `archivo:línea:columna`:

```
vec_kernels.c:34:21: optimized: loop vectorized using 16 byte vectors      ← saxpy_simd
vec_kernels.c:18:24: missed: couldn't vectorize loop                       ← saxpy_plain (sin restrict)
vec_kernels.c:25:24: missed: couldn't vectorize loop                       ← saxpy_restrict
vec_kernels.c:41:24: missed: couldn't vectorize loop                       ← prefix_dep (a[i-1])
```

Por qué falla cada uno (el detalle está en `-fdump-tree-vect-details`, que escribe un archivo `*.vect`):

| Ciclo | Razón real | Qué la quita |
|---|---|---|
| `saxpy_plain` | `versioning for alias required`: `x` e `y` podrían traslaparse; a `-O2` GCC 13 usa el modelo de costo *very-cheap*, que no agrega la comprobación de aliasing en tiempo de ejecución | `restrict`, o `omp simd`, o `-O3` |
| `saxpy_restrict` | `some scalar iterations would need to be peeled … not worthwhile`: `n` no es múltiplo del ancho del vector y *very-cheap* no genera epílogo | `omp simd`, o `-O3`, o `-fvect-cost-model=dynamic` |
| `prefix_dep` | `possible dependence between data-refs`, distancia 1: dependencia acarreada | Cambiar el algoritmo (*scan* en dos fases); **no** `omp simd` |

**Alineación.** Las cargas vectoriales prefieren direcciones múltiplo de 16/32/64 bytes; `malloc` solo
garantiza 16. Con `aligned_alloc(64, bytes)` y la cláusula `aligned(x,y:64)` el compilador omite el prólogo
de alineación. A `-O2` el efecto suele ser pequeño; se mide.

**Cuánto se gana.** saxpy (`y = a·x + y`) hace 2 flops por 12 bytes movidos: está limitado por memoria. En la
máquina de autoría, con los datos en L1 la versión `simd` fue 2.48× más rápida que la escalar (SSE2:
4 `float` por instrucción, así que 4× es el techo); en L2, 2.44×; con los datos en RAM, 1.33×.
**La vectorización acelera el cómputo, no el ancho de banda**: si el ciclo espera a la memoria, vectorizarlo
cambia poco.

**"Vectorizado" no significa "más rápido".** En Jacobi con la reducción `max` dentro del ciclo, `parallel for
simd` vectoriza (lo dice el reporte) y no gana nada: 1 hilo, 0.2766 s sin `simd` frente a
0.3067 s con `simd` (`n = 100000`, arreglos en L2). La razón está en el ensamblador
(`objdump -d jacobi1d | grep maxpd`): GCC 13 guarda el acumulador del máximo en la pila (`maxpd (%rsp)` …
`movaps %xmm0,(%rsp)`), y esa cadena de dependencia cuesta lo mismo que el `maxsd` escalar. Si se revisa la
convergencia cada 10 iteraciones (`check_every = 10`), el ciclo de actualización puro sí se beneficia:
0.1744 s → 0.1415 s con 1 hilo (×1.23) y 0.0728 s → 0.0368 s
con 4 hilos (×1.98). Lejos del 4× de saxpy en L1: el *stencil* mueve 24 bytes por punto (dos lecturas y una
escritura de `double`) y hace 2 flops. Con `n` de millones, en RAM, la ganancia casi desaparece.

## 3. Errores frecuentes

1. Comparar el resultado paralelo con `==` cuando hay sumas en punto flotante (idea errónea 10). Usa
   tolerancia relativa al valor más grande; con enteros y `max`/`min` sí exige igualdad.
2. Suponer que 4 hilos son más rápidos sin mirar el trabajo por región paralela (idea 1). Jacobi con
   `n = 64`: 9626 regiones paralelas de 62 puntos; pierde contra el secuencial.
3. `atomic`/`critical` por elemento en una reducción sobre arreglo: contención y falso compartido (idea 14).
4. Poner `#pragma omp simd` a un ciclo con `a[i-1]` "para ver si vectoriza": vectoriza y da resultados
   incorrectos. La directiva es una promesa.
5. Leer y escribir el **mismo** arreglo en el *stencil* ("Gauss-Seidel sin querer"): el resultado depende del
   orden de los hilos. Doble búfer.
6. Copiar `u_new` a `u` con un ciclo en cada iteración en vez de intercambiar punteros: duplica el tráfico de
   memoria.
7. Confundir "el compilador no vectorizó" con "no se puede vectorizar": a `-O2` el modelo de costo es
   conservador. Lee el reporte antes de concluir.
8. Confundir "loop vectorized" con "más rápido". La ganancia la limita la dependencia más larga del ciclo
   (en Jacobi, el máximo) o el ancho de banda. Se mide; si no gana, se busca por qué.

## 4. Para saber más

- OpenMP Architecture Review Board, *OpenMP API Specification*, versión 5.2 (openmp.org): secciones del
  constructo `simd` (cláusulas `safelen`, `aligned`, `reduction`), de la cláusula `reduction` (incluye
  secciones de arreglo) y del constructo `parallel for simd`.
- GCC 13 Manual, "Options That Control Optimization": `-ftree-vectorize`, `-fvect-cost-model`, `-fopt-info`,
  `-fdump-tree-vect`; y "Restricted Pointers" (`restrict`).
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022:
  capítulo 2 (SIMD y taxonomía de Flynn; jerarquía de memoria y caché) y capítulo 5 (OpenMP: reducciones,
  alcance de variables, `parallel for`, rendimiento).
