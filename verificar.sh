#!/usr/bin/env bash
# Verifica todo el código del repositorio: en cada directorio con Makefile ejecuta
#   make clean && make && make test, y al final make clean,
# y resume PASS/PEND/FAIL. Uso: ./verificar.sh [ruta-raíz]   (por defecto, el repositorio completo,
# incluida la carpeta docente/ si existe). Variables: TIMEOUT_S (por directorio, 300 por defecto).
set -u
ROOT="${1:-.}"
TIMEOUT_S="${TIMEOUT_S:-300}"
if [ "$(id -u)" = "0" ]; then
  export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
export MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"
export NUMBA_ENABLE_CUDASIM="${NUMBA_ENABLE_CUDASIM:-1}"
pass=0; pend=0; fail=0; failed=()
LOGDIR=$(mktemp -d "${TMPDIR:-/tmp}/verificar.XXXXXX"); B="$LOGDIR/build.log"; T="$LOGDIR/test.log"; trap 'rm -rf "$LOGDIR"' EXIT
# Cada carpeta corre con stdin en /dev/null: mpirun lee stdin y se comería la lista de Makefiles.
# PEND: esqueleto del estudiante que compila y cuyas únicas pruebas en FAIL dicen "TODO pendiente"
# (p. ej. practicas/P4-openmp, cuyo README avisa que B y C fallan hasta completar los TODO).
while IFS= read -r mk; do
  d=$(dirname "$mk")
  printf '== %s\n' "$d"
  rm -f "$B" "$T"
  ( cd "$d" || exit 1
    timeout "$TIMEOUT_S" make -s clean >/dev/null 2>&1
    if timeout "$TIMEOUT_S" make -s >"$B" 2>&1; then timeout "$TIMEOUT_S" make -s test >"$T" 2>&1; r=$?; else r=90; fi
    timeout "$TIMEOUT_S" make -s clean >/dev/null 2>&1   # sin binarios en el árbol al terminar
    exit "$r" ) </dev/null
  rc=$?
  if [ "$rc" -eq 0 ] || { [ "$rc" -ne 90 ] && [ "$rc" -ne 124 ] && grep -qE '^[[:space:]]*FAIL' "$T" 2>/dev/null \
       && ! grep -E '^[[:space:]]*FAIL' "$T" | grep -qv 'TODO pendiente'; }; then
    if grep -qiE 'warning:' "$B"; then
      printf '   WARN  (compila, pero con warnings)\n'; grep -iE 'warning:' "$B" | head -3 | sed 's/^/      /'
    fi
    if [ "$rc" -eq 0 ]; then printf '   PASS\n'; pass=$((pass+1))
    else printf '   PEND  (compila; solo fallan pruebas con TODO pendiente del estudiante)\n'; pend=$((pend+1)); fi
  else
    printf '   FAIL\n'; { [ "$rc" -eq 90 ] && tail -15 "$B" || tail -15 "$T"; } 2>/dev/null | sed 's/^/      /'
    fail=$((fail+1)); failed+=("$d")
  fi
done < <(find "$ROOT" -name Makefile -not -path '*/.git/*' -not -path '*/cp-env/*' | sort)
printf '\nResumen: %d PASS, %d PEND, %d FAIL\n' "$pass" "$pend" "$fail"
for d in "${failed[@]:-}"; do [ -n "$d" ] && printf '  - %s\n' "$d"; done
[ "$fail" -eq 0 ]
