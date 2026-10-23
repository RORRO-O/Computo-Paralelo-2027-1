#!/usr/bin/env python3
"""a_matmul_numba.py — Espejo en Numba CUDA de a_matmul_tiled.cu (Parte A, código completo): kernel ingenuo y
kernel por mosaicos con memoria compartida (cuda.shared.array) y dos barreras (cuda.syncthreads).
Sirve para ejecutar y rastrear la lógica SIN GPU:

    NUMBA_ENABLE_CUDASIM=1 python3 a_matmul_numba.py 32 16        # n=32, TILE=16 (≈ 5 s)
    NUMBA_ENABLE_CUDASIM=1 python3 a_matmul_numba.py 20 16        # n NO múltiplo de TILE

Uso: python3 a_matmul_numba.py [n=32 en CUDASIM / 512 en GPU] [tile=16] [naive|tiled|ambos]
Misma inicialización y mismo checksum que a_matmul_cpu.c. Verificación contra NumPy con la misma tolerancia
que el .cu (1e-4·n). Código de salida: 0 si todo PASS, 2 si algo falla. Bajo CUDASIM cada hilo se simula en
Python: usa n <= 64; los tiempos que imprime el simulador no significan nada.
"""
import os
import sys

import numpy as np
from numba import cuda, float32

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 5


@cuda.jit
def matmul_naive(A, B, C, n):
    row = cuda.blockIdx.y * cuda.blockDim.y + cuda.threadIdx.y
    col = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if row < n and col < n:  # este kernel no tiene barreras: la guardia puede envolver todo
        acc = float32(0.0)
        for k in range(n):
            acc += A[row, k] * B[k, col]
        C[row, col] = acc


def make_tiled_kernel(tile):
    """El tamaño de cuda.shared.array debe ser constante al compilar: por eso el kernel se construye dentro
    de una función que captura `tile` (en CUDA C es la macro TILE)."""

    @cuda.jit
    def matmul_tiled(A, B, C, n):
        s_A = cuda.shared.array(shape=(tile, tile), dtype=float32)
        s_B = cuda.shared.array(shape=(tile, tile), dtype=float32)
        tx = cuda.threadIdx.x
        ty = cuda.threadIdx.y
        row = cuda.blockIdx.y * tile + ty
        col = cuda.blockIdx.x * tile + tx
        acc = float32(0.0)
        n_tiles = (n + tile - 1) // tile
        for t in range(n_tiles):
            # (1) carga cooperativa con cero fuera de la matriz
            a_col = t * tile + tx
            if row < n and a_col < n:
                s_A[ty, tx] = A[row, a_col]
            else:
                s_A[ty, tx] = float32(0.0)
            b_row = t * tile + ty
            if b_row < n and col < n:
                s_B[ty, tx] = B[b_row, col]
            else:
                s_B[ty, tx] = float32(0.0)
            cuda.syncthreads()  # (2) el mosaico completo antes de leerlo
            for k in range(tile):  # (3) tile productos con datos de memoria compartida
                acc += s_A[ty, k] * s_B[k, tx]
            cuda.syncthreads()  # (4) nadie sobreescribe el mosaico mientras otro lo lee
        if row < n and col < n:  # (5) guardia de escritura después del ciclo, no "return" al inicio
            C[row, col] = acc

    return matmul_tiled


def init_matrices(n):
    # Misma fórmula que a_matmul_tiled.cu y a_matmul_cpu.c.
    i = np.arange(n).reshape(n, 1)
    j = np.arange(n).reshape(1, n)
    A = (((3 * i + 7 * j) % 11) / 11.0).astype(np.float32)
    B = (((5 * i + 2 * j) % 13) / 13.0).astype(np.float32)
    return A, B


def tolerance(n):
    return 1e-4 * n


def median(v):
    return sorted(v)[len(v) // 2]


def run(name, kernel, A, B, n, tile):
    grid_dim = (n + tile - 1) // tile  # redondeo hacia arriba en cada dimensión
    C = np.zeros((n, n), dtype=np.float32)
    d_A, d_B, d_C = cuda.to_device(A), cuda.to_device(B), cuda.to_device(C)
    kernel[(grid_dim, grid_dim), (tile, tile)](d_A, d_B, d_C, n)  # calentamiento (JIT en GPU real)
    cuda.synchronize()
    times = []
    for _ in range(1 if CUDASIM else REPS):  # en el simulador el tiempo no es una medición
        e0, e1 = cuda.event(), cuda.event()
        e0.record()
        kernel[(grid_dim, grid_dim), (tile, tile)](d_A, d_B, d_C, n)
        e1.record()
        e1.synchronize()  # el lanzamiento es asíncrono: sin esto se mide casi nada
        times.append(e0.elapsed_time(e1))
    d_C.copy_to_host(C)
    ref = A.astype(np.float64) @ B.astype(np.float64)
    err = float(np.max(np.abs(C - ref)))
    checksum = float(np.sum(C, dtype=np.float64))
    ok = err <= tolerance(n)
    print(f"{name:<13} n={n} tile={tile} malla={grid_dim}x{grid_dim} bloque={tile}x{tile} fases={grid_dim} "
          f"t_kernel_ms={median(times):.3f}{' (CUDASIM: no representativo)' if CUDASIM else ''}")
    print(f"    error maximo vs NumPy {err:.2e} (tolerancia {tolerance(n):.1e}) checksum={checksum:.6f} "
          f"verificacion={'PASS' if ok else 'FAIL'}")
    return ok


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else (32 if CUDASIM else 512)
    tile = int(sys.argv[2]) if len(sys.argv) > 2 else 16
    which = sys.argv[3] if len(sys.argv) > 3 else "ambos"
    if n <= 0 or tile <= 0 or tile * tile > 1024 or which not in ("naive", "tiled", "ambos"):
        print("uso: a_matmul_numba.py [n>0] [tile; tile*tile <= 1024] [naive|tiled|ambos]")
        sys.exit(1)
    if CUDASIM and n > 64:
        print("aviso: CUDASIM con n > 64 tarda minutos", file=sys.stderr)
    A, B = init_matrices(n)
    ok = True
    if which != "tiled":
        ok &= run("matmul_naive", matmul_naive, A, B, n, tile)
    if which != "naive":
        ok &= run("matmul_tiled", make_tiled_kernel(tile), A, B, n, tile)
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
