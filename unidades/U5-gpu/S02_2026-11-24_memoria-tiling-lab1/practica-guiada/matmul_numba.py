#!/usr/bin/env python3
"""matmul_numba.py — espejo en Numba CUDA de matmul_naive.cu y matmul_tiled.cu.

Sirve para verificar la lógica de los kernels SIN GPU con el simulador:
    NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 64 --tile 16
y también corre en una GPU real (Colab/Kaggle) sin la variable de entorno.

Opciones de la fase Investigar:
    --sin-sync1       quita la primera cuda.syncthreads() del kernel por mosaicos
    --grid-truncado   malla n//tile en lugar de ceil(n/tile)
Las matrices se inicializan con la misma fórmula que common.cuh y matmul_cpu.c, así que la
suma de comprobación (checksum) es comparable entre los tres programas.
"""
import argparse
import os
import sys
import time
import warnings

import numpy as np
from numba import cuda, float32

# Sin la primera barrera se lee memoria compartida no inicializada: puede contener basura
# (NaN, inf). NumPy avisaría en cada operación; silenciamos el aviso para leer la salida.
warnings.filterwarnings("ignore", category=RuntimeWarning)


def init_matrices(n):
    """Misma fórmula que init_matrices() en common.cuh y matmul_cpu.c."""
    i = np.arange(n, dtype=np.int64).reshape(n, 1)
    j = np.arange(n, dtype=np.int64).reshape(1, n)
    A = (((3 * i + 7 * j) % 11) / 11.0).astype(np.float32)
    B = (((5 * i + 2 * j) % 13) / 13.0).astype(np.float32)
    return A, B


def make_kernels(tile, sync1=True):
    """Construye los dos kernels. `tile` debe ser constante en tiempo de compilación porque
    dimensiona los arreglos en memoria compartida; por eso se captura en la clausura."""

    @cuda.jit
    def matmul_naive(A, B, C, n):
        # Un hilo por elemento de C. Mismos índices que en matmul_naive.cu.
        col = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
        row = cuda.blockIdx.y * cuda.blockDim.y + cuda.threadIdx.y
        if row < n and col < n:
            acc = float32(0.0)
            for k in range(n):
                acc += A[row, k] * B[k, col]      # 2 lecturas globales por iteración
            C[row, col] = acc

    @cuda.jit
    def matmul_tiled(A, B, C, n):
        s_A = cuda.shared.array((tile, tile), float32)   # mosaico de A en compartida
        s_B = cuda.shared.array((tile, tile), float32)   # mosaico de B en compartida
        tx = cuda.threadIdx.x
        ty = cuda.threadIdx.y
        row = cuda.blockIdx.y * tile + ty
        col = cuda.blockIdx.x * tile + tx
        acc = float32(0.0)
        n_tiles = (n + tile - 1) // tile
        for t in range(n_tiles):
            # (1) carga cooperativa; fuera de rango se escribe 0 (n no múltiplo de tile)
            a_col = t * tile + tx
            b_row = t * tile + ty
            s_A[ty, tx] = A[row, a_col] if (row < n and a_col < n) else float32(0.0)
            s_B[ty, tx] = B[b_row, col] if (b_row < n and col < n) else float32(0.0)
            if sync1:
                cuda.syncthreads()               # (2) el mosaico completo está en compartida
            for k in range(tile):                # (3) tile reutilizaciones por carga
                acc += s_A[ty, k] * s_B[k, tx]
            cuda.syncthreads()                   # (4) nadie sobreescribe antes de tiempo
        if row < n and col < n:
            C[row, col] = acc

    return matmul_naive, matmul_tiled


def run(kernel, name, A, B, n, tile, grid, reps, reads, reads_per_a, tol, simulado):
    """Lanza el kernel con calentamiento + reps repeticiones; verifica contra NumPy."""
    C = np.zeros((n, n), dtype=np.float32)       # ceros: un elemento no calculado se nota
    block = (tile, tile)
    if not simulado:                             # en el simulador el calentamiento no aporta
        kernel[grid, block](A, B, C, n)          # calentamiento (y compilación JIT)
        cuda.synchronize()
    times = []
    for _ in range(reps):
        t0 = time.perf_counter()
        kernel[grid, block](A, B, C, n)
        cuda.synchronize()
        times.append(time.perf_counter() - t0)
    median = sorted(times)[len(times) // 2]
    ref = A.astype(np.float64) @ B.astype(np.float64)
    max_err = float(np.max(np.abs(C.astype(np.float64) - ref)))
    ok = np.isfinite(max_err) and max_err <= tol
    print(f"{name:<9} n={n} tile={tile} malla={grid[0]}x{grid[1]} bloque={tile}x{tile}  "
          f"lecturas_globales(modelo)={reads}  (cada elemento de A: {reads_per_a} veces)")
    print(f"          error maximo vs NumPy {max_err:.2e}  mediana {median*1e3:.3f} ms "
          f"de {reps} -> {'PASS' if ok else 'FAIL'}")
    return C, ok


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n", type=int, default=64, help="tamaño n de las matrices n×n")
    parser.add_argument("--tile", type=int, default=16, help="tamaño del mosaico/bloque")
    parser.add_argument("--reps", type=int, default=1, help="repeticiones cronometradas (GPU: 5)")
    parser.add_argument("--sin-sync1", action="store_true", help="quita la 1a syncthreads")
    parser.add_argument("--grid-truncado", action="store_true", help="malla n//tile")
    parser.add_argument("--solo", choices=["ingenua", "mosaicos"], default=None,
                        help="ejecuta solo una versión")
    args = parser.parse_args()
    n, tile = args.n, args.tile
    if n <= 0 or tile <= 0:
        sys.exit("n y tile deben ser > 0")

    simulado = os.environ.get("NUMBA_ENABLE_CUDASIM") == "1"
    if simulado:
        print("[CUDASIM] simulador de CUDA activo: se verifica la logica; "
              "los tiempos NO son representativos")

    A, B = init_matrices(n)
    n_tiles = (n + tile - 1) // tile
    blocks = n // tile if args.grid_truncado else n_tiles
    grid = (blocks, blocks)
    if args.grid_truncado:
        print(f"[grid-truncado] malla {blocks}x{blocks} con division entera "
              f"(deberia ser {n_tiles}x{n_tiles})")
    if args.sin_sync1:
        print("[sin-sync1] se quito la primera cuda.syncthreads() del kernel por mosaicos")

    naive, tiled = make_kernels(tile, sync1=not args.sin_sync1)
    tol = 1e-4 * n                               # misma tolerancia que common.cuh
    all_ok = True
    C = None
    if args.solo != "mosaicos":
        C, ok = run(naive, "ingenua", A, B, n, tile, grid, args.reps,
                    reads=2 * n * n * n, reads_per_a=n, tol=tol, simulado=simulado)
        all_ok = all_ok and ok
    if args.solo != "ingenua":
        C, ok = run(tiled, "mosaicos", A, B, n, tile, grid, args.reps,
                    reads=2 * n * n * n_tiles, reads_per_a=n_tiles, tol=tol, simulado=simulado)
        all_ok = all_ok and ok

    checksum = float(np.sum(C, dtype=np.float64))
    print(f"checksum C = {checksum:.6f}   (compara con ./matmul_cpu {n} {tile})")
    print(f"csv,numba,{n},{tile},{'sim' if simulado else 'gpu'},{checksum:.6f},"
          f"{'PASS' if all_ok else 'FAIL'}")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
