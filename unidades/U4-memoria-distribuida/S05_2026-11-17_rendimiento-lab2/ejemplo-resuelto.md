> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · Ejemplo resuelto: del *ping-pong* al n a partir del cual conviene usar 4 procesos

Todo el código está en `practica-guiada/`. Las salidas son reales, obtenidas en el entorno de autoría (VM con
4 núcleos Intel Xeon a 2.1 GHz, 1 hilo por núcleo, Open MPI 4.1.6, gcc 13.3, `-O2`; la corrida completa está en
`practica-guiada/resultados-ejemplo/`). En el laboratorio los
números cambian; el procedimiento no. Los tiempos no son deterministas: dos corridas difieren en algunos por
ciento, y mucho más si hay carga ajena en la máquina (ver la variante que falla, al final).

## Problema

Tienes el Jacobi 1D con halos de la S04 (`jacobi_mpi.c`). Antes de medir, quieres **predecir** el *speedup* con
2 y 4 procesos para n = 1 000 000 y para n = 1 000, y decidir **a partir de qué n** conviene usar 4 procesos en
esta máquina. Después mides y comparas.

## Plan (3 líneas)

1. Medir α y β con el *ping-pong* → costo de un halo de 8 bytes.
2. Medir t_c (tiempo por punto por iteración) con la versión secuencial → costo del cómputo.
3. Armar `T_p(n) = (n/p)·t_c + 2(α + 8/β)`, predecir, medir con `escalado.sh`, comparar; despejar n*.

## Paso 1 · α y β con el *ping-pong*

El núcleo de `pingpong.c` (rango 0 envía, rango 1 devuelve; se cronometran `rounds` viajes redondos):

```c
for (int k = 0; k < rounds; k++) {
    if (rank == 0) {
        MPI_Send(buf, bytes, MPI_BYTE, 1, 0, MPI_COMM_WORLD);
        MPI_Recv(buf, bytes, MPI_BYTE, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    } else {
        MPI_Recv(buf, bytes, MPI_BYTE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Send(buf, bytes, MPI_BYTE, 0, 0, MPI_COMM_WORLD);
    }
}
double elapsed = MPI_Wtime() - t0;
if (r >= 0) t[r] = elapsed / (2.0 * rounds); /* ida y vuelta -> ida */
```

`make run-pingpong` (`mpirun -np 2 ./pingpong`):

```
ping-pong entre rangos 0 y 1 (mediana de 5 repeticiones, tras calentamiento; factor de rondas 1.00)
     bytes    T_ida(us)      min(us)      max(us)         MB/s   modelo(us)
         8        0.403        0.374        0.595         19.9        0.404
      1024        1.265        1.204        1.347        809.6        0.577
     65536       15.890       15.623       20.378       4124.2       11.534
   1048576      178.507      162.061      187.284       5874.2      178.507
   4194304      616.037      581.621      631.870       6808.5      712.818
alpha (latencia) ~ 0.403 us ; beta (ancho de banda) ~ 5.89 GB/s
modelo: T_com(m) = 0.403 us + m / (5.89 GB/s)
RESULT,alpha_us,0.4029,beta_GBps,5.8874
```

Lectura: **α ≈ 0.40 µs** (la fila de 8 bytes) y **β ≈ 5.9 GB/s** (ajustado con 1 MiB). Un halo de 8 bytes cuesta
0.403 + 0.0014 µs: es α. En otra corrida de la misma VM salió α = 0.397 µs y β = 6.58 GB/s: el 10 % de
diferencia en β es normal; en α la diferencia es de 1.5 %.

**Pausa 1. ¿Por qué se divide entre `2·rounds` y no entre `rounds`?**
<details><summary>Respuesta</summary>
Cada vuelta del ciclo es un viaje de ida y otro de regreso: dos mensajes. Lo que queremos es el costo de **un**
mensaje (lo que paga un halo). Medimos muchas vueltas porque un solo mensaje de 8 bytes dura menos que la
resolución útil del reloj; y se repite 5 veces con calentamiento para tomar la mediana (protocolo §2).
</details>

**Pausa 2. ¿Por qué α se lee del mensaje de 8 bytes y β se ajusta con el de 1 MiB, y no al revés?**
<details><summary>Respuesta</summary>
En `T = α + m/β`, con m = 8 bytes el término m/β es de nanosegundos: el tiempo medido **es** α (con un error
despreciable). Con m = 1 MiB el término m/β es cientos de microsegundos y α casi no cuenta: despejando,
β = m/(T − α). Si se hiciera al revés, el ruido de un término enmascararía al otro. La columna `modelo(us)`
muestra que entre 1 KiB y 64 KiB el modelo de dos parámetros se desvía: hay cambios de protocolo interno y
efectos de caché que una recta no captura. Para los halos de 8 bytes eso no importa.
</details>

## Paso 2 · t_c con la versión secuencial

`./jacobi_seq 1000000 1200` (6 corridas: 1 de calentamiento + 5 medidas):

```
jacobi_seq: n=1000000 iters=1200 reps=5 | mediana=1.0646 s (min 1.0218, max 1.1820) | 8.872e-04 s/iter | 0.887 ns por punto-iteración | checksum=2.714529e+01
RESULT,1,1000000,1200,5,1.022171;1.182017;1.021782;1.074771;1.064601,1.064601,1.021782,1.182017,8.871671e-04,0.000000e+00,2.7145288395e+01,0.90811693532361526
```

**t_c ≈ 0.89 ns** por punto por iteración (mediana 1.0646 s / 1 200 iteraciones / 10⁶ puntos). Entre repeticiones
hay un 16 % de diferencia (1.02–1.18 s); otra corrida dio 0.79 ns. Con un t_c de ±10 % el modelo sigue sirviendo
para lo que se usa: decidir el orden de magnitud de n*.

**Pausa 3. ¿Por qué t_c se mide con n = 1 000 000 y no con n = 1 000, que es más rápido?**
<details><summary>Respuesta</summary>
Con n = 1 000 los dos arreglos (16 KB) caben en la caché L1 y t_c sale menor que con n = 1 000 000 (16 MB, que
no cabe en L2). Como el n que nos interesa predecir es grande, t_c se mide a esa escala. El modelo con un solo
t_c es una aproximación: en la fase Crear de la práctica vas a ver que cerca de n* el bloque por proceso sí cabe
en caché y el cómputo sale algo más barato de lo que predice el modelo.
</details>

## Paso 3 · Predecir con el modelo

Por iteración y por proceso interior: cómputo `(n/p)·t_c`; comunicación `T_halo = 2(α + 8/β)`.
`python3 modelo.py --alpha-us <α> --beta-gbps <β> --tc-ns <t_c> --p 4 --tabla` con los valores de arriba:

```
$ python3 modelo.py --alpha-us 0.4029 --beta-gbps 5.8874 --tc-ns 0.887 --p 4 --tabla
T_halo por iteración = 2*(alpha + 8 B/beta) = 0.809 us
t_c = 0.887 ns por punto;  p = 4
n* (punto de equilibrio, S=1):      1,215 puntos
n_E (eficiencia >= 50%):            3,646 puntos
           n    T_1(us)    T_p(us)      S      E  comp/comm
       1,000       0.89       1.03   0.86    22%        0.3
       3,000       2.66       1.47   1.81    45%        0.8
      10,000       8.87       3.03   2.93    73%        2.7
      30,000      26.61       7.46   3.57    89%        8.2
     100,000      88.70      22.98   3.86    96%       27.4
     300,000     266.10      67.33   3.95    99%       82.3
   1,000,000     887.00     222.56   3.99   100%      274.3
   3,000,000    2661.00     666.06   4.00   100%      822.8
```

Lectura: con n = 1 000 000 la razón cómputo/comunicación es de cientos (274): el *speedup* debería acercarse a 4
(si la memoria no limita). Con n = 1 000 la razón es 0.3: cuatro procesos tardan **más** que uno (S = 0.86). Y hay
un n* de unos 1 200 puntos donde se cruzan. Predicción escrita antes de medir: S(2) ≈ 2 y S(4) ≈ 3.5–4 para
n = 10⁶; S(4) < 1 para n = 1 000.

## Paso 4 · Medir y comparar

`make run` (`escalado.sh` con N = 1 000 000, ITERS = 1 200, NLOCAL = 250 000; p = 1, 2, 4 y 8 sobre-suscrito):

<!-- GEN:MED:escalado -->
```
$ make run
== Entorno: 4 núcleos físicos (4 CPU lógicas); ITERS=1200; REPS=5 (+1 calentamiento); MPIRUN_FLAGS='--oversubscribe'
== Escalabilidad fuerte: n=1000000
config         p          n  mediana_s  speedup     efic
seq            1    1000000   1.087526   1.0000   1.0000
mpi            1    1000000   1.138031   0.9556   0.9556
mpi            2    1000000   0.615347   1.7673   0.8837
mpi            4    1000000   0.313223   3.4721   0.8680
mpi_oversub    8    1000000   0.453003   2.4007   0.3001
== Escalabilidad débil: n/p=250000
config         p          n  mediana_s  S_escal efic_debil
seq            1     250000   0.254483   1.0000   1.0000
mpi            1     250000   0.253055   1.0056   1.0056
mpi            2     500000   0.281000   1.8113   0.9056
mpi            4    1000000   0.337665   3.0146   0.7537
mpi_oversub    8    2000000   0.617223   3.2984   0.4123
== Aviso: p=8 > 4 núcleos -> sobre-suscrito; etiquetado mpi_oversub, se reporta aparte.
== CSV: resultados/fuerte.csv, resultados/debil.csv ; entorno: resultados/entorno.txt
```

CSV completos, `entorno.txt` y las dos gráficas: `practica-guiada/resultados-ejemplo/` (`cpu_ociosa_antes_de_medir: 98%`).

Lectura contra la predicción: S(2) = **1.77** y S(4) = **3.47** (eficiencia 87 %) con n = 10⁶; el modelo decía
3.99 para p = 4 y la predicción escrita era 3.5–4. El 13 % que falta no son los halos (serían ~1 µs por iteración
contra ~220 µs de cómputo): es la espera en `Waitall` al proceso que llega tarde en cada iteración más el ancho de
banda de memoria que los cuatro procesos comparten (cada uno recorre 4 MB por iteración). La fila `mpi,1` es 5 %
más lenta que `seq` (Pausa 4). La fila `mpi_oversub,8` (0.30–0.54 s, S = 2.40) se reporta aparte (Pausa 5). En
débil, la eficiencia débil es 0.91 con p = 2 y 0.75 con p = 4 aunque el cómputo por proceso no cambió: misma
causa; con p = 8 sobre-suscrito, 0.41. Las repeticiones de p = 4 van de 0.288 a 0.364 s y las de `seq` de 1.018 a
1.108 s: dispersión del 10–25 %, normal en una VM.

Nota de honestidad: la VM de autoría es compartida y durante esta revisión otros procesos entraban y salían
de la máquina; `make run` se repitió hasta obtener una corrida con medianas consistentes entre sí (`mpi,1` ≈ `seq`;
la fila p = 4 de fuerte y la de débil, que son la misma configuración, difieren 8 %) y se lanzó con `nice -n -20`
para que esos procesos no la desplazaran. En el laboratorio, con la máquina para ti solo, no hace falta nada de
eso: basta cerrar lo demás. La corrida descartada de abajo ("variante que falla") muestra cómo se ve cuando no se
hace.
<!-- /GEN:MED:escalado -->

Y el caso pequeño, `N=1000 ITERS=100000 NLOCAL=1000 OVERSUB="" PLOT=0 OUT=resultados-chico ./escalado.sh`:

<!-- GEN:MED:chico -->
```
== Entorno: 4 núcleos físicos (4 CPU lógicas); ITERS=100000; REPS=5 (+1 calentamiento); MPIRUN_FLAGS='--oversubscribe'
== Escalabilidad fuerte: n=1000
config         p          n  mediana_s  speedup     efic
seq            1       1000   0.044894   1.0000   1.0000
mpi            1       1000   0.055508   0.8088   0.8088
mpi            2       1000   0.099218   0.4525   0.2262
mpi            4       1000   0.119713   0.3750   0.0938
== Escalabilidad débil: n/p=1000
config         p          n  mediana_s  S_escal efic_debil
seq            1       1000   0.043560   1.0000   1.0000
mpi            1       1000   0.067574   0.6446   0.6446
mpi            2       2000   0.133621   0.6520   0.3260
mpi            4       4000   0.190368   0.9153   0.2288
== CSV: resultados-chico/fuerte.csv, resultados-chico/debil.csv ; entorno: resultados-chico/entorno.txt
```

Con n = 1 000 (ITERS = 100 000 para que la secuencial dure ≥ 40 ms): S(2) = **0.45** y S(4) = **0.38**. Cuatro
procesos tardan 2.7 veces **más** que uno, como predijo el modelo (razón cómputo/comunicación 0.3). Y aquí
`mpi,1` es 24 % más lenta que `seq`: con n chico el costo constante por iteración (Pausa 4) ya no se diluye.
<!-- /GEN:MED:chico -->

**Pausa 4. La fila `mpi,1` es más lenta que `seq`. ¿Qué paga `jacobi_mpi` con un solo proceso que `jacobi_seq`
no paga? ¿Es un costo constante o proporcional a n?**
<details><summary>Respuesta</summary>
Por iteración, aunque los vecinos sean `MPI_PROC_NULL`: dos `MPI_Irecv`, dos `MPI_Isend`, un `MPI_Waitall` y tres
lecturas de `MPI_Wtime` (los relojes de diagnóstico). Es un costo **por iteración, constante**, independiente de
n: con n grande se diluye (unos cuantos por ciento); con n pequeño es comparable al cómputo. Por eso el protocolo
exige comparar contra el mejor secuencial y no contra "la versión paralela con 1": la segunda ya trae la
sobrecarga de la paralelización y hace ver mejor el *speedup*.
</details>

**Pausa 5. ¿Por qué la fila `mpi_oversub,8` no se usa para hablar de escalabilidad?**
<details><summary>Respuesta</summary>
Con 8 procesos en 4 núcleos cada proceso tiene medio núcleo, y un proceso que espera un halo hace sondeo activo:
le quita CPU al vecino que debería producir el dato. La medición refleja la pelea por los núcleos, no el
algoritmo. Se mide (sirve para probar correctitud con más rangos) y se reporta aparte, etiquetada. Es la idea
errónea 20.
</details>

## Paso 5 · ¿A partir de qué n conviene usar 4 procesos?

Del modelo, en el punto de equilibrio (S = 1): `n·t_c = (n/4)·t_c + T_halo` ⇒ `n* = T_halo / (0.75·t_c)`. Y para
eficiencia E: `n_E = E·4·T_halo / (t_c·(1 − E))`. Con los parámetros medidos (`modelo.py`, salida de arriba):

```
n* (punto de equilibrio, S=1):      1,215 puntos      ← 0.809 µs / (0.887 ns × 0.75) = 1 216
n_E (eficiencia >= 50%):            3,646 puntos      ← 0.5 × 4 × 0.809 µs / (0.887 ns × 0.5) = 3 648
```

(La diferencia de una unidad es redondeo: el programa usa α, β y t_c con todos sus decimales.)

Verificación cerca de n* (`make run-fuerte NP=4 N=<n> ITERS=<2·10⁸/n>`):

Mediana de 5 repeticiones (tras calentamiento) con `jacobi_seq` y `jacobi_mpi -np 4`; ITERS = 2·10⁸/n para que
cada corrida dure ≥ 0.1 s. "razón" es la que imprime `jacobi_mpi`; "S modelo" sale de `modelo.py --n`:

| n | ITERS | T_seq (s) | T₄ (s) | S medido | S modelo | razón impresa | t_c secuencial (ns) |
|---|---|---|---|---|---|---|---|
| 607 (n*/2) | 329 489 | 0.1181 | 0.3409 | **0.35** | 0.57 | 0.1 | 0.59 |
| 1 215 (n*) | 164 609 | 0.0879 | 0.2116 | **0.42** | 1.00 | 0.2 | 0.44 |
| 2 430 (2n*) | 82 304 | 0.0951 | 0.1026 | **0.93** | 1.60 | 0.1 | 0.48 |
| 3 646 (n_E) | 54 854 | 0.1328 | 0.1084 | **1.23** | 2.00 | 0.4 | 0.66 |
| 8 000 | 25 000 | 0.2064 | 0.1683 | **1.23** | 2.75 | 0.7 | 1.03 |
| 16 000 | 12 500 | 0.1382 | 0.0824 | **1.68** | 3.26 | 1.1 | 0.69 |

El cruce por S = 1 medido está entre **2 400 y 3 600 puntos**: el doble o el triple del n* del modelo (1 215). El
modelo acierta el orden de magnitud y la forma de la curva, no el valor al 10 %. Tres causas, todas visibles en la
tabla: (1) la "comunicación" que imprime el programa es 0.9–1.1 µs por iteración, no los 0.81 µs del modelo: incluye
las cuatro llamadas no bloqueantes, los relojes y la **espera en `Waitall`** a que el vecino llegue; (2) con n chico
el rival secuencial es más rápido de lo que supone el modelo (t_c = 0.44–0.66 ns porque el arreglo cabe en caché,
contra 0.887 ns con n = 10⁶); (3) el tiempo de la corrida es el del proceso **más lento** (`MPI_MAX`), no el promedio.
La línea `jacobi_mpi` para n = 3 646 fue: `mediana=0.1084 s (min 0.1049, max 0.1134) | por iteración: cómputo
6.344e-07 s, comunicación 1.561e-06 s, razón cómputo/comunicación 0.4`.

**Pausa 6. Según el modelo, en S = 1, ¿cuánto vale la razón cómputo/comunicación? ¿Coincide con la que imprime el
programa en el cruce medido?**
<details><summary>Respuesta</summary>
En el equilibrio `(n*/p)·t_c = T_halo / (p − 1)`, así que la razón `(n*/p)·t_c / T_halo = 1/(p − 1)` = 0.33 con
p = 4. Es decir: para que cuatro procesos empaten con uno, el cómputo local de cada iteración tiene que valer
al menos un tercio de la comunicación. Para eficiencia del 50 % la razón debe ser 1; para 80 %, 4. En la tabla,
en el cruce medido (n ≈ 2 400–3 600) el programa imprime 0.1–0.4: del mismo orden, pero menor, porque su
"comunicación" incluye la espera en `Waitall` (causa 1 de arriba).
</details>

## Variante que falla: medir con otros programas corriendo

Esta corrida es real. Se hizo con `make run` en la misma VM mientras otros procesos ajenos (pruebas de otras
prácticas: un programa con 4 hilos OpenMP y otro `mpirun -np 4`) entraban y salían de la máquina. `entorno.txt`
decía `cpu_ociosa_antes_de_medir: 97%`: al **arrancar** la máquina estaba libre; la carga llegó durante la corrida.

```
fuerte.csv (n = 1 000 000, ITERS = 1 200)
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
seq,1,1000000,1.068531,1.052539,1.101558,1.029708,1.034170,1.052539,1.0000,1.0000
mpi,1,1000000,1.042300,1.081401,1.022241,1.172393,1.156167,1.081401,0.9733,0.9733
mpi,2,1000000,0.777426,0.851828,0.682825,0.676233,0.645528,0.682825,1.5414,0.7707
mpi,4,1000000,0.861274,0.858526,1.025848,0.993173,1.084306,0.993173,1.0598,0.2649
mpi_oversub,8,1000000,0.301248,0.328901,0.349649,0.375873,0.335886,0.335886,3.1336,0.3917

debil.csv (n/p = 250 000)
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
seq,1,250000,0.242591,0.219507,0.228745,0.207849,0.220701,0.220701,1.0000,1.0000
mpi,1,250000,0.236081,0.239362,0.241370,0.242023,0.246810,0.241370,0.9144,0.9144
mpi,2,500000,0.285265,0.273242,0.270412,0.245647,0.256922,0.270412,1.6323,0.8162
mpi,4,1000000,2.172751,1.531020,2.880500,2.948674,0.323531,2.172751,0.4063,0.1016
mpi_oversub,8,2000000,0.962409,0.941893,0.694207,0.820885,0.761961,0.820885,2.1509,0.2689
```

Síntomas: en fuerte, p = 4 no mejora nada sobre p = 1 (S = 1.06) y, absurdo, p = 8 sobre-suscrito sale **tres
veces más rápido** que p = 4 (0.34 s contra 0.99 s). En débil, las cinco repeticiones de p = 4 van de 0.32 s a
2.95 s (9×) cuando las de `seq` van de 0.21 a 0.24. Diagnóstico: los 4 procesos necesitaban los 4 núcleos; uno o
dos de ellos los compartían con los programas ajenos. Cada vez que un proceso era desalojado, los otros tres lo
esperaban en `MPI_Waitall` haciendo sondeo activo, es decir, quemando CPU sin avanzar. Con p = 8, Open MPI detecta
la sobre-suscripción y hace que los procesos que esperan **cedan** el núcleo (`mpi_yield_when_idle`), lo que, en una
máquina ya ocupada, resulta menos destructivo. Nada de esto dice algo sobre Jacobi. La medición se descarta y se
repite con la máquina libre: es el paso 1.5 del protocolo ("cierra lo demás"), y la razón por la que `escalado.sh`
mira la CPU ociosa antes de medir (y, con `WAIT_IDLE=60`, espera a que se libere antes de cada corrida). La
corrida válida es la de `resultados-ejemplo/`, hecha después con la máquina libre.

**Pausa 7. Si solo tuvieras esta tabla, ¿qué dato te alertaría primero de que algo está mal?**
<details><summary>Respuesta</summary>
La dispersión de `rep1…rep5` en la fila p = 4 de débil (0.32–2.95 s) frente a la de `seq` (0.21–0.24 s), y en
fuerte el que p = 8 sobre-suscrito gane a p = 4 por 3×. Una medición válida tiene repeticiones parecidas; cuando
la mediana oculta un rango de 9×, el problema no es el programa, es el entorno. Por eso el CSV lleva las cinco
repeticiones y no solo la mediana.
</details>
