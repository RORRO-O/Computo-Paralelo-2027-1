#!/usr/bin/env python3
"""flatten_map_numba.py — Espejo en Numba CUDA de flatten_map_2d.cu.

Mismo problema (paso de Jacobi 2D sobre una malla aplanada por filas), mismos kernels (2D completo,
1D con TODO(1)), misma referencia secuencial (NumPy) y misma salida. Sirve para:
  * verificar la lógica de índices sin GPU:  NUMBA_ENABLE_CUDASIM=1 python3 flatten_map_numba.py 10 8 3
  * correr en Colab/Kaggle con GPU real:     python3 flatten_map_numba.py 1024 1024 100 16 16 2d
Bajo CUDASIM los tiempos no significan nada (cada hilo es un hilo de Python); solo cuenta la verificación.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Unidad V · Sesión S05 (martes 1 de diciembre de 2026)

Uso: python3 flatten_map_numba.py [alto] [ancho] [iteraciones] [bloque_x] [bloque_y] [modo 2d|1d]
                                  [copiar_cada_iter 0|1] [fila_objetivo] [col_objetivo]
Por defecto: 1024 1024 100 16 16 2d 0 3 5
"""
import os
import sys
import time

import numpy as np
from numba import cuda, float32

CUDASIM = os.environ.get("NUMBA_ENABLE_CUDASIM", "0") == "1"
REPS = 1 if CUDASIM else 5          # bajo el simulador una repetición basta (no se mide nada)
TOP_VALUE = np.float32(100.0)
TOL = 1e-4


# -------------------------------------------------------------------------------------------
# Kernels (misma estructura que en flatten_map_2d.cu)
# -------------------------------------------------------------------------------------------
@cuda.jit
def jacobi_step_2d(inp, out, height, width, target_r, target_c, who):
    c = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x   # columna
    r = cuda.blockIdx.y * cuda.blockDim.y + cuda.threadIdx.y   # fila
    if r >= height or c >= width:                              # guardia: hilos sobrantes
        return
    idx = r * width + c
    if r == target_r and c == target_c:                        # registro de quién procesó la celda objetivo
        who[0] = cuda.blockIdx.x
        who[1] = cuda.blockIdx.y
        who[2] = cuda.threadIdx.x
        who[3] = cuda.threadIdx.y
        who[4] = idx
    if r == 0 or r == height - 1 or c == 0 or c == width - 1:  # frontera fija
        out[idx] = inp[idx]
        return
    out[idx] = float32(0.25) * (inp[idx - width] + inp[idx + width] + inp[idx - 1] + inp[idx + 1])


@cuda.jit
def jacobi_step_1d(inp, out, height, width, target_r, target_c, who):
    idx = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x  # un índice lineal por hilo
    if idx >= height * width:                                   # guardia del último bloque
        return
    # TODO(1): calcula la fila r y la columna c a partir de idx (idx = r*width + c).
    # Mientras r y c valgan -1, la guardia de abajo descarta a todos los hilos y el programa
    # imprime "TODO pendiente" en modo 1d.
    r = -1
    c = -1
    if r < 0 or c < 0:
        return
    if r == target_r and c == target_c:
        who[0] = cuda.blockIdx.x
        who[1] = 0
        who[2] = cuda.threadIdx.x
        who[3] = 0
        who[4] = idx
    if r == 0 or r == height - 1 or c == 0 or c == width - 1:
        out[idx] = inp[idx]
        return
    out[idx] = float32(0.25) * (inp[idx - width] + inp[idx + width] + inp[idx - 1] + inp[idx + 1])


# -------------------------------------------------------------------------------------------
# Anfitrión
# -------------------------------------------------------------------------------------------
def init_grid(h, w):
    g = np.zeros(h * w, dtype=np.float32)
    g[0:w] = TOP_VALUE                      # fila 0 completa: índices 0..w-1
    return g


def jacobi_cpu(init, h, w, iters):
    """Referencia secuencial (NumPy, float32, mismo orden de sumas que el kernel)."""
    cur = init.copy()
    nxt = init.copy()                       # frontera ya copiada en ambos
    for _ in range(iters):
        g = cur.reshape(h, w)
        n = nxt.reshape(h, w)
        n[1:-1, 1:-1] = np.float32(0.25) * (g[:-2, 1:-1] + g[2:, 1:-1] + g[1:-1, :-2] + g[1:-1, 2:])
        cur, nxt = nxt, cur
    return cur


def median(v):
    s = sorted(v)
    n = len(s)
    return s[n // 2] if n % 2 else 0.5 * (s[n // 2 - 1] + s[n // 2])


def ceil_div(a, b):
    return (a + b - 1) // b


def run_once(cfg, h_init, d_a, d_b, d_who, grid, block, kernel):
    """Una corrida completa: H2D, `iters` pasos y D2H. Regresa (t_kernel_s, t_total_s, h_out)."""
    h, w, iters = cfg["h"], cfg["w"], cfg["iters"]
    t_kernel = 0.0
    cuda.synchronize()
    t_total0 = time.perf_counter()
    if not cfg["copy_each"]:
        # Porte correcto: subir una vez, iterar en la GPU, bajar una vez.
        d_a.copy_to_device(h_init)
        d_b.copy_to_device(h_init)
        cuda.synchronize()
        t_k0 = time.perf_counter()
        for _ in range(iters):
            kernel[grid, block](d_a, d_b, h, w, cfg["target_r"], cfg["target_c"], d_who)
            d_a, d_b = d_b, d_a                 # ping-pong de punteros, sin copias
        cuda.synchronize()                      # sin esto se mide el encolado, no la ejecución
        t_kernel = time.perf_counter() - t_k0
        h_out = d_a.copy_to_host()
    else:
        # Porte incorrecto (a propósito): copiar ida y vuelta en cada iteración.
        h_scratch = h_init.copy()
        d_b.copy_to_device(h_init)
        for _ in range(iters):
            d_a.copy_to_device(h_scratch)
            cuda.synchronize()
            t_k0 = time.perf_counter()
            kernel[grid, block](d_a, d_b, h, w, cfg["target_r"], cfg["target_c"], d_who)
            cuda.synchronize()
            t_kernel += time.perf_counter() - t_k0
            h_scratch = d_b.copy_to_host()
        h_out = h_scratch
    cuda.synchronize()
    t_total = time.perf_counter() - t_total0
    return t_kernel, t_total, h_out


def main(argv):
    cfg = {"h": 1024, "w": 1024, "iters": 100, "bx": 16, "by": 16, "mode_2d": True,
           "copy_each": False, "target_r": 3, "target_c": 5}
    if len(argv) > 1 and argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0
    if len(argv) > 1: cfg["h"] = int(argv[1])
    if len(argv) > 2: cfg["w"] = int(argv[2])
    if len(argv) > 3: cfg["iters"] = int(argv[3])
    if len(argv) > 4: cfg["bx"] = int(argv[4])
    if len(argv) > 5: cfg["by"] = int(argv[5])
    if len(argv) > 6:
        if argv[6] not in ("2d", "1d"):
            print(__doc__, file=sys.stderr)
            return 1
        cfg["mode_2d"] = argv[6] == "2d"
    if len(argv) > 7: cfg["copy_each"] = int(argv[7]) != 0
    if len(argv) > 8: cfg["target_r"] = int(argv[8])
    if len(argv) > 9: cfg["target_c"] = int(argv[9])

    h, w, iters, bx, by = cfg["h"], cfg["w"], cfg["iters"], cfg["bx"], cfg["by"]
    if h < 3 or w < 3 or iters < 1 or bx < 1 or by < 1 or bx * by > 1024:
        print("Parámetros inválidos: alto y ancho >= 3, iteraciones >= 1, 1 <= bloque_x*bloque_y <= 1024",
              file=sys.stderr)
        return 1
    if not (0 <= cfg["target_r"] < h and 0 <= cfg["target_c"] < w):
        print(f"La celda objetivo ({cfg['target_r']},{cfg['target_c']}) está fuera de la malla {h}x{w}",
              file=sys.stderr)
        return 1

    n = h * w
    mode = "2d" if cfg["mode_2d"] else "1d"
    print(f"# flatten_map_numba · alto={h} ancho={w} iteraciones={iters} bloque={bx}x{by} modo={mode} "
          f"copiar_cada_iter={int(cfg['copy_each'])}" + ("  [CUDASIM: tiempos no representativos]" if CUDASIM else ""))
    if not CUDASIM:
        dev = cuda.get_current_device()
        print(f"GPU: {dev.name.decode() if isinstance(dev.name, bytes) else dev.name}")

    h_init = init_grid(h, w)

    # Referencia CPU: 1 calentamiento + REPS repeticiones; mediana.
    h_ref = jacobi_cpu(h_init, h, w, iters)
    t_cpu_v = []
    for _ in range(REPS):
        t0 = time.perf_counter()
        h_ref = jacobi_cpu(h_init, h, w, iters)
        t_cpu_v.append(time.perf_counter() - t0)
    t_cpu = median(t_cpu_v)

    print(f"indice lineal de (fila {cfg['target_r']}, col {cfg['target_c']}) con ancho {w}: "
          f"{cfg['target_r'] * w + cfg['target_c']}")

    d_a = cuda.to_device(np.zeros(n, dtype=np.float32))
    d_b = cuda.to_device(np.zeros(n, dtype=np.float32))
    d_who = cuda.to_device(np.full(5, -1, dtype=np.int32))

    if cfg["mode_2d"]:
        block = (bx, by)
        grid = (ceil_div(w, bx), ceil_div(h, by))          # x ↔ columnas, y ↔ filas
        kernel = jacobi_step_2d
        launched = grid[0] * grid[1] * bx * by
        print(f"malla 2D: bloques={grid[0]}x{grid[1]} hilos/bloque={bx}x{by}")
    else:
        block = (bx * by,)
        grid = (ceil_div(n, bx * by),)
        kernel = jacobi_step_1d
        launched = grid[0] * bx * by
        print(f"malla 1D: bloques={grid[0]} hilos/bloque={bx * by}")
    print(f"hilos lanzados={launched} celdas={n} hilos ociosos={launched - n} "
          f"({100.0 * (launched - n) / launched:.1f} %)")

    # Calentamiento (incluye la compilación JIT en GPU real) + REPS corridas medidas.
    run_once(cfg, h_init, d_a, d_b, d_who, grid, block, kernel)
    t_kernel_v, t_total_v, h_out = [], [], None
    for _ in range(REPS):
        tk, tt, h_out = run_once(cfg, h_init, d_a, d_b, d_who, grid, block, kernel)
        t_kernel_v.append(tk)
        t_total_v.append(tt)

    who = d_who.copy_to_host()
    verdict, exit_code = "FAIL", 1
    if who[4] == -1:
        if not cfg["mode_2d"]:
            print("TODO pendiente: el kernel 1D aún no recupera (fila, columna) a partir de idx. "
                  "Completa TODO(1) en jacobi_step_1d.")
            verdict, exit_code = "TODO", 0
        else:
            print("ningún hilo procesó la celda objetivo: revisa la malla y la guardia")
    else:
        print(f"hilo que la proceso: blockIdx=({who[0]},{who[1]}) threadIdx=({who[2]},{who[3]}) idx={who[4]}")
        max_diff = float(np.max(np.abs(h_out - h_ref)))
        ok = max_diff <= TOL
        verdict, exit_code = ("PASS", 0) if ok else ("FAIL", 1)
        print(f"verificacion vs CPU: {verdict} (max |diff| = {max_diff:.3e}, tol = {TOL:.1e})")
        print(f"checksum = {float(np.sum(h_out, dtype=np.float64)):.6f}")

    t_kernel, t_total = median(t_kernel_v), median(t_total_v)
    sk = t_cpu / t_kernel if t_kernel > 0 else float("nan")
    st = t_cpu / t_total if t_total > 0 else float("nan")
    print(f"t_cpu    (mediana de {REPS}, s) = {t_cpu:.6f}")
    print(f"t_kernel (mediana de {REPS}, s) = {t_kernel:.6f}   <- solo kernels (perf_counter + synchronize)")
    print(f"t_total  (mediana de {REPS}, s) = {t_total:.6f}   <- H2D + kernels + D2H")
    print(f"speedup sin transferencias = {sk:.2f}")
    print(f"speedup con transferencias = {st:.2f}")
    print("CSV,modo,bloque_x,bloque_y,alto,ancho,iteraciones,copiar_cada_iter,t_cpu_s,t_kernel_s,t_total_s,"
          "speedup_kernel,speedup_total,verificacion")
    print(f"CSV,numba-{mode},{bx},{by},{h},{w},{iters},{int(cfg['copy_each'])},{t_cpu:.6f},{t_kernel:.6f},"
          f"{t_total:.6f},{sk:.2f},{st:.2f},{verdict}")
    return exit_code


if __name__ == "__main__":
    sys.exit(main(sys.argv))
