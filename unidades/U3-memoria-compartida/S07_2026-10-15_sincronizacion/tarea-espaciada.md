> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S07 · Tarea espaciada (20–40 minutos)

**Entrega.** Carpeta `tareas/S07/` en el repositorio de tu equipo (el mismo de las prácticas), con un archivo
`respuestas.md` y los `.c` que se piden, antes del **lunes 19 de octubre de 2026, 10:30** (inicio de S08).
Cuenta en "Tareas espaciadas y ejercicios" (5 % del 2º parcial; se revisan 3 tareas al azar por estudiante
en el parcial, según `planeacion/mapa-evaluacion.md`). Se hace de forma individual; el *commit* debe ser tuyo.
IA: verde para que te explique un mensaje de error; amarillo (declarado) para que revise tu código y señale
carreras; rojo para que resuelva el ejercicio 1 por ti.

## 1. Del tema de hoy (20 min) · Encontrar y corregir carreras

**Si en clase no se llegó a la Fase 5 (Crear) de la práctica guiada**, este ejercicio se sustituye por
`histogram_locks.c` con el criterio de "listo" de `practica-guiada/README.md`, Fase 5 (el profesor lo anuncia en el
cierre). En ese caso entrega `tareas/S07/histogram_locks.c` y la tabla de tiempos en `respuestas.md`.

Este fragmento calcula tres cosas sobre un arreglo `v[0..n)` de `double`. Compilado con `-O2 -fopenmp` y 4 hilos
"a veces" da bien.

```c
double total = 0.0;
long   negatives = 0;
double largest = v[0];
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    total += v[i];
    if (v[i] < 0.0) negatives++;
    if (v[i] > largest) largest = v[i];
}
```

a) Señala **cada** acceso con carrera (variable y línea) y di por qué (quién lee, quién escribe, qué lo ordena).
b) Reescribe el fragmento corregido eligiendo para **cada** variable el mecanismo más barato que sea correcto
   (`reduction`, `atomic`, `critical`, candado o acumulador local). Justifica en una línea por variable.
c) Escríbelo como programa completo `tareas/S07/stats.c` que genere `n` valores deterministas (puedes copiar
   el generador de `practica-guiada/common.h`), calcule las tres cosas en serie y en paralelo, y compare: los
   conteos de forma exacta y las sumas en `double` con tolerancia relativa `1e-9`. Debe compilar sin *warnings*
   con `gcc -std=c11 -O2 -Wall -Wextra -fopenmp` e imprimir `OK` o `INCORRECTO` al final.

Criterio de "listo": compila sin *warnings*, imprime `OK` con 1, 2 y 4 hilos, y en `respuestas.md` está la
tabla variable → mecanismo → razón.

## 2. Intercalado, Unidades I y II (10 min) · Amdahl y Foster sobre tu histograma

Con los tiempos de la práctica guiada en la máquina de autoría (o los tuyos si los mediste): histograma
secuencial 0.015 s; versión local con 4 hilos 0.024 s; generar los datos, que no se paraleliza, 0.015 s.

a) Si consideras "programa completo" = generar datos + histograma, ¿qué fracción del tiempo secuencial total
   es paralelizable? ¿Qué *speedup* máximo predice Amdahl con 4 hilos para el programa completo? ¿Y con 16?
b) ¿Qué *speedup* y qué eficiencia obtuvo la versión local con 4 hilos **solo en el histograma**? ¿Es consistente
   con Amdahl o hay otro límite actuando? Nombra uno (ancho de banda de memoria, creación de hilos, contención).
c) Describe la versión local con las cuatro etapas de Foster en una línea cada una: partición, comunicación,
   aglomeración, mapeo. ¿Cuál etapa es la que hoy protegimos con `critical`?

<details><summary>Para autoverificar</summary>

a) Tiempo total secuencial 0.030 s; paralelizable 0.015 s → fracción paralelizable 0.5, secuencial 0.5.
   `S(4) = 1/(0.5 + 0.5/4) = 1.6`; `S(16) = 1/(0.5 + 0.5/16) ≈ 1.88`; con infinitos hilos, 2. La generación
   de datos pone el techo: antes de exprimir el histograma habría que paralelizar (o medir fuera) la generación.
b) `S = 0.015/0.024 ≈ 0.63`, eficiencia `≈ 0.16`. No es un límite de Amdahl (el ciclo es 100 % paralelo): el
   trabajo por elemento es tan pequeño que dominan el ancho de banda de memoria y el costo de despertar y
   sincronizar 4 hilos. Con `n` mayor o con más cómputo por elemento la eficiencia sube (se mide en S10).
c) Partición por dominio (bloques de elementos del arreglo); comunicación: combinar histogramas parciales;
   aglomeración: un bloque grande y un histograma local por hilo; mapeo: un hilo por núcleo (`parallel for`
   con reparto estático). Lo protegido con `critical` es la **comunicación** (la combinación final).
</details>

## 3. Preparación de S08, lunes 19 de octubre (5–10 min) · Predicción sobre reparto de trabajo

En `practica-guiada/nowait_buggy.c`, la función `f(i, n)` cuesta más cuanto mayor es `i` (entre 1 y 64 vueltas).
El ciclo se reparte con el reparto por omisión de gcc (bloques contiguos de igual tamaño, uno por hilo).

a) Con 4 hilos, ¿qué hilo termina al último y aproximadamente cuántas veces más trabajo hace que el primero?
   (suma las vueltas de cada bloque, o estímalo con el promedio de `reps` en cada cuarto).
b) Propón, en una línea, cómo repartirías las iteraciones para que los cuatro hilos terminen casi al mismo
   tiempo. No hace falta la sintaxis: la cláusula `schedule(static|dynamic|guided, chunk)` es el tema de S08.
c) Lee en la *OpenMP API Specification 5.2* la entrada de la cláusula `schedule` (sección *Worksharing-Loop
   Construct*) y escribe en una línea qué hace `schedule(dynamic, 1000)`.

<details><summary>Para autoverificar</summary>

a) El hilo 3 (índices del último cuarto): `reps` promedio ≈ 57 contra ≈ 9 del primer cuarto, unas 6 veces más
   trabajo. Los hilos 0, 1 y 2 esperan en la barrera.
b) Repartir en pedazos pequeños y entregarlos conforme cada hilo se desocupa, o intercalar índices (cíclico) para
   que cada hilo reciba índices bajos y altos.
c) Las iteraciones se reparten en bloques de 1000; cada hilo pide el siguiente bloque disponible cuando
   termina el suyo, hasta agotarlos.
</details>
