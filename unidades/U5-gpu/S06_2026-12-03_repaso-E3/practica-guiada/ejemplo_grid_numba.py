#!/usr/bin/env python3
"""ejemplo_grid_numba.py — Espejo en Numba CUDA de ejemplo_grid.cu (ejemplo resuelto, parte B).

Uso:
    NUMBA_ENABLE_CUDASIM=1 python3 ejemplo_grid_numba.py [n] [block] [--corregido]
Sin --corregido reproduce el error del anfitrión (grid = n // block); con --corregido usa el redondeo
hacia arriba. El kernel es el mismo en ambos casos: el error no está en el kernel.
"""
import os
import sys

import numpy as np
from numba import cuda

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"


@cuda.jit
def scale(x, y, n):
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:                                 # guardia presente: este kernel está bien
        y[i] = 0.5 * x[i]


def main():
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    n = int(args[0]) if len(args) > 0 else 1000
    block = int(args[1]) if len(args) > 1 else 256
    if n <= 0 or block <= 0 or block > 1024:
        print("uso: ejemplo_grid_numba.py [n>0] [block 1..1024] [--corregido]")
        sys.exit(1)
    corregido = "--corregido" in flags
    grid = (n + block - 1) // block if corregido else n // block

    h_x = (np.arange(n) % 7 + 1).astype(np.float32)
    h_y = np.zeros(n, dtype=np.float32)
    d_x = cuda.to_device(h_x)
    d_y = cuda.to_device(h_y)
    if grid > 0:                              # con n < block y sin corregir, grid = 0: no se lanza nada
        scale[grid, block](d_x, d_y, n)
        cuda.synchronize()
    d_y.copy_to_host(h_y)

    ref = 0.5 * h_x                           # ref >= 0.5: un 0 en y significa "nadie lo tocó"
    unprocessed = int(np.sum(h_y == 0.0))
    wrong = int(np.sum((h_y != 0.0) & (np.abs(h_y - ref) > 1e-5)))
    checksum = float(np.sum(h_y, dtype=np.float64))
    ok = unprocessed == 0 and wrong == 0
    modo = "CUDASIM" if CUDASIM else "GPU"
    print(f"ejemplo_grid: n={n} block={block} grid={grid} hilos_lanzados={grid * block} modo={modo}"
          f"{' (corregido)' if corregido else ''}")
    print(f"checksum={checksum:.1f} elementos_incorrectos={wrong} elementos_sin_procesar={unprocessed}")
    print(f"verificacion={'OK' if ok else 'FALLA'}")
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
