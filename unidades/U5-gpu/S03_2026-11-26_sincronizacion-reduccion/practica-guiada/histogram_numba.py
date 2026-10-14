#!/usr/bin/env python3
"""histogram_numba.py — Espejo en Numba CUDA de histogram.cu.

Uso:
    python3 histogram_numba.py [version: global|shared|all] [n] [block] [--bins B]
Sin GPU (simulador, solo correctitud; n pequeño):
    NUMBA_ENABLE_CUDASIM=1 python3 histogram_numba.py global 4096 256

Mismos datos que histogram.cu / histogram_cpu.c (hash multiplicativo; 25 % de los datos en el bin 0) y
verificación EXACTA contra numpy.bincount (conteos enteros: no hay redondeo).
La versión `shared` es el TODO(1) de la fase Crear: mientras el kernel no escriba nada, se imprime
"TODO pendiente".
"""
import argparse
import os
import sys
import time

import numpy as np
from numba import cuda, uint32

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 5


@cuda.jit
def hist_global_atomic(v, hist, n):
    # Todos los hilos de todos los bloques compiten por las mismas `bins` direcciones globales.
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:
        cuda.atomic.add(hist, v[i], 1)


def make_shared_kernel(bins):
    """`bins` dimensiona el arreglo en memoria compartida; por eso se captura en la clausura."""

    @cuda.jit
    def hist_shared_atomic(v, hist, n):
        # TODO(1): histograma privado por bloque en cuda.shared.array(bins, uint32):
        # poner en cero, syncthreads, atómicas en compartida, syncthreads, volcado con `bins` atómicas
        # globales por bloque. Pistas en README.md, sección "Crear". Mientras tanto no escribe nada.
        i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
        if i < 0:                      # nunca cierto: el kernel queda vacío a propósito
            hist[0] = uint32(0)

    return hist_shared_atomic


def init_data(n, bins):
    i = np.arange(n, dtype=np.uint64)
    h = ((i * np.uint64(2654435761)) & np.uint64(0xFFFFFFFF)) >> np.uint64(24)
    v = (h % np.uint64(bins)).astype(np.uint8)
    v[::4] = 0                                   # sesgo: i % 4 == 0 -> bin 0
    return v


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("version", nargs="?", default="all", choices=["global", "shared", "all"])
    parser.add_argument("n", nargs="?", type=int, default=(4096 if CUDASIM else 1 << 20))
    parser.add_argument("block", nargs="?", type=int, default=256)
    parser.add_argument("--bins", type=int, default=16)
    args = parser.parse_args()
    n, block, bins = args.n, args.block, args.bins
    if n <= 0 or block < bins or block > 1024:
        sys.exit("uso: histogram_numba.py [version] [n>0] [block bins..1024] [--bins B]")
    grid = (n + block - 1) // block

    v = init_data(n, bins)
    ref = np.bincount(v, minlength=bins).astype(np.uint32)
    d_v = cuda.to_device(v)
    d_hist = cuda.to_device(np.zeros(bins, dtype=np.uint32))

    print(f"histogram_numba: n={n} bins={bins} block={block} grid={grid} modo={'CUDASIM' if CUDASIM else 'GPU'}")
    print("hist_cpu=[" + ",".join(str(c) for c in ref) + "]")

    versions = []
    if args.version in ("all", "global"):
        versions.append(("global", hist_global_atomic, n, 0))
    if args.version in ("all", "shared"):
        versions.append(("shared", make_shared_kernel(bins), bins * grid, n))

    all_ok = True
    for name, kernel, atomics_global, atomics_shared in versions:
        times_ms = []
        reps = range(0, 1) if CUDASIM else range(-1, REPS)   # CUDASIM: un solo lanzamiento
        for r in reps:
            d_hist.copy_to_device(np.zeros(bins, dtype=np.uint32))
            t0 = time.perf_counter()
            kernel[grid, block](d_v, d_hist, n)
            cuda.synchronize()
            if r >= 0:
                times_ms.append((time.perf_counter() - t0) * 1e3)
        hist = d_hist.copy_to_host()
        total = int(hist.sum())
        exact = np.array_equal(hist, ref)
        timing = (f"tiempo_simulador_ms={times_ms[0]:.1f} (NO es una medición)" if CUDASIM else
                  f"kernel_mediana_ms={sorted(times_ms)[len(times_ms) // 2]:.4f} "
                  f"(min {min(times_ms):.4f}, max {max(times_ms):.4f})")
        print(f"version={name:<7} atomicas_globales={atomics_global:<8} atomicas_compartidas={atomics_shared:<8} {timing}")
        print("   hist_gpu=[" + ",".join(str(c) for c in hist) + "]")
        if total == 0:
            print("   total=0 -> TODO pendiente: hist_shared_atomic no escribe nada todavía (TODO(1))")
        else:
            print(f"   total={total} verificacion={'OK' if exact else 'FALLA'}")
            all_ok &= exact
    sys.exit(0 if all_ok else 2)


if __name__ == "__main__":
    main()
