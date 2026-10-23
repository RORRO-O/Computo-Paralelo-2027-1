#!/usr/bin/env python3
"""item_III2_hist_numba.py — Espejo en Numba del ítem III.2 del examen de práctica (histograma de 8 bins).

Uso:
    NUMBA_ENABLE_CUDASIM=1 python3 item_III2_hist_numba.py [n] [--corregido]
Sin --corregido reproduce el kernel con el error (hist[b] += 1 sin atómica); con --corregido usa
cuda.atomic.add. Aviso: el simulador ejecuta los hilos de un bloque como hilos de Python y rara vez
intercala la lectura y la escritura de dos hilos sobre el mismo contador, así que la carrera casi nunca
se manifiesta aquí; en la GPU, con n = 2^20, se pierden casi todas las cuentas. Una carrera que "no se
ve" en una plataforma no está corregida: se razona sobre los accesos.
"""
import os
import sys

import numpy as np
from numba import cuda

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
BINS = 8


@cuda.jit
def hist8_buggy(v, hist, n):
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:
        hist[v[i]] += 1                       # lectura, suma y escritura por separado


@cuda.jit
def hist8_fixed(v, hist, n):
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:
        cuda.atomic.add(hist, v[i], 1)        # indivisible


def main():
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    n = int(args[0]) if args else 1000
    if n <= 0:
        print("uso: item_III2_hist_numba.py [n>0] [--corregido]")
        sys.exit(1)
    corregido = "--corregido" in flags
    block = 256
    grid = (n + block - 1) // block

    h_v = (np.arange(n) % BINS).astype(np.uint8)
    ref = np.bincount(h_v, minlength=BINS).astype(np.uint32)
    d_v = cuda.to_device(h_v)
    d_hist = cuda.to_device(np.zeros(BINS, dtype=np.uint32))
    kernel = hist8_fixed if corregido else hist8_buggy
    kernel[grid, block](d_v, d_hist, n)
    cuda.synchronize()
    h_hist = d_hist.copy_to_host()

    wrong = int(np.sum(h_hist != ref))
    modo = "CUDASIM" if CUDASIM else "GPU"
    print(f"hist_gpu=[{','.join(str(int(x)) for x in h_hist)}] modo={modo}{' (corregido)' if corregido else ''}")
    print(f"hist_cpu=[{','.join(str(int(x)) for x in ref)}]")
    print(f"n={n} total_gpu={int(h_hist.sum())} bins_incorrectos={wrong} verificacion={'OK' if wrong == 0 else 'FALLA'}")
    sys.exit(0 if wrong == 0 else 2)


if __name__ == "__main__":
    main()
