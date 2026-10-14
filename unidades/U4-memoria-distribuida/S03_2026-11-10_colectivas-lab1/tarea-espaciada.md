> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S03 · Tarea espaciada (20–30 minutos; hasta 40 si no terminaste la fase Crear en clase)

Tres ejercicios cortos: uno del tema de hoy (elegir entre colectivas que se confunden), uno intercalado de
las Unidades I y III (Amdahl y Karp–Flatt sobre una medición real de hoy) y uno de preparación para S04.
Individual. Sin IA en los ejercicios 1(a), 2 y 3 (son del tipo que aparece en el Examen 3, martes 8 de
diciembre); en 1(b) aplica el semáforo de `docs/metodo/05-politica-ia.md`.

**Entrega.** La traes resuelta (papel o `tarea-S03.md` en tu repositorio) a la sesión S04 del **jueves 12 de
noviembre de 2026, 10:30, Salón 3208**, junto con la tarea de S02. En los primeros minutos la autocalificas con
las claves de `<details>` (2 min); el profesor registra la entrega, no el acierto, y revisa 3 al azar por
parcial. **Esta tarea no tiene peso propio; el examen de práctica del jueves 3 de diciembre y el 10–20 %
acumulativo del Examen 3 toman ítems de aquí.** Si faltaste hoy, esta tarea sustituye tu recuperación y tu
*exit ticket* de S03.

**Aparte:** la Práctica 5 sigue (Parte C entre sesiones; Lab 2 el martes 17 de noviembre; entrega el domingo
22 de noviembre a las 23:59; 15 % del 3er parcial). Esta tarea no la sustituye.

---

## Ejercicio 1 · Tema de hoy (10 min; +10 si debes la fase Crear)

**(a) Elige la colectiva y justifícala en una línea.** Para cada situación escribe **una** colectiva de
`Bcast`, `Scatter`/`Scatterv`, `Gather`/`Gatherv`, `Reduce`, `Allreduce`, `Allgather`, `Barrier`, y la razón
contestando "¿quién tiene el dato antes y quién lo necesita después?". Si hace falta más de una, dilo.

1. El rango 0 leyó de un archivo la tolerancia `tol` y el número de iteraciones; todos los rangos los necesitan.
2. Cada rango tiene la suma parcial de un residuo; **solo** el rango 0 va a imprimir el total.
3. Cada rango tiene la suma parcial de un residuo; **todos** deben decidir con el total si siguen iterando.
4. Cada rango calculó su bloque de `y`; en la siguiente iteración **todos** necesitan `y` completo como nuevo `x`.
5. El rango 0 debe imprimir los máximos locales de todos los rangos, **en orden de rango**, sin combinarlos.
6. Una matriz de 10 filas se reparte entre 4 procesos y cada uno recibe sus filas desde el rango 0.

<details><summary>Clave</summary>

1. `MPI_Bcast` (dos llamadas, porque `tol` es `double` y las iteraciones `int`; o una sola con un arreglo de 2
`double`). Antes: solo el 0. Después: todos, el mismo dato.<br>
2. `MPI_Reduce` con `MPI_SUM`, raíz 0. Antes: todos un pedazo. Después: solo el 0 lo necesita combinado.
`Allreduce` también da el resultado correcto, pero paga por dejarlo en todos.<br>
3. `MPI_Allreduce` con `MPI_SUM`. Después lo necesitan todos, y además todos deben tomar la **misma** decisión
(si cada uno comparara su parcial, pararían en iteraciones distintas y la siguiente colectiva se colgaría).<br>
4. `MPI_Allgather`. Antes: cada uno un bloque. Después: todos el vector completo. `Gather` + `Bcast` funciona
pero son dos colectivas y el 0 es cuello de botella.<br>
5. `MPI_Gather` (los `p` valores quedan en el 0 en orden de rango). `Reduce` con `MPI_MAX` **no**: combinaría y
perdería los valores individuales.<br>
6. `MPI_Scatterv`: 10 no es múltiplo de 4 (bloques 3, 3, 2, 2); `Scatter` exige bloques iguales.
</details>

**(b) Si no terminaste en clase la fase Crear** de `practica-guiada/README.md` (`norma_allreduce.c`), este es
tu ejercicio del tema: escríbela y verifica con `make test` (3 líneas `PASS` de `norma_allreduce`). Si ya la
terminaste, (b) no aplica.

## Ejercicio 2 · Intercalado (Unidades I y III): Amdahl y Karp–Flatt con datos de hoy (10 min)

Mediciones reales de `practica-guiada/` con `n = 4096` y 40 productos con la misma matriz repartida una vez
(protocolo: calentamiento, 5 repeticiones, mediana; máquina virtual de 4 núcleos **compartida**, carga
ajena ≈ 5–6 durante la medición, es decir, la regla "cierra lo demás" no se pudo cumplir):

| Configuración | Mediana (s) |
|---|---|
| `matvec_seq 4096 40` | 1.072 |
| `matvec_collectives -np 2`, `4096 40` | 0.789 |
| `matvec_collectives -np 4`, `4096 40` | 0.559 |

Desglose de una corrida con `-np 4`: `scatter = 0.165`, `bcast = 0.011`, `calcular = 0.611` (máximo entre
rangos), `gather = 0.000`.

a) Calcula S(2), S(4), E(2) y E(4).
b) Toma como fracción secuencial `f` el tiempo que el rango 0 pasa repartiendo (`scatter + bcast`), dividido entre
el tiempo secuencial. Con Amdahl, ¿cuál es el *speedup* máximo con 4 procesos? ¿Y con infinitos?
c) Calcula la fracción secuencial de Karp–Flatt con la medición real de p = 4: f = (1/S − 1/p) / (1 − 1/p).
¿Es mayor o menor que la de (b)? ¿Qué sobrecarga **además** de la comunicación explica la diferencia? (Mira el
`calcular` del desglose contra 1.072 / 4.)
d) Una línea: ¿en qué unidad se mide la fracción secuencial de Amdahl, y por qué no sirve contar líneas de
código para estimarla aquí?

<details><summary>Respuestas</summary>

a) S(2) = 1.072 / 0.789 = 1.36; E(2) = 0.68. S(4) = 1.072 / 0.559 = 1.92; E(4) = 0.48.<br>
b) f ≈ (0.165 + 0.011) / 1.072 ≈ 0.16. Amdahl: S_max(4) = 1 / (0.16 + 0.84 / 4) = 1 / 0.37 ≈ 2.7;
S_max(∞) = 1 / 0.16 ≈ 6.1.<br>
c) f_KF(4) = (1/1.92 − 1/4) / (1 − 1/4) = (0.521 − 0.250) / 0.750 ≈ 0.36, mayor que 0.16. La diferencia es el
cómputo que no escaló: `calcular` tardó 0.611 s en el rango más lento, cuando el reparto ideal sería
1.072 / 4 ≈ 0.27 s; con los núcleos ocupados por procesos ajenos, el rango más lento marca el paso (desbalance,
idea errónea 20: la sobre-suscripción cambia las mediciones). Karp–Flatt mete en `f` todo lo que no escala, no
solo la comunicación.<br>
d) En **tiempo** de la versión secuencial (idea errónea 2). Aquí la parte que no escala son tres líneas
(`Scatter`, `Bcast`, `Gather`) y el 16 % del tiempo; el cómputo son otras tres líneas y el 84 %.
</details>

## Ejercicio 3 · Preparación para S04 (jueves 12 de noviembre, 10:30): celdas fantasma (5–8 min)

El jueves se reparte una barra de 12 celdas (Jacobi 1D, el mismo que hiciste con OpenMP en S11) entre 3
procesos en bloques contiguos. En cada iteración, `u_new[i]` se calcula con `u[i-1]` y `u[i+1]`.

a) ¿Qué celdas tiene el proceso 1? ¿Qué valores necesita que **no** están en su memoria, y en qué proceso están?
b) ¿Cuántos mensajes punto a punto envía y recibe el proceso 1 **por iteración**? ¿Con qué llamada de S02 los
harías sin riesgo de interbloqueo?
c) Al final de cada iteración cada proceso tiene su `local_diff` (máximo cambio en su bloque). Todos deben parar
en la **misma** iteración cuando el máximo global baje de `tol`. ¿Qué colectiva de hoy usarías y con qué operación?
d) Lee 3 minutos `notas-estudiante.md` de S02, §5 (interbloqueo y `MPI_Sendrecv`): el jueves se usa en cada iteración.

<details><summary>Respuestas</summary>

a) Celdas 4–7 (con celdas 0–11 numeradas desde 0; en la numeración 1–12 de S04 son 5–8). Necesita la celda 3
(proceso 0) y la celda 8 (proceso 2).<br>
b) Envía 2 (su primera celda al 0, su última al 2) y recibe 2: 4 mensajes por iteración. Con `MPI_Sendrecv`
(o `Isend`/`Irecv` + `Wait`, que se ve el jueves).<br>
c) `MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD)`: todos la llaman y todos
obtienen el mismo máximo, así que todos toman la misma decisión.<br>
d) Sin respuesta; se verifica con la pregunta 2 de la recuperación de S04.
</details>
