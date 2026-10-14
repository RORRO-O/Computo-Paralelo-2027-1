#!/usr/bin/env python3
"""transpose_numba.py — espejo en Numba CUDA de transpose.cu (fase CREAR).

Viene completa la versión ingenua. transpose_shared tiene el TODO(1): escríbela aquí o en
transpose.cu (o en ambos) y verifica sin GPU con:
    NUMBA_ENABLE_CUDASIM=1 python3 transpose_numba.py --n 20 --tile 8
"""
import argparse
import os
import sys

import numpy as np
from numba import cuda, float32

# Cambia a True cuando termines TODO(1).
TODO1_LISTO = False


def make_kernels(tile):
    @cuda.jit
    def transpose_naive(inp, out, n):
        col = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
        row = cuda.blockIdx.y * cuda.blockDim.y + cuda.threadIdx.y
        if row < n and col < n:
            out[col, row] = inp[row, col]        # lectura coalescida, escritura saltada

    @cuda.jit
    def transpose_shared(inp, out, n):
        tile_sh = cuda.shared.array((tile, tile + 1), float32)
        # TODO(1): lee el mosaico por filas a tile_sh, sincroniza, escribe el mosaico
        # transpuesto por filas en out. Mismo criterio de "listo" que en transpose.cu.
        if cuda.threadIdx.x < 0:                 # nunca cierto: evita avisos de variable sin uso
            out[0, 0] = tile_sh[0, 0] + inp[0, 0] + n

    return transpose_naive, transpose_shared


def check(kernel, name, inp, n, tile):
    out = np.zeros((n, n), dtype=np.float32)
    grid = ((n + tile - 1) // tile, (n + tile - 1) // tile)
    kernel[grid, (tile, tile)](inp, out, n)
    cuda.synchronize()
    max_err = float(np.max(np.abs(out - inp.T)))
    ok = max_err == 0.0
    print(f"{name:<16} n={n} tile={tile} malla={grid[0]}x{grid[1]}  "
          f"error maximo {max_err:.1e} -> {'PASS' if ok else 'FAIL'}")
    return ok


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n", type=int, default=20)
    parser.add_argument("--tile", type=int, default=8)
    args = parser.parse_args()
    n, tile = args.n, args.tile
    if os.environ.get("NUMBA_ENABLE_CUDASIM") == "1":
        print("[CUDASIM] simulador de CUDA activo")
    i = np.arange(n).reshape(n, 1)
    j = np.arange(n).reshape(1, n)
    inp = ((7 * i + 3 * j) % 101).astype(np.float32)   # misma matriz que transpose.cu

    naive, shared = make_kernels(tile)
    ok = check(naive, "transpose_naive", inp, n, tile)
    if TODO1_LISTO:
        ok = check(shared, "transpose_shared", inp, n, tile) and ok
    else:
        print("TODO pendiente: transpose_shared (TODO(1)); solo se verifico la version ingenua.")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
