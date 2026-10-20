> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Notas · Portar la V2 a GPU: aplanar, mapear, mover una vez, verificar, medir

## 1. La idea central

Una V3 no es "la V2 en otro lenguaje". Es **un *kernel* propio para el ciclo caliente** de la V2, con los datos
viviendo en la GPU mientras duran las iteraciones, verificado contra la V1 y medido con y sin transferencias.
Todo lo demás (leer archivos, inicializar, escribir resultados) se queda en la CPU, y la ley de Amdahl manda:
si ese resto es el 5 % del tiempo de la V1, el *speedup* total no pasa de 20 aunque el *kernel* tarde cero.

## 2. Seis pasos, con sus fórmulas

| Paso | Qué decides | Fórmulas y reglas |
|---|---|---|
| 1. Identificar | El ciclo que domina el perfil de la V1 (H1). Un elemento de salida por iteración, sin dependencias dentro del mismo paso | Si hay escrituras compartidas (reducción, histograma): atómicas o rediseño (S03) |
| 2. Aplanar | Toda estructura 2D pasa a un arreglo 1D contiguo | `idx = fila*ancho + col`; `fila = idx / ancho`; `col = idx % ancho`; vecinos `idx ± 1`, `idx ± ancho` |
| 3. Mapear | Un hilo por elemento; malla 1D o 2D; bloque múltiplo de 32 (≤ 1024) | 2D: `col = blockIdx.x*blockDim.x + threadIdx.x`, `fila = blockIdx.y*blockDim.y + threadIdx.y`; bloques = `ceil(ancho/bx) × ceil(alto/by)`; **guardia** `if (fila >= alto \|\| col >= ancho) return;` |
| 4. Mover una vez | Qué sube al inicio, qué baja al final, qué se queda | Entre iteraciones: intercambio de punteros (ping-pong), nunca `cudaMemcpy` |
| 5. Verificar | Comparar con la V1 (no con la V2) con tolerancia | `cudaGetLastError()` + `cudaDeviceSynchronize()` detectan errores, **no** resultados equivocados |
| 6. Medir | Protocolo: calentamiento, 5 repeticiones, mediana | `cudaEvent` con `cudaEventSynchronize` antes de leer; **dos** tiempos: solo *kernels* y con H2D/D2H; T(1) = V1 con `-O2`; GPU y fecha declaradas |

`threadIdx.x` recorre lo contiguo (columnas) para que un *warp* lea 32 floats seguidos (coalescencia, S02).

## 3. El ejemplo en diez líneas

Paso de Jacobi 2D (promedio de 4 vecinos; frontera fija; fila 0 = 100). Malla `alto × ancho` aplanada; *kernel* 2D
con bloques 16 × 16; ping-pong de dos búferes en la GPU; 100 iteraciones; verificación con tolerancia 1e-4.

- (fila 3, col 5) con ancho 8 → `idx = 29`; la procesa `blockIdx=(0,0) threadIdx=(5,3)`; en mapeo 1D con 256 hilos,
  `threadIdx.x = 29` del bloque 0. (Salida real en CUDASIM y en la referencia C: `checksum = 1128.125000` para 10 × 8 × 3.)
- 37 × 45 con 16 × 16 → 3 × 3 bloques, 2304 hilos lanzados, 1665 celdas, 639 ociosos (27.7 %); sin guardia, el hilo
  (15, 15) del bloque (2, 2) escribiría `idx = 2162` en un arreglo de 1665.
- 1024 × 1024 × 100: CPU 0.088 s (real: mediana de 5, máquina de revisión con 4 núcleos; en Colab se espera
  0.1–0.4 s). En una T4 se **esperan** ≈ 3–10 ms solo *kernels* y ≈ 5–15 ms con transferencias (no ejecutado aquí;
  depende de la GPU asignada). Copiando la malla en cada iteración: ≈ 150–400 ms. Mismo *kernel*, misma
  verificación, *speedup* con transferencias de varias decenas a ≈ 1×.

## 4. Qué cuenta como V3 (y qué no)

| Aceptado | No cuenta como V3 completa (y lo que cuesta en `proyecto/entrega-final/rubrica-codigo.md`) |
|---|---|
| CUDA C con `nvcc` | Llamar a `cupy.matmul`, `cv2.cuda`, `torch` o similar sin un *kernel* propio → C3 "En desarrollo" como máximo |
| Numba CUDA (`@cuda.jit`) | Una V3 que no se verifica contra la V1 con tolerancia declarada → C1 "En desarrollo" o menos |
| CuPy con `RawKernel` o `ElementwiseKernel` escrito por el equipo | Un solo tiempo, o solo el tiempo del *kernel*, o sin GPU/fecha → C4 "En desarrollo" o menos |
| Bibliotecas **alrededor** del *kernel* (subir datos, graficar) | Código que ningún integrante puede explicar línea por línea → prueba de propiedad en la defensa |

Ejemplo mínimo aceptado en CuPy (el *kernel* es tuyo; CuPy solo administra la memoria):

```python
import cupy as cp
step = cp.RawKernel(r'''
extern "C" __global__ void step(const float* in, float* out, int h, int w) {
    int c = blockIdx.x*blockDim.x + threadIdx.x, r = blockIdx.y*blockDim.y + threadIdx.y;
    if (r >= h || c >= w) return;
    int i = r*w + c;
    if (r == 0 || r == h-1 || c == 0 || c == w-1) { out[i] = in[i]; return; }
    out[i] = 0.25f*(in[i-w] + in[i+w] + in[i-1] + in[i+1]);
}''', 'step')
step(((w+15)//16, (h+15)//16), (16, 16), (d_in, d_out, h, w))
```

## 5. Errores frecuentes al portar

| Error | Cómo se ve | Idea errónea |
|---|---|---|
| Copiar en cada iteración | PASS, pero el tiempo total es decenas de veces el del *kernel* | 24: "las transferencias no cuentan" |
| Olvidar la guardia | PASS en tamaños múltiplos del bloque, FAIL o `illegal memory access` en los demás | 27: "sin error = correcto" |
| Escrituras compartidas sin atómica | Resultado cambia entre corridas; a veces coincide | 7 y 27 |
| Medir sin sincronizar | `t_kernel` de microsegundos, *speedup* de miles | 5: "medir una vez basta" |
| Medir sin calentamiento | La primera corrida incluye inicialización del contexto o JIT | 5 |
| Comparar contra la V2 con un hilo o contra `-O0` | *Speedup* inflado | Protocolo §3 |
| `x` recorriendo filas | Correcto pero varias veces más lento | 23: "la memoria global es tan rápida como la compartida" |
| Pensar un hilo = un núcleo | Lanzar "pocos hilos grandes" en lugar de uno por elemento | 22 |

## 6. Fechas que importan esta semana

- **P6** (Lab 2 hoy): entrega domingo 6 de diciembre, 23:59 (15 % del 3er parcial).
- **Entrega final del proyecto**: lunes 7 de diciembre, 10:30 (repositorio V1·V2·V3, 40 puntos; reporte PDF, 30 puntos).
  Rúbricas en `proyecto/entrega-final/`.
- **Examen 3** (Unidades IV–V): martes 8 de diciembre, 08:30–10:00. Repaso el jueves 3 de diciembre, 10:30 (S06).
- **Defensa oral**: jueves 10 de diciembre (15 puntos; preguntas individuales). Lista de cotejo en `proyecto/defensa/`.

## 7. Para saber más

- *CUDA C++ Programming Guide*, NVIDIA: "Programming Model → Thread Hierarchy" (índices 2D y `dim3`) y
  "Device Memory" (`cudaMalloc`/`cudaMemcpy`).
- *CUDA C++ Best Practices Guide*, NVIDIA: "Data Transfer Between Host and Device" (minimizar transferencias,
  memoria fija) y "Timing" (eventos y sincronización).
- Documentación de Numba CUDA: "Writing CUDA Kernels" (`cuda.grid`, `blockIdx`, `blockDim`) y "Memory management".
- Kirk y Hwu, *Programming Massively Parallel Processors*: cap. 3 (mallas multidimensionales y datos aplanados) y
  el capítulo de *stencil* (patrón de vecinos, ping-pong).
