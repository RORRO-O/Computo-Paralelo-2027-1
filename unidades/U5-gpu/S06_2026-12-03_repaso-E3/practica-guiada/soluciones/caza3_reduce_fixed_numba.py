#!/usr/bin/env python3
"""caza3_reduce_fixed_numba.py — Solución del cazador 3 en Numba (espejo de soluciones/caza3_reduce_fixed.cu).

Uso: NUMBA_ENABLE_CUDASIM=1 python3 soluciones/caza3_reduce_fixed_numba.py [n] [block]
El único cambio respecto a caza3_reduce_numba.py es cuda.syncthreads() al final de cada nivel del árbol,
fuera del if: todo el bloque llega a la barrera antes de leer el siguiente nivel.
"""
import os
import sys
import time

import numpy as np
from numba import cuda, float32

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 1 if CUDASIM else 5     # en el simulador el tiempo no significa nada: una sola ejecución
BLOCK = 256     # tamaño máximo de bloque: la memoria compartida se reserva con este tamaño


@cuda.jit
def block_sum(x, partial, n):
    s = cuda.shared.array(BLOCK, float32)
    tid = cuda.threadIdx.x
    i = cuda.blockIdx.x * cuda.blockDim.x + tid
    s[tid] = x[i] if i < n else 0.0           # carga con guardia; los sobrantes aportan 0
    cuda.syncthreads()                        # todo el bloque terminó de cargar
    stride = cuda.blockDim.x // 2
    while stride > 0:
        if tid < stride:
            s[tid] += s[tid + stride]         # nivel del árbol: la mitad baja suma a la alta
        cuda.syncthreads()                    # nadie lee el siguiente nivel hasta que todos sumaron
        stride //= 2
    if tid == 0:
        partial[cuda.blockIdx.x] = s[0]       # suma parcial del bloque


def median(values):
    return sorted(values)[len(values) // 2]


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    block = int(sys.argv[2]) if len(sys.argv) > 2 else BLOCK
    if n <= 0 or block <= 0 or block > BLOCK or (block & (block - 1)) != 0:
        print(f"uso: caza3_reduce_numba.py [n>0] [block: potencia de 2, <= {BLOCK}]")
        sys.exit(1)
    if CUDASIM and n > 20000:
        print("aviso: CUDASIM con n > 20000 tarda minutos", file=sys.stderr)
    grid = (n + block - 1) // block

    h_x = (np.arange(n) % 10 + 1).astype(np.float32)
    ref = float(np.sum(h_x, dtype=np.float64))
    h_partial = np.zeros(grid, dtype=np.float32)

    d_x = cuda.to_device(h_x)
    d_partial = cuda.to_device(h_partial)

    # Protocolo: 1 calentamiento + 5 repeticiones; solo el kernel.
    if not CUDASIM:                          # calentamiento (incluye el JIT en GPU real)
        block_sum[grid, block](d_x, d_partial, n)
        cuda.synchronize()
    times_ms = []
    for _ in range(REPS):
        t0 = time.perf_counter()
        block_sum[grid, block](d_x, d_partial, n)
        cuda.synchronize()
        times_ms.append((time.perf_counter() - t0) * 1e3)
    d_partial.copy_to_host(h_partial)

    # El anfitrión termina la reducción (segunda etapa) y verifica contra NumPy.
    total = float(np.sum(h_partial, dtype=np.float64))
    ok = abs(total - ref) <= 1e-6 * abs(ref)
    modo = "CUDASIM" if CUDASIM else "GPU"

    print(f"caza3: n={n} block={block} grid={grid} modo={modo}")
    if grid <= 8:
        print("parciales_gpu=" + ",".join(f"{p:.1f}" for p in h_partial))
    print(f"suma_gpu={total:.1f} suma_cpu={ref:.1f}")
    print(f"t_kernel_ms={median(times_ms):.4f} (mediana de {REPS}, solo kernel)")
    print(f"verificacion={'OK' if ok else 'FALLA'}")
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
