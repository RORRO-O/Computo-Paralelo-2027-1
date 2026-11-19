#!/usr/bin/env python3
"""main_numba.py — Espejo en Numba CUDA de la práctica guiada de GPU. PUNTO DE PARTIDA de /nueva-sesion.

Sustituye el kernel por el de la sesión; debe dar el mismo resultado que main_cpu.c con tolerancia.
Problema de relleno: SAXPY y[i] = a*x[i] + y[i] con x[i] = i mod 7, y[i] = 1, a = 2; se reporta la suma de y.

Uso:
    python3 main_numba.py [n] [hilos_por_bloque]              con GPU (Colab/Kaggle)
    NUMBA_ENABLE_CUDASIM=1 python3 main_numba.py 4096 64       sin GPU: simulador, solo correctitud, n pequeño

Salida: n=<valor>  resultado=<valor>  tiempo_kernel_s=<segundos>  tiempo_total_s=<segundos>  tiempo_s=<segundos>
tiempo_kernel_s no incluye transferencias; tiempo_total_s sí (H2D + kernel + D2H); tiempo_s = tiempo_total_s.
En el simulador los tiempos no significan nada: no se reportan como medición.
"""
import sys
import time

import numpy as np
from numba import cuda

DEFAULT_N = 4_000_000
DEFAULT_BLOCK = 256


@cuda.jit
def saxpy_kernel(a, x, y):
    i = cuda.grid(1)
    if i < y.size:  # guarda de límites: el grid se redondea hacia arriba
        y[i] = a * x[i] + y[i]


def main(argv):
    try:
        n = int(argv[1]) if len(argv) > 1 else DEFAULT_N
        block = int(argv[2]) if len(argv) > 2 else DEFAULT_BLOCK
        if n <= 0 or block <= 0:
            raise ValueError
    except ValueError:
        print(f"uso: {argv[0]} [n] [hilos_por_bloque]   (enteros positivos)", file=sys.stderr)
        return 2

    x = (np.arange(n) % 7).astype(np.float32)
    y = np.ones(n, dtype=np.float32)
    blocks = (n + block - 1) // block  # grid redondeado hacia arriba

    t0 = time.perf_counter()
    d_x = cuda.to_device(x)
    d_y = cuda.to_device(y)
    cuda.synchronize()
    t1 = time.perf_counter()
    saxpy_kernel[blocks, block](np.float32(2.0), d_x, d_y)
    cuda.synchronize()
    t2 = time.perf_counter()
    result = d_y.copy_to_host()
    t3 = time.perf_counter()

    print(f"n={n}")
    print(f"resultado={float(result.astype(np.float64).sum()):.1f}")
    print(f"tiempo_kernel_s={t2 - t1:.6f}")
    print(f"tiempo_total_s={t3 - t0:.6f}")
    print(f"tiempo_s={t3 - t0:.6f}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
