#!/usr/bin/env python3
"""Grafica perfiles de temperatura producidos con --print (una o varias salidas).

Uso:  python3 graficar_perfil.py perfil_seq.txt perfil_mpi.txt perfil_buggy.txt [-o perfil.png]
Cada archivo es la salida de jacobi1d_seq / jacobi1d_mpi / jacobi1d_mpi_buggy con --print:
las líneas "i valor" se grafican; las demás se ignoran.
"""
import argparse
import sys

import matplotlib
matplotlib.use("Agg")           # sin ventana: solo escribe el PNG
import matplotlib.pyplot as plt


def read_profile(path):
    xs, ys = [], []
    with open(path, encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if len(parts) == 2 and parts[0].isdigit():
                xs.append(int(parts[0]))
                ys.append(float(parts[1]))
    if not xs:
        sys.exit(f"{path}: no tiene líneas 'i valor'; ¿corriste con --print?")
    return xs, ys


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="+", help="salidas con --print")
    ap.add_argument("-o", "--output", default="perfil.png")
    args = ap.parse_args()

    fig, ax = plt.subplots(figsize=(7, 4))
    markers = ["o", "s", "^", "x", "d"]
    for k, path in enumerate(args.files):
        xs, ys = read_profile(path)
        ax.plot(xs, ys, marker=markers[k % len(markers)], markersize=4, linewidth=1, label=path)
    ax.set_xlabel("celda global i")
    ax.set_ylabel("temperatura u[i]")
    ax.set_title("Jacobi 1D: perfil final")
    ax.grid(True, linewidth=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(args.output, dpi=120)
    print(f"gráfica guardada en {args.output}")


if __name__ == "__main__":
    main()
