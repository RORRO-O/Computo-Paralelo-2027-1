#!/bin/bash
# race-check.sh — Compila con ThreadSanitizer (clang + Archer, o gcc) y ejecuta para detectar carreras OpenMP.
# Uso: race-check.sh archivo.c [más.c] [--threads 4] [--asan] [--out salida.txt] -- [args del programa]
# Salida: 0 sin hallazgos · 1 carreras o problemas de ASan/UBSan · 2 error de compilación o archivo inexistente.
# Variables: CP_STD_C (por defecto -std=c11), RACE_CHECK_CC=gcc fuerza gcc aunque haya clang + Archer.
set -uo pipefail
SRCS=(); THREADS=4; ASAN=0; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --threads) THREADS=${2:?}; shift 2 ;;
    --asan) ASAN=1; shift ;;
    --out) OUT=${2:?}; shift 2 ;;
    --) shift; break ;;
    -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) SRCS+=("$1"); shift ;;
  esac
done
ARGS=("$@")
[ ${#SRCS[@]} -ge 1 ] || { echo "falta el archivo fuente" >&2; exit 2; }
for s in "${SRCS[@]}"; do [ -f "$s" ] || { echo "no existe: $s" >&2; exit 2; }; done
STD_C=${CP_STD_C:--std=c11}
INC="-I$(dirname "${SRCS[0]}")"
TMP=$(mktemp -d); trap 'rm -r "$TMP"' EXIT
BIN="$TMP/prog_tsan"; REP="$TMP/rep.txt"; : > "$REP"
di() { printf '%s\n' "$*" | tee -a "$REP"; }

ARCHER=$(ls /usr/lib/llvm-*/lib/libarcher.so 2>/dev/null | head -1)
if [ "${RACE_CHECK_CC:-}" != gcc ] && command -v clang >/dev/null 2>&1 && [ -n "$ARCHER" ] \
   && echo 'int main(void){return 0;}' | clang -x c -fopenmp -fsanitize=thread -o "$TMP/t" - 2>/dev/null; then
  CC=clang; MODO="clang + ThreadSanitizer + Archer ($ARCHER)"; export OMP_TOOL_LIBRARIES="$ARCHER"
else
  CC=gcc; MODO="gcc + ThreadSanitizer (libgomp sin instrumentar: solo cuentan los reportes que tocan tus archivos)"
fi
LIBM="-lm"   # siempre: las cabeceras del curso (cronometro.h, a_hist.h) usan libm y enlazarla de más no cuesta nada
di "== race-check: $MODO | OMP_NUM_THREADS=$THREADS | fuentes: ${SRCS[*]} | args: ${ARGS[*]:-}"
if ! $CC $STD_C -fopenmp -g -O1 -fno-omit-frame-pointer -fsanitize=thread -Wall -Wextra $INC "${SRCS[@]}" -o "$BIN" $LIBM 2>"$TMP/cc.txt"; then
  di "ERROR de compilación:"; cat "$TMP/cc.txt" | tee -a "$REP"
  [ -n "$OUT" ] && { mkdir -p "$(dirname "$OUT")"; cp "$REP" "$OUT"; }
  exit 2
fi
[ -s "$TMP/cc.txt" ] && { di "-- warnings de compilación (CONVENCIONES §3: deben corregirse):"; cat "$TMP/cc.txt" | tee -a "$REP"; }

SUPP="$(cd "$(dirname "$0")/.." && pwd)/suppressions.txt"
export TSAN_OPTIONS="${TSAN_OPTIONS:-halt_on_error=0 second_deadlock_stack=1} report_signal_unsafe=0 ignore_noninstrumented_modules=1 suppressions=$SUPP log_path=$TMP/tsan"
OMP_NUM_THREADS=$THREADS "$BIN" "${ARGS[@]}" >"$TMP/stdout.txt" 2>"$TMP/stderr.txt"; RC=$?
di "-- salida del programa (exit=$RC):"; tail -5 "$TMP/stdout.txt" | tee -a "$REP"
cat "$TMP"/tsan.* >> "$TMP/stderr.txt" 2>/dev/null
TOTAL=$(grep -c 'WARNING: ThreadSanitizer: data race' "$TMP/stderr.txt" 2>/dev/null || true); TOTAL=${TOTAL:-0}
pat=$(printf '%s|' "${SRCS[@]##*/}"); pat=${pat%|}
RACES=$(awk -v pat="(${pat}):[0-9]+" '/WARNING: ThreadSanitizer: data race/{if (blk && blk ~ pat) n++; blk=""} {blk=blk"\n"$0} END{if (blk && blk ~ pat) n++; print n+0}' "$TMP/stderr.txt")
HALLAZGOS=0
if [ "$RACES" -gt 0 ]; then
  HALLAZGOS=1
  di "-- $RACES carrera(s) de datos en TU código ($TOTAL reportes en total). Líneas implicadas (veces, archivo:línea):"
  grep -oE "[^ ]*(${pat}):[0-9]+" "$TMP/stderr.txt" | sed 's#.*/##' | sort | uniq -c | sort -rn | head -20 | tee -a "$REP"
  di "-- primer reporte completo:"
  awk '/WARNING: ThreadSanitizer: data race/{f=1} f{print} /^SUMMARY/{if (f) exit}' "$TMP/stderr.txt" | head -40 | tee -a "$REP"
else
  di "-- sin carreras de datos en tu código con $THREADS hilos ($TOTAL reportes solo del runtime, ignorados). Prueba también --threads 8 y otro tamaño."
fi

if [ "$ASAN" = 1 ]; then
  di "== AddressSanitizer + UBSan"
  if gcc $STD_C -fopenmp -g -O1 -fsanitize=address,undefined -fno-omit-frame-pointer $INC "${SRCS[@]}" -o "$TMP/prog_asan" $LIBM 2>/dev/null; then
    OMP_NUM_THREADS=$THREADS ASAN_OPTIONS=detect_leaks=1 "$TMP/prog_asan" "${ARGS[@]}" >/dev/null 2>"$TMP/asan.txt"; ARC=$?
    if [ $ARC -ne 0 ] || grep -q 'ERROR: AddressSanitizer\|runtime error' "$TMP/asan.txt"; then
      HALLAZGOS=1
      di "-- ASan/UBSan reportó problemas (exit=$ARC):"
      grep -E 'ERROR|runtime error|SUMMARY|#[0-9] .*(\.c|\.h):[0-9]+' "$TMP/asan.txt" | head -20 | tee -a "$REP"
    else
      di "-- ASan/UBSan: limpio."
    fi
  else
    di "-- no se pudo compilar con ASan/UBSan."
  fi
fi
[ -n "$OUT" ] && { mkdir -p "$(dirname "$OUT")"; cp "$REP" "$OUT"; echo "reporte guardado en $OUT"; }
exit "$HALLAZGOS"
