> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S13 · ConcepTests (instrucción entre pares en el bloque de los tres ítems peor contestados)

En una sesión de repaso no hay bloque de instrucción explícita: cada uno de los tres ítems que se discuten
(minutos 50–80) **abre** con un ConcepTest sobre la misma idea errónea pero con otro caso, para saber si la
corrección entre pares ya la movió. Secuencia fija: voto individual (1 min, tarjetas A/B/C/D) → discusión
en parejas (2 min: "convence a tu par") → revoto → explicación (2 min). Si el primer voto supera 80 % se
salta la discusión; si queda bajo 30 % se reexplica antes de discutir. Cada distractor nace de una idea
errónea del Anexo A de `docs/metodo/01-marco-pedagogico.md` o de una nueva que aquí se documenta.

Qué CT se usa depende de qué ítems fallaron: CT1 acompaña a los ítems I.5/V (rendimiento), CT2 a II/III.1/IV
(alcance, barreras, tareas) y CT3 a I.3/III.2/VI (dependencias y `schedule`). Si los tres ítems peor
contestados caen en una sola fila, se usa el CT de esa fila y los otros dos pasan a la recuperación de U4 S01
(jueves 5 de noviembre) o al Examen 2.

## CT1 · Tres números que parecen uno (ítems I.5 y V; ideas 3, 31, 5)

Un equipo reporta, con el protocolo completo y el mismo `n`: mejor secuencial `T(1) = 10.0 s`; versión
paralela con **1 hilo** `12.0 s`; con **4 hilos** `3.0 s`. En su reporte escriben "*speedup* 4.0 con 4 hilos,
eficiencia 100 %". ¿Qué es correcto?

- **A)** Tienen razón: `12.0 / 3.0 = 4.0` y `4.0 / 4 = 1.0`.
- **B)** `S(4) = 10.0 / 3.0 ≈ 3.3` y `E(4) ≈ 0.83`; el 12.0 solo puede reportarse aparte, declarado como "paralela
  con 1 hilo", y sirve para medir la sobrecarga de OpenMP (20 %).
- **C)** `S(4) = 3.3` y `E(4) = 3.3`: la eficiencia con 4 hilos es el mismo número.
- **D)** No se puede saber: falta repetir las tres mediciones con `-O0` para quitar el efecto del compilador.

<details><summary>Respuesta, origen de los distractores y guion (ábrelo después de votar)</summary>

| Opción | Origen |
|---|---|
| A | Idea errónea 31: el denominador es el **mejor secuencial**, no la paralela con 1 hilo (protocolo §3). |
| **B** | **Correcta.** |
| C | Idea errónea 3: eficiencia = *speedup* / p. |
| D | Idea errónea 5: nunca se mide con `-O0`. |

**Acierto esperado en el primer voto:** 60–75 % (acaban de corregir V; A atrae a quien usa "su" programa como
referencia).

**Guion de discusión (3 líneas).** "Quien votó A: si alguien tenía un programa secuencial de 10 s y ustedes le
dan uno de 3 s, ¿cuánto ganó? ¿Y si le dan el de 12 s con un hilo, ganó o perdió? Quien votó C: ¿qué fracción de
cada núcleo está trabajando si 4 núcleos rinden como 3.3?" Cerrar con la regla: *S contra el mejor secuencial,
E = S/p, y la paralela con 1 hilo se reporta aparte para medir cuánto cuesta OpenMP.*

</details>

## CT2 · Alcance y barreras en diez líneas (ítems II, III.1, IV; ideas 9, 15, 12, 32)

```c
int k = 3;
long a[8];
#pragma omp parallel num_threads(4) private(k)
{
    int j = omp_get_thread_num();
    #pragma omp for schedule(static) nowait
    for (int i = 0; i < 8; i++) a[i] = i * j;
    #pragma omp barrier
    if (j == 0) printf("%ld\n", a[7]);
}
```

¿Cuál afirmación es correcta?

- **A)** Dentro de la región `k` vale 3 en cada hilo, porque `private` le da a cada hilo una copia del valor.
- **B)** `j` es compartida porque los cuatro hilos la escriben; hay una carrera en `int j = …`.
- **C)** `k` tiene un valor indefinido en cada hilo; `j` es privada por alcance; la `barrier` la alcanzan los
  cuatro hilos, así que `a[7]` ya está escrito cuando el hilo 0 lo imprime: imprime `21`.
- **D)** El `#pragma omp barrier` sobra: `omp for` ya termina con una barrera y el `printf` es seguro sin él.

<details><summary>Respuesta, origen de los distractores y guion (ábrelo después de votar)</summary>

| Opción | Origen |
|---|---|
| A | Idea errónea 9: `private` no copia; queda indefinida (aquí no se usa, así que el programa es correcto de todos modos). |
| B | Idea errónea 15: lo declarado dentro de la región es privado. |
| **C** | **Correcta.** `a[7]` lo escribe el hilo 3 (`static`: dos iteraciones por hilo; `7 · 3 = 21`); la barrera explícita, fuera de cualquier `if`, ordena esa escritura antes de la lectura del hilo 0. |
| D | Idea errónea 12 al revés: el `nowait` quitó la barrera implícita; sin la explícita, el hilo 0 podría leer `a[7]` antes de que el hilo 3 lo escriba. |

**Acierto esperado en el primer voto:** 50–65 % (D es el distractor fuerte: quien recuerda "hay barrera al final
del `for`" olvida que `nowait` la quita).

**Guion de discusión.** "Quien votó D: lee la línea del `for` completa; ¿qué hace la última palabra? Quien votó
A: ¿para qué existiría `firstprivate` si `private` ya copiara? Quien votó B: ¿cuántas `j` hay con 4 hilos?"
Regla general: *lo declarado adentro es privado; `private` es basura; `nowait` quita la barrera y entonces la
pones tú, fuera de cualquier `if`.*

</details>

## CT3 · Un `schedule` no arregla una dependencia (ítems I.3, III.2, VI; ideas 30, 11, 30b, 30c)

```c
y[0] = x[0];
#pragma omp parallel for schedule(dynamic, 64)
for (long i = 1; i < n; i++)
    y[i] = 0.5 * y[i - 1] + x[i];
```

Con 4 hilos el resultado es incorrecto. ¿Qué es cierto?

- **A)** Con `schedule(static)` sería correcto: el problema es que `dynamic` desordena las iteraciones.
- **B)** Ninguna cláusula lo corrige: la iteración `i` necesita el `y[i-1]` que escribe la iteración `i-1`;
  hay que cambiar el algoritmo (dos fases, como el *scan*) o dejarlo secuencial.
- **C)** Basta `reduction(+:y[:n])`: OpenMP combina las copias de `y` al final.
- **D)** Basta `ordered` y queda tan rápido como `static`, porque solo ordena las escrituras.

<details><summary>Respuesta, origen de los distractores y guion (ábrelo después de votar)</summary>

| Opción | Origen |
|---|---|
| A | Idea errónea 30 con disfraz de 11: `static` también reparte en bloques y cada bloque leería un `y[lo-1]` no escrito. |
| **B** | **Correcta** (S11 §1.2: el *scan* en dos fases cuesta 1.5× el tráfico de memoria y dio *speedup* 1.9 con 4 hilos; aquí el coeficiente 0.5 complica la fase 2, así que "secuencial si no domina el tiempo" también vale). |
| C | Idea errónea 30b (agregada al Anexo A con esta sesión): usar `reduction` para una recurrencia. `reduction` combina copias **independientes** al final; no transmite el valor de una iteración a la siguiente. |
| D | Idea errónea 30c (agregada al Anexo A con esta sesión): `ordered` obliga a ejecutar el bloque en orden de iteración: es correcto y **serializa** el ciclo (más lento que secuencial por la sincronización). |

**Acierto esperado en el primer voto:** 45–60 % (C atrae a quien aprendió `reduction(+:hist[:n])` en S11 sin
distinguir reducción de recurrencia).

**Guion de discusión.** "Quien votó A o C: con 4 hilos y `static`, ¿qué vale `y[lo-1]` cuando el hilo 1 empieza
su bloque? ¿Quién lo escribió ya? Quien votó D: si cada iteración espera a la anterior, ¿cuántas se ejecutan
al mismo tiempo?" Regla general: *antes del pragma, lista qué lee y qué escribe cada iteración; si lee lo que
escribió otra, no es un problema de cláusulas, es de algoritmo.*

</details>

## Registro para el profesor (llenar en la sesión)

| ConcepTest | ¿Se usó? (ítem al que acompañó) | % 1er voto | % revoto | Opción más votada entre los errados | Nota |
|---|---|---|---|---|---|
| CT1 | | | | | |
| CT2 | | | | | |
| CT3 | | | | | |
