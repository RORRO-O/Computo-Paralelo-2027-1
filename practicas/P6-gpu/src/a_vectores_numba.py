#!/usr/bin/env python3
"""a_vectores_numba.py — Espejo en Numba CUDA de los kernels de a_vectores.cu (Parte A).

Uso:
    python3 a_vectores_numba.py [n] [block] [vector_add|saxpy|ambos]
Sin GPU (simulador en CPU: verifica la LÓGICA, los tiempos no significan nada; usa n pequeño):
    NUMBA_ENABLE_CUDASIM=1 python3 a_vectores_numba.py 1000 256

Mismo índice global, misma guardia, misma inicialización y mismo checksum que a_vectores.cu y
a_vectores_cpu.c. Con GPU real mide el kernel con eventos de CUDA (cuda.event) y el total con
copias usando perf_counter + cuda.synchronize(); 1 calentamiento (incluye la compilación JIT) + 5.
Bajo CUDASIM se hace una sola repetición: el tiempo del simulador no significa nada y cada hilo
se ejecuta en Python (n = 1000 tarda ~1 s; n = 20 000, ~20 s).
Termina con código 0 si todas las verificaciones contra NumPy pasan.
"""
import os
import sys
import time

import numpy as np
from numba import cuda

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 5
ALPHA = np.float32(2.0)


@cuda.jit
def vector_add_kernel(a, b, c, n):
    # Índice global igual que en CUDA C (cuda.grid(1) es la abreviatura equivalente).
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:  # guardia
        c[i] = a[i] + b[i]


@cuda.jit
def saxpy_kernel(alpha, x, y, out, n):
    i = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    if i < n:
        out[i] = alpha * x[i] + y[i]


def median(values):
    return sorted(values)[len(values) // 2]


def run(name, n, block):
    grid = (n + block - 1) // block  # división entera redondeada hacia arriba
    # Anfitrión: misma inicialización que a_vectores.cu / a_vectores_cpu.c
    a = (np.arange(n) % 7).astype(np.float32)
    b = (np.arange(n) % 13).astype(np.float32)
    c = np.zeros(n, dtype=np.float32)
    ref = (a + b) if name == "vector_add" else (ALPHA * a + b)

    def launch(d_a, d_b, d_c):
        if name == "vector_add":
            vector_add_kernel[grid, block](d_a, d_b, d_c, n)
        else:
            saxpy_kernel[grid, block](ALPHA, d_a, d_b, d_c, n)

    # Calentamiento (en GPU real incluye la compilación JIT del kernel y la creación del contexto)
    d_a, d_b, d_c = cuda.to_device(a), cuda.to_device(b), cuda.to_device(c)
    launch(d_a, d_b, d_c)
    cuda.synchronize()

    kernel_ms, total_ms = [], []
    reps = 1 if CUDASIM else REPS  # en el simulador el tiempo no es una medición: una repetición basta
    for _ in range(reps):
        # --- total con copias: H2D + kernel + D2H, reloj de CPU con sincronización ---
        t0 = time.perf_counter()
        d_a, d_b = cuda.to_device(a), cuda.to_device(b)       # equivalente de cudaMemcpy H2D
        launch(d_a, d_b, d_c)
        d_c.copy_to_host(c)                                   # D2H; sincroniza al terminar
        cuda.synchronize()
        total_ms.append((time.perf_counter() - t0) * 1e3)
        # --- solo kernel: eventos de CUDA (en CUDASIM se emulan con el reloj de CPU) ---
        e0, e1 = cuda.event(), cuda.event()
        e0.record()
        launch(d_a, d_b, d_c)
        e1.record()
        e1.synchronize()  # el lanzamiento es asíncrono: sin esto se mide casi nada
        kernel_ms.append(e0.elapsed_time(e1))  # ms entre las dos marcas, en el reloj de la GPU

    d_c.copy_to_host(c)
    max_abs_err = float(np.max(np.abs(c - ref)))
    checksum = float(np.sum(c, dtype=np.float64))
    ok = max_abs_err <= 1e-5
    print(f"kernel={name} n={n} block={block} grid={grid} hilos_lanzados={grid * block} "
          f"modo={'CUDASIM' if CUDASIM else 'GPU'}")
    print(f"    t_kernel_ms={median(kernel_ms):.4f} t_total_ms={median(total_ms):.4f} "
          f"checksum={checksum:.1f} max_abs_err={max_abs_err:.3g} verificacion={'OK' if ok else 'FALLA'}")
    return ok


def main():
    default_n = 2048 if CUDASIM else 1 << 24  # bajo CUDASIM cada hilo se simula en Python
    n = int(sys.argv[1]) if len(sys.argv) > 1 else default_n
    block = int(sys.argv[2]) if len(sys.argv) > 2 else 256
    which = sys.argv[3] if len(sys.argv) > 3 else "ambos"
    if n <= 0 or block <= 0 or block > 1024 or which not in ("vector_add", "saxpy", "ambos"):
        print("uso: a_vectores_numba.py [n>0] [block 1..1024] [vector_add|saxpy|ambos]")
        sys.exit(1)
    if CUDASIM and n > 20000:
        print("aviso: CUDASIM con n > 20000 puede tardar varios minutos", file=sys.stderr)
    ok = True
    if which != "saxpy":
        ok &= run("vector_add", n, block)
    if which != "vector_add":
        ok &= run("saxpy", n, block)
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
