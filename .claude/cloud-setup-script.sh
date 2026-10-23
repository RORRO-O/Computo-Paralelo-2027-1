#!/bin/bash
# Setup script del entorno cloud de Claude Code (claude.ai → Code → menú del entorno → Edit → Setup script).
# No se instala desde el repositorio: se pega en esa pantalla. Corre como root en Ubuntu 24.04 antes de cada sesión
# nueva y su resultado se cachea, así que las sesiones arrancan con el toolchain listo. Debe terminar con código 0.
# El hook .claude/hooks/session-start.sh repite estas comprobaciones como red de seguridad (en ~1 s si ya está todo).
set -u
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq || true
apt-get install -y -qq --no-install-recommends \
  openmpi-bin libopenmpi-dev \
  libomp-dev libclang-rt-18-dev \
  hyperfine valgrind jq pandoc \
  >/dev/null || echo "apt-get falló; el hook SessionStart lo reintentará"
# mpi4py compila contra MPI: va después de apt. pytest ya viene en la imagen.
pip install --quiet numpy matplotlib numba mpi4py pandas pytest \
  || pip install --quiet --break-system-packages numpy matplotlib numba mpi4py pandas pytest \
  || echo "pip falló; el hook SessionStart lo reintentará"
exit 0
