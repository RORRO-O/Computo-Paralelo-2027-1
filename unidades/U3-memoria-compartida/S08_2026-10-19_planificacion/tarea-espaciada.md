> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S08 · Tarea espaciada (20–40 minutos)

**Entrega:** archivo `tareas/S08.md` en tu repositorio del curso (texto + tablas; el código del ejercicio 1 en
`tareas/S08/`), antes del **jueves 22 de octubre de 2026, 10:30** (inicio de S10). Cuenta en "Tareas
espaciadas y ejercicios" (5 % del 2º parcial; se revisan 3 al azar por parcial). Trabajo individual; puedes
discutirlo con tu pareja de la práctica, pero las mediciones y el texto son tuyos.

**Antes:** el pre-laboratorio de la Práctica 4 se entrega **mañana martes 20 de octubre a las 08:30**, al
inicio del Lab 1. No lo dejes para después de esta tarea.

## 1. Del tema de hoy (15 min) · Terminar la fase Crear: primos por división de prueba

Completa la fase 5 de `practica-guiada/README.md` si no la terminaste en clase:

1. Tu predicción escrita (política, *chunk*, *speedup* esperado con 4 hilos) **antes** de medir.
2. El núcleo `primes` agregado a `unbalanced.c` (copia el archivo modificado a `tareas/S08/`). Debe compilar
   con las banderas del curso sin *warnings* y `make test` debe seguir en `0 FAIL`.
3. La tabla de `OMP_NUM_THREADS=4 ./unbalanced primes 2000000 static static,1 dynamic,64 guided,64` más al
   menos una política adicional que tú elijas. Pega la salida completa (incluye las líneas `#` con la
   secuencial y la columna `verif`). Comprueba que el resultado sea 148 933 (cantidad de primos menores que
   2 000 000).
4. Tres líneas: política elegida, por qué (forma de la carga + costo por *chunk*), y si tu predicción se cumplió.

Nota: si tu laptop tiene 2 núcleos, usa `OMP_NUM_THREADS=2` y dilo en el reporte. Si al medir los tiempos
salen todos parecidos, revisa `uptime` y cierra lo que esté consumiendo CPU.

## 2. Intercalado · Unidad I: *speedup*, eficiencia y la fracción secuencial que no es secuencial (10 min)

Con la tabla real del núcleo `mandelbrot` (n = 1000, 4 hilos) de `notas-estudiante.md`, sección 4:

a) Calcula el *speedup* y la **eficiencia** de `static` y de `dynamic,4`.

b) Calcula la fracción secuencial de Karp–Flatt, `f = (1/S − 1/p) / (1 − 1/p)`, para ambas políticas.

c) El código del ciclo es el mismo en ambos casos; no hay ninguna parte secuencial que cambie. Entonces,
¿qué está midiendo realmente `f` cuando cambia tanto entre `static` y `dynamic,4`? Explica en 3–4 líneas qué
tiene que ver con la barrera implícita del `for` y por qué Amdahl, tal como lo vimos en la Unidad I, no
distingue entre "código secuencial" y "hilos esperando".

<details>
<summary>Verifica tus cálculos (ábrelo después de hacerlos)</summary>

Procedimiento: S = T_sec / T_pol; E = S / 4; f = (1/S − 1/4) / (3/4). Con la tabla publicada en
`notas-estudiante.md` §4 (medida con la máquina de autoría limitada, como ahí se advierte): `static`
S = 0.406 / 0.424 ≈ 0.96, E ≈ 0.24, f ≈ 1.06; `dynamic,4` S = 0.406 / 0.313 ≈ 1.30, E ≈ 0.32, f ≈ 0.69. Si
el profesor regeneró la tabla en una máquina libre, tus números serán mejores (la E de `dynamic,4` queda
mucho más cerca de 1 y la de `static` cerca de 0.5), pero el patrón es el mismo: **f baja al cambiar solo el
`schedule`**, con el mismo código. Lo que `f` mide es el **tiempo de procesador ocioso** por cualquier causa:
código secuencial, sincronización, **desbalance** y, en la máquina de autoría, también la competencia por los
núcleos (por eso ahí f sale mayor que 1, algo imposible si solo midiera código secuencial). Con `static`, dos
hilos esperan en la barrera mientras los del centro de la imagen terminan; ese tiempo de espera entra en la
fórmula como si fuera "fracción secuencial". Por eso Karp–Flatt se usa como diagnóstico: si f crece con p,
hay sobrecarga o desbalance crecientes, y la primera pregunta es qué `schedule` tiene el ciclo.

</details>

## 3. Preparación de S09 · martes 20 de octubre de 2026, 08:30 (5–10 min)

En S09 se usan tareas (`task`, `taskwait`, `taskloop`) para paralelizar recursión, y empieza el Lab 1 de la
Práctica 4. Lee la sección sobre *tasking* del capítulo 5 de Pacheco y Malensek (2.ª ed.) o la introducción
de *Tasking Constructs* de la especificación OpenMP 5.2, y responde por escrito antes de la sesión:

```c
#pragma omp parallel num_threads(4)
{
    #pragma omp single
    {
        for (int i = 0; i < 8; i++) {
            #pragma omp task
            printf("tarea %d por hilo %d\n", i, omp_get_thread_num());
        }
        printf("fin del single\n");
    }
}
```

a) ¿Cuántas tareas se crean y cuántos hilos las crean?
b) ¿Puede imprimirse `fin del single` **antes** que alguna línea `tarea i`? Justifica con lo que leíste: ¿en
qué momento se ejecuta una tarea?
c) ¿En qué se parece el reparto de tareas entre hilos a `schedule(dynamic)` de hoy y en qué se diferencia?

<details>
<summary>Para comparar después de leer</summary>

a) 8 tareas, creadas todas por **un solo hilo** (el que entra al `single`); las ejecutan los 4 hilos del
equipo. b) Sí: `task` **encola** la tarea, no la ejecuta en el acto (idea errónea 13 del Anexo A); el hilo
creador sigue y puede imprimir `fin del single` antes; las tareas pendientes se completan a más tardar en la
barrera implícita al final del `single`. c) Se parece: los hilos libres toman trabajo de una cola conforme se
desocupan (balance dinámico). Se diferencia: las tareas pueden crearse de forma irregular y recursiva (no
hay un espacio de iteraciones fijo) y cada una lleva su propio entorno de datos.

</details>
