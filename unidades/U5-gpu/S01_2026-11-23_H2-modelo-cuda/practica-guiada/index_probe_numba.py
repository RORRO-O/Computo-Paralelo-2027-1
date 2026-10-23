#!/usr/bin/env python3
"""index_probe_numba.py — Espejo en Numba de index_probe.cu: ¿qué índice global le toca a cada hilo?

Uso:  NUMBA_ENABLE_CUDASIM=1 python3 index_probe_numba.py [n] [block]     (por defecto 10 y 4)
En GPU real también funciona.

1. Cada hilo imprime desde el kernel (orden NO garantizado; en CUDASIM las líneas incluso se
   pueden entremezclar porque el simulador usa hilos de Python).
2. Cada hilo con i < n anota quién lo atendió en owner_block[i], owner_thread[i]; el anfitrión
   imprime esa tabla ordenada para comprobar que cada índice tiene exactamente un dueño.
"""
import sys

import numpy as np
from numba import cuda


@cuda.jit
def print_index(n, owner_block, owner_thread):
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:
        print("bloque", cuda.blockIdx.x, ", hilo", cuda.threadIdx.x, "-> i =", i)
        owner_block[i] = cuda.blockIdx.x
        owner_thread[i] = cuda.threadIdx.x
    else:
        print("bloque", cuda.blockIdx.x, ", hilo", cuda.threadIdx.x, "-> i =", i, "(i >= n: este hilo NO trabaja)")


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    block = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    if n <= 0 or block <= 0 or block > 1024 or n > 4096:
        print("uso: index_probe_numba.py [n 1..4096] [block 1..1024]")
        sys.exit(1)
    grid = (n + block - 1) // block
    print(f"n={n} block={block} grid={grid}  hilos_lanzados={grid * block}  ociosos={grid * block - n}")

    owner_block = np.full(n, -1, dtype=np.int32)
    owner_thread = np.full(n, -1, dtype=np.int32)
    d_owner_block = cuda.to_device(owner_block)
    d_owner_thread = cuda.to_device(owner_thread)

    print("--- print desde el kernel (orden NO garantizado) ---", flush=True)
    print_index[grid, block](n, d_owner_block, d_owner_thread)
    cuda.synchronize()  # espera al kernel; en GPU real además vacía el buffer de print
    sys.stdout.flush()

    d_owner_block.copy_to_host(owner_block)
    d_owner_thread.copy_to_host(owner_thread)

    print("--- tabla ordenada por índice (la imprime el anfitrión) ---")
    for i in range(n):
        print(f"i = {i} <- bloque {owner_block[i]}, hilo {owner_thread[i]}")
    print(f"indices_sin_dueno={int(np.sum(owner_block < 0))}")


if __name__ == "__main__":
    main()
