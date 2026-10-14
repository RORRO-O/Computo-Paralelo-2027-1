> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S07 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min, tarjetas o manos cerradas) → discusión en parejas (2 min: "convence a
tu par") → revoto → explicación (2 min). Si el primer voto supera 80 % de aciertos se salta la discusión; si
queda por debajo de 30 % se reexplica el punto antes de discutir. Cada distractor nace de una idea errónea
del Anexo A de `docs/metodo/01-marco-pedagogico.md` o de una nueva que aquí se documenta.

## CT1 · "Salió bien cinco veces" (minuto ~28, tras el ejemplo resuelto)

Este código se compiló con `gcc -O2 -fopenmp` y se corrió cinco veces con 4 hilos. Las cinco veces imprimió
el valor correcto.

```c
long count = 0;
#pragma omp parallel for
for (long i = 0; i < n; i++)
    if (data[i] > 0) count++;
printf("%ld\n", count);
```

¿Qué concluyes?

- **A)** No hay condición de carrera: cinco corridas correctas lo demuestran.
- **B)** Hay condición de carrera; que saliera bien fue casualidad o efecto del compilador, y puede fallar con
  otro `n`, otra máquina u otras banderas.
- **C)** No hay carrera porque `count++` es una sola instrucción en x86 y una instrucción no se puede interrumpir.
- **D)** Hay carrera solo cuando `n` no es divisible entre el número de hilos.

| Opción | Origen |
|---|---|
| A | Idea errónea 7: "si salió bien una vez, no hay carrera" |
| **B** | **Correcta** |
| C | Nueva: "una instrucción = atómica". `incq (mem)` sin prefijo `lock` se descompone en leer, sumar y escribir entre núcleos; además el compilador puede partirla o acumular en registro. Se agrega al catálogo como 7b. |
| D | Nueva: confunde el reparto de iteraciones con la sincronización de datos. El reparto decide quién hace qué iteración; la carrera está en que todos escriben la misma `count`. Se agrega como 7c. |

**Acierto esperado en el primer voto:** 50–60 % (A y C se reparten el resto; D poca gente).

**Guion de discusión (3 líneas).** "Quien votó A: ¿qué tendría que pasar para que saliera mal? Si no puedes
describir una secuencia de eventos que lo rompa, busca la tabla de leer-modificar-escribir. Quien votó C: ¿qué
hace el procesador con `count++` cuando `count` está en la caché de otro núcleo?" Cerrar con la salida real de
`counter_buggy` a `-O2` (correcto tres veces) y a `-O0` (casi siempre incorrecto): mismo código, misma carrera.

## CT2 · `atomic` en el histograma (minuto ~68, puesta en común)

```c
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    int bin = bin_of(x[i], nbins);
    #pragma omp atomic
    hist[bin]++;
}
```

¿Cuál afirmación es correcta?

- **A)** `atomic` y `critical` hacen exactamente lo mismo aquí; la diferencia es solo de sintaxis.
- **B)** `atomic` protege la actualización de `hist[bin]` sea cual sea `bin`, y deja que hilos en bins distintos
  avancen en paralelo; `critical` serializaría todas las actualizaciones, incluso las de bins distintos.
- **C)** No hace falta `atomic`: cada hilo procesa índices `i` distintos, así que nunca escriben la misma
  posición.
- **D)** `atomic` elimina la barrera implícita del final del `for`, así que después del ciclo hay que poner
  `#pragma omp barrier` antes de leer `hist`.

| Opción | Origen |
|---|---|
| A | Idea errónea 8: "`critical` y `atomic` son equivalentes" |
| **B** | **Correcta** |
| C | Nueva: confunde el índice del ciclo (`i`, distinto por hilo) con la posición escrita (`hist[bin]`, que depende de los datos). Muy frecuente en histogramas y en cualquier *scatter*. Se agrega como 7d. |
| D | Idea errónea 12 invertida: `atomic` no toca las barreras; la barrera implícita del `for` sigue ahí y basta para leer `hist` después. |

**Acierto esperado en el primer voto:** 55–65 %.

**Guion de discusión.** "Quien votó C: dos hilos con `i = 3` e `i = 7 000 000`, ¿pueden caer en `bin = 12` los
dos? Quien votó A: en la tabla de tiempos, `critical` costó 73 ns por elemento y `atomic` 16; si fueran lo
mismo, ¿de dónde sale la diferencia?" Regla general: `atomic` protege **una** actualización simple de **una**
posición; `critical` protege **código**. Se elige el más barato que sea correcto.

## CT3 · `private` y alcance (reserva: transferencia o apertura de S08, lunes 19 de octubre)

```c
int k = 10;
int out[4];
#pragma omp parallel for private(k)
for (int i = 0; i < 4; i++) {
    int j = k + i;
    out[i] = j;
}
```

Con 4 hilos, ¿qué vale `out[2]` después del ciclo?

- **A)** 12.
- **B)** No se sabe: `k` dentro del ciclo tiene un valor indefinido.
- **C)** 2: `private` inicializa `k` en cero.
- **D)** Depende de qué hilo escriba `j` al último, porque `j` es compartida.

| Opción | Origen |
|---|---|
| A | Idea errónea 9: "`private` copia el valor inicial" |
| **B** | **Correcta** (para copiar el 10 se usa `firstprivate(k)`) |
| C | Variante de la 9: "`private` inicializa en cero" (confusión con `reduction`, que sí inicializa con la identidad de la operación). Se agrega como 9b. |
| D | Idea errónea 15: "las variables declaradas dentro de la región son compartidas". `j` es privada por alcance. |

**Acierto esperado en el primer voto:** 45–55 %.

**Guion de discusión.** "Quien votó A: ¿qué cláusula existe entonces para copiar el valor? Si `private` ya lo
copiara, `firstprivate` no tendría razón de ser. Quien votó D: ¿cuántas `j` hay con 4 hilos?" Mostrar
`private_buggy.c`: la fila B cambia entre corridas, la C no.

## Registro para el profesor (llenar en la sesión)

| ConcepTest | % 1er voto | % revoto | Opción más votada entre los errados | Nota |
|---|---|---|---|---|
| CT1 | | | | |
| CT2 | | | | |
| CT3 | | | | |
