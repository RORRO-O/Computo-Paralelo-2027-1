> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S10 · Ejemplo resuelto (por completar): ¿cuánto puede acelerar este programa? Amdahl con fracción **medida**

Código: `practica-guiada/profile_amdahl.c`. Compila con `make` dentro de `practica-guiada/` y corre con
`OMP_PROC_BIND=close OMP_PLACES=cores OMP_NUM_THREADS=4 ./profile_amdahl` (es lo que hace `make run`). Las
salidas de este documento son corridas reales en la máquina de autoría (máquina virtual, 4 vCPU Intel Xeon
2.1 GHz, gcc 13.3, `-O2`); las tuyas tendrán otros números donde se indica.

Este ejemplo es **por completar**: tiene tres huecos que resuelves tú antes de abrir la respuesta. Es la tercera
sesión de contenido de la unidad y el andamiaje se retira: el código está completo, los cálculos no.

## Problema

Un programa hace tres cosas en orden: **A** genera `n = 2 000 000` datos con una recurrencia
(`estado = estado·a + c`, cada valor depende del anterior), **B** transforma cada dato con 64 pasos de un mapa
logístico (cada elemento es independiente) y **C** suaviza el resultado con `y[i] = 0.9·y[i−1] + 0.1·z[i]` y suma.
Solo B se puede repartir con `parallel for` tal cual. Pregunta: **¿cuánto puede acelerar el programa con 4
hilos?** Hay que responderla **antes** de medir la versión paralela, y después comprobarla.

## Plan en tres líneas

1. Perfilar por secciones la versión **secuencial** con `omp_get_wtime()` (protocolo: calentamiento + 5
   repeticiones, mediana) y obtener la fracción secuencial `f` en **tiempo**.
2. Predecir con Amdahl `S(4)` y el techo `S(∞) = 1/f`.
3. Paralelizar B, medir con el protocolo, y comparar `S` medido con la predicción usando Karp–Flatt.

## Paso 1 · Perfil por secciones de la versión secuencial

El cronómetro va alrededor de **cada** sección, no del programa completo:

```c
double t0 = now();                 /* now() es omp_get_wtime() (common.h) */
generate(x, n);                    /* A: recurrencia, secuencial */
t[0] = now() - t0;

t0 = now();
transform_seq(x, z, n, iters);     /* B: elemento a elemento */
t[1] = now() - t0;

t0 = now();
double s = smooth_and_sum(z, y, n);/* C: y[i] depende de y[i-1], secuencial */
t[2] = now() - t0;
```

Salida real (es la primera mitad de la corrida con 4 hilos: el programa mide siempre primero el perfil secuencial):

```
== perfil secuencial: n=2000000 iters=64  (mediana de 5 repeticiones tras 1 calentamiento)
  seccion                          tiempo (s) fraccion
  A generar (secuencial)               0.0140     7.5%
  B transformar                        0.1689    90.3%
  C suavizar+sumar (secuencial)        0.0050     2.7%
  total                                0.1871   100.0%
  fraccion secuencial medida f = (A + C) / total = 0.101
  Amdahl con f medida: S(2)=1.82  S(4)=3.07  S(8)=4.68  S(inf)=9.88
```

Fíjate en el código fuente: la función de B (`transform_one` + `transform_seq`) tiene casi las mismas líneas que
la de A (`generate`), y C es la más larga de las tres. Nada de eso importa para Amdahl.

**Hueco 1.** Con la tabla de arriba, calcula la fracción secuencial `f = (T_A + T_C) / T_total`. Escríbela con tres
decimales **antes** de abrir la respuesta. ¿Qué porcentaje de las *líneas* del programa es secuencial y por qué ese
dato no sirve?

<details><summary>Respuesta</summary>

`f = (0.0140 + 0.0050) / 0.1871 = 0.101`. Alrededor del 10 % del **tiempo** es secuencial. En líneas de código, las
funciones de A y C juntas (`generate`, `smooth_and_sum`) son más de la mitad de las líneas de las tres secciones; si
usaras ese dato (idea errónea 2) predecirías un techo de menos de 2×, y el programa en realidad puede llegar casi
a 9.88×. La fracción de Amdahl es una fracción de
**tiempo medido** en la versión secuencial; el programa la imprime en la línea `fraccion secuencial medida`.
</details>

**Hueco 2.** Con tu `f`, predice el *speedup* de Amdahl con 2, 4 y 8 hilos y el techo con infinitos hilos:
`S(p) = 1 / (f + (1 − f)/p)`. Anota los cuatro números.

<details><summary>Respuesta</summary>

`S(2) = 1.82`, `S(4) = 3.07`, `S(8) = 4.68`, `S(∞) = 1/f = 9.88`. Es lo que imprime la línea `Amdahl con f medida`.
Observa cuánto se gana de 4 a 8 hilos (3.07 → 4.68) frente a lo que se gana de 1 a 2: la parte secuencial pesa
cada vez más. Esta predicción es un **techo**: supone que B escala perfectamente y que repartirlo no cuesta nada.
</details>

## Paso 2 · Paralelizar B y medir

El único cambio es el pragma sobre el ciclo de B; A y C quedan igual:

```c
static void transform_par(const double *x, double *z, long n, int iters)
{
    #pragma omp parallel for schedule(static)   /* elementos independientes: reparto estático */
    for (long i = 0; i < n; i++) z[i] = transform_one(x[i], iters);
}
```

Salida real con 4 hilos (misma corrida; el programa mide primero el perfil secuencial y luego el paralelo):

```
== con 4 hilos (solo la seccion B es paralela)
  B transformar: 0.1689 s -> 0.0520 s   speedup de B = 3.25  eficiencia de B = 0.81
  total:         0.1871 s -> 0.0726 s   speedup total = 2.58  eficiencia total = 0.64
  Amdahl predijo S(4) = 3.07 con f = 0.101;  Karp-Flatt con el speedup total medido: f = 0.184
  reloj de pared (omp_get_wtime) de las 6 corridas paralelas: 0.480 s;  clock() en el mismo lapso: 1.400 s  (clock() suma la CPU de los 4 hilos)
  suma de control: secuencial=1335861.687405 paralela=1335861.687405  coinciden
  total        hilos=4  mediana=0.0726 s  (min 0.0698, max 0.1173)  speedup=2.58  eficiencia=0.64  ok
  seccionB     hilos=4  mediana=0.0520 s  (min 0.0499, max 0.0956)  speedup=3.25  eficiencia=0.81  ok
```

**Hueco 3.** Con los dos totales (secuencial y con 4 hilos) calcula (a) el *speedup* total medido, (b) su
eficiencia, (c) la fracción secuencial de Karp–Flatt `f_KF = (1/S − 1/p) / (1 − 1/p)`. Compárala con la `f` medida
del Hueco 1: ¿coinciden? Si no, ¿dónde está la diferencia?

<details><summary>Respuesta</summary>

(a) `S = 0.1871 / 0.0726 = 2.58`. (b) `E = 2.58 / 4 = 0.64`. (c) `f_KF = (1/2.58 − 1/4) / 0.75 = 0.184`.
La `f` medida fue 0.101; Karp–Flatt dice que el programa **se comporta** como si fuera secuencial en un 18 %. La
diferencia no está en A ni en C (no cambiaron): está en que B no escaló 4×, sino 3.25× (eficiencia de B: 0.81). Esa
pérdida dentro de la región paralela (crear y sincronizar hilos, memoria, competencia por el procesador en una
máquina virtual) entra en `f_KF` como si fuera código secuencial. Lectura: `f_KF ≈ f` → el límite es la parte
secuencial; `f_KF ≫ f` → el límite está dentro de la región paralela.
</details>

**Pausa 4.** La línea `reloj de pared …` de la salida dice que `clock()` midió casi tres veces más tiempo que
`omp_get_wtime()` en el mismo lapso. ¿Por qué? ¿Qué *speedup* saldría si alguien cronometrara con `clock()`?

<details><summary>Respuesta</summary>

`clock()` devuelve tiempo de **CPU** del proceso: suma lo que consumen **todos** los hilos. Con 4 hilos ocupados,
un segundo de pared son hasta cuatro segundos de CPU. El usuario percibe el tiempo de pared; por eso el protocolo
exige `omp_get_wtime()`. Con `clock()`, `T(4)` saldría inflado y el *speedup* se encogería hasta parecer que
paralelizar no sirvió o empeoró (idea errónea 31).
</details>

**Pausa 5.** Si tuvieras que subir el techo del programa, ¿qué sección atacarías primero y qué habría que cambiar
en ella? (pista: ¿qué impide repartir A con `parallel for`?)

<details><summary>Respuesta</summary>

A, porque es la que más pesa de las secuenciales. No se reparte tal cual porque cada valor depende del anterior
(dependencia acarreada por el ciclo, la misma que verás en el *scan* de S11, lunes 26 de octubre). Se arregla con
un generador que admita saltar hacia adelante, o con una semilla distinta por bloque (cambia la secuencia, no la
estadística). Después iría C, que es un filtro recursivo: también tiene dependencia y necesita el patrón de dos
fases de S11. Lo que **no** sirve es agregar hilos a B: el techo sigue en `1/f`.
</details>

## Variante que falla · medir con `-O0`, una sola vez y sin calentamiento

Es la combinación de la idea errónea 5. Compilado con `-O0`, el mismo perfil secuencial en la máquina de autoría
dio `A = 0.0583 s`, `B = 0.8715 s`, `C = 0.0223 s`: todo 4–5 veces más lento, pero no en la misma proporción (B se
frenó 5.2×, A 4.2×), así que `f` bajó a `0.084` (frente a `0.101` con `-O2`) y el techo de Amdahl subió a 11.9×.
Estarías prediciendo el techo de un programa que nadie va a ejecutar, y el *speedup* que midieras después
compararía dos binarios lentos. Si además tomas la primera corrida en vez de la mediana, pagas la creación del
equipo de hilos y las cachés frías dentro de `T(4)`. El `Makefile` no tiene objetivo para `-O0` a propósito;
compruébalo a mano si quieres: `gcc -std=c11 -O0 -fopenmp profile_amdahl.c -o pa_O0 -lm && OMP_NUM_THREADS=1
./pa_O0`.

## Modifica la fracción secuencial sin tocar A ni C

El segundo argumento es el trabajo por elemento de B. Con `iters = 8`, B pesa menos y `f` sube; con `iters = 256`,
`f` baja. Dos corridas reales con 4 hilos:

```
### profile_amdahl 2000000 8 (iters=8: f mas grande)
  fraccion secuencial medida f = (A + C) / total = 0.551
  Amdahl con f medida: S(2)=1.29  S(4)=1.51  S(8)=1.65  S(inf)=1.81
  B transformar: 0.0149 s -> 0.0045 s   speedup de B = 3.27  eficiencia de B = 0.82
  total:         0.0338 s -> 0.0252 s   speedup total = 1.34  eficiencia total = 0.34
  Amdahl predijo S(4) = 1.51 con f = 0.551;  Karp-Flatt con el speedup total medido: f = 0.661
### profile_amdahl 2000000 256 (iters=256: f mas pequena)
  fraccion secuencial medida f = (A + C) / total = 0.018
  Amdahl con f medida: S(2)=1.96  S(4)=3.79  S(8)=7.10  S(inf)=55.28
  B transformar: 1.1386 s -> 0.2820 s   speedup de B = 4.04  eficiencia de B = 1.01
  total:         1.1632 s -> 0.3071 s   speedup total = 3.79  eficiencia total = 0.95
  Amdahl predijo S(4) = 3.79 con f = 0.018;  Karp-Flatt con el speedup total medido: f = 0.019
```

Mismo código, misma máquina: el techo de Amdahl depende de **cuánto tiempo** es secuencial, y eso lo decide el tamaño
del trabajo paralelo, no el número de líneas. Con `iters = 256` la sección B pesa el 98 % y escaló 4.04× (una
eficiencia de 1.01 es ruido de medición de ±2 %, no un efecto de caché; se reporta tal cual), así que `f_KF` (0.019)
coincide con la `f` medida (0.018): el único límite que queda es la parte secuencial. Con `iters = 8`, B es tan
corta (4.5 ms con 4 hilos) que la sobrecarga de la región pesa y `f_KF` (0.66) supera a `f` (0.55).

## Qué te llevas

1. La fracción secuencial se **mide** por secciones con `omp_get_wtime()` sobre la versión secuencial; se expresa en
   tiempo, nunca en líneas.
2. Amdahl con `f` medida da un **techo** (`1/f`) y una predicción para cada `p`; se escribe antes de medir.
3. Karp–Flatt convierte el `S` medido en una `f` efectiva: comparada con la `f` medida dice si el problema está
   fuera (código secuencial) o dentro (sobrecarga) de la región paralela.
4. `clock()` no mide tiempo de pared; `-O0` no mide el programa real; una corrida no es una medición.
