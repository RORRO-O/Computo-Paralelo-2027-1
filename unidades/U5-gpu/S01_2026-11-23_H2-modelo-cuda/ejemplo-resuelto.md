> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Ejemplo resuelto · Suma de vectores en CUDA C (y su espejo en Numba)

Lee el código con las pausas. En cada pausa, contesta en voz baja (o por escrito) **antes** de abrir la respuesta.
El archivo completo, con medición por `cudaEvent_t` y salida CSV, está en `practica-guiada/vector_add.cu`; aquí va
la versión mínima que muestra el modelo.

## Problema

Dados dos vectores `a` y `b` de `n = 16 777 216` (2^24) `float`, calcular `c[i] = a[i] + b[i]` en la GPU, verificar
el resultado contra la CPU y liberar todo. Cada vector ocupa 64 MB.

## Plan en 3 líneas

1. El **anfitrión** (CPU) llena `a` y `b`, reserva memoria en el **dispositivo** (GPU) y copia `a` y `b` hacia allá.
2. Lanza un ***kernel*** con suficientes bloques de hilos para cubrir `n`; cada hilo calcula **un** elemento.
3. Copia `c` de regreso, lo compara con la suma hecha en la CPU y libera la memoria de ambos lados.

## Código comentado

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>

/* Toda llamada a la API regresa un cudaError_t; esta macro lo revisa y dice en qué línea falló. */
#define CUDA_CHECK(call) do { cudaError_t e__ = (call); if (e__ != cudaSuccess) {                 \
    fprintf(stderr, "Error de CUDA en %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e__)); \
    exit(EXIT_FAILURE); } } while (0)

/* (1) Código de DISPOSITIVO: esta función la ejecutan miles de hilos a la vez. */
__global__ void vector_add(const float *a, const float *b, float *c, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;   /* (2) índice global de este hilo */
    if (i < n)                                       /* (3) guardia */
        c[i] = a[i] + b[i];
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    int block = 256;                                 /* hilos por bloque */
    int grid = (n + block - 1) / block;              /* (4) bloques: división redondeada hacia arriba */
    size_t bytes = (size_t)n * sizeof(float);

    /* --- Anfitrión --- */
    float *h_a = (float *)malloc(bytes), *h_b = (float *)malloc(bytes);
    float *h_c = (float *)malloc(bytes), *h_ref = (float *)malloc(bytes);
    for (int i = 0; i < n; i++) { h_a[i] = (float)(i % 7); h_b[i] = (float)(i % 13); }

    /* --- Dispositivo: la GPU tiene SU propia memoria --- */
    float *d_a, *d_b, *d_c;
    CUDA_CHECK(cudaMalloc((void **)&d_a, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_b, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_c, bytes));
    CUDA_CHECK(cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice));   /* (5) H2D */
    CUDA_CHECK(cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice));

    vector_add<<<grid, block>>>(d_a, d_b, d_c, n);   /* lanzamiento: regresa de inmediato */
    CUDA_CHECK(cudaGetLastError());                  /* (6) ¿el lanzamiento fue válido? */
    CUDA_CHECK(cudaDeviceSynchronize());             /* (6) ¿la ejecución terminó sin falla? */

    CUDA_CHECK(cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost));   /* (5) D2H */

    /* (7) Verificación contra la CPU */
    for (int i = 0; i < n; i++) h_ref[i] = h_a[i] + h_b[i];
    double max_abs_err = 0.0;
    for (int i = 0; i < n; i++) {
        double d = fabs((double)h_c[i] - (double)h_ref[i]);
        if (d > max_abs_err) max_abs_err = d;
    }
    printf("n=%d block=%d grid=%d max_abs_err=%g verificacion=%s\n",
           n, block, grid, max_abs_err, (max_abs_err <= 1e-5) ? "OK" : "FALLA");

    CUDA_CHECK(cudaFree(d_a)); CUDA_CHECK(cudaFree(d_b)); CUDA_CHECK(cudaFree(d_c));
    free(h_a); free(h_b); free(h_c); free(h_ref);
    return 0;
}
```

Compila en Colab con `nvcc -O2 -arch=sm_75 ejemplo.cu -o ejemplo`; sin GPU, `nvcc -c -arch=sm_75 ejemplo.cu` solo
comprueba que compila (así se verificó este texto).

## Salida

**Real, sin GPU** (mismo *kernel* en Numba bajo el simulador, y la referencia en C; obtenidas al escribir este material):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 practica-guiada/vector_add_numba.py 1000 256
vector_add_numba: n=1000 block=256 grid=4 hilos_lanzados=1024 modo=CUDASIM
kernel_mediana_ms=269.7073 (min 243.3690, max 293.9053)
checksum=8991.0 max_abs_err=0 verificacion=OK

$ ./practica-guiada/vector_add_cpu
vector_add_cpu: n=16777216 reps=5 mediana_ms=18.0454 (min 17.8284, max 18.2549)  ancho_banda_efectivo_GB_s=11.2
checksum=150994935.0 max_abs_err=0 verificacion=OK
```

**Esperada en la GPU** (no ejecutada en el entorno de autoría; una T4 de Colab; el tiempo depende de la GPU asignada):

```
$ ./ejemplo
n=16777216 block=256 grid=65536 max_abs_err=0 verificacion=OK
```

Con la versión completa (`vector_add.cu`), además: `kernel_mediana_ms ≈ 0.8–1.0`, `con_copias_mediana_ms ≈ 30–60`,
`ancho_banda_efectivo_GB_s ≈ 200–250`. Compara con los 18 ms de un núcleo de CPU: el *kernel* es ~20 veces más
rápido, pero **con las copias** la GPU pierde. Ese tema es de la S04 (lunes 30 de noviembre).

## Pausas de autoexplicación

**(1) ¿Por qué `__global__` y por qué la función regresa `void`?**
<details><summary>Respuesta</summary>
`__global__` marca un <em>kernel</em>: se llama desde el anfitrión y se ejecuta en el dispositivo. No puede regresar
valores porque el lanzamiento es asíncrono (el anfitrión sigue antes de que el <em>kernel</em> termine); los
resultados salen por memoria del dispositivo. Las funciones auxiliares que solo corren en la GPU se marcan
<code>__device__</code>.
</details>

**(2) ¿Por qué `i = blockIdx.x * blockDim.x + threadIdx.x` y no simplemente `i = threadIdx.x`?**
<details><summary>Respuesta</summary>
<code>threadIdx.x</code> reinicia en 0 en cada bloque: con 65 536 bloques habría 65 536 hilos "número 3" y todos
escribirían <code>c[3]</code>. <code>blockIdx.x * blockDim.x</code> es el desplazamiento del bloque dentro de la
malla. El hilo 3 del bloque 2 con bloques de 256 calcula <code>i = 2·256 + 3 = 515</code>.
</details>

**(3) Si `grid` ya se calculó bien, ¿para qué sirve la guardia `if (i < n)`?**
<details><summary>Respuesta</summary>
<code>grid · block ≥ n</code>, con igualdad solo si <code>n</code> es múltiplo de <code>block</code>. Con
<code>n = 1000</code> y <code>block = 256</code> se lanzan 1024 hilos; los 24 últimos tienen
<code>i = 1000…1023</code> y, sin guardia, leerían y escribirían fuera de los arreglos. La guardia es lo único que
los detiene. No es opcional: solo se omite cuando <code>n</code> es múltiplo exacto <strong>y está garantizado</strong>.
</details>

**(4) ¿Por qué `(n + block - 1) / block` y no `n / block`?**
<details><summary>Respuesta</summary>
La división entera trunca: <code>1000 / 256 = 3</code> bloques = 768 hilos, y los elementos 768…999 nunca se
calculan. Sumar <code>block - 1</code> antes de dividir redondea hacia arriba: <code>1255 / 256 = 4</code>. Es la
misma técnica que usaste en MPI para repartir <code>n</code> elementos entre <code>p</code> procesos cuando no divide
exacto.
</details>

**(5) ¿Por qué hay que copiar con `cudaMemcpy`? ¿No puede la CPU leer `d_c` directamente?**
<details><summary>Respuesta</summary>
No. La GPU tiene su propia memoria con su propio espacio de direcciones; <code>d_c</code> es un apuntador que solo
tiene sentido en el dispositivo. Desreferenciarlo en el anfitrión da una violación de segmento. Es el mismo
principio que en MPI (Unidad IV): dos espacios de memoria separados, todo intercambio es una transferencia
explícita. Esas transferencias cuestan y se miden (protocolo: "con y sin copias").
</details>

**(6) ¿Por qué `cudaGetLastError()` y además `cudaDeviceSynchronize()`? ¿No basta uno?**
<details><summary>Respuesta</summary>
Detectan cosas distintas. <code>cudaGetLastError()</code> justo después de <code>&lt;&lt;&lt;…&gt;&gt;&gt;</code>
reporta errores de <strong>lanzamiento</strong> (configuración inválida: <code>block = 2000</code> excede el máximo
de 1024). Los errores de <strong>ejecución</strong> (acceso ilegal a memoria) ocurren después, de forma asíncrona, y
solo aparecen en la siguiente llamada que sincroniza: <code>cudaDeviceSynchronize()</code> o un
<code>cudaMemcpy</code>. Sin esa sincronización, el error se atribuye a una línea que no tiene la culpa.
</details>

**(7) Si CUDA no reportó ningún error, ¿para qué comparar contra la CPU?**
<details><summary>Respuesta</summary>
Porque "sin error" no significa "correcto" (idea errónea 27). CUDA no sabe qué resultado esperabas: un
<em>kernel</em> con muy pocos bloques termina limpio y deja elementos sin calcular; uno sin guardia puede escribir
fuera del arreglo sin que nadie se queje. La única evidencia de correctitud es una referencia independiente (aquí,
la CPU) y una tolerancia declarada.
</details>

## Variantes que fallan

**Variante A: `grid = n / block`.** Con `n = 1000`, 3 bloques. Ejecutada realmente bajo CUDASIM (forzando `grid = 3`):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 practica-guiada/vector_add_numba.py 1000 256 3
vector_add_numba: n=1000 block=256 grid=3 hilos_lanzados=768 modo=CUDASIM
checksum=6901.0 max_abs_err=18 verificacion=FALLA
```

Ningún error de CUDA. `max_abs_err = 18` porque el mayor `a[i] + b[i]` es `6 + 12` y esos elementos quedaron en 0.
La diferencia de `checksum` (8991 − 6901 = 2090) es la suma de los 232 elementos no calculados. Sin la comparación
contra la CPU, este programa "funciona".

**Variante B: sin guardia.** Ejecutada bajo CUDASIM (el hilo que falla primero puede variar):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 practica-guiada/vector_add_numba.py 1000 256 0 --sin-guardia
…
IndexError: tid=[237, 0, 0] ctaid=[3, 0, 0]: index 1005 is out of bounds for axis 0 with size 1000
```

El simulador usa arreglos de NumPy y detecta el acceso. En la GPU (esperado, no ejecutado aquí) los 24 hilos
sobrantes escriben 96 bytes después del final de `d_c`; como `cudaMalloc` redondea las reservas, lo más probable
es que no haya error y la verificación pase. Sigue siendo un error: con `grid = 4000` la escritura sale de la memoria
reservada y `cudaDeviceSynchronize` regresa `an illegal memory access was encountered`.

## El mismo *kernel* en Numba

```python
from numba import cuda

@cuda.jit
def vector_add(a, b, c, n):
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x   # o cuda.grid(1)
    if i < n:
        c[i] = a[i] + b[i]

d_a = cuda.to_device(a); d_b = cuda.to_device(b); d_c = cuda.to_device(c)   # cudaMalloc + cudaMemcpy H2D
vector_add[grid, block](d_a, d_b, d_c, n)                                    # <<<grid, block>>>
cuda.synchronize()                                                            # cudaDeviceSynchronize
d_c.copy_to_host(c)                                                           # cudaMemcpy D2H
```

Numba compila el *kernel* la primera vez que se lanza (JIT): por eso la primera ejecución tarda más y el protocolo
exige calentamiento. Con `NUMBA_ENABLE_CUDASIM=1` el *kernel* se simula en la CPU: sirve para verificar índices y
guardias sin GPU, no para medir tiempo.

## Qué te llevas

- Un hilo por elemento; el índice global combina bloque e hilo; los bloques se calculan redondeando hacia arriba;
  la guardia protege el último bloque.
- Dos espacios de memoria: todo cruza por `cudaMemcpy`, y esas copias se miden.
- Dos verificaciones de error (lanzamiento y ejecución) **más** una comparación contra la CPU. Ninguna sustituye a
  las otras.
