#!/bin/bash
# check-source.sh — Hook PostToolUse(Edit|Write) · Cómputo Paralelo · 6BM1 · ESCOM-IPN
# Compila el archivo recién editado con las banderas del curso (docs/CONVENCIONES.md §3) y
# devuelve a Claude los errores (exit 2 → stderr llega a Claude) o los warnings (additionalContext).
#   .c  → gcc -std=c11 -O2 -Wall -Wextra -fopenmp -c -o /dev/null (mpicc si incluye mpi.h); se compila de verdad, no solo
#         -fsyntax-only, para que aparezcan los warnings de flujo (-Wmaybe-uninitialized) · .cpp → g++ -std=c++17 (mpicxx)
#   .cu → nvcc -c si existe; si no, avisa que solo cabe revisión estática
#   .py → análisis sintáctico con ast
# Los .h no se compilan sueltos (dependen de quien los incluye). Variables: CP_STD_C (por defecto -std=c11).
set -uo pipefail
entrada=$(cat)
if command -v jq >/dev/null 2>&1; then
  archivo=$(printf '%s' "$entrada" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  archivo=$(printf '%s' "$entrada" | python3 -I -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi
{ [ -n "${archivo:-}" ] && [ -f "$archivo" ]; } || exit 0
case "$archivo" in */cp-env/*|*/tests/out/*|*/bin/*|*/.git/*) exit 0 ;; esac

dir=$(dirname "$archivo")
STD_C=${CP_STD_C:--std=c11}
rc=0; salida=""; cmd=""
usa_mpi() { grep -qE '^[[:space:]]*#[[:space:]]*include[[:space:]]*[<"]mpi\.h' "$1"; }

case "$archivo" in
  *.c)
    CC=gcc; usa_mpi "$archivo" && command -v mpicc >/dev/null 2>&1 && CC=mpicc
    cmd="$CC $STD_C -O2 -Wall -Wextra -fopenmp -c -o /dev/null -I$dir"
    salida=$($cmd "$archivo" 2>&1); rc=$? ;;
  *.cpp|*.cc|*.cxx)
    CXX=g++; usa_mpi "$archivo" && command -v mpicxx >/dev/null 2>&1 && CXX=mpicxx
    cmd="$CXX -std=c++17 -O2 -Wall -Wextra -fopenmp -c -o /dev/null -I$dir"
    salida=$($cmd "$archivo" 2>&1); rc=$? ;;
  *.cu)
    if ! command -v nvcc >/dev/null 2>&1; then
      ctx="nvcc no está en este entorno (sin GPU): $archivo no se compiló. Pide revisión estática a cuda-reviewer; compila y prueba en Colab/Kaggle o en la máquina con GPU. Para verificar la lógica de un kernel sin GPU usa numba.cuda con NUMBA_ENABLE_CUDASIM=1."
      command -v jq >/dev/null 2>&1 && jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
      exit 0
    fi
    cmd="nvcc -O2 -Xcompiler -Wall -c -o /dev/null -I$dir"
    salida=$($cmd "$archivo" 2>&1); rc=$? ;;
  *.py)
    cmd="python3 ast.parse"
    salida=$(python3 -I -c 'import ast,sys; ast.parse(open(sys.argv[1],encoding="utf-8").read(), sys.argv[1])' "$archivo" 2>&1); rc=$? ;;
  *) exit 0 ;;
esac

if [ "$rc" -ne 0 ]; then
  printf 'ERRORES al compilar %s (%s):\n%s\n' "$archivo" "$cmd" "$(printf '%s' "$salida" | head -c 6000)" >&2
  exit 2
fi
if [ -n "$salida" ] && command -v jq >/dev/null 2>&1; then
  ctx=$(printf 'Warnings en %s (%s). CONVENCIONES §3 exige -Wall -Wextra sin warnings; corrígelos antes de seguir:\n%s' \
        "$archivo" "$cmd" "$(printf '%s' "$salida" | head -c 6000)")
  jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
fi
exit 0
