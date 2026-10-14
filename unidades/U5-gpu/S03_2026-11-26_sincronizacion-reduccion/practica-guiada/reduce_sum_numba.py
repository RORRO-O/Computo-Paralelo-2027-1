#!/usr/bin/env python3
"""reduce_sum_numba.py — Espejo en Numba CUDA de los tres kernels de reduce_sum.cu.

Uso:
    python3 reduce_sum_numba.py [version] [n] [block] [--etapa2 cpu|atomic] [--sin-sync]
      version: atomic | tree_div | tree_nodiv | all   (por defecto all)
Sin GPU (simulador en CPU, solo correctitud; n pequeño):
    NUMBA_ENABLE_CUDASIM=1 python3 reduce_sum_numba.py all 1000 256

Mismos datos, mismo orden de sumas y misma verificación que la versión en C:
    x[i] = 1.0 + (i % 10) * 0.1 (float32), x[n-1] = 9.5; referencia en double; tolerancia relativa 1e-4.
--sin-sync quita la cuda.syncthreads() de dentro del ciclo del árbol (carrera deliberada, fase Investigar).
"""
import argparse
import os
import sys
import time

import numpy as np
from numba import cuda, float32

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 5
TOL_REL = 1e-4


@cuda.jit
def reduce_atomic(x, out, n):
    # Versión 1: cada hilo suma su elemento sobre UNA posición de memoria global.
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:
        cuda.atomic.add(out, 0, x[i])


def make_tree_kernels(block, sync_levels=True):
    """Los arreglos en memoria compartida necesitan tamaño constante: se captura `block` en la clausura."""

    @cuda.jit
    def reduce_tree_div(x, partial, out, n, atomic_stage2):
        # Versión 2: árbol CON divergencia (stride creciente, hilos activos intercalados).
        s = cuda.shared.array(block, float32)
        tid = cuda.threadIdx.x
        i = cuda.blockIdx.x * cuda.blockDim.x + tid
        s[tid] = x[i] if i < n else float32(0.0)
        cuda.syncthreads()                      # (A) todo el bloque cargó
        stride = 1
        while stride < cuda.blockDim.x:
            if tid % (2 * stride) == 0:
                s[tid] += s[tid + stride]
            if sync_levels:
                cuda.syncthreads()              # (B) nivel completo antes del siguiente
            stride *= 2
        if tid == 0:
            if atomic_stage2:
                cuda.atomic.add(out, 0, s[0])
            else:
                partial[cuda.blockIdx.x] = s[0]

    @cuda.jit
    def reduce_tree_nodiv(x, partial, out, n, atomic_stage2):
        # Versión 3: árbol SIN divergencia (stride decreciente, hilos activos consecutivos).
        s = cuda.shared.array(block, float32)
        tid = cuda.threadIdx.x
        i = cuda.blockIdx.x * cuda.blockDim.x + tid
        s[tid] = x[i] if i < n else float32(0.0)
        cuda.syncthreads()                      # (A)
        stride = cuda.blockDim.x // 2
        while stride > 0:
            if tid < stride:
                s[tid] += s[tid + stride]
            if sync_levels:
                cuda.syncthreads()              # (B)
            stride //= 2
        if tid == 0:
            if atomic_stage2:
                cuda.atomic.add(out, 0, s[0])
            else:
                partial[cuda.blockIdx.x] = s[0]

    return reduce_tree_div, reduce_tree_nodiv


def init_data(n):
    # Misma aritmética en float32, paso a paso, que `1.0f + (float)(i % 10) * 0.1f` en C: así los datos son
    # idénticos bit a bit en los tres programas (calcular en double y redondear una vez daría otros valores).
    k = (np.arange(n) % 10).astype(np.float32)
    x = np.float32(1.0) + k * np.float32(0.1)
    x[n - 1] = np.float32(9.5)
    return x


def tree_emulation_cpu(x, n, block, divergent):
    """Mismo orden de sumas que el kernel, en float32, vectorizado por bloque (NumPy)."""
    grid = (n + block - 1) // block
    s = np.zeros((grid, block), dtype=np.float32)
    s.flat[:n] = x
    if divergent:
        stride = 1
        while stride < block:
            idx = np.arange(0, block, 2 * stride)
            s[:, idx] += s[:, idx + stride]
            stride *= 2
    else:
        stride = block // 2
        while stride > 0:
            s[:, :stride] += s[:, stride:2 * stride]
            stride //= 2
    return s[:, 0].copy()


def median(values):
    return sorted(values)[len(values) // 2]


def run_version(name, kernel, d_x, d_partial, d_out, x, n, block, grid, atomic_stage2, ref):
    is_atomic = name == "atomic"
    times_ms = []
    # GPU: calentamiento (incluye el JIT) + REPS repeticiones. CUDASIM: un solo lanzamiento; el tiempo del
    # simulador no es una medición y cada lanzamiento de un árbol tarda segundos.
    reps = range(0, 1) if CUDASIM else range(-1, REPS)
    for r in reps:
        d_out[0] = 0.0
        t0 = time.perf_counter()
        if is_atomic:
            kernel[grid, block](d_x, d_out, n)
        else:
            kernel[grid, block](d_x, d_partial, d_out, n, atomic_stage2)
        cuda.synchronize()
        if r >= 0:
            times_ms.append((time.perf_counter() - t0) * 1e3)

    if is_atomic or atomic_stage2:
        total = float(d_out.copy_to_host()[0])
        n_atomics = n if is_atomic else grid
        stage2 = "-" if is_atomic else "atomic"
    else:
        partial = d_partial.copy_to_host()
        total = float(np.sum(partial, dtype=np.float64))   # etapa 2 en CPU, en double
        n_atomics = 0
        stage2 = "cpu"

    err_rel = abs(total - ref) / abs(ref)
    ok = err_rel <= TOL_REL
    if CUDASIM:
        timing = f"tiempo_simulador_ms={times_ms[0]:.1f} (NO es una medición)"
    else:
        timing = f"kernel_mediana_ms={median(times_ms):.4f} (min {min(times_ms):.4f}, max {max(times_ms):.4f})"
    print(f"version={name:<10} etapa2={stage2:<6} atomicas_globales={n_atomics:<8} {timing}")
    line = f"   suma={total:.6f} err_rel={err_rel:.2e} verificacion={'OK' if ok else 'FALLA'}"
    if not is_atomic and not atomic_stage2:
        emul = tree_emulation_cpu(x, n, block, name == "tree_div")
        same = np.array_equal(partial, emul)
        line += f" parciales_bit_a_bit_igual_a_emulacion_cpu={'si' if same else 'no'}"
    print(line)
    return ok


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("version", nargs="?", default="all", choices=["atomic", "tree_div", "tree_nodiv", "all"])
    parser.add_argument("n", nargs="?", type=int, default=(1000 if CUDASIM else 1 << 20))
    parser.add_argument("block", nargs="?", type=int, default=256)
    parser.add_argument("--etapa2", choices=["cpu", "atomic"], default="cpu")
    parser.add_argument("--sin-sync", action="store_true", help="quita la syncthreads entre niveles del árbol")
    args = parser.parse_args()
    n, block = args.n, args.block
    if n <= 0 or block <= 0 or block > 1024:
        sys.exit("uso: reduce_sum_numba.py [version] [n>0] [block 1..1024] [--etapa2 cpu|atomic] [--sin-sync]")
    if CUDASIM and n > 20000:
        print("aviso: CUDASIM con n > 20000 puede tardar varios minutos", file=sys.stderr)
    if args.version != "atomic" and (block & (block - 1)) != 0:
        print(f"aviso: el árbol supone block potencia de 2; con block={block} se pierden sumandos "
              "(experimento de la fase Investigar)", file=sys.stderr)

    grid = (n + block - 1) // block
    atomic_stage2 = args.etapa2 == "atomic"
    x = init_data(n)
    ref = float(np.sum(x, dtype=np.float64))

    d_x = cuda.to_device(x)
    d_partial = cuda.to_device(np.zeros(grid, dtype=np.float32))
    d_out = cuda.to_device(np.zeros(1, dtype=np.float32))

    print(f"reduce_sum_numba: n={n} block={block} grid={grid} modo={'CUDASIM' if CUDASIM else 'GPU'}")
    print(f"referencia_cpu_double={ref:.6f}  tolerancia_relativa={TOL_REL:.0e}")
    if args.sin_sync:
        print("AVISO: --sin-sync: el árbol NO sincroniza entre niveles (carrera deliberada)")

    tree_div, tree_nodiv = make_tree_kernels(block, sync_levels=not args.sin_sync)
    todo = []
    if args.version in ("all", "atomic"):
        todo.append(("atomic", reduce_atomic))
    if args.version in ("all", "tree_div"):
        todo.append(("tree_div", tree_div))
    if args.version in ("all", "tree_nodiv"):
        todo.append(("tree_nodiv", tree_nodiv))

    all_ok = True
    for name, kernel in todo:
        all_ok &= run_version(name, kernel, d_x, d_partial, d_out, x, n, block, grid, atomic_stage2, ref)
    sys.exit(0 if all_ok else 2)


if __name__ == "__main__":
    main()
