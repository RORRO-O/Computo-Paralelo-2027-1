> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Guía de estudio del Examen 2 · martes 3 de noviembre de 2026 · 08:30–10:00 · Salón 3208 (o Lab LS4 con los equipos apagados)

# Guía de estudio · Examen departamental 2 (Unidad III, memoria compartida con OpenMP)

Esta guía es pública y no contiene ítems del examen. Te dice qué entra y cuánto pesa cada tema, te da 30
preguntas para practicar recuperación (con respuesta escondida), un plan de 5 días, los errores que más
cuestan puntos, lo que no entra, cómo será el día del examen y la hoja de calibración. Índice de la unidad:
[`README.md`](README.md).

| | |
|---|---|
| Fecha y lugar | **martes 3 de noviembre de 2026, 08:30–10:00**, Salón 3208 (o Lab LS4 con los equipos apagados), filas alternas |
| Duración y puntaje | **80 minutos efectivos · 100 puntos · 15 ítems en seis secciones** (0.8 min por punto) |
| Versiones | A y B, alternadas por fila; mismo temario, misma dificultad, mismos tipos de ítem |
| Material permitido | **Ninguno**: sin apuntes, sin IA y sin dispositivos (celular, reloj inteligente, **calculadora** y audífonos apagados y en la mochila). **No hay hoja de fórmulas**: las de *speedup*, eficiencia y Amdahl se escriben de memoria |
| Alcance | Unidad III completa: sesiones del 1 al 29 de octubre (la primera mitad, del 1 al 13, y S07–S13) y la Práctica 4. Entre 10 % y 20 % de Unidades I–II, **dentro** de problemas de la Unidad III |
| Peso | 40 % del 2.º parcial ([`planeacion/mapa-evaluacion.md`](../../planeacion/mapa-evaluacion.md); supuesto por simetría con el 1.er parcial, por confirmar) |
| Devolución | Calificación y clave a más tardar el **martes 10 de noviembre**; análisis de los errores más frecuentes el **jueves 12 de noviembre** (U4 S04) |

## 1. Temario con peso orientativo

Los pesos salen de la tabla de especificaciones del examen, que el profesor escribió antes que los ítems
(`docs/metodo/04-evaluacion.md` §2.1). Son puntos de 100. Úsalos para repartir tu tiempo, no para dejar temas
fuera.

| # | Tema (sesión) | Peso | Debes poder… | Dónde repasar | Banco (§3) |
|---|---|---|---|---|---|
| 1 | Regiones, `parallel for`, alcance (`shared`/`private`/`firstprivate`) y `reduction` (1–13 oct, S07) | **8** | Decir de cada variable si es compartida o privada y con qué valor entra y sale | [S07 notas](S07_2026-10-15_sincronizacion/notas-estudiante.md) §5 · [S13 notas](S13_2026-10-29_H1-repaso/notas-estudiante.md) §2 | 1–3 |
| 2 | Carreras y sincronización: `atomic`, `critical`, candados, `barrier`, `nowait`, `single`/`master` (S07) | **17** | Encontrar la variable compartida que se escribe; elegir la protección más barata que sea correcta; decir quién llega a cada barrera | [S07 notas](S07_2026-10-15_sincronizacion/notas-estudiante.md) §1–4 · [S13 notas](S13_2026-10-29_H1-repaso/notas-estudiante.md) §3 | 4–8 |
| 3 | `schedule`, `collapse` y balance de carga (S08) | **9** | Escribir el reparto de `static` y `static,c`; elegir política y *chunk* por la forma de la carga | [S08 notas](S08_2026-10-19_planificacion/notas-estudiante.md) §2–6 | 9–11 |
| 4 | Tareas: `task`, `taskwait`, entorno de datos, granularidad y corte (S09) | **10** | Usar `parallel` + `single` + `task` + `taskwait`; decir qué entra `shared` y qué `firstprivate`; contar tareas | [S09 notas](S09_2026-10-20_tareas-lab1/notas-estudiante.md) §1–4 | 12–14 |
| 5 | Medición: protocolo, *speedup*, eficiencia, Amdahl con fracción medida, Karp–Flatt, escalabilidad fuerte y débil (S10, S12; Unidad I) | **23** | Calcular a mano con dos decimales e interpretar qué limita el *speedup* | [S10 notas](S10_2026-10-22_rendimiento/notas-estudiante.md) §1–2 y §5 · [S12 notas](S12_2026-10-27_lab2-proyecto/notas-estudiante.md) §1 y §3 | 15–21 |
| 6 | Falso compartido y acumulación por hilo (S10) | **7** | Reconocerlo (correcto pero lento) y corregirlo con acumulador local o relleno | [S10 notas](S10_2026-10-22_rendimiento/notas-estudiante.md) §3 y §5 | 22–23 |
| 7 | Patrones (*scan*, *stencil* de Jacobi, reducción sobre arreglo) y `simd` (S11; Flynn, Unidad I) | **20** | Detectar dependencias entre iteraciones; aplicar el patrón correcto; decir qué promete `simd` y cuándo ayuda | [S11 notas](S11_2026-10-26_patrones-simd/notas-estudiante.md) §1–3 · [S13 tarea](S13_2026-10-29_H1-repaso/tarea-espaciada.md) ejercicio 2b (Flynn) | 24–28 |
| 8 | Diseño con Foster y plan de medición (S12; Unidad II) | **6** | Medir → listar dependencias → elegir construcción; partición, comunicación, aglomeración y mapeo | [S12 notas](S12_2026-10-27_lab2-proyecto/notas-estudiante.md) §1–2 | 29–30 |
| | **Total** | **100** | | | |

Por nivel cognitivo: 30 puntos de recordar/comprender, 50 de aplicar/analizar y 20 de evaluar/crear. Los
14 puntos de Unidades I–II están dentro de las filas 5, 7 y 8: Amdahl con la fracción medida, eficiencia débil y
Gustafson, la taxonomía de Flynn y el método de Foster. El banco los practica en las preguntas 15–17 y 29; Flynn,
en el ejercicio 2b de la tarea de S13.

**Estructura** (la misma del [examen de práctica](S13_2026-10-29_H1-repaso/examen-practica-U3.md) de S13; tiempo
sugerido que viene impreso en las instrucciones):

| Sección | Tipo de ítem | Minutos sugeridos |
|---|---|---|
| I | Opción múltiple (una letra, sin justificar) | 12 |
| II | Predecir la salida (justificar en una línea) | 14 |
| III | Encontrar y corregir el error | 15 |
| IV | Completar código | 9 |
| V | Problemas numéricos de rendimiento | 16 |
| VI | Diseño breve (10 líneas como máximo por inciso) | 12 |
| — | Revisión | 2 |

## 2. Cómo usar esta guía

- **Recupera, no releas.** Contesta cada pregunta **por escrito y sin apuntes** antes de abrir su respuesta.
  Releer se siente mejor y rinde menos (`docs/metodo/01-marco-pedagogico.md`, P2).
- **Espacia.** El plan de §4 reparte las 30 preguntas en cuatro días y regresa a las que fallaste uno y dos días
  después. Mezcla temas en cada sesión: así practicas **elegir** la herramienta, que es lo que pide el examen.
- **Marca cada respuesta** con ✓ (completa), ~ (parcial) o ✗. Las ~ y ✗ vuelven al día siguiente.
- **Zona sin IA para contestar.** Puedes pedirle a un asistente que te genere preguntas nuevas del mismo tipo
  (uso verde, [`docs/metodo/05-politica-ia.md`](../../docs/metodo/05-politica-ia.md)), pero contéstalas tú y
  verifica su clave compilando: las salidas de programas paralelos son justo donde la IA más se equivoca.

**Supuestos del código** (los mismos del examen): C11, gcc 13, `-O2`, 4 núcleos físicos y `OMP_NUM_THREADS=4`
salvo que se diga otra cosa; los fragmentos omiten `#include` y `main`. Cada fragmento de este banco se compiló
con `gcc -std=c11 -O2 -Wall -Wextra -fopenmp` (gcc 13.3, máquina virtual de 4 núcleos) y se ejecutó con 1, 2 y
4 hilos y varias corridas para fijar la respuesta; la salida obtenida está en la clave. Si quieres comprobarlo
tú, envuelve el fragmento en un `main` **después** de contestar.

## 3. Banco de 30 preguntas de recuperación

Las 11 marcadas **[código]** traen el fragmento y piden predecir la salida o encontrar el error.

### A · Alcance y `reduction` (tema 1)

**1. [código · predecir]**

```c
const long n = 10000000;
double s = 0.0;
#pragma omp parallel for reduction(+:s)
for (long i = 0; i < n; i++)
    s += 0.1;
printf("%.10f\n", s);
```

a) ¿Con qué valor arranca la copia de `s` de cada hilo y qué pasa con el `0.0` que `s` tenía antes del ciclo?
b) El mismo ciclo sin pragma imprime `999999.9998389754`. Con 4 hilos, ¿esperas exactamente lo mismo? Si no,
¿hay carrera? c) ¿Cómo se compara con la versión secuencial en una prueba?

<details><summary>Respuesta 1</summary>

a) Cada copia privada arranca en la identidad de `+`, que es 0. Al terminar el ciclo, OpenMP combina las copias
**con el valor original** de `s` (aquí 0.0) usando `+`.

b) No exactamente. Salida verificada: `1000000.0000402561` con 4 hilos y `999999.9999107814` con 2 (iguales en
tres corridas cada una; OpenMP no fija el orden de combinación, así que el último dígito podría variar). **No hay
carrera**: cada hilo suma su bloque y los parciales se combinan en otro orden, y en punto flotante el orden
cambia el redondeo (idea errónea 10). Ninguno de los dos es "el exacto" (10⁶), porque 0.1 no se representa en
binario.

c) Con tolerancia relativa, p. ej. `|par − seq| ≤ 1e-9 · |seq|`: la diferencia es 2.0·10⁻⁴, relativa 2.0·10⁻¹⁰,
y pasa. Con enteros, `max` y `min` sí se exige igualdad. Repasa: S07 notas §3 y §7; S11 CT1.
</details>

**2. [código · encontrar el error]** El autor esperaba `sum=5050.0`.

```c
double sum = 0.0;
#pragma omp parallel for private(sum)
for (int i = 1; i <= 100; i++)
    sum += i;
printf("sum=%.1f\n", sum);
```

¿Qué imprime y por qué? ¿Cuál es la corrección? ¿Serviría `firstprivate(sum)`?

<details><summary>Respuesta 2</summary>

Imprime `sum=0.0` (verificado con 1 y 4 hilos; gcc 13 no dio ningún *warning*). Cada hilo suma en una copia
privada **sin inicializar** (idea errónea 9) que se descarta al terminar; la `sum` de afuera nunca se tocó.
Corrección: `reduction(+:sum)`, que imprime `sum=5050.0` (verificado). `firstprivate(sum)` tampoco sirve: las
copias arrancarían en 0.0, pero tampoco regresan; seguiría imprimiendo 0.0. Repasa: S07 notas §5.
</details>

**3. [código · predecir]**

```c
int x = 1;
#pragma omp parallel num_threads(4)
{
    int y = omp_get_thread_num();
    #pragma omp single
    x = 10 + y;
}
printf("x=%d\n", x);
```

a) ¿Cuántas copias de `y` existen? b) ¿Qué valores puede imprimir? c) ¿Hay carrera sobre `x`?

<details><summary>Respuesta 3</summary>

a) Cuatro: `y` se declara dentro de la región, así que es privada por alcance (idea errónea 15).

b) `x=10`, `x=11`, `x=12` o `x=13`: el bloque `single` lo ejecuta **un** hilo, cualquiera, no necesariamente el 0.
En 40 corridas verificadas salió `x=10` 21 veces, `x=11` 6, `x=12` 10 y `x=13` 3.

c) No: solo un hilo escribe `x`, y la barrera implícita del final del `single` (y la del final de la región)
ordena esa escritura antes del `printf`. Repasa: S07 notas §4–5.
</details>

### B · Carreras y sincronización (tema 2)

**4. [recuperación]** Escribe las tres condiciones que convierten dos accesos en una condición de carrera.
Después: un histograma con `hist[b]++` sin protección pasó `make test` 20 veces seguidas con 4 hilos. ¿Qué
concluyes y cómo lo verificas? Con incrementos perdidos, ¿el total queda por arriba o por debajo de `n`?

<details><summary>Respuesta 4</summary>

(1) Dos hilos acceden a la misma posición de memoria; (2) al menos uno escribe; (3) nada ordena los accesos (ni
barrera, ni `atomic`, ni `critical`, ni candado). Veinte corridas buenas no son evidencia: una carrera es no
determinista y con `-O2` o poca contención puede no manifestarse (idea errónea 7). Se razona sobre los accesos
(`hist[b]` lo escriben varios hilos) y se localiza con ThreadSanitizer (`-fsanitize=thread`, `n` pequeño). El
total con pérdidas solo puede quedar **por debajo** de `n`. Repasa: S07 notas §1–2.
</details>

**5. [código · encontrar el error]** Se busca el máximo de `a[0..n)`.

```c
double m = a[0];
#pragma omp parallel for
for (long i = 1; i < n; i++) {
    #pragma omp atomic
    if (a[i] > m) m = a[i];
}
```

<details><summary>Respuesta 5</summary>

**No compila.** gcc 13 responde `error: expected expression before 'if'` (verificado). `#pragma omp atomic` solo
acepta una actualización simple de **una** variable escalar (`x++`, `x += e`, `x = x op e`, una lectura o una
escritura); un `if` con comparación y asignación no lo es (idea errónea 8). Lo correcto y barato: quitar el
`atomic` y escribir `#pragma omp parallel for reduction(max:m)`. Con `a[i] = (37·i) mod 1000` y `n = 1000`
imprimió `m=999.0` con 1 y con 4 hilos. Un `critical` alrededor del `if` también sería correcto, pero serializa
todas las iteraciones. (OpenMP 5.1 agrega `atomic compare`, que acepta `if (a[i] > m) { m = a[i]; }` con llaves, y
gcc 13 lo compila; no se vio en el curso y paga una operación atómica por iteración, así que `reduction` sigue
siendo lo más barato.) Repasa: S07 notas §3 y §7 (error 3).
</details>

**6. [código · encontrar el error]** Un compañero afirma: "los dos ciclos tienen el mismo `schedule(static)` y
el mismo `n`, así que el `nowait` es seguro". ¿Tiene razón?

```c
#pragma omp parallel num_threads(4)
{
    #pragma omp for schedule(static) nowait
    for (int i = 0; i < n; i++) a[i] = 2 * i;
    #pragma omp for schedule(static)
    for (int i = 0; i < n; i++) b[i] = a[n - 1 - i] + 1;
}
```

<details><summary>Respuesta 6</summary>

**No.** La garantía de `static` (mismo `n`, mismo reparto) asegura que la iteración `i` de los dos ciclos la
ejecuta el mismo hilo; eso basta cuando cada hilo lee **lo que él escribió**. Aquí la iteración `i` lee
`a[n − 1 − i]`, que escribió **otro** hilo (el hilo 0 lee el bloque del hilo 3), y sin barrera puede leerlo antes
de que exista (idea errónea 12). Verificado con `n = 4·10⁶` y `a` inicializado en −1: en 10 corridas hubo entre
6 010 y 1 043 453 valores de `b` incorrectos, y ThreadSanitizer señaló la escritura `a[i] = 2 * i` contra la
lectura `a[n - 1 - i]`. Corrección: quitar el `nowait` para recuperar la barrera implícita: 0 incorrectos en
10 corridas. Repasa: S07 notas §4; S08 CT3; S13 notas §2, paso 3.
</details>

**7. [recuperación · elegir]** Para cada caso elige `reduction`, `atomic` o `critical`, y di por qué descartas las
otras dos.
a) `total += w[i]` sobre un `double` escalar.
b) `count[key[i]]++` con 1 000 000 de casillas y claves al azar (dos hilos casi nunca tocan la misma casilla).
c) Al terminar su parte, cada hilo escribe su línea de resumen en un archivo compartido `out` con tres llamadas
seguidas (`fprintf(out, "hilo %d: ", id); fprintf(out, "%ld", mine); fputc('\n', out);`), y las líneas no deben
mezclarse.

<details><summary>Respuesta 7</summary>

a) `reduction(+:total)`: copias privadas y una combinación al final. `atomic` haría una operación sincronizada por
elemento (≈ 5 veces más cara en la medición de S07) y `critical` serializaría el ciclo.

b) `atomic`: protege la actualización de **esa** casilla y deja avanzar en paralelo a los hilos que van a casillas
distintas; con choques raros es barata. `reduction(+:count[:1000000])` también es correcta, pero cada hilo reserva
e inicializa su copia de un millón de casillas y al final se combinan: hay que medir. `critical` serializaría
todas las actualizaciones, incluso las de casillas distintas.

c) `critical` alrededor de las tres llamadas: son llamadas a función, no una actualización simple, así que `atomic`
no aplica, y no hay nada que reducir. Se ejecuta una vez por hilo, así que su costo no importa. Una sola llamada a
`fprintf` no se mezcla con otras (C11 bloquea el *stream* en cada llamada); tres llamadas de hilos distintos sí
pueden intercalarse. Regla de S13 notas §3: la más barata **que sea correcta**.
</details>

**8. [código · predecir]**

```c
double table[64];
#pragma omp parallel num_threads(4)
{
    int id = omp_get_thread_num();
    if (id == 0) {
        for (int k = 0; k < 64; k++) table[k] = k * 0.5;
        #pragma omp barrier            /* "que los demás esperen la tabla" */
    }
    printf("hilo %d: table[63]=%.1f\n", id, table[63]);
}
```

¿Qué pasa al ejecutarlo con 4 hilos? Corrígelo.

<details><summary>Respuesta 8</summary>

**Se cuelga** (interbloqueo). Una barrera la tienen que encontrar **todos** los hilos del equipo (idea errónea
32). Aquí solo la encuentra el hilo 0, que espera para siempre; los hilos 1–3 no esperan nada: leen `table[63]`
cuando les toca (otra carrera) y se quedan en la barrera implícita del final de la región. Verificado: en tres
corridas el programa no terminó en 3 s y hubo que detenerlo; con la salida sin búfer, los hilos 1–3 alcanzaron a
imprimir `table[63]=0.0` o `table[63]=31.5` según la corrida, y el hilo 0 nunca imprimió.

Corrección: sacar la `barrier` del `if` para que la alcancen los cuatro, o llenar la tabla dentro de
`#pragma omp single`, que termina con barrera implícita. Corregido, los cuatro imprimen `table[63]=31.5`
(verificado). Repasa: S07 notas §4; S13 cazador 2 (`practica-guiada/`).
</details>

### C · `schedule` y balance de carga (tema 3)

**9. [código · predecir]**

```c
int owner[10];
#pragma omp parallel for num_threads(3) schedule(static, 3)
for (int i = 0; i < 10; i++)
    owner[i] = omp_get_thread_num();
```

a) Escribe `owner[0..9]`. b) ¿Cuántas iteraciones hace cada hilo? c) ¿Y con `schedule(dynamic, 3)`?

<details><summary>Respuesta 9</summary>

a) `0 0 0 1 1 1 2 2 2 0` (verificado; igual en cada corrida). Bloques de 3 repartidos como cartas: {0,1,2} al
hilo 0, {3,4,5} al 1, {6,7,8} al 2 y {9} otra vez al 0. El error típico es escribir el reparto de `static` sin
*chunk*.

b) 4, 3 y 3.

c) No se puede predecir: cada hilo pide el siguiente bloque al desocuparse y el mapa cambia entre corridas. Ni
siquiera cuántas hace cada hilo: en tres corridas de verificación, un solo hilo tomó los cuatro bloques.
Repasa: S08 notas §2.
</details>

**10. [recuperación · elegir]** Elige política (y *chunk*, si aplica) para cada ciclo con 4 hilos y da la razón en
una línea.
a) 10⁷ iteraciones de ≈ 40 ns, todas iguales.
b) Ciclo triangular: la iteración `i` hace `i` operaciones.
c) Filas de una imagen de Mandelbrot: las del centro cuestan cientos de veces más que las del borde.
d) 200 archivos de tamaño impredecible (de 1 KB a 2 GB); cada iteración procesa uno.

<details><summary>Respuesta 10</summary>

a) `static`: no hay nada que balancear; `dynamic,1` pagaría una operación atómica por iteración, del mismo orden
que el trabajo (idea errónea 11).

b) `static,c` con `c` pequeño (el reparto cíclico balancea una carga monótona y sigue siendo predecible) o
`dynamic,c` con `c` de decenas a cientos. `static` sin *chunk* le da al último hilo casi seis veces el trabajo del
primero (en el mapa de S08, 58 unidades contra 10).

c) `dynamic,c` con `c` pequeño (2–8 filas): la carga está concentrada y no conviene que dos hilos carguen todo el
centro.

d) `dynamic` (aunque sea `dynamic,1`): cada iteración tarda de milisegundos a segundos, así que pedir el siguiente
archivo es despreciable; con `static`, el hilo al que le toquen los archivos grandes termina al último y los demás
esperan en la barrera. Regla: un *chunk* cuyo trabajo sea mucho mayor que el costo de pedirlo. Repasa: S08 notas
§3 y §5.
</details>

**11. [recuperación · numérico]** En S08, con carga uniforme (8·10⁶ iteraciones de ≈ 50 ns) y 4 hilos,
`dynamic,1` tardó 0.75 s y el secuencial 0.45 s. a) ¿Por qué perdió el paralelo? b) ¿Con qué *chunk* empezarías
a probar según la regla `n / (p × 10 a 100)`? c) ¿Por qué no un *chunk* de 2·10⁶?

<details><summary>Respuesta 11</summary>

a) Cada iteración pide su bloque a un contador compartido con una operación atómica en competencia; ese costo, de
decenas de nanosegundos, es del orden del trabajo y se pagó 8 millones de veces.

b) Entre 8·10⁶ / (4 × 100) = 20 000 y 8·10⁶ / (4 × 10) = 200 000.

c) Con 2·10⁶ solo hay 4 bloques: es `static` disfrazado y, si un hilo se retrasa, no hay con qué compensar. En
S08, `dynamic,256` y `dynamic,4096` tardaron 0.21–0.22 s; `dynamic,1`, 0.75 s. Repasa: S08 notas §3.
</details>

### D · Tareas (tema 4)

**12. [código · predecir]**

```c
static long n_tasks = 0;                 /* global: compartida en las tareas */
static void work(long lo, long hi, long cutoff)
{
    if (hi - lo <= cutoff) return;       /* aquí iría el trabajo secuencial del tramo */
    long mid = lo + (hi - lo) / 2;
    #pragma omp task
    work(lo, mid, cutoff);
    #pragma omp task
    work(mid, hi, cutoff);
    #pragma omp atomic
    n_tasks += 2;
    #pragma omp taskwait
}
/* en main: */
#pragma omp parallel
#pragma omp single
work(0, 100, 10);
printf("tareas=%ld\n", n_tasks);
```

a) ¿Qué imprime? b) ¿Cambia con 1 hilo? c) Un compañero aplica la fórmula `2·(n/cutoff − 1)` y obtiene 18.
¿Por qué no coincide?

<details><summary>Respuesta 12</summary>

a) `tareas=30` (verificado con 1, 2 y 4 hilos). El tramo de 100 crea 2 tareas de 50; cada 50 crea 2 de 25 (4);
cada 25 crea una de 12 y una de 13 (8); cada 12 o 13 es mayor que 10 y crea dos de 6 o de 6 y 7 (16); las de 6 y 7
ya no crean. 2 + 4 + 8 + 16 = 30.

b) No: el número de tareas lo fija la recursión, no los hilos; los hilos solo cambian **quién** ejecuta cada una.

c) La fórmula supone que `n/cutoff` es potencia de 2 y que los tramos llegan justo al corte. Aquí los tramos de
12 y 13 todavía pasan el corte y se parten otra vez: 16 hojas, 15 nodos internos, 2 × 15 = 30. Repasa: S09 notas
§4.
</details>

**13. [código · encontrar el error]** El autor quería exactamente 8 tareas.

```c
long count = 0;
#pragma omp parallel num_threads(4)
{
    for (int k = 0; k < 8; k++) {
        #pragma omp task
        {
            #pragma omp atomic
            count++;
        }
    }
}
printf("count=%ld\n", count);
```

<details><summary>Respuesta 13</summary>

Imprime `count=32` (verificado, tres corridas): sin `single`, cada uno de los 4 hilos ejecuta el `for` y crea sus
propias 8 tareas. Falta `#pragma omp single` justo después del `parallel`: un hilo genera las tareas y los otros
las toman de la cola; así imprime `count=8` (verificado). En las dos versiones el `printf` es seguro, porque la
barrera implícita del final de la región espera a todas las tareas. Repasa: S09 notas §1 y §8 (error 8).
</details>

**14. [recuperación]** a) En una tarea sin cláusulas, ¿qué regla decide si una variable es compartida o
`firstprivate`? b) En `fib_buggy.c` (S09) la hija calcula `x = fib(n - 1)`, el padre hace `taskwait` y devuelve
`x + y`, y el programa imprime 0. ¿Por qué, si hay `taskwait`? c) `taskwait` espera a… ¿las hijas directas, todas
las descendientes o los demás hilos?

<details><summary>Respuesta 14</summary>

a) Es compartida si era compartida en el contexto donde se crea la tarea (global, o declarada antes del
`parallel`); cualquier otra (parámetros y locales de la función, lo declarado dentro de la región) entra como
`firstprivate`, con el valor del momento.

b) `x` es local de la función: la hija escribe en **su** copia y el padre lee la suya, que nadie tocó. El
`taskwait` esperó bien; el problema es el entorno de datos. Corrección: `#pragma omp task shared(x)`. No es
carrera y no da *warning*.

c) A las hijas **directas** de la tarea actual, las haya ejecutado el hilo que sea (ideas erróneas 13 y 13d). Para
esperar a todas las descendientes existe `taskgroup`. Repasa: S09 notas §2–3; S09 CT1 y CT3.
</details>

### E · Medición y rendimiento (tema 5; incluye Amdahl y Gustafson de la Unidad I)

Sin calculadora: deja indicadas las divisiones y redondea a dos decimales al final.

**15. [numérico]** Perfil de la versión secuencial (`-O2`, mediana de 5): lectura 0.40 s (no paralelizable),
cálculo 5.20 s (paralelizable; es el 30 % de las líneas del archivo) y escritura 0.40 s (no paralelizable).
a) `f_p`. b) Cota de Amdahl con 4 y con 8 hilos, y con infinitos. c) ¿Qué obtiene quien calcula con líneas?

<details><summary>Respuesta 15</summary>

a) `T(1) = 6.00 s`; `f_p = 5.20 / 6.00 = 0.87` (y `1 − f_p = 0.80 / 6.00 = 0.13`; conviene arrastrar la fracción
2/15).

b) `S(4) = 1 / (0.133 + 0.867/4) = 1 / 0.35 = 2.86`; `S(8) = 1 / (0.133 + 0.108) = 1 / 0.242 = 4.14`;
`S(∞) = 1 / 0.133 = 7.50`.

c) Con `f_p = 0.30`, `S(4) = 1 / (0.70 + 0.075) = 1.29`: la idea errónea 2, que en el examen vale cero. Repasa:
S10 notas §2; S12 notas §1.
</details>

**16. [numérico]** El mismo programa medido con el protocolo y el mismo `n`: `T(2) = 3.42 s` y `T(4) = 2.16 s`.
a) `S` y `E` con 2 y 4 hilos. b) Karp–Flatt, `f = (1/S − 1/p) / (1 − 1/p)`, con 2 y 4. c) Compara con
`1 − f_p = 0.13` de la pregunta 15: ¿dónde está el límite y qué atacarías primero?

<details><summary>Respuesta 16</summary>

a) `S(2) = 6.00 / 3.42 = 1.75`, `E(2) = 0.88`; `S(4) = 6.00 / 2.16 = 2.78`, `E(4) = 0.69`.

b) `f(2) = (0.57 − 0.50) / 0.50 = 0.14`; `f(4) = (0.36 − 0.25) / 0.75 = 0.15`.

c) `f` queda muy cerca de `1 − f_p` (0.14–0.15 contra 0.13) y casi no crece con `p`: el programa está limitado por
su parte secuencial, no por sobrecarga. Se atacan los 0.80 s de lectura y escritura. Si `f` fuera mucho mayor que
0.13 o creciera con `p`, la pérdida estaría **dentro** de la región: sincronización, memoria, desbalance o falso
compartido. Repasa: S10 notas §2 y §5.
</details>

**17. [numérico]** Un filtro de imagen: `T(1, 1 Mpx) = 2.00 s` (mejor secuencial), `T(4, 1 Mpx) = 0.80 s` y
`T(4, 4 Mpx) = 2.40 s`. a) ¿Qué pares de mediciones forman escalabilidad fuerte y cuáles débil? b) `S(4)` y `E(4)`
fuertes. c) Eficiencia débil `E_w(4) = T(1, n) / T(4, 4n)` y *speedup* escalado `4 · E_w`. d) ¿Qué pregunta
responde cada una?

<details><summary>Respuesta 17</summary>

a) Fuerte: 1 Mpx con 1 y con 4 hilos (mismo `n`). Débil: 1 Mpx con 1 hilo y 4 Mpx con 4 hilos (`n/p` fijo).

b) `S = 2.00 / 0.80 = 2.50`; `E = 2.50 / 4 = 0.63`.

c) `E_w = 2.00 / 2.40 = 0.83`; `S_w = 4 × 0.83 = 3.33`.

d) Fuerte: ¿cuánto más rápido resuelvo **el mismo** problema? Débil (Gustafson): ¿cuánto **más problema** resuelvo
en casi el mismo tiempo? Llamar *speedup* a `2.00 / 2.40` es la idea errónea 6. Repasa: S10 notas §2.
</details>

**18. [recuperación · completar]** El protocolo del curso en huecos: se compila con ____; ____ corrida(s) de
calentamiento que no cuentan; al menos ____ repeticiones; se reporta la ____ junto con el ____ y el ____; el reloj
es ____ y no ____; `T(1)` es ____.

<details><summary>Respuesta 18</summary>

`-O2`; 1; 5; mediana, con mínimo y máximo; `omp_get_wtime()` (reloj de pared), no `clock()`, que suma la CPU de
todos los hilos (idea errónea 31); `T(1)` es el **mejor secuencial**, no la versión paralela con 1 hilo. Además:
tamaño fijo y declarado, hilos hasta los núcleos físicos, solo la región de interés y la máquina sin otra carga
(`uptime`). Repasa: S10 notas §1; [`herramientas/protocolo-medicion.md`](../../herramientas/protocolo-medicion.md).
</details>

**19. [recuperación · interpretar]** Con el protocolo completo y `make test` en PASS, un equipo obtiene
`S(4) = 4.4`. Sus datos ocupan 12 MB y cada núcleo tiene 4 MB de caché L2. a) ¿Es un error? b) Calcula Karp–Flatt.
¿Qué significa un valor negativo? c) ¿Cómo se reporta?

<details><summary>Respuesta 19</summary>

a) No necesariamente: con 4 hilos cada uno trabaja sobre 3 MB, que caben en su L2; con 1 hilo, los 12 MB no caben
en una (idea errónea 4).

b) `f = (1/4.4 − 0.25) / 0.75 = (0.227 − 0.250) / 0.75 = −0.03`. Solo dice que `S > p` y que el modelo de Amdahl,
que no considera la caché, no describe esos datos; no demuestra que el código no tenga parte secuencial (4b).

c) Verificar la correctitud, repetir con el protocolo y reportarlo **con** la explicación: tamaño por hilo frente
a la L2. Repasa: S10 notas §2; S10 CT3.
</details>

**20. [numérico]** Perfil secuencial: A = 0.10 s (secuencial), B = 0.80 s (`parallel for`), C = 0.10 s
(secuencial). Con 4 hilos B tarda 0.25 s y A y C no cambian. El programa imprime "sección B: speedup 3.20".
a) *Speedup* y eficiencia del programa. b) ¿Qué predecía Amdahl y por qué lo medido queda por debajo?

<details><summary>Respuesta 20</summary>

a) `S = 1.00 / (0.10 + 0.25 + 0.10) = 1.00 / 0.45 = 2.22`; `E = 0.56`. El 3.20 es el de la sección, no el del
programa (idea errónea 2b): el usuario ve el tiempo total.

b) `f_p = 0.80`: `S(4) = 1 / (0.20 + 0.80/4) = 2.50`. Lo medido queda por debajo porque B escaló 3.2 y no 4: hay
sobrecarga, memoria o desbalance dentro de la región. Repasa: S10 CT1; S12 notas §3.
</details>

**21. [numérico · interpretar]** `T(1) = 2.40 s` (mediana). Cinco corridas con 4 hilos: 0.62, 0.60, 0.61, 1.40 y
0.63 s. a) ¿Qué *speedup* se reporta? b) ¿Qué darían el promedio y el mínimo, y por qué no se usan? c) ¿Qué haces
con el 1.40?

<details><summary>Respuesta 21</summary>

a) Mediana 0.62 s, así que `S = 2.40 / 0.62 = 3.87`.

b) El promedio, 0.772 s, daría 3.11: el pico lo arrastra. El mínimo, 0.60 s, daría 4.00: es quedarse con el dato
que conviene. Las dos son variantes de la idea errónea 5.

c) Se reporta como máximo, junto al mínimo; si se repite, se investiga (otro proceso, `uptime`, migración de
hilos). No se borra. Repasa: S12 CT3; S10 notas §1.
</details>

### F · Falso compartido (tema 6)

**22. [recuperación]** Cuatro hilos cuentan en `long counts[4]` y cada uno escribe solo en `counts[tid]`.
`make test` pasa siempre, pero con 4 hilos el ciclo acelera 2.2× y con una variable local por hilo, 3.6× (S10).
a) ¿Hay carrera? b) ¿Qué pasa en el *hardware*? c) ¿Cuántos `long` caben en una línea de caché de x86-64?
d) ¿Arregla algo poner `atomic`? ¿Y usar 8 hilos?

<details><summary>Respuesta 22</summary>

a) No: cada hilo escribe una posición distinta (idea errónea 14b).

b) Falso compartido: las cuatro casillas viven en la misma línea de caché de 64 bytes; cada escritura invalida la
copia de esa línea en los otros núcleos, que tienen que volver a pedirla.

c) 8 (64 bytes / 8 bytes).

d) `atomic` lo empeora: agrega una operación sincronizada sobre la misma línea. Más hilos también: más núcleos
peleando la misma línea (idea errónea 14). Repasa: S10 notas §5; S10 CT2.
</details>

**23. [recuperación]** Para corregirlo, un equipo usa `typedef struct { long v; char pad[56]; } padded_t;` y
`padded_t counts[4];`. a) ¿Por qué 56? b) ¿Por qué el acumulador local (`long mine = 0;` dentro de la región y una
sola escritura al final) es todavía mejor? c) ¿Qué cláusula hace ese patrón por ti?

<details><summary>Respuesta 23</summary>

a) 8 bytes de `v` + 56 de relleno = 64: dos `v` consecutivos quedan a 64 bytes de distancia y nunca caen en la
misma línea.

b) El local vive en un registro o en la pila del hilo: no depende del tamaño de línea de cada máquina y toca la
memoria compartida una sola vez por hilo. En S10, con 4 hilos: `contiguo` 2.17×, `relleno` 3.50×, `local` 3.56×.

c) `reduction(+:…)`. Repasa: S10 notas §3 y §6 (error 8).
</details>

### G · Patrones y `simd` (tema 7)

**24. [código · predecir]**

```c
int hist[4] = {1, 1, 1, 1};
#pragma omp parallel for num_threads(4) reduction(+:hist[:4])
for (int i = 0; i < 22; i++)
    hist[i % 4] += 1;
printf("%d %d %d %d\n", hist[0], hist[1], hist[2], hist[3]);
```

a) ¿Qué imprime con 4 hilos? b) ¿Y con 1? c) ¿Qué hace OpenMP con `hist[:4]`?

<details><summary>Respuesta 24</summary>

a) `7 7 6 6` (verificado). De las 22 iteraciones, los residuos 0 y 1 salen 6 veces y los residuos 2 y 3, 5 veces;
a eso se suma el 1 inicial de cada casilla.

b) Lo mismo, `7 7 6 6` (verificado): con enteros la reducción es exacta.

c) Cada hilo recibe una copia privada de las cuatro casillas, inicializada en 0; al terminar, OpenMP suma las
copias **y el valor original** en `hist`. Es el patrón "local por hilo y combinar una vez", automatizado
(OpenMP 4.5 o posterior). Repasa: S11 notas §1.1.
</details>

**25. [código · encontrar el error]** ¿Cuáles de estos ciclos dan con `parallel for` el mismo resultado que en
secuencial? Antes de los ciclos, `a[i] = i`, `c[i] = i` y `d` está en ceros; `n = 10⁶`.

```c
/* (a) */
#pragma omp parallel for
for (long i = 1; i < n; i++) b[i] = a[i] + a[i - 1];
/* (b) */
#pragma omp parallel for
for (long i = 0; i < n; i++) c[i] = 2 * c[i] + 1;
/* (c) */
#pragma omp parallel for
for (long i = 1; i < n; i++) d[i] = d[i - 1] + 1;
```

<details><summary>Respuesta 25</summary>

**(a) y (b) sí; (c) no.** (a) lee solo `a` y escribe solo `b`. (b) lee y escribe el mismo arreglo, pero cada
iteración toca **su** casilla: compartir arreglo no es dependencia si el índice es el mismo. (c) la iteración `i`
lee `d[i − 1]`, que escribe la iteración anterior: dependencia acarreada por el ciclo (idea errónea 30).

Verificado, elementos distintos de la versión secuencial con 4 hilos: (a) 0, (b) 0, (c) 749 999; con 2 hilos,
(c) 499 999; igual en tres corridas. Cada hilo arranca su bloque leyendo un `d[lo − 1]` que sigue en 0.

Ninguna cláusula lo arregla: `reduction` no transmite el valor de la iteración anterior (30b) y `ordered` es
correcto pero serializa el ciclo (30c). Aquí basta la forma cerrada `d[i] = i`; en general se cambia el algoritmo
(*scan* en dos fases). Repasa: S11 notas §1.2; S13 CT3.
</details>

**26. [recuperación]** a) Describe en tres líneas el *scan* en dos fases con `p` hilos. b) ¿Por qué con 4 hilos su
*speedup* queda lejos de 4? c) ¿Por qué su resultado en `double` difiere del secuencial en los últimos dígitos y
eso no es una carrera?

<details><summary>Respuesta 26</summary>

a) (1) Cada hilo hace el *scan* local de su bloque y guarda el total del bloque. (2) Se calculan los
desplazamientos: el del bloque `t` es la suma de los totales de los bloques anteriores (son `p` números). (3) Cada
hilo suma su desplazamiento a todo su bloque.

b) Recorre la memoria dos veces: la fase 1 lee `x` y escribe `y`; la fase 3 vuelve a leer y escribir todo `y`. Es
un ciclo limitado por memoria y mueve casi el doble de bytes que el secuencial por la relectura de `y` (S11 notas
§1.2 y Pausa 5 del ejemplo resuelto), más el paso de los `p` totales. En S11 dio 1.89 con 4 hilos y `n = 2²³`.

c) Las sumas se agrupan en otro orden y en punto flotante el orden cambia el redondeo: en S11, 2.9·10⁻⁷ absoluto y
6.9·10⁻¹⁴ relativo a la suma total, igual en cada corrida. Una carrera da diferencias enormes que cambian con el
reparto. Se compara con tolerancia (idea errónea 10). Repasa: S11 notas §1.2; S11 CT1.
</details>

**27. [recuperación]** Jacobi 1D con doble búfer, `reduction(max:diff)` y una región `parallel for` por pasada del
`while`. a) ¿Por qué el resultado y el número de pasadas son idénticos al secuencial con cualquier número de
hilos? b) ¿Cuánto cuesta `tmp = u; u = u_new; u_new = tmp;`? c) Con `n = 64`, el secuencial tardó 0.0006 s y el
paralelo con 4 hilos, 0.0330 s. ¿Por qué?

<details><summary>Respuesta 27</summary>

a) En una pasada ninguna iteración lee lo que otra escribe (lee `u`, escribe `u_new`), la aritmética de cada punto
es la misma y el máximo no depende del orden en que se combine: es exacto.

b) O(1): se intercambian punteros; no se copia ningún elemento.

c) Cada pasada abre una región paralela (despertar hilos, repartir, barrera, combinar el máximo): fueron 9 626
regiones de 62 puntos cada una, y el costo fijo de cada región, de microsegundos, supera el trabajo (idea errónea
1). Con `n = 100 000` el paralelo sí ganó: 3.28× con 4 hilos. Repasa: S11 notas §1.3; S11 CT2.
</details>

**28. [recuperación]** a) `#pragma omp simd`, ¿es una petición o una promesa? ¿Qué pasa si es falsa? b) En el
Jacobi de S11, `parallel for simd` con la reducción `max` dentro del ciclo vectorizó (lo dijo el reporte del
compilador) y no ganó nada. ¿Qué enseña eso? c) Un ciclo mueve 24 bytes por punto y hace 2 operaciones de punto
flotante. ¿Qué limita lo que puede ganar si se vectoriza?

<details><summary>Respuesta 28</summary>

a) Una **promesa** de que las iteraciones son independientes: el compilador deja de exigir pruebas. Si es falsa, el
programa queda fuera de la especificación. Una dependencia visible (mismo arreglo, distancia 1) gcc 13 la respeta y
no vectoriza; una oculta (el mismo arreglo por dos punteros) la ignora, vectoriza y el resultado sale mal sin
aviso.

b) "Vectorizado" lo dice el compilador; "más rápido" lo dice el cronómetro. La cadena de dependencia del máximo
(gcc 13 guarda el acumulador en la pila) costó lo mismo que en escalar; revisando la convergencia cada 10 pasadas,
el ciclo de actualización sí ganó: 1.23× con 1 hilo y 1.98× con 4.

c) El ancho de banda de memoria: vectorizar acelera el cómputo, no la memoria. Con los datos en RAM la ganancia casi
desaparece. Repasa: S11 notas §2.
</details>

### H · Diseño con Foster y plan de medición (tema 8; Unidad II)

**29. [recuperación · diseño]** Suavizado de una imagen de 4000 × 4000: cada píxel nuevo es el promedio de sus
8 vecinos en la imagen vieja y todos los píxeles cuestan lo mismo. Con OpenMP y 4 hilos, di en una línea cada
etapa de Foster y cómo se ve en el código.

<details><summary>Respuesta 29</summary>

- **Partición:** un píxel por tarea (descomposición de dominio).
- **Comunicación:** cada tarea lee sus 8 vecinos de la imagen vieja. En memoria compartida es una lectura, no un
  mensaje, y obliga a escribir en otra imagen (doble búfer).
- **Aglomeración:** bloques de filas en vez de píxeles sueltos, para que repartir y sincronizar cueste poco frente
  al trabajo. No es "juntar todo en un hilo" (idea errónea 28).
- **Mapeo:** `#pragma omp parallel for schedule(static)` sobre las filas, porque la carga es uniforme.

Repasa: S12 notas §2; Unidad II.
</details>

**30. [recuperación · ordenar]** Ordena los pasos para pasar de la V1 a la V2: (a) escribir el `#pragma`;
(b) perfilar la V1 por secciones, con mediana de 5; (c) listar qué lee y qué escribe cada iteración del ciclo
caliente; (d) calcular `f_p` en tiempo y la cota de Amdahl; (e) medir la región **y** el total con el protocolo
y comparar con la predicción; (f) escribir el pre-mortem (qué *speedup* esperas y qué podría salir mal).

<details><summary>Respuesta 30</summary>

**b → d → c → a → f → e.** El pre-mortem puede ir en cualquier momento antes de medir (e). Poner el pragma primero
es la idea errónea 29; elegir el ciclo por su número de líneas y no por su tiempo, la 2. Repasa: S12 notas §1;
S12 CT2.
</details>

## 4. Plan de estudio de 5 días (sesiones de 40 minutos)

Cada sesión es individual, sin apuntes mientras contestas y con el cronómetro a la vista. Estructura fija:
**5 min de vaciado** (escribe en una hoja en blanco todo lo que recuerdes del tema indicado y compáralo después con
el archivo que se cita) → **25 min de preguntas** del banco, por escrito → **10 min de corrección**: abre las
respuestas, marca ✓/~/✗ y anota en tu bitácora (abajo) las que vuelven. Si no terminas, lo pendiente pasa al día
siguiente. Este plan sirve de base para el que escribiste en el *exit ticket* de S13.

| Día | Fecha | Vaciado (5 min) | Preguntas (25 min) | Qué vuelve |
|---|---|---|---|---|
| 1 | miércoles 28 de octubre | — (la sesión entera es una prueba) | **Examen de práctica** completo, 40 min cronometrados, con las casillas 1 y 2 de su hoja de calibración ([`examen-practica-U3.md`](S13_2026-10-29_H1-repaso/examen-practica-U3.md)). No abras la clave: se corrige en clase el jueves 29 | — |
| 2 | jueves 29 de octubre (tarde, después de S13) | La tabla de decisión "la más barata que sea correcta" ([S13 notas](S13_2026-10-29_H1-repaso/notas-estudiante.md) §3) | 1, 4, 9, 12, 15, 22, 26, 29 | Los ítems del examen de práctica que fallaste: lee solo el archivo que indica su mapa "ítem → dónde repasar" |
| 3 | viernes 30 de octubre | Las fórmulas: `S`, `E`, Amdahl, Karp–Flatt, `E_w` ([S13 notas](S13_2026-10-29_H1-repaso/notas-estudiante.md) §4) | 2, 5, 10, 13, 16, 19, 23, 27 | Las ~ y ✗ del día 2 |
| 4 | sábado 31 de octubre | El protocolo de lectura de cinco pasos ([S13 notas](S13_2026-10-29_H1-repaso/notas-estudiante.md) §2) | 3, 6, 11, 14, 17, 20, 24, 28, 30 | Las ~ y ✗ del día 3, y dos ✓ del día 2 elegidas al azar |
| — | domingo 1 de noviembre | Sin sesión de estudio: la **Práctica 4 vence a las 23:59** | — | — |
| 5 | lunes 2 de noviembre (sin clase) | Las ideas erróneas de §5 que más fallaste | 7, 8, 18, 21, 25 | Todas las ~ y ✗ pendientes, y rehacer el ítem peor contestado del examen de práctica (lo pide la tarea de S13) |
| Examen | martes 3 de noviembre, antes de salir de casa | 5 min: escribe de memoria las fórmulas y compáralas con S13 notas §4. Nada nuevo | — | — |

Cada día mezcla temas a propósito: el día 2 tiene una pregunta de cada uno de los ocho temas. Si una pregunta te
sale ✗ dos días seguidos, vuelve a hacer la práctica guiada de su sesión (§1, columna "Dónde repasar") antes de
intentarla otra vez. Fuera de estas sesiones queda la práctica guiada de S13 con tu pareja (≈ 55 min, entre el
jueves 29 y el lunes 2); sus fases 4–5 son el ejercicio 1 de la tarea de S13, que vence el martes 3 a las 08:30.

**Bitácora de calibración** (cópiala en tu cuaderno). Antes de cada sesión anota cuántas esperas contestar bien;
al corregir, cuántas fueron.

| Día | Preguntas | Espero acertar | Acerté (✓) | Vuelven (~ y ✗) |
|---|---|---|---|---|
| 2 | 8 | | | |
| 3 | 8 + las del día 2 | | | |
| 4 | 9 + las del día 3 | | | |
| 5 | 5 + pendientes | | | |

Si cada día esperas más de lo que aciertas, te pasará lo mismo el martes: dedica el día 5 a tus ✗, no a lo que ya
sabes.

## 5. Errores frecuentes (Anexo A) y qué pregunta los entrena

Catálogo completo en [`docs/metodo/01-marco-pedagogico.md`](../../docs/metodo/01-marco-pedagogico.md), Anexo A.
Los distractores de la opción múltiple del examen salen de aquí.

| # | Idea errónea | Lo correcto | Preguntas |
|---|---|---|---|
| 1 | "Más hilos siempre es más rápido" | Lo limitan la parte secuencial, la memoria, la sincronización y el costo de crear hilos o regiones | 11, 27 |
| 2 · 2b | "La fracción de Amdahl se mide en líneas" · "el *speedup* de la sección es el del programa" | `f_p` es tiempo de la versión secuencial; se reporta el total | 15, 20, 30 |
| 3 | "Eficiencia = *speedup*" | `E = S/p`; una `E > 1` sin explicación es un error | 16, 17 |
| 4 · 4b | "El superlineal es un error de medición" · "`f` negativa demuestra algo del código" | Puede ser caché y se explica; `f < 0` solo dice que Amdahl no describe esos datos | 19 |
| 5 | "Medir una vez basta" / "se mide con `-O0`" | `-O2`, calentamiento, mediana de ≥ 5 con mínimo y máximo | 18, 21 |
| 6 | "Fuerte y débil son sinónimos" | Fuerte: mismo `n`; débil: `n` crece con `p` | 17 |
| 7 · 7d | "Si salió bien, no hay carrera" · "con índices `i` distintos nunca escriben lo mismo" | La carrera es no determinista; la posición escrita puede coincidir aunque `i` no | 4, 6 |
| 8 | "`critical` y `atomic` son equivalentes" | `atomic`: una actualización simple de una variable; `critical`: cualquier bloque | 5, 7 |
| 9 | "`private` copia el valor inicial" | Queda indefinida; para copiar, `firstprivate` | 2 |
| 10 | "`reduction` da exactamente lo mismo que la suma secuencial" | En punto flotante cambia el redondeo: se compara con tolerancia | 1, 26 |
| 11 · 11b | "`dynamic` siempre gana" · "el reparto solo afecta la correctitud" | `dynamic` cuesta por *chunk*; el reparto decide cuánto trabaja el hilo más lento | 10, 11 |
| 12 | "Al final de `omp for` no hay barrera" | Sí la hay, y también al final de `single`, `sections` y `parallel`; `nowait` la quita en `for`, `single` y `sections`, nunca en `parallel`; `master` no tiene | 3, 6, 13 |
| 13 · 13c · 13d | "La tarea se ejecuta al crearse" · "solo el `single` crea tareas" · "`taskwait` es una barrera de hilos" | Se encola; `taskwait` espera a las hijas directas, las ejecute quien las ejecute | 12, 13, 14 |
| 14 · 14b | "El falso compartido no existe o se arregla con más hilos" · "casillas distintas son carrera" | No es carrera; es la línea de caché compartida; local o relleno | 22, 23 |
| 15 | "Lo declarado dentro de la región es compartido" | Es privado por alcance | 3 |
| 28 · 29 | "Aglomerar es juntar todo" · "primero se programa y luego se diseña" | Aglomerar reduce sobrecarga sin perder paralelismo; primero se mide y se listan dependencias | 29, 30 |
| 30 · 30b · 30c | "Cualquier `for` se paraleliza" · "una recurrencia se arregla con `reduction`" · "`ordered` la corrige sin costo" | Con dependencia entre iteraciones se cambia el algoritmo | 25 |
| 31 | "`clock()` mide tiempo de pared" / "`T(1)` es la paralela con 1 hilo" | `omp_get_wtime()`; `T(1)` es el mejor secuencial | 18 |
| 32 | "Un `barrier` dentro de un `if` está bien si algún hilo lo ejecuta" | Todos los hilos del equipo deben llegar a la misma barrera | 8 |

Errores de forma que también cuestan puntos (S13 notas §5 y §6): proteger la variable privada y dejar sin nada la
compartida; `firstprivate` "por si acaso" en una variable que se quiere ver afuera; no justificar en "predecir la
salida"; dar un número sin la fórmula en la sección V.

## 6. Qué no entra

- **Unidades IV y V** (MPI y GPU): no hay código MPI ni CUDA en este examen.
- **`lastprivate`**: no apareció en S07–S13 ni en la Práctica 4; no se evalúa salvo que el profesor anuncie lo
  contrario antes del examen.
- **Solo panorama, no se piden en código:** el *pipeline* (S11), la afinidad (`OMP_PROC_BIND`, `OMP_PLACES`; S10),
  `depend` (S09) y `taskloop` (S09; si lo usas en un diseño, justifícalo).
- **Computadora:** no hay; nada se compila ni se ejecuta. Lo que sí puede venir en un enunciado es la salida de un
  programa o de ThreadSanitizer, para que la interpretes.
- **Hoja de fórmulas y calculadora:** no hay. Practica las divisiones a mano con dos decimales.

## 7. El día del examen (martes 3 de noviembre)

**Antes de entrar**

- Llega antes de las 08:30 al Salón 3208; si el examen se aplica en el LS4, los equipos estarán apagados. Te
  sentarás en filas alternas con versiones A y B.
- Lleva pluma o lápiz y goma. Celular, reloj inteligente, calculadora y audífonos van **apagados y en la mochila**.
- La tarea de S13 vence a las 08:30 de ese día (`tareas/<usuario-github>/U3-S13.md` en el repositorio del equipo).

**Al recibir el examen**

1. Llena la **casilla 1 de la hoja de calibración** (§8) **antes** de leer los ítems.
2. Escribe tu número de lista y la versión en cada hoja.
3. Lee las instrucciones de la portada: 80 minutos, 100 puntos, 15 ítems, el tiempo sugerido por sección (§1) y
   los supuestos del código (gcc 13, `-O2`, 4 núcleos, `OMP_NUM_THREADS=4`; las funciones que no se muestran hacen
   lo que dice su nombre y no usan OpenMP).

**Mientras contestas**

- Orden sugerido: la opción múltiple (I) y los problemas numéricos (V) primero; después completar (IV), predecir
  (II), encontrar el error (III) y al final el diseño (VI).
- Opción múltiple: una letra por ítem en la tabla de la portada; una respuesta incorrecta no resta.
- "Justifica en una línea" pide una oración con la razón técnica. Los ítems abiertos dan puntos parciales: escribe
  tu razonamiento y deja indicadas las operaciones.
- En "predecir la salida", escribe primero el mapeo (qué hilo hace qué iteraciones) y una copia por hilo cuando
  haya `firstprivate`; después calcula.
- En "encontrar el error", recorre los cinco pasos del protocolo de lectura (S13 notas §2) y di por qué descartas
  las otras correcciones.
- Si un ítem te parece ambiguo, escribe el supuesto que tomaste y contesta con él. Solo se aclaran dudas de
  redacción: levanta la mano.

**Al entregar**

- Llena las **casillas 2 y 3 de la hoja de calibración** (la calificación que crees haber obtenido y los tres
  temas que menos dominas) y entrégala **aparte** del examen.

**Después**

- Calificación y clave, a más tardar el martes 10 de noviembre. El jueves 12 de noviembre (U4 S04) se trabajan en
  clase los tres ítems peor contestados.
- Tu hoja de calibración se abre después de calificar y te regresa con tu brecha; al grupo solo se le muestra el
  promedio. No afecta tu calificación.
- Si no puedes presentarte por causa justificada: con justificante institucional se aplica la versión B en un
  horario acordado, a más tardar el jueves 12 de noviembre (propuesta por defecto, a confirmar por el profesor;
  `docs/metodo/04-evaluacion.md` §2.4). Avísale al profesor con tu justificante lo antes posible. Si queda una
  reposición pendiente, la clave pública espera a que se aplique.

## 8. Hoja de calibración

El profesor la entrega impresa el día del examen; este es el modelo. Se llena en dos momentos, se entrega aparte
y **no afecta la calificación** (`docs/metodo/04-evaluacion.md` §2.3).

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Examen 2 · martes 3 de noviembre de 2026 · Hoja de calibración · se entrega **aparte** del examen
>
> Nombre: `______________________________`  Número de lista: `____`  Versión: A / B (encierra)
>
> | Casilla | Cuándo | Qué escribes |
> |---|---|---|
> | 1 · Predicción | Al recibir el examen, **antes** de leerlo | Calificación que esperas (0–100, la escala del examen): `____` |
> | 2 · Postdicción | Al entregar, sin volver a abrir el examen | Calificación que crees haber obtenido (0–100): `____` |
> | 3 · Lo que menos dominas | Al entregar | Los **tres** temas de la Unidad III que menos dominas: 1. `____` 2. `____` 3. `____` |
>
> Temas para la casilla 3 (o escribe otro): regiones y alcance de variables · carreras y sincronización (`atomic`,
> `critical`, candados, barreras) · `schedule` y balance · tareas · medición (Amdahl, Karp–Flatt, fuerte/débil) ·
> falso compartido · patrones (*scan*, *stencil*) y `simd` · diseño con Foster.
>
> *La llena el profesor después de calificar:* calificación real `____` · brecha (postdicción − real) `____`

**Cómo leer tu brecha.** La que importa es la de la postdicción: casilla 2 menos tu calificación real. Si supera
15 puntos (el 15 % de 100), sobreestimaste: estudiaste con la sensación de saber y no con la prueba de saber.
Compárala con la brecha de tu examen de práctica (casilla 3 de su hoja, en puntos de 60, donde el mismo 15 % son
9 puntos) y con tu bitácora de §4. Si las tres apuntan al mismo lado, el ajuste para el Examen 3 (martes 8 de
diciembre) es más preguntas de recuperación y menos relectura, desde la primera semana de la Unidad IV.
