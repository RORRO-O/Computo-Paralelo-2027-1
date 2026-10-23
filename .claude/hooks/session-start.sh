#!/bin/bash
# session-start.sh — Hook SessionStart · Cómputo Paralelo · 6BM1 · ESCOM-IPN
# Solo actúa en sesiones cloud de Claude Code (CLAUDE_CODE_REMOTE=true). En una máquina local no hace nada.
#  1) Comprueba el toolchain del curso e instala lo que falte (idempotente). El lugar documentado para instalar
#     dependencias es el *setup script* del entorno cloud (.claude/cloud-setup-script.sh); este hook es la red de
#     seguridad: si el setup script ya corrió, termina en ~1 s; si no, tarda 30–60 s la primera vez.
#  2) Exporta variables para toda la sesión mediante $CLAUDE_ENV_FILE.
#  3) Imprime un resumen del hardware y de las reglas (el stdout de SessionStart se agrega al contexto de Claude).
set -uo pipefail
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
export DEBIAN_FRONTEND=noninteractive
log() { echo "[session-start] $*" >&2; }
SUDO=""; [ "$(id -u)" = 0 ] || { command -v sudo >/dev/null 2>&1 && SUDO="sudo -n"; }

# --- Paquetes del sistema: solo los que faltan -------------------------------------------------------------
APT=()
command -v mpicc     >/dev/null 2>&1 || APT+=(openmpi-bin libopenmpi-dev)        # MPI (mpicc, mpirun)
command -v hyperfine >/dev/null 2>&1 || APT+=(hyperfine)                          # benchmarking de línea de comandos
command -v valgrind  >/dev/null 2>&1 || APT+=(valgrind)                           # cachegrind/helgrind (sin PMU no hay perf)
command -v jq        >/dev/null 2>&1 || APT+=(jq)                                 # lo usan los hooks
ls /usr/lib/llvm-*/lib/libarcher.so >/dev/null 2>&1 || APT+=(libomp-dev libclang-rt-18-dev)  # clang -fopenmp + Archer (TSan para OpenMP)
if [ ${#APT[@]} -gt 0 ]; then
  log "instalando: ${APT[*]}"
  if ! $SUDO apt-get install -y -qq --no-install-recommends "${APT[@]}" >/dev/null 2>&1; then
    $SUDO apt-get update -qq >/dev/null 2>&1 || true
    $SUDO apt-get install -y -qq --no-install-recommends "${APT[@]}" >/dev/null 2>&1 || log "ADVERTENCIA: apt-get falló para: ${APT[*]}"
  fi
fi

# --- Python: solo lo que falta ---------------------------------------------------------------------------------
PIP=()
for m in numpy matplotlib numba mpi4py pandas pytest; do python3 -c "import $m" >/dev/null 2>&1 || PIP+=("$m"); done
if [ ${#PIP[@]} -gt 0 ]; then
  log "pip install ${PIP[*]}"
  pip install --quiet "${PIP[@]}" >/dev/null 2>&1 \
    || pip install --quiet --user "${PIP[@]}" >/dev/null 2>&1 \
    || pip install --quiet --break-system-packages "${PIP[@]}" >/dev/null 2>&1 \
    || log "ADVERTENCIA: pip falló para: ${PIP[*]}"
fi

# --- Variables para toda la sesión (cada comando Bash las carga antes de ejecutarse) --------------------------
if [ -n "${CLAUDE_ENV_FILE:-}" ] && ! grep -q 'OMPI_ALLOW_RUN_AS_ROOT' "$CLAUDE_ENV_FILE" 2>/dev/null; then
  cat >> "$CLAUDE_ENV_FILE" <<'ENV'
export PATH="$HOME/.local/bin:$PATH"
# mpirun corre como root dentro del contenedor y pedimos más procesos que núcleos (protocolo: se declara)
export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export MPIRUN_FLAGS="--oversubscribe"
export TSAN_OPTIONS="halt_on_error=0 second_deadlock_stack=1"
ENV
fi

# --- Resumen al contexto ----------------------------------------------------------------------------------------
CPU=$(lscpu 2>/dev/null | sed -n 's/^Model name:[[:space:]]*//p' | head -1)
OMPV=$(echo | gcc -fopenmp -dM -E - 2>/dev/null | sed -n 's/#define _OPENMP //p')
MPIV=$(mpirun --version 2>/dev/null | head -1); [ -n "$MPIV" ] || MPIV="sin MPI"
if command -v nvcc >/dev/null 2>&1; then CUDA="nvcc $(nvcc --version | sed -n 's/.*release \([0-9.]*\).*/\1/p')"
else CUDA="no (sin GPU: cuda-reviewer, NUMBA_ENABLE_CUDASIM=1, Colab/Kaggle)"; fi
PY=$(python3 - <<'PY' 2>/dev/null
mods = []
for m in ("numpy", "numba", "mpi4py", "matplotlib"):
    try:
        __import__(m); mods.append(m)
    except Exception:
        pass
print("/".join(mods) or "sin paquetes")
PY
)
ARCHER=$(ls /usr/lib/llvm-*/lib/libarcher.so 2>/dev/null | head -1)
echo "Entorno Cómputo Paralelo listo: $(nproc) núcleos sin SMT ($CPU) | gcc $(gcc -dumpfullversion 2>/dev/null) con OpenMP $OMPV | $MPIV | CUDA: $CUDA | TSan+Archer: $([ -n "$ARCHER" ] && echo sí || echo no) | perf de hardware: no (la VM no expone PMU; usa valgrind --tool=cachegrind) | Python $(python3 -V 2>/dev/null | cut -d' ' -f2): $PY. Reglas en CLAUDE.md. Skills: /medir /graficar /race-check /revisar-practica. Agentes: openmp-reviewer mpi-reviewer cuda-reviewer perf-analyst revisor-material calificador tutor-socratico."
exit 0
