> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Ejemplo resuelto · S12 · ¿Dónde está el punto caliente? Del perfil a la predicción y a la medición

Código: `practica-guiada/ejemplo_perfil.c` (compila con `make` en esa carpeta). Léelo con el archivo abierto.
Es un ejemplo **por completar**: tiene tres huecos. En cada uno escribe tu respuesta antes de abrir la pista y,
después, la respuesta. Las pausas numeradas son preguntas de autoexplicación.

## Problema

Una "V1" de juguete con tres fases, como cualquier proyecto del curso:

| Fase | Qué hace | Costo teórico | Líneas de la función |
|---|---|---|---|
| carga | genera n = 2 000 000 puntos (x, y) en [0,1)² | O(n) | 8 |
| cómputo | por punto, seis rasgos: radio, ángulo (`atan2`), cuadrante, distancia al centro, anillo, peso (`exp`) | O(n) | 23 |
| resumen | cuenta los pares a distancia < 0.01 entre los primeros m = 48 000 puntos ("verificación para el reporte") | O(m²) | 14 (el ciclo doble, 6) |

Queremos la V2: ¿qué fase paralelizamos, qué *speedup* esperamos y cuánto obtenemos?

## Plan (tres líneas)

1. Un `omp_get_wtime()` entre fases; tabla de tiempos y fracciones con 1 hilo (mediana de 5).
2. Fracción paralelizable **en tiempo** de cada candidata → cota de Amdahl → elegir la fase.
3. Paralelizar esa fase, verificar correctitud (`make test`), medir con el protocolo región y total, comparar.

## Código comentado (fragmentos; el archivo completo tiene 141 líneas)

```c
/* main: un reloj entre fase y fase. Antes del primer reloj, una región vacía crea el equipo
 * de hilos: el protocolo no cuenta el arranque. */
#pragma omp parallel
{ (void)omp_get_thread_num(); }

double t0 = omp_get_wtime();
load_phase(px, py, n);
double t1 = omp_get_wtime();
double sum_w = compute_phase(px, py, radius, angle, weight, ring, n, par_compute);
double t2 = omp_get_wtime();
long close_pairs = summary_phase(px, py, m, par_summary);
double t3 = omp_get_wtime();
```

```c
/* Fase 2 · cómputo: iteraciones independientes salvo sum_w (reducción).
 * if(parallel): si es falso, la región corre con un equipo de UN hilo (= secuencial). */
#pragma omp parallel for if(parallel) reduction(+:sum_w)
for (long i = 0; i < n; i++) {
    double x = px[i], y = py[i];
    double r = sqrt(x * x + y * y);
    double th = atan2(y, x);
    /* … cuatro rasgos más … */
    radius[i] = r; angle[i] = th; weight[i] = w; ring[i] = ring_id;
    sum_w += w;
}
```

```c
/* Fase 3 · resumen: ciclo triangular (j > i): la iteración i hace m-i-1 comparaciones.
 * count es reducción. schedule(runtime) toma la planificación fijada con omp_set_schedule
 * (dynamic,64 por defecto; static con el argumento "static"). */
#pragma omp parallel for if(parallel) reduction(+:count) schedule(runtime)
for (long i = 0; i < m; i++) {
    double xi = px[i], yi = py[i];
    for (long j = i + 1; j < m; j++) {
        double dx = px[j] - xi, dy = py[j] - yi;
        if (dx * dx + dy * dy < r2) count++;
    }
}
```

> **Pausa 1.** ¿Por qué un reloj entre fases y no `time ./ejemplo_perfil`?
> <details><summary>Respuesta</summary>
> `time` mide el proceso completo (arranque, reservas de memoria, las tres fases, liberación) y no dice **dónde**
> está el tiempo. Para elegir qué paralelizar necesitamos el tiempo de cada fase. Además `time` reporta `user`
> sumando la CPU de todos los hilos; lo que acota Amdahl es el tiempo de pared (`real`), que es lo que mide
> `omp_get_wtime()`. Nunca `clock()`: suma la CPU de todos los hilos y "no ve" el *speedup*.
> </details>

> **Pausa 2.** ¿Para qué está la región `parallel` vacía antes de `t0`?
> <details><summary>Respuesta</summary>
> La primera región paralela de un programa crea los hilos (decenas de microsegundos a milisegundos según la
> máquina). Sin la región de calentamiento ese costo se cargaría a la primera fase paralela y distorsionaría su
> tiempo. El protocolo dice "una ejecución de calentamiento que no se cuenta"; esto es lo mismo dentro del
> programa. En tu V2 haz lo mismo o mide el costo aparte y decláralo.
> </details>

## Paso 1 · Predecir antes de medir

> **Pausa 3.** Sin mirar la siguiente sección: ¿qué fase domina? Escribe un porcentaje para cada una.
> <details><summary>Respuesta</summary>
> La mayoría elige **cómputo**: tiene 23 líneas, tres funciones trascendentes y seis arreglos. Pero su costo es
> O(n) = 2 × 10⁶ puntos × unas decenas de nanosegundos ≈ 0.1 s. El resumen es O(m²): 48 000² / 2 ≈ 1.15 × 10⁹
> comparaciones ≈ 1.1–1.2 s. Las líneas no miden tiempo; el orden de crecimiento y la medición sí.
> </details>

## Paso 2 · Medir el perfil secuencial

```bash
make
OMP_NUM_THREADS=1 ./ejemplo_perfil                        # una corrida: la tabla del programa
REPS=5 ./medir.sh ./ejemplo_perfil resumen "1" 2000000 48000 seq    # 5 repeticiones, mediana
```

Entorno de referencia de todo este documento: máquina virtual Linux con 4 vCPU (Intel Xeon 2.80 GHz), gcc 13.3,
`-O2`, compartida con otros procesos durante la autoría; por eso todas las tablas traen mediana **y** rango, y
las configuraciones se corrieron intercaladas (5 repeticiones cada una, tras 1 de calentamiento). Tus tiempos
cambiarán; las fracciones y las conclusiones no deberían.

Una corrida con 1 hilo (salida real del programa):

```
suma_pesos=9.762863065857e+05
pares_cercanos=359709
ejemplo_perfil n=2000000 m=48000 modo=seq plan=dynamic hilos_max=1
fase        tiempo_s  fraccion
carga         0.0276     0.020
computo       0.1264     0.094
resumen       1.1939     0.886
total         1.3478     1.000
```

Medianas de 5 repeticiones (1 hilo):

| Fase | Mediana (s) | Fracción del total |
|---|---|---|
| carga | 0.0189 | 0.015 |
| cómputo | 0.0919 | 0.073 |
| resumen | 1.1543 · rango [1.0811, 1.1876] | 0.911 |
| **total** | **1.2667** | 1.000 |

La predicción de la Pausa 3 falla para casi todos: el **resumen**, con su ciclo de 6 líneas, es el 91 % del
tiempo; el cómputo "pesado" es el 7 %.

### Hueco 1 · Cota de Amdahl para cada candidata

Con f en **tiempo**: si se paraleliza solo el cómputo, f_c = ______ y S_max(4) = ______; si se paraleliza solo el
resumen, f_r = ______, S_max(2) = ______, S_max(4) = ______ y S_max(∞) = ______.

<details><summary>Pista</summary>
f = tiempo de la fase / tiempo total, con los dos tomados de la tabla de 1 hilo. S_max(p) = 1 / ((1 − f) + f/p).
Para S_max(∞) el término f/p se va a cero.
</details>

<details><summary>Respuesta</summary>

- Solo cómputo: f_c = 0.0919 / 1.2667 = **0.073**; S_max(4) = 1 / (0.927 + 0.073/4) = 1 / 0.945 = **1.06**.
  Ni con infinitos hilos pasa de 1 / 0.927 = 1.08.
- Solo resumen: f_r = 1.1543 / 1.2667 = **0.911**; S_max(2) = 1 / (0.089 + 0.456) = **1.84**;
  S_max(4) = 1 / (0.089 + 0.228) = **3.16**; S_max(∞) = 1 / 0.089 = **11.2**.

La decisión sale de la tabla, no del tamaño de las funciones.
</details>

> **Pausa 4.** La función de cómputo tiene 23 líneas y la del resumen 14 (el ciclo doble, 6). ¿Por qué eso no
> entra en ningún cálculo?
> <details><summary>Respuesta</summary>
> Porque la fracción paralelizable de Amdahl se define sobre el **tiempo** de la versión secuencial (idea
> errónea 2). Diez líneas con un `strtod` por registro pueden costar más que doscientas de aritmética. Lo
> único que convierte líneas en tiempo es el reloj.
> </details>

## Paso 3 · La variante que falla: paralelizar la fase "que se ve pesada"

```bash
REPS=5 ./medir.sh ./ejemplo_perfil computo "4" 2000000 48000 computo
```

Medianas de 5 repeticiones, 4 hilos, modo `computo` (solo la fase de cómputo en paralelo):

| Métrica | 1 hilo (seq) | 4 hilos, modo `computo` | *Speedup* |
|---|---|---|---|
| fase cómputo | 0.0919 s | 0.0349 s | 2.63 |
| **total** | 1.2667 s | 1.1680 s | **1.08** |

La fase escaló (2.63 con 4 hilos: es un ciclo con `atan2` y `exp` por punto, limitado por memoria y por las
llamadas a `libm`), pero el programa completo mejoró 8 %, justo lo que la cota decía (1.06). Un equipo que
paraleliza "la función más larga" sin perfilar llega a H2 con este número.

## Paso 4 · Paralelizar la fase correcta y comparar con la predicción

### Hueco 2 · Las dependencias del ciclo del resumen

Antes de escribir el pragma: por iteración de `i`, ¿qué **lee** el ciclo? ¿Qué **escribe**? ¿De qué tipo es cada
escritura (independiente / reducción / carrera potencial / dependencia verdadera)? ¿Qué planificación conviene
y por qué? Escribe la línea `#pragma` completa.

<details><summary>Pista</summary>
Hay una sola variable que escriben todas las iteraciones. Y cuenta cuántas comparaciones hace la iteración
i = 0 y cuántas la i = 47 000.
</details>

<details><summary>Respuesta</summary>

Lee `px[]`, `py[]` (nadie los escribe en el ciclo) y `r2`. Escribe solo `count`, y lo escriben **todas** las
iteraciones con `+`: **reducción** → `reduction(+:count)`. `xi`, `yi`, `dx`, `dy`, `j` están declaradas dentro:
privadas por alcance. No hay escrituras a arreglos ni dependencia entre iteraciones.

Trabajo por iteración: la i = 0 hace 47 999 comparaciones; la i = 47 000 hace 999. Desigual por diseño →
`schedule(dynamic, 64)` (S08: `dynamic` gana cuando las iteraciones son desiguales; `static` repartiría el
primer bloque, el más pesado, a un solo hilo). En el archivo está como `schedule(runtime)` para poder comparar
las dos sin recompilar:

```c
#pragma omp parallel for reduction(+:count) schedule(dynamic, 64)
```
</details>

```bash
REPS=5 ./medir.sh ./ejemplo_perfil resumen "1 2 4" 2000000 48000 resumen dynamic
```

Medianas de 5 repeticiones, modo `resumen`, `dynamic, 64`:

| Hilos | total (s) | S_total | resumen (s) · [mín, máx] | S_resumen | Cota de Amdahl S_max(p) |
|---|---|---|---|---|---|
| 1 | 1.2667 | 1.00 | 1.1543 · [1.0811, 1.1876] | 1.00 | 1.00 |
| 2 | 0.7422 | 1.71 | 0.5968 · [0.5614, 0.6408] | 1.93 | 1.84 |
| 4 | 0.4507 | **2.81** | 0.3383 · [0.3156, 0.4274] | **3.41** | 3.16 |

La fase escaló 1.93 y 3.41 (eficiencia 97 % y 85 %); el total, 1.71 y 2.81. Correctitud antes que nada:
`pares_cercanos=359709` en todos los modos y `suma_pesos` igual hasta 1e-9 (`make test`).

> **Pausa 5.** ¿Por qué el total con 4 hilos (2.81) quedó **debajo** de la cota (3.16) si la cota ya descuenta
> la parte secuencial?
> <details><summary>Respuesta</summary>
> Porque la cota supone que la fase escala **perfecto** (÷4) y escaló 3.41. Con el *speedup* real de la fase:
> T(4) ≈ 0.0189 + 0.0919 + 1.1543/3.41 = 0.449 s → S_total = 1.2667/0.449 = 2.82, que es lo medido (2.81).
> Amdahl no falló: la cota es una cota. Lo que falta por explicar es por qué la fase no dio 4.0: en esta
> máquina compartida, parte es ruido (mira el rango con 4 hilos) y parte es el costo por *chunk* de `dynamic`
> y el desbalance residual del final del ciclo. Karp–Flatt sobre la fase: f_KF(4) = (1/3.41 − 1/4)/(1 − 1/4) = 0.058.
> </details>

### Hueco 3 · ¿Y con `static`?

Predice: con `schedule(static)` y 4 hilos, ¿la fase del resumen tardará más, menos o igual que con `dynamic`?
¿Por qué? Escribe tu *speedup* esperado para la fase: ______

<details><summary>Pista</summary>
Con `static` sin `chunk`, el hilo 0 recibe las iteraciones 0…11 999 (las más largas) y el hilo 3 las
36 000…47 999 (las más cortas). Suma el trabajo de cada bloque: es la suma de una progresión aritmética.
</details>

<details><summary>Respuesta</summary>

El hilo 0 hace ≈ 7/16 del trabajo total y el hilo 3 ≈ 1/16; el ciclo termina cuando acaba el hilo 0, así que el
*speedup* máximo de la fase con `static` es 16/7 ≈ **2.3**, no 4. Medido:

```bash
REPS=5 ./medir.sh ./ejemplo_perfil resumen "4" 2000000 48000 resumen static
```

| Planificación (4 hilos) | resumen (s) · [mín, máx] | S_resumen | total (s) | S_total |
|---|---|---|---|---|
| `dynamic, 64` | 0.3383 · [0.3156, 0.4274] | 3.41 | 0.4507 | 2.81 |
| `static` | 0.5218 · [0.4814, 0.5430] | 2.21 | 0.6454 | 1.96 |

2.21 medido contra 2.3 previsto: el modelo del desbalance explica el número. Esto es lo que la sección 3 de la
plantilla llama "lo comprobaremos midiendo `static` contra `dynamic`, no lo supondremos".
</details>

> **Pausa 6.** El *speedup* de la fase y el del programa completo no coinciden. ¿Cuál reportas en H2?
> <details><summary>Respuesta</summary>
> Los dos, en la misma tabla. El de la región (3.41) dice qué tan bien escaló tu paralelización; el del total
> (2.81) es lo que acota Amdahl y lo que siente quien usa el programa. Reportar solo el de la región infla el
> resultado; reportar solo el total esconde si el problema está en tu pragma o en la parte secuencial.
> </details>

## Paso 5 · ¿Y si paralelizamos ambas?

```bash
REPS=5 ./medir.sh ./ejemplo_perfil resumen "4" 2000000 48000 ambas dynamic
```

| Modo (4 hilos) | cómputo (s) | resumen (s) | total (s) | S_total |
|---|---|---|---|---|
| `resumen` | 0.0932 | 0.3383 | 0.4507 | 2.81 |
| `ambas` | 0.0375 | 0.3104 · [0.3017, 0.3655] | 0.3667 | 3.45 |

Paralelizar también el cómputo ahorra ≈ 0.06 s (la diferencia en la fase del resumen entre los dos modos cae
dentro del rango: es ruido). Vale la pena solo porque es gratis (un pragma y una reducción ya verificados); el
orden correcto fue primero el resumen. Con `ambas`, la parte secuencial que queda es la carga (0.019 s) y el
*speedup* máximo del programa sería ≈ 1.2667/0.019 ≈ 67 con infinitos hilos: el siguiente límite ya no es
Amdahl, es el hardware (4 núcleos) y la memoria.

> **Pausa 7.** El modo `seq` ejecuta el mismo binario con `if(0)`: un equipo de un hilo. ¿Es un T(1) válido
> según el protocolo?
> <details><summary>Respuesta</summary>
> Es la misma aritmética en el mismo orden, con una región de un solo hilo cuyo costo es de microsegundos;
> funciona como "mejor secuencial" y los resultados coinciden exactamente (`make test`). Pero el protocolo pide
> **declararlo**: "T(1) es la V2 con un hilo; verificamos que coincide con la V1 en resultado y tiempo". En tu
> proyecto la V1 existe por separado: mídela y úsala como T(1).
> </details>

## Resumen del método (lo que se lleva a la plantilla)

| Paso | En este ejemplo | En tu V1 |
|---|---|---|
| Perfil por secciones | tabla de 3 fases, 1 hilo, mediana de 5 | sección 1 de la plantilla |
| Fracción en tiempo | f_resumen = 0.911; f_cómputo = 0.073 (7 % del tiempo con 62 % de las líneas de las tres funciones) | f de las secciones "sí" |
| Cota de Amdahl | S_max(2) = 1.84, S_max(4) = 3.16 para el resumen; 1.06 para el cómputo | S_max(2), S_max(4) |
| Dependencias | `count` y `sum_w` reducciones; escrituras `arreglo[i]` independientes | sección 2 |
| Estrategia | `parallel for` + `reduction` + `dynamic, 64` por ciclo triangular | sección 3 |
| Medición | región y total, 1/2/4 hilos, mediana [mín, máx] | sección 4 |
| Comparación | total 2.81 vs. cota 3.16: la fase dio 3.41, no 4; `static` habría dado 2.21 (modelo: 2.3) | pre-mortem, sección 5 |
