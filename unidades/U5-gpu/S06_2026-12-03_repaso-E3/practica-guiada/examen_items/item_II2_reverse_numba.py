#!/usr/bin/env python3
"""item_II2_reverse_numba.py — Espejo en Numba del ítem II.2 del examen de práctica (verificado en CUDASIM).
Uso: NUMBA_ENABLE_CUDASIM=1 python3 item_II2_reverse_numba.py
"""
import numpy as np
from numba import cuda, int32


@cuda.jit
def reverse_in_block(data, n):
    s = cuda.shared.array(4, int32)
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:
        s[cuda.threadIdx.x] = data[i]
    cuda.syncthreads()
    j = cuda.blockDim.x - 1 - cuda.threadIdx.x       # posición espejo dentro del bloque
    src = cuda.blockIdx.x * cuda.blockDim.x + j      # índice global de esa posición
    if i < n and src < n:
        data[i] = s[j]


def main():
    n = 10
    h = np.arange(n, dtype=np.int32)
    d = cuda.to_device(h)
    reverse_in_block[3, 4](d, n)
    cuda.synchronize()
    d.copy_to_host(h)
    print(" ".join(str(v) for v in h))


if __name__ == "__main__":
    main()
