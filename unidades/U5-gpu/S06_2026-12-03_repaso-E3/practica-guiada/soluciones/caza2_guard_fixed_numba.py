#!/usr/bin/env python3
"""caza2_guard_fixed_numba.py — Solución del cazador 2 en Numba (espejo de soluciones/caza2_guard_fixed.cu).

Uso: NUMBA_ENABLE_CUDASIM=1 python3 soluciones/caza2_guard_fixed_numba.py [n] [block]
El único cambio respecto a caza2_guard_numba.py es la guardia `if i < n:` dentro del kernel.
"""
import os
import sys
import time

import numpy as np
from numba import cuda

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 1 if CUDASIM else 5     # en el simulador el tiempo no significa nada: una sola ejecución


@cuda.jit
def axpb(x, y, a, b, n):
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x   # índice global del hilo
    if i < n:                                                  # guardia: los sobrantes no tocan memoria
        y[i] = a * x[i] + b


def median(values):
    return sorted(values)[len(values) // 2]


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    block = int(sys.argv[2]) if len(sys.argv) > 2 else 256
    if n <= 0 or block <= 0 or block > 1024:
        print("uso: caza2_guard_numba.py [n>0] [block 1..1024]")
        sys.exit(1)
    if CUDASIM and n > 20000:
        print("aviso: CUDASIM con n > 20000 tarda minutos", file=sys.stderr)
    a, b = np.float32(2.0), np.float32(1.0)
    grid = (n + block - 1) // block          # redondeo hacia arriba
    cap = grid * block                       # hilos lanzados = elementos reservados

    # Anfitrión: x válido en [0, n), relleno 0 después; y arranca en -1 (centinela) en todo cap.
    h_x = np.zeros(cap, dtype=np.float32)
    h_x[:n] = (np.arange(n) % 7).astype(np.float32)
    h_y = np.full(cap, -1.0, dtype=np.float32)

    d_x = cuda.to_device(h_x)                # cudaMalloc + cudaMemcpy H2D
    d_y = cuda.to_device(h_y)

    # Protocolo: 1 calentamiento (incluye el JIT en GPU real) + 5 repeticiones; solo el kernel.
    if not CUDASIM:                          # calentamiento (incluye el JIT en GPU real)
        axpb[grid, block](d_x, d_y, a, b, n)
        cuda.synchronize()
    times_ms = []
    for _ in range(REPS):
        t0 = time.perf_counter()
        axpb[grid, block](d_x, d_y, a, b, n)
        cuda.synchronize()
        times_ms.append((time.perf_counter() - t0) * 1e3)
    d_y.copy_to_host(h_y)                    # cudaMemcpy D2H

    # Verificación: (1) los n válidos contra NumPy; (2) los centinelas siguen en -1.
    ref = a * h_x[:n] + b
    wrong = int(np.sum(np.abs(h_y[:n] - ref) > 1e-5))
    altered = int(np.sum(h_y[n:] != -1.0))
    checksum = float(np.sum(h_y[:n], dtype=np.float64))
    ok = wrong == 0 and altered == 0
    modo = "CUDASIM" if CUDASIM else "GPU"

    print(f"caza2: n={n} block={block} grid={grid} hilos_lanzados={cap} sobrantes={cap - n} modo={modo}")
    print(f"checksum={checksum:.1f} elementos_incorrectos={wrong} centinelas_alterados={altered} (de {cap - n})")
    print(f"t_kernel_ms={median(times_ms):.4f} (mediana de {REPS}, solo kernel)")
    print(f"verificacion={'OK' if ok else 'FALLA'}")
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
