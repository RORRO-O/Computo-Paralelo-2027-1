> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S13 · Ejemplo resuelto: leer un programa OpenMP como lo pide el examen

Código: `practica-guiada/ejemplo_revision.c`. Compila con `make` dentro de `practica-guiada/`. Las salidas
son corridas reales en la máquina de autoría (4 núcleos, gcc 13, `-O2`). Es un ejemplo **por completar**
(última sesión de la unidad, `07-guia-de-autoria.md` §A.5): tiene seis pausas con respuesta y tres huecos
que llenas tú; abre cada `<details>` solo después de escribir tu respuesta.

El Examen 2 (martes 3 de noviembre, 08:30) tiene tres ítems que se resuelven leyendo código: predecir la
salida, encontrar el error y completar. Los tres se contestan con el mismo protocolo de cuatro preguntas,
que es lo que este ejemplo practica sobre un programa de 20 líneas:

1. **¿Qué variable se escribe dentro de la región?** Para cada una: ¿compartida o privada? ¿quién más la toca?
   ¿qué construcción ordena esos accesos?
2. **¿Qué alcance tiene cada temporal?** Declarada afuera sin cláusula → compartida; `private` → copia sin
   inicializar; `firstprivate` → copia con el valor de afuera; declarada adentro → privada.
3. **¿Quién llega a cada barrera y quién lee después de ella?** `omp for` y `single` terminan con barrera
   salvo `nowait`; `parallel` siempre.
4. **¿Qué hilo ejecuta qué iteración?** Solo `static` lo garantiza (y lo repite entre ciclos iguales).

## Problema

Dado `x[0..n)`, calcular `a[i] = 2·x[i] − 0.5` y contar cuántos `a[i]` superan `thr = 0.6`, con un equipo de
hilos y **dos** ciclos: uno que escribe `a[]` y otro que lo lee. Los datos son calculables a mano:
`x[i] = ((7·i) mod 11) / 10`.

## Plan en tres líneas

1. Una región `parallel` con dos `omp for schedule(static)`: el primero escribe `a[i]`, el segundo cuenta.
2. El contador de cada hilo vive en una variable declarada **dentro** de la región; al final se combina una
   vez por hilo con `atomic`.
3. El primer ciclo lleva `nowait`: hay que **demostrar** que es seguro, no suponerlo.

## Código (la función paralela; `owner1`, `owner2` y `hits_by_thread` solo registran quién hizo qué)

```c
long hits = 0;                                    /* compartida: la escriben todos al final */
#pragma omp parallel firstprivate(thr)            /* copia inicializada de thr en cada hilo */
{
    int tid = omp_get_thread_num();
    long my_hits = 0;                             /* declarada adentro: privada por alcance */

    #pragma omp for schedule(static) nowait       /* ciclo 1: escribe a[i]; sin barrera al final */
    for (long i = 0; i < n; i++) {
        a[i] = 2.0 * x[i] - 0.5;
        owner1[i] = tid;
    }

    #pragma omp for schedule(static)              /* ciclo 2: lee a[i]; barrera implícita al final */
    for (long i = 0; i < n; i++) {
        owner2[i] = tid;
        if (a[i] > thr) my_hits++;
    }

    hits_by_thread[tid] = my_hits;
    #pragma omp atomic                            /* una actualización compartida por hilo */
    hits += my_hits;
}                                                 /* barrera de fin de región: hits completa */
```

## Salida real (`OMP_NUM_THREADS=4 ./ejemplo_revision 16`)

```
ejemplo_revision: n=16 hilos=4 thr=0.6
  i      :    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
  x[i]   :  0.0  0.7  0.3  1.0  0.6  0.2  0.9  0.5  0.1  0.8  0.4  0.0  0.7  0.3  1.0  0.6
  a[i]   : -0.5  0.9  0.1  1.5  0.7 -0.1  1.3  0.5 -0.3  1.1  0.3 -0.5  0.9  0.1  1.5  0.7
  a>thr  :    .    *    .    *    *    .    *    .    .    *    .    .    *    .    *    *
  owner1 :    0    0    0    0    1    1    1    1    2    2    2    2    3    3    3    3
  owner2 :    0    0    0    0    1    1    1    1    2    2    2    2    3    3    3    3
  mapas iguales en los dos ciclos: si
  hits por hilo: h0=2 h1=2 h2=1 h3=3
hits = 8  (referencia secuencial 8)  ok
```

**Pausa 1.** `thr` solo se lee dentro de la región. ¿Qué pasaría con `private(thr)`? ¿Y sin ninguna cláusula?
¿Cuál de las tres formas elegirías en el examen y por qué?

<details><summary>Respuesta</summary>

Con `private(thr)` cada hilo compararía contra una copia **sin inicializar** (idea errónea 9): resultado
indefinido (en el cazador 3 de la práctica guiada salieron ceros). Sin cláusula, `thr` es compartida y solo se
lee: correcto y gratis. `firstprivate` también es correcto (una copia por hilo con el 0.6) y sería necesario
solo si cada hilo fuera a modificar su copia. En el examen se acepta "sin cláusula" o `firstprivate` con la
razón; `private` es el error que el ítem busca.
</details>

**Pausa 2.** `my_hits` no aparece en ninguna cláusula y todos los hilos la escriben. ¿Por qué no hay carrera?

<details><summary>Respuesta</summary>

Está declarada **dentro** de la región: cada hilo tiene la suya (idea errónea 15: lo declarado adentro no es
compartido). Por eso la salida muestra cuatro valores, `h0=2 h1=2 h2=1 h3=3`, y su suma, 8, es `hits`.
</details>

**Pausa 3.** El ciclo 1 lleva `nowait`: un hilo puede entrar al ciclo 2 mientras otro sigue escribiendo `a[]`.
¿Por qué es seguro aquí? ¿Qué tiene que cumplirse para que lo sea?

<details><summary>Respuesta</summary>

Porque los dos ciclos tienen el **mismo mapeo**: con `schedule(static)`, el mismo número de iteraciones y la
misma región paralela, OpenMP garantiza que la iteración `i` le toca al mismo hilo en los dos ciclos (OpenMP
API 5.2, *worksharing-loop construct*, reglas de `static`). Las filas `owner1` y `owner2` lo muestran. Así,
en el ciclo 2 cada hilo lee únicamente los `a[i]` que él mismo escribió en el ciclo 1: no depende de nadie y
no necesita esperar a nadie. Con `dynamic` o `guided` no hay garantía y el `nowait` se vuelve una carrera
(variante que falla, abajo). Regla: `nowait` solo cuando **nadie lee después lo que otro hilo escribió**.
</details>

**Pausa 4.** ¿Por qué `atomic` en `hits += my_hits` y no `critical` ni `reduction`? ¿Y si se quita?

<details><summary>Respuesta</summary>

Sin protección es una carrera (4 hilos leen-modifican-escriben `hits`; con 4 actualizaciones rara vez se
manifiesta, pero existe: idea 7). `atomic` protege exactamente eso: una actualización simple de una variable
escalar, con costo mínimo. `critical` también es correcto y más caro, irrelevante con 4 actualizaciones.
`reduction(+:hits)` es la forma idiomática y hace lo mismo que `my_hits` + `atomic` por ti: es el Hueco 1.
</details>

## Huecos por completar

**Hueco 1.** Reescribe la región con `reduction(+:hits)` y **sin** `my_hits` ni `atomic`. ¿Cuántas líneas
cambian? ¿El `nowait` sigue siendo seguro?

<details><summary>Pista</summary>

`reduction` va en el `parallel` (no en un `for`), porque el acumulador se usa en el segundo ciclo y se
combina al cerrar la región. La variable que se acumula ahora es `hits` directamente.
</details>

<details><summary>Respuesta</summary>

```c
#pragma omp parallel firstprivate(thr) reduction(+:hits)
{
    #pragma omp for schedule(static) nowait
    for (long i = 0; i < n; i++) a[i] = 2.0 * x[i] - 0.5;
    #pragma omp for schedule(static)
    for (long i = 0; i < n; i++) if (a[i] > thr) hits++;   /* hits es la copia privada del hilo */
}                                                          /* al cerrar: suma de las copias */
```

Desaparecen `my_hits`, `hits_by_thread[tid] = …` y el `atomic`; `hits++` escribe en la copia privada. El
`nowait` sigue siendo seguro por la misma razón de la Pausa 3: no depende de cómo se acumula, sino de quién
lee qué.
</details>

**Hueco 2.** Con **2 hilos** y `n = 16`, ¿qué imprime `hits por hilo`? Escribe el mapeo `static` y cuenta los
asteriscos de cada mitad con la fila `a>thr` de arriba.

<details><summary>Pista</summary>

Con 2 hilos y `static` sin *chunk*, cada hilo recibe un bloque contiguo de `16 / 2` iteraciones. Los dos
ciclos reparten igual, así que cada hilo cuenta los asteriscos de su propio bloque.
</details>

<details><summary>Respuesta</summary>

Hilo 0: `i = 0..7` (asteriscos en 1, 3, 4, 6 → 4); hilo 1: `i = 8..15` (9, 12, 14, 15 → 4). Salida real:
`hits por hilo: h0=4 h1=4` y `hits = 8`. El total no depende del número de hilos; el reparto sí.
</details>

**Hueco 3.** Con 4 hilos y `n = 18` (no divisible), ¿cómo reparte `static`? Escribe `owner1` para `i = 0..17`.

<details><summary>Pista</summary>

`18 = 4 · 4 + 2`: cada hilo recibe 4 iteraciones y sobran 2. Lo que debes decidir es a quién van esas dos y
si los bloques siguen siendo contiguos (`notas-estudiante.md` §2.4).
</details>

<details><summary>Respuesta</summary>

`static` sin *chunk* reparte bloques contiguos "aproximadamente iguales"; gcc (libgomp) da los sobrantes a
los primeros hilos: `0 0 0 0 0 1 1 1 1 1 2 2 2 2 3 3 3 3` (5, 5, 4, 4). Salida real: esa fila y
`hits por hilo: h0=3 h1=2 h2=1 h3=3`, `hits = 9`. Con 3 hilos y `n = 16`: `6, 5, 5` (`h0=3 h1=2 h2=3`).
</details>

## Pausa 5 · Medición: ¿vale como evidencia?

`./ejemplo_revision medir 10000000` sigue el protocolo (1 calentamiento + 5 repeticiones, mediana) para la
versión secuencial (un solo ciclo que escribe `a[i]` y lo compara de inmediato) y la paralela. Corridas reales:

| Hilos | Secuencial, mediana (s) | Paralelo, mediana (s) | *Speedup* | Eficiencia | Karp–Flatt `f` |
|---|---|---|---|---|---|
| 1 | 0.0195 | 0.0418 | 0.47 | 0.47 | — |
| 2 | 0.0196 | 0.0237 | 0.83 | 0.41 | 1.42 |
| 4 | 0.0207 | 0.0288 | 0.72 | 0.18 | 1.52 |

**Pausa 5.** El programa es correcto (`make test` lo verifica) y con 4 hilos es **más lento** que la
secuencial. ¿Esta tabla sirve como evidencia según `herramientas/protocolo-medicion.md`? ¿Qué explica el
*speedup* < 1? ¿Qué significa una `f` de Karp–Flatt mayor que 1?

<details><summary>Respuesta</summary>

No sirve: `T(1) ≈ 0.02 s < 0.1 s` (protocolo §5): se mide la sobrecarga, no el trabajo. Además, el
paralelo hace **más trabajo de memoria** que el secuencial: escribe `a[]` completo (80 MB) en el ciclo 1 y lo
vuelve a leer en el ciclo 2, mientras que el secuencial compara cada `a[i]` cuando todavía está en un
registro. Dos pasadas contra una, en un ciclo limitado por el ancho de banda (dos flops por 16 bytes),
más dos repartos y una barrera. Karp–Flatt supone que el paralelo hace el **mismo** trabajo que el
secuencial repartido entre `p`; cuando hace más, la fórmula devuelve `f > 1`: no "142 % secuencial", sino
"el modelo no aplica". Es la idea errónea 1 con datos: más hilos no es más rápido cuando el problema es
de milisegundos y lo limita la memoria. En el examen, la pregunta "¿es válida esta medición?" se contesta con
el protocolo, no con el *speedup*.
</details>

## Variante que falla · el mismo `nowait` con otro mapeo

`make ejemplo_revision_falla` compila con `-DVARIANTE_FALLA`: el ciclo 1 usa `schedule(dynamic, 1)` y el
ciclo 2 sigue en `static`. Salida real con `n = 64` y 4 hilos (recortada):

```
  owner1 :    0    0    0    0    0    0    0    0    0    0    3    0    0    0  ...   0    3    0    3
  owner2 :    0    0    0    0    0    0    0    0    0    0    0    0    0    0  ...   3    3    3    3
  mapas iguales en los dos ciclos: NO
  hits por hilo: h0=8 h1=7 h2=7 h3=7
hits = 29  (referencia secuencial 29)  ok
```

Salió **bien**. También salió bien en seis corridas de `medir` con `n = 10 000 000`. ThreadSanitizer, en tres
corridas con `n = 64`:

```
SUMMARY: ThreadSanitizer: data race ejemplo_revision.c:63 in count_hits_par._omp_fn.0
  Read of size 8 ... by thread T3:   Previous write of size 8 ... by thread T1:
```

**Pausa 6.** La línea 63 es `if (a[i] > thr)`. ¿Qué dos accesos chocan? ¿Por qué el resultado sale bien y aun
así el programa está mal? ¿Qué cambiarías: el `schedule` o el `nowait`?

<details><summary>Respuesta</summary>

El hilo T3 **lee** `a[i]` en el ciclo 2 y el hilo T1 lo había **escrito** en el ciclo 1 (en otra corrida fue el
hilo principal; los papeles cambian, el par de líneas no). Con `dynamic` el hilo que lee no es el que escribió,
y nada le garantiza que la escritura ya ocurrió. Sale bien porque el ciclo 1 es tan corto que, en la práctica,
termina antes de que el otro hilo llegue a esa `i`: una ventana de nanosegundos, no una garantía (idea 7). Dos
correcciones válidas: quitar el `nowait` (una barrera entre los ciclos; cuesta una sincronización) o volver a
`static` en ambos (mismo mapeo; gratis). La segunda es la más barata que es correcta.
</details>

## Qué te llevas

1. Cuatro preguntas resuelven los tres ítems de código del examen: qué se escribe y quién lo ordena; alcance de
   cada temporal; quién llega a cada barrera y quién lee después; qué hilo hace qué iteración.
2. `nowait` se justifica con el mapeo, no con la prisa: solo `static` con el mismo `n` garantiza que cada hilo
   lee lo que él mismo escribió.
3. Acumular en privado y combinar una vez (`my_hits` + `atomic`, o `reduction`) es el patrón; `private` deja
   basura; lo declarado adentro ya es privado.
4. Una medición con `T(1) < 0.1 s` no es evidencia; un *speedup* < 1 con `f > 1` dice "más trabajo", no "más
   secuencial".
5. "Salió bien" no es verificación: razonar sobre los accesos y ThreadSanitizer sobre la versión sin
   sincronizar sí lo son.
