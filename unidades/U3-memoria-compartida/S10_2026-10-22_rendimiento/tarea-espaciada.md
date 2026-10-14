> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S10 · Tarea espaciada (20–40 minutos)

**Entrega.** Carpeta `tareas/S10/` en el repositorio de tu equipo, con `respuestas.md`, el CSV y el PNG del
ejercicio 1, antes del **lunes 26 de octubre de 2026, 10:30** (inicio de S11). La autocalificas con la clave en
`<details>` en los primeros minutos de S11; el profesor registra la entrega (5 % del 2º parcial para "Tareas
espaciadas y ejercicios"; se revisan 3 al azar por parcial, según `planeacion/mapa-evaluacion.md`). Trabajo
individual: las mediciones son tuyas y se te puede pedir que las repitas. IA: verde para que te explique
Karp–Flatt o un mensaje de `make`; amarillo (declarado) para que revise tu interpretación; rojo para inventar o
"mejorar" números.

**Recordatorios de fechas.** El **martes 27 de octubre, 08:30, Lab LS4** es el Lab 2 de la Práctica 4: se trabajan
las **Partes C y D** (`practicas/P4-openmp/README.md`) y hay mini-defensas; la Parte D usa exactamente lo de hoy.
El **jueves 29 de octubre, 10:30** se recibe **H1 · Avance 1 del proyecto** en clase (12 % del 2º parcial). La
Práctica 4 completa se entrega el **domingo 1 de noviembre, 23:59** (40 %).

## 1. Del tema de hoy (15–20 min) · Medir con el protocolo completo y elegir con datos

Si en clase no terminaste la fase Crear de `practica-guiada/README.md`, este ejercicio **es** esa fase; si la
terminaste, entrega lo mismo con el núcleo de la Parte B de tu Práctica 4.

Núcleo a medir: el de la Parte B de tu Práctica 4 o, si todavía no compila, el histograma de S07
(`unidades/U3-memoria-compartida/S07_2026-10-15_sincronizacion/practica-guiada/`, versiones `atomic` y `local`).

1. **Predicción escrita antes de medir:** "con 4 hilos espero S ≈ ___ porque ___" (una línea; se compara al final).
2. Mide con el protocolo: `-O2`, 1 calentamiento, 5 repeticiones, mediana, `T(1)` = mejor secuencial, y un
   tamaño con el que la versión secuencial tarde **≥ 1 s** (en clase se usaron tamaños reducidos para caber en los
   90 minutos; aquí no). Hilos: 1, 2, 4 (y 8 si tu máquina tiene 8 núcleos físicos; declara el hardware).
3. Escribe el CSV con las 11 columnas del protocolo (`config,hilos,n,rep1,…,rep5,mediana_s,speedup,eficiencia`)
   con tu propio código (copia la función `csv_append` de `practica-guiada/common.h`) y grafícalo con
   `python3 practica-guiada/graficar.py tu.csv --titulo "..."`. Pega en `respuestas.md` la tabla Markdown que
   imprime el script (trae la `f` de Karp–Flatt).
4. **Elección justificada** (tres líneas). Para acumular un conteo por hilo viste tres formas en sesiones
   distintas: (i) `atomic` sobre la casilla compartida (S07), (ii) una ranura por hilo en un arreglo contiguo
   (S10, `contiguo`), (iii) acumulador local y una sola combinación al final (S07 `local`, S10 `local`;
   `reduction` lo hace por ti). Di cuál usa tu núcleo, cuál usarías y por qué, citando un número de tu tabla.
5. Interpretación (3–6 líneas, protocolo §4): dónde deja de escalar, por qué (fracción secuencial medida,
   memoria, sincronización, falso compartido), si `f` crece con `p`, y si coincidió con tu predicción.

Criterio de "listo": el CSV abre con `graficar.py` sin error, el PNG tiene la línea ideal, la tabla trae `f`, y
las tres líneas de la elección citan un dato medido.

## 2. Intercalado, Unidades I y II (10 min) · Gustafson, `clock()` y Foster sobre los datos de hoy

a) Con `weak_scaling` en la máquina de autoría (ver `notas-estudiante.md`, §4) se midió `T(1, n) = 0.104 s` y
`T(4, 4n) = 0.118 s`. Calcula la eficiencia débil `E_w = T(1,n)/T(p,p·n)` y el *speedup* escalado
`S_w = p · E_w`. ¿Qué ley de la Unidad I describe este experimento (Amdahl o Gustafson) y por qué su techo no es
`1/f`?

b) `profile_amdahl` con 4 hilos imprimió (valores de una corrida): reloj de pared `0.75 s`, `clock()` `1.28 s`
en el mismo lapso. Si alguien calculara el *speedup* con `clock()`, ¿saldría mayor o menor que el real, y por qué
el protocolo prohíbe `clock()` para esto? (dos líneas)

c) Foster sobre `false_sharing.c`: la partición son los índices `i`; la aglomeración es "un bloque de `n/p`
índices por hilo". ¿En qué etapa de Foster se decide que cada hilo tenga **sus propias** casillas, y por qué esa
decisión por sí sola no evita el falso compartido? (dos líneas; pista: la etapa que habla de **datos**, no de tareas,
es la que decide el acomodo en memoria).

<details><summary>Para autoverificar</summary>

a) `E_w = 0.104 / 0.118 ≈ 0.88`; `S_w = 4 × 0.88 ≈ 3.5`. Es el escenario de **Gustafson**: el problema crece
con los procesadores y la parte secuencial se vuelve proporcionalmente más pequeña, así que el *speedup*
escalado crece casi linealmente con `p` en lugar de toparse con `1/f`. Amdahl responde "¿cuánto más rápido el
mismo problema?"; Gustafson, "¿cuánto más problema en el mismo tiempo?".

b) **Menor.** `clock()` suma el tiempo de CPU de **todos** los hilos: con 4 hilos ocupados marca ≈ 1.7 veces más que
el reloj de pared aquí, así que `T(4)` medido con `clock()` sale inflado y el *speedup* se encoge (incluso por
debajo de 1). El usuario espera tiempo de pared; por eso `omp_get_wtime()` (idea errónea 31).

c) En la **aglomeración/mapeo** se decide qué datos locales tiene cada hilo (las casillas propias). Pero tener
casillas propias decide **qué** escribe cada hilo, no **dónde** quedan en memoria: si las casillas de distintos
hilos caben en la misma línea de 64 bytes, el hardware las trata como una unidad. El acomodo (relleno o variable
local) es una decisión adicional de la misma etapa.
</details>

## 3. Preparación de S11, lunes 26 de octubre, 10:30 (5–10 min) · Dependencias y `simd`

S11 trata patrones (reducción sobre arreglos, *scan*, *stencil* de Jacobi, *pipeline*) y vectorización con
`omp simd`. Lee en la *OpenMP API Specification 5.2* la introducción del constructo `simd` (sección *SIMD
Directives*), o el apartado sobre dependencias en ciclos del capítulo 5 de Pacheco y Malensek (2.ª ed.), y
responde por escrito:

a) ¿Puede llevar `#pragma omp parallel for` tal cual este ciclo? Sí/no y la razón en una línea.

```c
for (long i = 1; i < n; i++)
    y[i] = y[i - 1] + x[i];
```

b) En `saxpy_vs_matmul.c` de hoy, `saxpy` quedó limitado por memoria (la eficiencia cae aunque no haya parte
secuencial). Conjetura: si el compilador vectoriza el ciclo con `simd` (4 operaciones por instrucción), ¿esperas
que `saxpy` se acelere ~4 veces, poco o nada? Una línea con la razón. "No sé" es válida.

<details><summary>Para comparar después de leer</summary>

a) **No.** La iteración `i` lee `y[i-1]`, que escribe la iteración `i-1`: dependencia acarreada por el ciclo. Dos
hilos con iteraciones consecutivas leerían un valor aún no escrito (resultado incorrecto). En S11 se reescribe en
dos fases (sumas por bloque + corrección).

b) **Poco o nada**: si el ciclo ya está limitado por el ancho de banda de memoria, hacer la aritmética más rápido
no cambia cuánto tardan los datos en llegar. `simd` ayuda cuando el ciclo está limitado por cómputo. En S11 se
mide exactamente esto con `-fopt-info-vec`.
</details>
