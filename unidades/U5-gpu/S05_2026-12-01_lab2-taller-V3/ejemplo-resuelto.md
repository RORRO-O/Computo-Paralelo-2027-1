> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Ejemplo resuelto · De la V2 (OpenMP) a la V3 (CUDA): portar el paso de Jacobi 2D en seis pasos

El código completo está en `practica-guiada/flatten_map_2d.cu` (y su espejo `flatten_map_numba.py`). Aquí se
recorre en el orden en que se toma cada decisión. En clase el profesor lo piensa en voz alta; tú responde cada
pausa **antes** de abrirla.

## Problema

Un equipo tiene una V2 de difusión de calor en OpenMP: una malla de `h × w` floats; en cada paso, cada celda
interior toma el promedio de sus cuatro vecinas; la frontera no cambia. Quiere la V3 en GPU, verificada contra
la V1 y medida con el protocolo del curso.

## Plan en tres líneas

1. Portar **solo** el ciclo caliente (el paso de Jacobi); dejar lectura, inicialización y escritura en CPU.
2. Aplanar la malla a un arreglo 1D, mapear un hilo por celda con una malla 2D de bloques, subir los datos una vez.
3. Verificar contra la V1 con tolerancia y medir con y sin transferencias, 5 repeticiones, mediana.

## Paso 1 · Identificar el *kernel* candidato

Fragmento de la V2 (compila con `gcc -std=c11 -O2 -Wall -Wextra -fopenmp`):

```c
float **cur, **nxt;                      /* cur[r][c]: cada fila con su propio malloc */
for (int it = 0; it < iters; it++) {
    #pragma omp parallel for collapse(2) schedule(static)
    for (int r = 1; r < h - 1; r++)
        for (int c = 1; c < w - 1; c++)
            nxt[r][c] = 0.25f * (cur[r-1][c] + cur[r+1][c] + cur[r][c-1] + cur[r][c+1]);
    float **t = cur; cur = nxt; nxt = t;  /* ping-pong */
}
```

El perfilado de la V1 (H1) decía que este ciclo era > 95 % del tiempo. Es el candidato: cada `nxt[r][c]` depende
solo de `cur` (del paso anterior), no hay dos iteraciones que escriban la misma posición, y el trabajo por celda es
idéntico. Amdahl: si el 5 % restante queda en CPU, el *speedup* total no pasa de 20, haga lo que haga la GPU.

## Paso 2 · Aplanar

`float **` es un arreglo de punteros a filas que viven en direcciones distintas del anfitrión. Una sola `cudaMemcpy`
copia un bloque contiguo de bytes; copiar `cur` copiaría **punteros del anfitrión**, inválidos en la GPU.

```c
float *grid = malloc((size_t)h * w * sizeof(float));   // h*w floats contiguos, fila tras fila
// (r, c)  ->  grid[r * w + c]          r = idx / w,  c = idx % w
```

Vecinos de `idx`: `idx - w` (arriba), `idx + w` (abajo), `idx - 1`, `idx + 1`.

**Pausa 1.** ¿Por qué no basta con hacer `cudaMemcpy(d_grid, cur, h * sizeof(float *), ...)`?

<details><summary>Respuesta</summary>
Porque eso copia `h` punteros (direcciones de memoria del anfitrión), no los `h·w` floats. En la GPU esas direcciones no apuntan a nada válido: el primer acceso es un <code>illegal memory access</code> o, peor, lee basura sin error. La alternativa de copiar fila por fila (h copias) funciona pero paga h veces la latencia de PCIe; con h = 2048 son miles de transferencias pequeñas. Aplanar resuelve las dos cosas con una copia.
</details>

## Paso 3 · Mapear: un hilo por celda, malla 2D

```c
__global__ void jacobi_step_2d(const float *in, float *out, int height, int width, ...)
{
    int c = blockIdx.x * blockDim.x + threadIdx.x;   // columna: x recorre lo contiguo
    int r = blockIdx.y * blockDim.y + threadIdx.y;   // fila
    if (r >= height || c >= width) return;           // guardia: hilos sobrantes del último bloque
    int idx = r * width + c;
    if (r == 0 || r == height - 1 || c == 0 || c == width - 1) { out[idx] = in[idx]; return; }
    out[idx] = 0.25f * (in[idx - width] + in[idx + width] + in[idx - 1] + in[idx + 1]);
}
// lanzamiento:
dim3 block(16, 16);
dim3 grid((width + 15) / 16, (height + 15) / 16);    // ceil en x (columnas) y en y (filas)
```

**Pausa 2.** ¿Por qué `threadIdx.x` recorre columnas y no filas? ¿Qué cambiaría en el rendimiento si se invierte?

<details><summary>Respuesta</summary>
Los 32 hilos de un <em>warp</em> tienen <code>threadIdx.x</code> consecutivos. Si x recorre columnas, el <em>warp</em> lee floats contiguos en memoria (acceso coalescido, S02): 16 floats = 64 bytes por fila del bloque. Si x recorriera filas, cada hilo del <em>warp</em> leería una dirección separada por <code>width·4</code> bytes: 32 transacciones en vez de 1 o 2. El resultado sería el mismo; el tiempo, varias veces mayor.
</details>

**Pausa 3.** Para 37 × 45 con bloques 16 × 16 se lanzan 3 × 3 bloques = 2304 hilos para 1665 celdas. ¿Qué escribe el hilo (15, 15) del bloque (2, 2) si se quita la guardia?

<details><summary>Respuesta</summary>
Calcula c = 2·16 + 15 = 47, r = 47, idx = 47·45 + 47 = 2162, fuera de un arreglo de 1665 floats. Como no es frontera (47 ≠ 0 y 47 ≠ 36), además <em>lee</em> <code>in[2162 ± 45]</code>. Es comportamiento indefinido: puede corromper el otro búfer (la verificación falla "sin error"), disparar <code>illegal memory access</code>, o no notarse. La guardia cuesta una comparación por hilo y evita las tres.
</details>

## Paso 4 · Mover datos una vez, no por iteración

```c
CUDA_CHECK(cudaMemcpy(d_a, h_init, bytes, cudaMemcpyHostToDevice));   // sube UNA vez
for (int it = 0; it < iters; it++) {
    jacobi_step_2d<<<grid, block>>>(d_a, d_b, h, w, ...);
    CUDA_CHECK(cudaGetLastError());
    std::swap(d_a, d_b);                                                // intercambia punteros, no datos
}
CUDA_CHECK(cudaMemcpy(h_out, d_a, bytes, cudaMemcpyDeviceToHost));    // baja UNA vez
```

El *kernel* escribe **todas** las celdas de `out` (la frontera se copia dentro), así que el segundo búfer ni
siquiera necesita inicializarse. Cada iteración lee de un búfer y escribe en el otro; sin eso habría una carrera:
un hilo leería un vecino ya actualizado por otro hilo en el mismo paso.

**Pausa 4.** El equipo propone, "para simplificar", `cudaMemcpy` de ida y vuelta en cada iteración y seguir usando
sus arreglos del anfitrión. ¿Cuántas veces más datos cruzan el PCIe con 100 iteraciones?

<details><summary>Respuesta</summary>
100 veces más en cada dirección: 100 subidas y 100 bajadas de la malla completa en lugar de una y una. Con 1024 × 1024 floats (4 MB) son 800 MB en lugar de 8 MB. A 3–6 GB/s (memoria paginable) eso es 150–300 ms de puras copias contra ~10 ms de <em>kernels</em>: la V3 pasa de ~30× a ~1× respecto a la V1. El programa reproduce esto con <code>copiar_cada_iter=1</code>.
</details>

## Paso 5 · Verificar contra la V1 con tolerancia

```c
CUDA_CHECK(cudaDeviceSynchronize());
CUDA_CHECK(cudaGetLastError());                      // errores de ejecución del kernel
float max_diff = 0.0f;
for (size_t i = 0; i < n; i++) max_diff = fmaxf(max_diff, fabsf(h_out[i] - h_ref[i]));
printf("verificacion vs CPU: %s (max |diff| = %.3e, tol = %.1e)\n", max_diff <= TOL ? "PASS" : "FAIL", ...);
```

`h_ref` lo produce la referencia secuencial (la V1) con la **misma aritmética en float**. La tolerancia (1e-4)
existe porque la GPU puede reordenar o fusionar operaciones; aquí la diferencia resultó ser 0, pero no se puede
exigir igualdad bit a bit en general (idea errónea 10, de la Unidad III, aplica igual).

**Pausa 5.** `cudaGetLastError()` y `cudaDeviceSynchronize()` regresan `cudaSuccess`. ¿Ya está correcta la V3?

<details><summary>Respuesta</summary>
No. Esas llamadas detectan errores de <em>lanzamiento</em> (bloque inválido) y de <em>ejecución</em> (acceso ilegal). No detectan un índice equivocado que cae dentro del arreglo, un vecino mal calculado, una guardia que descarta celdas válidas, ni un búfer que nunca se copió. Por eso la verificación compara con la V1. "El <em>kernel</em> no dio error" es necesario, no suficiente (idea errónea 27).
</details>

## Paso 6 · Medir con y sin transferencias

```c
cudaEventRecord(e_total0);
cudaMemcpy(... H2D ...);
cudaEventRecord(e_k0);
for (...) { kernel<<<...>>>; swap; }
cudaEventRecord(e_k1);
cudaEventSynchronize(e_k1);                      // sin esto, se mide el encolado
cudaEventElapsedTime(&ms_kernel, e_k0, e_k1);
cudaMemcpy(... D2H ...);
cudaEventRecord(e_total1);
cudaEventSynchronize(e_total1);
cudaEventElapsedTime(&ms_total, e_total0, e_total1);
```

Se hace una corrida de calentamiento que no se cuenta y luego 5 corridas; se reporta la mediana de cada tiempo. La
referencia CPU se mide igual (1 + 5, mediana).

**Pausa 6.** ¿Por qué los lanzamientos de *kernel* obligan a sincronizar antes de leer el reloj, si en OpenMP
bastaba con `omp_get_wtime()` después del ciclo?

<details><summary>Respuesta</summary>
Un lanzamiento <code>&lt;&lt;&lt;&gt;&gt;&gt;</code> es asíncrono: la CPU lo encola y sigue. Al final de un <code>parallel for</code> de OpenMP hay una barrera implícita; aquí no. Sin <code>cudaEventSynchronize</code> (o <code>cudaDeviceSynchronize</code>) el reloj se detiene microsegundos después de encolar 100 lanzamientos, y el "tiempo del <em>kernel</em>" sale absurdamente pequeño. Es la versión GPU de la idea errónea 5: medir mal y creer el número.
</details>

## Salidas

**Referencia CPU (real, máquina de autoría: 4 núcleos, gcc 13, `-O2`, sin GPU):**

```
$ ./flatten_map_cpu 1024 1024 100
# flatten_map_cpu · alto=1024 ancho=1024 iteraciones=100 (referencia secuencial)
indice lineal de (fila 3, col 5) con ancho 1024: 3077
checksum = 627403.109541
t_cpu (mediana de 5, s) = 0.204470   min = 0.143430   max = 0.230399
```

**Espejo Numba en CUDASIM (real, sin GPU), caso pequeño:**

```
$ NUMBA_ENABLE_CUDASIM=1 python3 flatten_map_numba.py 10 8 3 16 16 2d 0 3 5
indice lineal de (fila 3, col 5) con ancho 8: 29
malla 2D: bloques=1x1 hilos/bloque=16x16
hilos lanzados=256 celdas=80 hilos ociosos=176 (68.8 %)
hilo que la proceso: blockIdx=(0,0) threadIdx=(5,3) idx=29
verificacion vs CPU: PASS (max |diff| = 0.000e+00, tol = 1.0e-04)
checksum = 1128.125000
```

La referencia en C para los mismos argumentos da `checksum = 1128.125000`: tres implementaciones independientes
(C, NumPy, *kernel* simulado) coinciden.

**GPU (salida esperada, no ejecutada aquí; T4 de Colab, 1024 × 1024 × 100; los valores dependen de la GPU asignada):**

```
GPU: Tesla T4 (40 SMs, 1024 hilos máx. por bloque)
malla 2D: bloques=64x64 hilos/bloque=16x16
hilos lanzados=1048576 celdas=1048576 hilos ociosos=0 (0.0 %)
verificacion vs CPU: PASS (max |diff| <= 1e-4)
t_cpu    (mediana de 5, s) ≈ 0.3–0.6        (CPU de Colab)
t_kernel (mediana de 5, s) ≈ 0.005–0.015    <- solo kernels
t_total  (mediana de 5, s) ≈ 0.008–0.020    <- H2D + kernels + D2H
speedup sin transferencias ≈ 30–60
speedup con transferencias ≈ 20–40
```

Con `copiar_cada_iter=1`: `t_total ≈ 0.15–0.40 s` y *speedup* con transferencias ≈ 1–3. Mismo *kernel*, misma
verificación PASS, una V3 inútil.

## Variantes que fallan (y cómo se ven)

| Variante | Síntoma | Qué lo delata |
|---|---|---|
| Copiar en cada iteración | PASS, pero `t_total` 20–40× mayor que `t_kernel` | La columna "con transferencias" del protocolo |
| Sin guardia (`-DSIN_GUARDIA`) con 37 × 45 | FAIL sin error de CUDA, o `illegal memory access`, o nada | Probar un tamaño no múltiplo del bloque |
| Sin `cudaEventSynchronize` | `t_kernel` de microsegundos, *speedup* de miles | Un *speedup* mayor que el cociente de anchos de banda es sospechoso |
| Leer y escribir el mismo búfer | Resultado distinto entre corridas; a veces PASS | Repetir la verificación; razonar sobre lecturas y escrituras |
| Comparar contra la V2 con 1 hilo o con `-O0` | *Speedup* inflado | T(1) debe ser la V1 con `-O2` |

## Resumen: los seis pasos y dónde van en tu `plan-V3.md`

| Paso | Decisión | Sección de `plan-V3.md` |
|---|---|---|
| 1 | Ciclo caliente de la V2; Amdahl sobre lo que queda en CPU | 1 |
| 2 | Aplanar estructuras; fórmula de índice; bytes en GPU | 2 |
| 3 | Mapeo 1D/2D; bloque múltiplo de 32; `ceil`; guardia | 3, 4 |
| 4 | Qué sube una vez, qué baja una vez, qué se queda | 5 |
| 5 | Verificación contra la V1 con tolerancia, dos tamaños | 6 |
| 6 | Con y sin transferencias, 5 repeticiones, mediana, GPU declarada | 7 |
