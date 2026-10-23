#!/usr/bin/env bash
# falso_gpu_kv.sh — Igual que falso_gpu.sh pero con el formato clave=valor de la plantilla de entrega final.
# Uso: ./falso_gpu_kv.sh N
echo "n=${1:-0}"
echo "checksum=3.141592653590"
echo "tiempo_kernel_s=0.003000"
echo "tiempo_total_s=0.012000"
