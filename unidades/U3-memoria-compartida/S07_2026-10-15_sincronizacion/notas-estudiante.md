> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S07 · Notas: corrección en memoria compartida

Si faltaste: lee esto (10 min), haz el `ejemplo-resuelto.md` con sus pausas (20 min) y la práctica guiada
(`practica-guiada/README.md`, 40 min). Con eso reconstruyes la sesión.

## 1. El problema: condición de carrera

Una **condición de carrera** (*data race*) ocurre cuando dos hilos acceden a la misma posición de memoria,
al menos uno escribe, y nada ordena los accesos. El caso típico es `x++` o `hist[bin]++` sobre una variable
compartida: para el procesador son tres pasos (leer, modificar, escribir) y otro hilo puede meterse entre
ellos. El efecto es perder actualizaciones; el síntoma es un resultado que cambia entre corridas.

Palabras clave: *leer-modificar-escribir*, *no determinista*, *actualización perdida*.

Tres hechos que conviene memorizar:

- Una carrera **no siempre se manifiesta**. Con `-O2`, con pocos hilos o con poca contención el resultado puede
  salir bien muchas veces. "Salió bien" no es evidencia (idea errónea 7).
- El total con pérdidas siempre queda **por debajo** del correcto, nunca por encima.
- Una carrera es comportamiento indefinido en C: el compilador puede transformar el código suponiendo que
  no existe (por eso `count++` con `-O2` "salió bien" en el ejemplo).

## 2. Diagnóstico

**Razonando.** Para cada variable que se escribe dentro de la región paralela: ¿es compartida? ¿quién más la
lee o escribe? ¿qué construcción ordena esos accesos? Si la respuesta a la última es "nada", hay carrera.

**Con ThreadSanitizer.** `gcc -std=c11 -fsanitize=thread -g -O1 -fopenmp archivo.c` y ejecutar con `n`
pequeño (es 5–20 veces más lento). El reporte dice la línea, los dos hilos y la memoria en conflicto:

```
WARNING: ThreadSanitizer: data race
  Write of size 8 ... by main thread:   #0 main._omp_fn.0 counter_buggy.c:38
  Previous read of size 8 ... by thread T1:   #0 main._omp_fn.0 counter_buggy.c:37
SUMMARY: ThreadSanitizer: data race counter_buggy.c:38
```

Limitación importante con gcc: ThreadSanitizer no ve la sincronización interna de `libgomp` (barreras,
`critical`, candados), así que **también reporta "carreras" en código correcto**. Úsalo para localizar la línea
de una carrera que sospechas en código sin sincronizar; para código sincronizado, la verificación es razonar y
comparar contra la versión secuencial con varias corridas y distinto número de hilos (`make test`).

## 3. Cinco formas de corregir, y cuánto cuestan

| Mecanismo | Qué protege | Cuándo usarlo | Costo medido (ns por actualización, 4 hilos, orientativo) |
|---|---|---|---|
| `reduction(op:x)` | Acumulación con `+ * - & | ^ && || min max` | Siempre que la operación sea una reducción | ~3 |
| Acumulador local + combinación | Lo que tú quieras (arreglos, estructuras) | Reducciones que `reduction` no expresa (p. ej. histograma en OpenMP < 4.5) | ~3 |
| `#pragma omp atomic` | **Una** actualización simple de **una** variable escalar: `x++`, `x += e`, `x = x op e` | Actualizaciones dispersas (histograma) donde los hilos rara vez chocan | ~15 |
| `#pragma omp critical` | Una región arbitraria de código | Varias variables a la vez, condiciones, llamadas | ~60 |
| `omp_lock_t` (`omp_init_lock`, `omp_set_lock`, `omp_unset_lock`, `omp_destroy_lock`) | Lo mismo que `critical`, con un objeto que puedes tener en un arreglo (un candado por bin) | Cuando necesitas varios candados independientes o adquirir/soltar en puntos distintos del código | ~60 |

Los números son de `practica-guiada/sum_variants.c` en la máquina de autoría; en la tuya cambiarán, el orden no.
`critical` y `atomic` **no** son equivalentes (idea errónea 8): `atomic` es más barato porque pide menos.
Los histogramas de la práctica dieron el mismo orden: `critical` 73 ns, `atomic` 16 ns, local 2.4 ns por elemento.

El patrón que gana casi siempre: **acumular en privado, combinar una vez**. `reduction` es ese patrón
automatizado. Desde OpenMP 4.5 también funciona con arreglos: `reduction(+:hist[:nbins])`.

## 4. Barreras, `nowait`, `single`, `master`

- Al final de `omp for`, `omp sections` y `omp single` hay una **barrera implícita**: ningún hilo sigue hasta que
  todos terminan (idea errónea 12). Al final de la región `parallel` también, y esa no se quita.
- `nowait` quita la barrera implícita. Es seguro solo si después del ciclo nadie lee lo que otro hilo escribió
  en él. `practica-guiada/nowait_buggy.c` muestra el caso en que no es seguro.
- `#pragma omp barrier`: barrera explícita, donde tú la necesites.
- `#pragma omp single`: el bloque lo ejecuta **un** hilo (cualquiera); los demás esperan en su barrera implícita.
- `#pragma omp master`: el bloque lo ejecuta el hilo 0; **sin** barrera. OpenMP 5.1 lo declara obsoleto en
  favor de `masked`, pero gcc 13 lo acepta.

## 5. `private` vs `firstprivate` vs declarar adentro

| Cláusula / forma | Valor inicial en cada hilo | Valor afuera al terminar |
|---|---|---|
| `shared(x)` (por omisión para lo declarado afuera) | La misma variable para todos | Lo que quedó escrito (riesgo de carrera) |
| `private(x)` | **Indefinido** (basura) — idea errónea 9 | No cambia |
| `firstprivate(x)` | Copia del valor que tenía afuera | No cambia |
| Variable declarada **dentro** de la región | La que tú le pongas | No existe afuera (privada por alcance) — idea errónea 15 |

## 6. Ejemplo resuelto en una pantalla

```c
long s = 0;
#pragma omp parallel
{
    long local = 0;                      /* privada por alcance */
    #pragma omp for nowait               /* nadie lee datos ajenos después: seguro */
    for (long i = 0; i < n; i++) local += data[i];
    #pragma omp atomic                   /* una actualización compartida por hilo */
    s += local;
}                                        /* barrera de fin de región: s completa */
```

Equivale a `#pragma omp parallel for reduction(+:s)`. Costó 3 ns por elemento contra 62 de `critical`.

## 7. Errores frecuentes

1. Verificar una carrera corriendo el programa "varias veces". → Razona sobre los accesos y usa ThreadSanitizer
   sobre la versión sin sincronizar.
2. Poner `critical` alrededor de todo el cuerpo del ciclo, incluido el cómputo que es privado. → Protege solo
   la actualización compartida; calcula `bin` afuera.
3. Usar `atomic` con un `if` o con dos variables. → No compila o no protege lo que crees; usa `critical` o
   `reduction(max:…)`.
4. `private(x)` esperando que `x` conserve su valor. → `firstprivate(x)`.
5. Olvidar `omp_unset_lock`. → El programa se cuelga en el siguiente `omp_set_lock`.
6. `nowait` "para que vaya más rápido" sin revisar quién lee qué. → Carrera entre ciclos.
7. Comparar sumas en `double` con `==`. → Tolerancia relativa (idea errónea 10).
8. Confiar en que ThreadSanitizer con gcc esté limpio en código con `critical`. → Falsos positivos de `libgomp`.

## 8. Para saber más

- OpenMP Architecture Review Board, *OpenMP Application Programming Interface*, versión 5.2 (noviembre de 2022):
  secciones *atomic Construct*, *critical Construct*, *barrier Construct*, *Lock Routines*, *Data-Sharing
  Attribute Clauses*. <https://www.openmp.org/specifications/>
- GCC, *GNU Offloading and Multi Processing Runtime Library (libgomp)*, manual de la versión 13: variables
  de entorno (`OMP_NUM_THREADS`) y rutinas de candados. <https://gcc.gnu.org/onlinedocs/libgomp/>
- GCC, *Instrumentation Options*: `-fsanitize=thread`. <https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html>
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022,
  capítulo 5 (OpenMP): secciones sobre `critical`, `atomic`, candados y la implementación de reducciones.
