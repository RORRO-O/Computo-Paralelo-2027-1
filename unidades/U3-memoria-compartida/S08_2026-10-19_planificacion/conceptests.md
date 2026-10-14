> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S08 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min) → discusión en parejas (2 min) → revoto → explicación (2 min).
Si el primer voto supera 80 % de aciertos se salta la discusión; si queda por debajo de 30 % se reexplica
antes de discutir. Los distractores citan el número de la idea errónea del Anexo A de
`docs/metodo/01-marco-pedagogico.md`.

---

## ConcepTest 1 · ¿Quién ejecuta qué? (minuto ~28, después del ejemplo resuelto)

Con 4 hilos y n = 16:

```c
#pragma omp parallel for schedule(static, 2)
for (int i = 0; i < 16; i++)
    owner[i] = omp_get_thread_num();
```

¿Qué iteraciones ejecuta el **hilo 1**?

- **A)** 4, 5, 6, 7
- **B)** 2, 3, 10, 11
- **C)** 1, 5, 9, 13
- **D)** No se puede saber: depende de qué hilo esté libre cuando se reparte cada bloque

<details>
<summary>Respuesta, origen de los distractores, porcentaje esperado y guion</summary>

**Respuesta: B.** `static,2` forma bloques de 2 iteraciones y los reparte **cíclicamente** en orden de número
de hilo: bloques 0,1,2,3 → hilos 0,1,2,3; bloques 4,5,6,7 → hilos 0,1,2,3. El hilo 1 recibe los bloques 1 y 5,
es decir, las iteraciones 2–3 y 10–11. Esto lo fija la especificación: es predecible antes de ejecutar.

| Distractor | De dónde nace |
|---|---|
| A | Confunde `static,2` con `static` sin *chunk* (bloques contiguos de n/p). Es el mapa que acaban de ver en el ejemplo. |
| C | Confunde `static,2` con `static,1` (reparto cíclico de 1 en 1). |
| D | Cree que toda planificación es dinámica / "el primero que se desocupa toma el siguiente". Variante de la idea errónea 11: no distingue `static` de `dynamic`. |

**Porcentaje esperado en el primer voto: 50–60 %.** Es la primera vez que aplican el reparto cíclico por
bloques.

**Guion de discusión (3 líneas).** "Dibujen los 16 cuadritos y agrúpenlos de 2 en 2. Numeren los bloques.
Ahora repartan los bloques como se reparten cartas: 0, 1, 2, 3, 0, 1, 2, 3. ¿Quién tiene el bloque de las
iteraciones 10 y 11?" Después del revoto, mostrar la línea `static,2` del mapa real de `schedule_map` y
subrayar: **con `static` se puede predecir; con `dynamic` no**.

</details>

---

## ConcepTest 2 · ¿Qué política gana aquí? (minuto ~68, puesta en común)

Un ciclo de 10 000 000 iteraciones. **Todas** cuestan lo mismo (unos 50 ns cada una). Hay 4 hilos y el
programa se mide con el protocolo del curso. ¿Qué política esperas que dé el **menor** tiempo?

- **A)** `schedule(dynamic)`, porque reparte el trabajo conforme los hilos se desocupan
- **B)** `schedule(static)`
- **C)** `schedule(guided)`, porque combina lo mejor de `static` y `dynamic`
- **D)** Las tres dan lo mismo: el trabajo total es igual y los 4 hilos lo hacen completo

<details>
<summary>Respuesta, origen de los distractores, porcentaje esperado y guion</summary>

**Respuesta: B.** Con carga uniforme no hay nada que balancear y `static` decide el reparto **una sola vez**,
sin coordinación en tiempo de ejecución. `dynamic` sin *chunk* (= `dynamic,1`) obliga a los hilos a pedir
las iteraciones **una por una** a un contador compartido: 10⁷ operaciones atómicas en competencia, cada una
comparable al trabajo de la iteración misma. En la práctica guiada el núcleo `uniform` lo muestra: `dynamic`
termina **más lento que la versión secuencial**.

| Distractor | De dónde nace |
|---|---|
| A | Idea errónea 11: "`dynamic` siempre gana porque reparte mejor". Ignora el costo por *chunk*. |
| C | Variante de la 11: `guided` también paga coordinación y aquí no hay desbalance que corregir. Es mejor que `dynamic,1` pero no que `static`. |
| D | Supone que repartir es gratis. Pariente de la idea 1 ("más hilos siempre es más rápido"): el tiempo de coordinación no aparece en su modelo. |

**Porcentaje esperado en el primer voto: 55–65 %** (ya vieron la tabla del núcleo `uniform` en la práctica;
si es menor de 40 %, la tabla no se discutió lo suficiente: volver a proyectarla).

**Guion de discusión.** "¿Cuánto trabajo hace una iteración? 50 ns. ¿Cuánto cuesta pedir la siguiente
iteración a un contador que otros 3 hilos también están tocando? Del mismo orden. ¿Entonces qué fracción
del tiempo es trabajo útil con `dynamic,1`?" Regla general al cerrar: **uniforme → `static`; desigual →
`dynamic`/`guided` con un *chunk* tal que el trabajo de un *chunk* sea mucho mayor que el costo de pedirlo.**

</details>

---

## ConcepTest 3 · `nowait` y la evidencia (reserva: minuto ~72 si hay tiempo; si no, va a la tarea)

```c
#pragma omp parallel
{
    #pragma omp for schedule(dynamic, 4) nowait
    for (int i = 0; i < n; i++) a[i] = f(i);

    #pragma omp for schedule(dynamic, 4)
    for (int i = 0; i < n; i++) b[i] = 2 * a[i];
}
```

El programa se ejecutó 5 veces y las 5 veces `b[]` salió correcto. ¿Qué concluyes?

- **A)** Es correcto: el `nowait` solo quita una barrera innecesaria, porque los dos ciclos tienen el mismo `schedule` y el mismo `n`
- **B)** Es correcto: aunque diga `nowait`, el segundo ciclo no empieza hasta que todos los hilos terminan el primero
- **C)** Hay una carrera de datos: nada garantiza que `a[i]` esté escrita cuando se lee; que saliera bien 5 veces no prueba nada
- **D)** Hay una carrera, y la forma de corregirla es poner `#pragma omp critical` alrededor de `b[i] = 2 * a[i]`

<details>
<summary>Respuesta, origen de los distractores, porcentaje esperado y guion</summary>

**Respuesta: C.** Con `dynamic` no existe garantía de que la iteración `i` del segundo ciclo la ejecute el
mismo hilo que la del primero. Un hilo que termina antes entra al segundo ciclo y puede leer `a[i]` antes de
que otro la escriba. La carrera es real aunque no se manifieste (idea errónea 7). Se detecta con
ThreadSanitizer (`make tsan` en la práctica guiada) o razonando sobre quién escribe y quién lee.

| Distractor | De dónde nace |
|---|---|
| A | Aplica mal la garantía de la especificación: esa garantía existe para **`static`** con el mismo *chunk* y el mismo número de iteraciones, no para `dynamic`. Es el matiz nuevo de hoy. |
| B | Idea errónea 12 al revés: no entiende que `nowait` **sí** elimina la barrera. |
| D | `critical` da exclusión mutua, no **orden**: el hilo lector seguiría pudiendo entrar antes que el escritor. Confusión entre sincronización de exclusión y de orden (S07). |

**Porcentaje esperado en el primer voto: 35–45 %.** A y C se reparten la mayoría.

**Guion de discusión.** "¿Qué garantiza la especificación cuando dos ciclos tienen el mismo `schedule(static)`?
¿Dice lo mismo de `dynamic`? Si no lo dice, ¿con qué derecho confiamos en que 'salió bien'?" Al cerrar: la
corrección es quitar el `nowait` (recuperar la barrera) **o** usar `schedule(static)` idéntico en ambos ciclos
y dejar el `nowait`; `nowait_buggy.c` muestra las dos variantes.

</details>

---

## Registro del profesor (llenar durante la sesión)

| ConcepTest | % 1.er voto | % revoto | Distractor más votado | Nota |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
