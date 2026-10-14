> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S10 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min, tarjetas A/B/C/D o manos cerradas) → discusión en parejas (2 min:
"convence a tu par") → revoto → explicación (2 min). Si el primer voto supera 80 % de aciertos se salta la
discusión; si queda por debajo de 30 % se reexplica el punto antes de discutir. En CT2 la discusión y el revoto
ocurren solo si el primer voto queda entre 30 % y 80 %. Cada distractor nace de una idea errónea del Anexo A de
`docs/metodo/01-marco-pedagogico.md` o de una nueva que aquí se documenta.

## CT1 · Amdahl con datos medidos (minuto ~28, tras el ejemplo resuelto)

Un programa tiene tres secciones. Medidas con `omp_get_wtime()` en la versión secuencial (mediana de 5):
`A = 0.02 s` (generar datos, no paralelizable), `B = 0.18 s` (transformar, `parallel for`), `C = 0.01 s`
(suavizar, no paralelizable). Con 4 hilos, la sección B tarda `0.05 s` y A y C no cambian. La sección B tiene
el 90 % de las líneas del programa.

¿Cuál afirmación es correcta?

- **A)** El *speedup* del programa con 4 hilos es 3.6 (= 0.18 / 0.05).
- **B)** El *speedup* del programa con 4 hilos es ≈ 2.6 y, por más hilos que se agreguen, nunca pasará de 7.
- **C)** El *speedup* con 4 hilos es ≈ 2.6, así que con 8 hilos será ≈ 5.2.
- **D)** La eficiencia con 4 hilos es 2.6, igual que el *speedup*.

| Opción | Origen |
|---|---|
| A | Nueva: "el *speedup* del núcleo es el *speedup* del programa". Se mide el total que ve el usuario: `(0.02 + 0.18 + 0.01) / (0.02 + 0.05 + 0.01) = 0.21 / 0.08 ≈ 2.6`. Se agrega al catálogo como 2b. |
| **B** | **Correcta.** `f = (A + C) / total = 0.03 / 0.21 ≈ 0.143`; Amdahl: `S(∞) = 1/f = 7`; `S(4) = 1/(0.143 + 0.857/4) ≈ 2.8` (el 2.6 medido queda por debajo porque B escaló 3.6 y no 4). |
| C | Idea errónea 1: "más hilos siempre es más rápido" en su forma lineal. Amdahl con `f = 0.143`: `S(8) = 1/(0.143 + 0.857/8) ≈ 4.0`, no 5.2; y el techo es 7. |
| D | Idea errónea 3: eficiencia = *speedup* / p = 2.6 / 4 = 0.65. |

Quien use "90 % de las líneas" para calcular `f = 0.1` cae en la idea errónea 2: la fracción se mide en tiempo
(aquí 0.143, no 0.1). Preguntarlo explícitamente en la discusión aunque no sea una opción.

**Acierto esperado en el primer voto:** 45–60 % (A es el distractor fuerte: es el número "bonito" que imprime el
programa para la sección B).

**Guion de discusión (3 líneas).** "Quien votó A: si el usuario cronometra el programa completo, ¿ve 3.6 veces
menos tiempo? Suma las tres secciones antes y después. Quien votó C: con infinitos hilos B tarda cero; ¿cuánto
tarda entonces el programa? Ese es el techo." Cerrar con la salida real de `profile_amdahl` proyectada:
la línea `Amdahl con f medida` y la línea `Karp-Flatt`.

## CT2 · Sin carrera y aun así más lento (minuto ~68, puesta en común)

```c
long counts[4] = {0, 0, 0, 0};
#pragma omp parallel num_threads(4)
{
    int tid = omp_get_thread_num();
    #pragma omp for
    for (long i = 0; i < n; i++)
        if (bin_of(i) == 0) counts[tid]++;     /* cada hilo escribe SOLO en counts[tid] */
}
```

`make test` pasa: el total coincide siempre con la versión secuencial. Pero con 4 hilos el ciclo tarda **más**
que con 1. ¿Cuál es la explicación y la corrección?

- **A)** Hay una condición de carrera porque los cuatro hilos escriben en el mismo arreglo; falta `atomic`.
- **B)** Las cuatro casillas caben en la misma línea de caché y cada escritura invalida la copia de los otros
  núcleos (falso compartido); se corrige acumulando en una variable local o separando las casillas con relleno.
- **C)** Es la sobrecarga normal de crear hilos; con 8 o 16 hilos se compensa.
- **D)** Es un error de medición: hay que compilar con `-O0` para ver el tiempo real del ciclo.

| Opción | Origen |
|---|---|
| A | Nueva: confundir **falso** compartido con compartir de verdad. `counts[tid]` es una posición distinta por hilo: no hay carrera; `atomic` lo haría todavía más lento. Se agrega al catálogo como 14b. |
| **B** | **Correcta** (idea errónea 14, versión correcta). En la práctica guiada: `contiguo` frente a `relleno` y `local`. |
| C | Idea errónea 14 ("se arregla con más hilos") combinada con la 1: más hilos sobre la misma línea empeoran el rebote. |
| D | Idea errónea 5: nunca se mide con `-O0`; además `-O0` no cambia dónde viven los datos. |

**Acierto esperado en el primer voto:** 60–75 % (acaban de medirlo; A atrae a quien no distingue carrera de
contención).

**Guion de discusión.** "Quien votó A: ¿qué dos hilos escriben la **misma** posición? Si ninguno, ¿qué protege
`atomic`? Quien votó C: en tu tabla, ¿`contiguo` mejoró de 2 a 4 hilos tanto como `relleno`?" Regla general:
*una línea de caché es la unidad que viaja entre núcleos; dos hilos que escriben en la misma línea se estorban
aunque no compartan ningún dato.*

## CT3 · *Speedup* superlineal (reserva: transferencia, o apertura de S11 el lunes 26 de octubre)

Un equipo mide con el protocolo completo (mediana de 5, `-O2`, mejor secuencial como `T(1)`), `make test` pasa, y
obtiene `S(4) = 4.6`. Sus datos ocupan 6 MB; cada núcleo tiene 2 MB de caché L2.

- **A)** Es imposible: hay que repetir la medición hasta que salga ≤ 4.
- **B)** Es posible: con 4 hilos cada uno trabaja sobre 1.5 MB, que caben en su L2; con 1 hilo los 6 MB no caben
  en una. Se reporta explicándolo y verificando correctitud.
- **C)** Significa que la versión secuencial está mal compilada; ambas deben compilarse con `-O0` para comparar.
- **D)** Karp–Flatt da `f` negativa, lo que demuestra que el programa no tiene ninguna parte secuencial.

| Opción | Origen |
|---|---|
| A | Idea errónea 4: "el *speedup* superlineal es un error de medición". |
| **B** | **Correcta.** El efecto de caché es real y explicable; la regla del protocolo (§5) es no reportarlo **sin** explicación. |
| C | Idea errónea 5 (`-O0`). Con `-O0` el secuencial sería artificialmente lento y el *speedup* perdería sentido. |
| D | Nueva: `f` de Karp–Flatt negativa solo dice que el modelo de Amdahl (que no contempla efectos de caché) no aplica a esos datos; no demuestra nada sobre el código. Se agrega como 4b. |

**Acierto esperado en el primer voto:** 50–65 %.

**Guion de discusión.** "Quien votó A: ¿qué cambió entre 1 y 4 hilos además del número de hilos? ¿Cuánta caché
tiene el programa a su disposición en cada caso? Quien votó D: calcula `f` con `S = 4.6`, `p = 4`: `(1/4.6 − 1/4)
/ 0.75 ≈ −0.043`. ¿Qué supone Amdahl que aquí no se cumple?"

## Registro para el profesor (llenar en la sesión)

| ConcepTest | % 1er voto | % revoto | Opción más votada entre los errados | Nota |
|---|---|---|---|---|
| CT1 | | | | |
| CT2 | | | | |
| CT3 | | | | |
