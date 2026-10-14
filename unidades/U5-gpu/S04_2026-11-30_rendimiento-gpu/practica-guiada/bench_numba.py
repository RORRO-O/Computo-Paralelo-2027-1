"""bench_numba.py — Espejo en Numba CUDA de los kernels de bench_gpu.cu.

Sin GPU (verificación en el simulador):  NUMBA_ENABLE_CUDASIM=1 python3 bench_numba.py --n 1000
Con GPU (Colab/Kaggle):                  python3 bench_numba.py --n 16777216

Comprueba que vector_add y saxpy dan el mismo resultado que NumPy para cada tamaño de bloque
(32, 64, ..., 1024) y, si hay GPU real, mide el tiempo del kernel con eventos (cuda.event), que son
el equivalente de cudaEvent_t: 1 calentamiento + 5 repeticiones, mediana.
Termina con código 0 si toda verificación pasa y 1 si alguna falla.
"""
import argparse
import os
import sys
import time

import numpy as np
from numba import cuda

BLOCK_SIZES = (32, 64, 128, 256, 512, 1024)
N_REPS = 5
ALPHA = 2.0
SIMULATOR = os.environ.get("NUMBA_ENABLE_CUDASIM") == "1"


@cuda.jit
def vector_add_kernel(a, b, c, n):
    i = cuda.grid(1)  # equivale a blockIdx.x * blockDim.x + threadIdx.x
    if i < n:
        c[i] = a[i] + b[i]


@cuda.jit
def saxpy_kernel(alpha, x, y, out, n):
    i = cuda.grid(1)
    if i < n:
        out[i] = alpha * x[i] + y[i]


def median(values):
    return sorted(values)[len(values) // 2]


def time_kernel_ms(launch):
    """Mediana en ms de N_REPS lanzamientos medidos con eventos de la GPU (tras 1 calentamiento)."""
    launch()
    cuda.synchronize()
    times = []
    for _ in range(N_REPS):
        start, stop = cuda.event(), cuda.event()
        start.record()
        launch()
        stop.record()
        stop.synchronize()  # igual que cudaEventSynchronize
        times.append(cuda.event_elapsed_time(start, stop))
    return median(times)


def main():
    parser = argparse.ArgumentParser(description="Espejo Numba de bench_gpu.cu")
    parser.add_argument("--n", type=int, default=1000 if SIMULATOR else 1 << 24,
                        help="elementos por vector (en el simulador conviene n <= 2000)")
    args = parser.parse_args()
    n = args.n

    a = (np.arange(n, dtype=np.float32) % 1000) * np.float32(0.001)
    b = np.float32(1.0) + (np.arange(n, dtype=np.float32) % 7)
    ref = {"vector_add": a + b, "saxpy": np.float32(ALPHA) * a + b}

    d_a, d_b = cuda.to_device(a), cuda.to_device(b)
    d_c = cuda.device_array_like(a)

    mode = "simulador (CUDASIM, sin tiempos)" if SIMULATOR else "GPU real"
    print(f"bench_numba: n = {n}, modo = {mode}")
    print(f"{'kernel':<11}{'bloque':>7}{'malla':>9}{'error máx':>12}{'estado':>8}{'kernel ms':>12}")
    all_ok = True
    t0 = time.perf_counter()
    for block in BLOCK_SIZES:
        grid = (n + block - 1) // block
        for name in ("vector_add", "saxpy"):
            if name == "vector_add":
                def launch(): vector_add_kernel[grid, block](d_a, d_b, d_c, n)
            else:
                def launch(): saxpy_kernel[grid, block](ALPHA, d_a, d_b, d_c, n)
            d_c.copy_to_device(np.zeros(n, dtype=np.float32))  # borra el resultado anterior
            launch()
            cuda.synchronize()
            err = float(np.max(np.abs(d_c.copy_to_host() - ref[name])))
            ok = err < 1e-5
            all_ok &= ok
            ms = "" if SIMULATOR else f"{time_kernel_ms(launch):12.4f}"
            print(f"{name:<11}{block:>7}{grid:>9}{err:>12.2e}{'OK' if ok else 'FALLA':>8}{ms}")
    print(f"Verificación contra NumPy: {'OK' if all_ok else 'FALLA'} "
          f"({time.perf_counter() - t0:.1f} s de pared)")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
