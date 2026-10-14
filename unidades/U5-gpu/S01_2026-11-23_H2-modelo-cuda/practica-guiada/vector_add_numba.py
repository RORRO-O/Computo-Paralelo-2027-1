#!/usr/bin/env python3
"""vector_add_numba.py — Espejo en Numba CUDA del kernel de vector_add.cu.

Uso:
    python3 vector_add_numba.py [n] [block] [grid] [--sin-guardia]
Sin GPU (simulador en CPU, solo correctitud; n pequeño):
    NUMBA_ENABLE_CUDASIM=1 python3 vector_add_numba.py 1000 256

Mismo índice global, misma guardia, misma inicialización y mismo checksum que la versión en C.
En GPU real el tiempo incluye una compilación JIT la primera vez; por eso hay calentamiento.
"""
import os
import sys
import time

import numpy as np
from numba import cuda

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 5


@cuda.jit
def vector_add(a, b, c, n):
    # Índice global igual que en CUDA C. (cuda.grid(1) es la abreviatura equivalente.)
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:  # guardia
        c[i] = a[i] + b[i]


@cuda.jit
def vector_add_sin_guardia(a, b, c, n):
    # Variante deliberadamente incorrecta: los hilos sobrantes escriben fuera del arreglo.
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    c[i] = a[i] + b[i]


def median(values):
    return sorted(values)[len(values) // 2]


def main():
    flags = [x for x in sys.argv[1:] if x.startswith("--")]
    args = [x for x in sys.argv[1:] if not x.startswith("--")]
    sin_guardia = "--sin-guardia" in flags

    # Bajo CUDASIM cada hilo se simula en Python: con n grande tardaría minutos.
    default_n = 2048 if CUDASIM else 1 << 24
    n = int(args[0]) if len(args) > 0 else default_n
    block = int(args[1]) if len(args) > 1 else 256
    grid = int(args[2]) if len(args) > 2 else 0
    if n <= 0 or block <= 0 or block > 1024:
        print("uso: vector_add_numba.py [n>0] [block 1..1024] [grid; 0=auto] [--sin-guardia]")
        sys.exit(1)
    if grid <= 0:
        grid = (n + block - 1) // block  # división entera redondeada hacia arriba

    modo = "CUDASIM" if CUDASIM else "GPU"
    if CUDASIM and n > 20000:
        print("aviso: CUDASIM con n > 20000 puede tardar varios minutos", file=sys.stderr)

    # Anfitrión: misma inicialización que vector_add.cu / vector_add_cpu.c
    a = (np.arange(n) % 7).astype(np.float32)
    b = (np.arange(n) % 13).astype(np.float32)
    c = np.zeros(n, dtype=np.float32)

    # Dispositivo: equivalentes de cudaMalloc + cudaMemcpy H2D
    d_a = cuda.to_device(a)
    d_b = cuda.to_device(b)
    d_c = cuda.to_device(c)

    kernel = vector_add_sin_guardia if sin_guardia else vector_add

    # Calentamiento (en GPU real incluye la compilación JIT del kernel)
    kernel[grid, block](d_a, d_b, d_c, n)
    cuda.synchronize()

    times_ms = []
    for _ in range(REPS):
        t0 = time.perf_counter()
        kernel[grid, block](d_a, d_b, d_c, n)
        cuda.synchronize()  # el lanzamiento es asíncrono: sin esto se mide casi nada
        times_ms.append((time.perf_counter() - t0) * 1e3)

    d_c.copy_to_host(c)  # equivalente de cudaMemcpy D2H

    # Verificación contra la CPU (NumPy): "sin error" no significa "correcto"
    ref = a + b
    max_abs_err = float(np.max(np.abs(c - ref)))
    checksum = float(np.sum(c, dtype=np.float64))
    ok = max_abs_err <= 1e-5

    print(f"vector_add_numba: n={n} block={block} grid={grid} hilos_lanzados={grid * block} modo={modo}")
    print(f"kernel_mediana_ms={median(times_ms):.4f} (min {min(times_ms):.4f}, max {max(times_ms):.4f})")
    print(f"checksum={checksum:.1f} max_abs_err={max_abs_err:.3g} verificacion={'OK' if ok else 'FALLA'}")
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
