#!/usr/bin/env bash
# falso_gpu.sh — Simula un programa V3 para probar run_all.sh: imprime TIEMPO_S (con transferencias) y
# TIEMPO_KERNEL_S (sin transferencias) con valores fijos. Solo se usa en tests/run_tests.sh.
# Uso: ./falso_gpu.sh N
echo "n ${1:-0}"
echo "RESULTADO 3.141592653590"
echo "TIEMPO_KERNEL_S 0.002000"
echo "TIEMPO_S 0.010000"
