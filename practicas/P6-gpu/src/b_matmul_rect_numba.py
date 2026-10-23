#!/usr/bin/env python3
"""b_matmul_rect_numba.py — Espejo en Numba CUDA de b_matmul_rect.cu (Parte B): C = A·B con A de M×K, B de K×N
y C de M×N. Kernel ingenuo rectangular completo y kernel por mosaicos con los MISMOS TODO(1)–TODO(4) que el .cu.
Las matrices viajan como arreglos 1D guardados por filas (igual que en CUDA C), para que los índices lineales
signifiquen lo mismo en los dos programas. Sirve para verificar tu lógica SIN GPU:

    NUMBA_ENABLE_CUDASIM=1 python3 b_matmul_rect_numba.py 32 32 32 16     # cuadrada: pasa aun sin corregir
    NUMBA_ENABLE_CUDASIM=1 python3 b_matmul_rect_numba.py 20 40 12 16     # rectangular, no múltiplo de TILE

Uso: python3 b_matmul_rect_numba.py [M K N] [tile=16] [naive|tiled|ambos]   (por defecto 20 40 12 en CUDASIM)
Misma inicialización y mismo checksum que b_matmul_rect_cpu.c. Verificación contra NumPy con tolerancia 1e-4·K.
Código de salida: 0 si todo PASS, 2 si algo falla (o hay un acceso fuera de rango), 3 si hay TODO pendiente.
Bajo CUDASIM cada hilo se simula en Python: usa M, K, N <= 64.

Tu trabajo: corrige TODO(1)–TODO(4) (los mismos que en el .cu) y pon TODO_LISTO = True. Mientras sea False el
programa imprime "TODO pendiente" y termina con código 3 sin lanzar el kernel por mosaicos.
"""
import os
import sys

import numpy as np
from numba import cuda, float32

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 5

# Pon True cuando hayas corregido TODO(1)–TODO(4) (aquí y en el .cu).
TODO_LISTO = False


@cuda.jit
def matmul_rect_naive(A, B, C, M, K, N):
    row = cuda.blockIdx.y * cuda.blockDim.y + cuda.threadIdx.y
    col = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if row < M and col < N:  # sin barreras: la guardia puede envolver todo
        acc = float32(0.0)
        for k in range(K):
            acc += A[row * K + k] * B[k * N + col]  # A tiene K columnas; B, N
        C[row * N + col] = acc


@cuda.jit(device=True)
def load_or_zero(mat, r, c, rows, cols):
    # TODO(1): mat[r][c] de una matriz rows×cols guardada por filas, o 0.0 si (r, c) cae fuera.
    #          Dos cosas de estas líneas solo valen para matrices cuadradas.
    if r < rows and c < rows:  # <- TODO(1)
        return mat[r * rows + c]  # <- TODO(1)
    return float32(0.0)


def make_tiled_kernel(tile):
    """cuda.shared.array necesita un tamaño constante al compilar: el kernel se construye para cada `tile`."""

    @cuda.jit
    def matmul_rect_tiled(A, B, C, M, K, N):
        s_A = cuda.shared.array(shape=(tile, tile), dtype=float32)
        s_B = cuda.shared.array(shape=(tile, tile), dtype=float32)
        tx = cuda.threadIdx.x
        ty = cuda.threadIdx.y
        row = cuda.blockIdx.y * tile + ty  # fila de C (y de A)
        col = cuda.blockIdx.x * tile + tx  # columna de C (y de B)
        acc = float32(0.0)
        # TODO(2): ¿a lo largo de qué dimensión avanzan las fases?
        n_tiles = (M + tile - 1) // tile  # <- TODO(2)
        for t in range(n_tiles):
            # TODO(3): los índices son los de la Parte A; faltan las dimensiones (filas, columnas) de cada matriz.
            s_A[ty, tx] = load_or_zero(A, row, t * tile + tx, M, M)  # <- TODO(3)
            s_B[ty, tx] = load_or_zero(B, t * tile + ty, col, M, M)  # <- TODO(3)
            cuda.syncthreads()  # (dado) el mosaico completo antes de leerlo
            for k in range(tile):
                acc += s_A[ty, k] * s_B[k, tx]
            cuda.syncthreads()  # (dado) nadie sobreescribe el mosaico mientras otro lo lee
        # TODO(4): dos defectos que con matrices cuadradas no se notan.
        if row < M and col < M:  # <- TODO(4)
            C[row * M + col] = acc  # <- TODO(4)

    return matmul_rect_tiled


def init_matrices(M, K, N):
    # Las fórmulas de la Parte A con otras formas (igual que b_matmul_rect.cu y b_matmul_rect_cpu.c).
    i = np.arange(M).reshape(M, 1)
    j = np.arange(K).reshape(1, K)
    A = (((3 * i + 7 * j) % 11) / 11.0).astype(np.float32)
    i = np.arange(K).reshape(K, 1)
    j = np.arange(N).reshape(1, N)
    B = (((5 * i + 2 * j) % 13) / 13.0).astype(np.float32)
    return A, B


def median(v):
    return sorted(v)[len(v) // 2]


def run(name, kernel, A, B, M, K, N, tile):
    # (Dado) malla 2D para C (M×N): x recorre las N columnas, y recorre las M filas; redondeo hacia arriba.
    grid = ((N + tile - 1) // tile, (M + tile - 1) // tile)
    C = np.zeros(M * N, dtype=np.float32)
    d_A, d_B, d_C = cuda.to_device(A.ravel()), cuda.to_device(B.ravel()), cuda.to_device(C)
    times = []
    try:
        kernel[grid, (tile, tile)](d_A, d_B, d_C, M, K, N)  # calentamiento (JIT en GPU real)
        cuda.synchronize()
        for _ in range(1 if CUDASIM else REPS):  # en el simulador el tiempo no es una medición
            e0, e1 = cuda.event(), cuda.event()
            e0.record()
            kernel[grid, (tile, tile)](d_A, d_B, d_C, M, K, N)
            e1.record()
            e1.synchronize()
            times.append(e0.elapsed_time(e1))
    except IndexError as exc:  # CUDASIM revisa los límites de cada acceso; la GPU real no (idea errónea 34)
        print(f"{name:<17} M={M} K={K} N={N} tile={tile}: acceso fuera de rango en el kernel -> {exc}")
        print("    verificacion=FAIL")
        return False
    d_C.copy_to_host(C)
    ref = (A.astype(np.float64) @ B.astype(np.float64)).ravel()
    err = float(np.max(np.abs(C - ref)))
    checksum = float(np.sum(C, dtype=np.float64))
    ok = err <= 1e-4 * K
    print(f"{name:<17} M={M} K={K} N={N} tile={tile} malla={grid[0]}x{grid[1]} bloque={tile}x{tile} "
          f"t_kernel_ms={median(times):.3f}{' (CUDASIM: no representativo)' if CUDASIM else ''}")
    print(f"    error maximo vs NumPy {err:.2e} (tolerancia {1e-4 * K:.1e}) checksum={checksum:.6f} "
          f"verificacion={'PASS' if ok else 'FAIL'}")
    return ok


def main():
    args = sys.argv[1:]
    which = "ambos"
    if args and args[-1] in ("naive", "tiled", "ambos"):
        which = args.pop()
    dims = [int(a) for a in args[:3]] if len(args) >= 3 else ([20, 40, 12] if CUDASIM else [1000, 600, 700])
    tile = int(args[3]) if len(args) > 3 else 16
    M, K, N = dims
    if min(M, K, N) <= 0 or tile <= 0 or tile * tile > 1024:
        print("uso: b_matmul_rect_numba.py [M K N] [tile; tile*tile <= 1024] [naive|tiled|ambos]")
        sys.exit(1)
    if CUDASIM and max(M, K, N) > 64:
        print("aviso: CUDASIM con dimensiones > 64 tarda minutos", file=sys.stderr)
    A, B = init_matrices(M, K, N)
    ok = True
    if which != "tiled":
        ok &= run("matmul_rect_naive", matmul_rect_naive, A, B, M, K, N, tile)
    if which != "naive":
        if not TODO_LISTO:
            print("matmul_rect_tiled TODO pendiente: corrige TODO(1)-TODO(4) y pon TODO_LISTO = True")
            sys.exit(3)
        ok &= run("matmul_rect_tiled", make_tiled_kernel(tile), A, B, M, K, N, tile)
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
