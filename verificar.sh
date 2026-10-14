#!/usr/bin/env bash
# Verifica todo el código del repositorio: en cada directorio con Makefile ejecuta
#   make clean && make && make test
# y resume PASS/FAIL. Uso: ./verificar.sh [ruta-raíz]   (por defecto, el repositorio completo,
# incluida la carpeta docente/ si existe). Variables: TIMEOUT_S (por directorio, 300 por defecto).
set -u
ROOT="${1:-.}"
TIMEOUT_S="${TIMEOUT_S:-300}"
if [ "$(id -u)" = "0" ]; then
  export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
export MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"
export NUMBA_ENABLE_CUDASIM="${NUMBA_ENABLE_CUDASIM:-1}"
pass=0; fail=0; failed=()
while IFS= read -r mk; do
  d=$(dirname "$mk")
  printf '== %s\n' "$d"
  if ( cd "$d" && timeout "$TIMEOUT_S" make -s clean >/dev/null 2>&1; timeout "$TIMEOUT_S" make -s >/tmp/verificar_build.log 2>&1 && timeout "$TIMEOUT_S" make -s test >/tmp/verificar_test.log 2>&1 ); then
    if grep -qiE 'warning:' /tmp/verificar_build.log; then
      printf '   WARN  (compila y pasa, pero con warnings)\n'; grep -iE 'warning:' /tmp/verificar_build.log | head -3 | sed 's/^/      /'
    fi
    printf '   PASS\n'; pass=$((pass+1))
  else
    printf '   FAIL\n'; tail -15 /tmp/verificar_test.log 2>/dev/null | sed 's/^/      /'; fail=$((fail+1)); failed+=("$d")
  fi
done < <(find "$ROOT" -name Makefile -not -path '*/.git/*' -not -path '*/cp-env/*' | sort)
printf '\nResumen: %d PASS, %d FAIL\n' "$pass" "$fail"
for d in "${failed[@]:-}"; do [ -n "$d" ] && printf '  - %s\n' "$d"; done
[ "$fail" -eq 0 ]
