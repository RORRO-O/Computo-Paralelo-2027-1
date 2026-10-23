#!/usr/bin/env bash
# Pruebas de la práctica guiada S12. Comparan las versiones paralelas contra la secuencial
# (misma binaria, 1 hilo) con tolerancia en los flotantes y exactitud en los enteros.
# Tamaños pequeños (cada caso < 1 s). Termina con 0 solo si todo pasa.
set -u
cd "$(dirname "$0")/.." || exit 1
make -s all || { echo "FAIL: la compilación falló"; exit 1; }

fail=0
pass() { echo "PASS: $1"; }
failf() { echo "FAIL: $1"; fail=1; }
field() { grep "^$2=" <<<"$1" | cut -d= -f2; }                    # valor de una línea "clave=valor"
rel_close() {                                                      # |a-b| <= tol*max(|a|,1e-300)
    awk -v a="$1" -v b="$2" -v tol="$3" 'BEGIN{d=a-b; if(d<0)d=-d; m=(a<0?-a:a); if(m<1e-300)m=1e-300; exit !(d<=tol*m)}'
}

# ---- fases: 1 hilo vs 4 hilos (si TODO(1) sigue pendiente, ambas son secuenciales y también pasa)
N=100000; K=100
out1=$(OMP_NUM_THREADS=1 ./fases $N $K) || failf "fases no corre con 1 hilo"
out4=$(OMP_NUM_THREADS=4 ./fases $N $K) || failf "fases no corre con 4 hilos"
sum1=$(field "$out1" suma); sum4=$(field "$out4" suma)
hist1=$(field "$out1" histograma); hist4=$(field "$out4" histograma)
if rel_close "$sum1" "$sum4" 1e-9; then pass "fases: suma 4 hilos = suma 1 hilo (tol 1e-9) [$sum1]"
else failf "fases: suma difiere: 1 hilo=$sum1  4 hilos=$sum4"; fi
if [ "$hist1" = "$hist4" ] && [ -n "$hist1" ]; then pass "fases: histograma idéntico con 1 y 4 hilos"
else failf "fases: histograma difiere: $hist1 vs $hist4"; fi
total_bins=$(tr ',' '\n' <<<"$hist1" | awk '{s+=$1} END{print s}')
if [ "$total_bins" = "$N" ]; then pass "fases: el histograma cuenta los $N registros"
else failf "fases: el histograma suma $total_bins, no $N"; fi
frac_sum=$(awk '$1=="carga"||$1=="computo"||$1=="salida"{s+=$3} END{printf "%.3f", s}' <<<"$out1")
if rel_close "$frac_sum" 1.0 0.02; then pass "fases: las fracciones de las tres fases suman 1 ($frac_sum)"
else failf "fases: las fracciones suman $frac_sum"; fi
grep -q "TODO pendiente" <<<"$out4" && echo "INFO: TODO(1) sigue pendiente (la fase de cómputo corrió con 1 hilo)"

# ---- ejemplo_perfil: cada modo paralelo contra seq, con 4 hilos, y plan static vs dynamic
EN=50000; EM=3000
ref=$(OMP_NUM_THREADS=1 ./ejemplo_perfil $EN $EM seq) || failf "ejemplo_perfil no corre en modo seq"
ref_sum=$(field "$ref" suma_pesos); ref_pairs=$(field "$ref" pares_cercanos)
for mode in computo resumen ambas; do
    for plan in dynamic static; do
        out=$(OMP_NUM_THREADS=4 ./ejemplo_perfil $EN $EM $mode $plan) || { failf "ejemplo_perfil $mode $plan no corre"; continue; }
        s=$(field "$out" suma_pesos); c=$(field "$out" pares_cercanos)
        if rel_close "$ref_sum" "$s" 1e-9 && [ "$ref_pairs" = "$c" ]; then
            pass "ejemplo_perfil: modo=$mode plan=$plan coincide con seq (pares=$c)"
        else
            failf "ejemplo_perfil: modo=$mode plan=$plan: suma $s vs $ref_sum, pares $c vs $ref_pairs"
        fi
    done
done

# ---- argumentos inválidos deben rechazarse con código distinto de 0
./fases 0 10 >/dev/null 2>&1 && failf "fases acepta n=0" || pass "fases rechaza n=0"
./ejemplo_perfil 10 20 seq >/dev/null 2>&1 && failf "ejemplo_perfil acepta m>n" || pass "ejemplo_perfil rechaza m>n"

if [ $fail -eq 0 ]; then echo "TODAS LAS PRUEBAS PASARON"; else echo "HAY PRUEBAS FALLIDAS"; fi
exit $fail
