> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Tarea espaciada · S12 → S13

Tiempo estimado: 40 minutos (20 en equipo + 20 individuales). **Entrega:** la parte de equipo (1a) va al
repositorio del equipo antes del **jueves 29 de octubre a las 10:30** y se revisa dentro de H1; las partes 1b,
2 y 3 las traes escritas y las **autocalificas con la clave** al inicio de S13 (2 minutos, dentro del bloque
5–10). El profesor registra la entrega, no el acierto; revisa 3 tareas al azar por parcial. Cuenta en "tareas
espaciadas y ejercicios" (5 % del 2.º parcial: proporción de tareas entregadas a tiempo × calidad de las
revisadas). Quien faltó hoy, entregarla sustituye el *exit ticket* y la recuperación de la sesión.

## 1. Del tema de hoy

### 1a. (Equipo, 20 min) Perfil por secciones de tu V1

Es el "Crear" de la práctica guiada que no cabe en clase.

1. Inserta `omp_get_wtime()` entre las secciones de tu V1 (como en `practica-guiada/fases.c`) e imprime
   tiempo y fracción de cada una. Compila con `-O2`; corre 1 de calentamiento + 5 repeticiones con el tamaño
   que usarás para medir (T(1) ≥ 1 s) y anota la mediana, el mínimo y el máximo.
2. Llena las **secciones 0, 1 y 2** de `practica-guiada/plan-paralelizacion-V2.md` en tu repositorio:
   perfil, f, S_max(2), S_max(4) y la tabla de dependencias del ciclo que domina.
3. *Commit* "Agregar perfil por secciones de la V1" (los tres integrantes aparecen en el historial de la semana).

Esto es insumo directo de **H1 (jueves 29 de octubre, en clase)**, que pide la V1 con diseño de Foster y
perfilado: ver `proyecto/hitos/H1-avance-1.md`. No lo hagas dos veces.

**Si tu V1 todavía no corre completa:** haz el mismo ejercicio con `fases.c` para n = 500000 y para
n = 2000000 (k = 200 en ambos), llena las secciones 1 y 2 para ese programa y escribe en tres líneas qué
cambió en la fracción paralelizable al crecer n y por qué. Entrega eso y la fecha en que tu V1 correrá.

### 1b. (Individual, 8 min) Elige y justifica

En `fases.c`, supón que **sí** decides paralelizar la fase de salida (líneas 90–95), donde cada iteración hace
`hist[bin]++` con 10 clases y n = 500 000 registros. Tienes tres opciones vistas en S07 y S11:

- (i) `#pragma omp parallel for` + `#pragma omp critical` alrededor de `hist[bin]++`
- (ii) `#pragma omp parallel for` + `#pragma omp atomic` antes de `hist[bin]++`
- (iii) `#pragma omp parallel for reduction(+:hist[:N_BINS])` (reducción sobre arreglo, OpenMP ≥ 4.5), o su
  equivalente manual: histograma privado por hilo y combinar al final

Escribe: cuál eliges, **por qué** en dos líneas (piensa en cuántas veces se ejecuta la operación protegida y en
qué comparten los hilos), y cuál descartas primero. Después, para la fase de **cómputo** (líneas 70–80), elige
entre `schedule(static)` y `schedule(dynamic, 1000)` y justifica en una línea con la forma del trabajo por
iteración.

<details>
<summary>Clave de 1b</summary>

Salida: se descarta primero **(i)**: `critical` se ejecutaría 500 000 veces y serializa el ciclo entero (más
lento que secuencial). **(ii)** es correcta y más barata que `critical` (idea errónea 8), pero sigue siendo una
operación atómica por registro sobre 10 celdas compartidas que además comparten línea de caché (falso
compartido, S10). **(iii)** es la mejor: cada hilo cuenta en su copia privada sin sincronizar y se combinan
10 números al final; es lo que hace `reduction` con arreglos. (Y, como dice la práctica guiada, con 0.1 % del
tiempo esta fase no vale la pena paralelizarla: la elección correcta en el proyecto es "no".)

Cómputo: **`static`**. Todas las iteraciones hacen exactamente k pasos: trabajo uniforme, y `static` no paga
el costo por *chunk* de `dynamic` (idea errónea 11). `dynamic` ganaría si el trabajo por iteración fuera
desigual (como el ciclo triangular del ejemplo resuelto).

</details>

## 2. Intercalado de unidades previas (individual, 7 min)

a) **(Unidad II, Foster)** En `fases.c`, ¿la partición natural de la fase de cómputo es una descomposición de
**dominio** o **funcional**? ¿Cuál es la "tarea" más fina posible? Si el *runtime* reparte las iteraciones en
bloques de n/4 por hilo, ¿qué paso de Foster está haciendo y qué se reduce con ello? (tres líneas)

b) **(Unidad I, escalabilidad)** En `fases.c` la carga crece con n y el cómputo con n·k. Si duplicas **n**, ¿cambia
la fracción paralelizable f? ¿Y si duplicas **k**? ¿Cuál de las dos situaciones corresponde al argumento de
Gustafson y cuál a la escalabilidad fuerte de Amdahl? Responde con las fórmulas; no hace falta correr nada.

<details>
<summary>Clave de 2</summary>

a) **Dominio**: los datos (registros) se reparten y la misma operación se aplica a cada uno. La tarea más
fina es una partícula (una iteración de `i`). Repartir en bloques de n/4 es **aglomeración** (seguida del
**mapeo** bloque → hilo): reduce la sobrecarga de planificación y mejora la localidad sin perder paralelismo,
porque siguen quedando cuatro bloques para cuatro hilos. Juntar todo en un hilo no sería aglomerar (idea
errónea 28).

b) Con T_carga = c₁·n y T_cómputo = c₂·n·k, f = c₂·n·k / (c₁·n + c₂·n·k): la n se cancela, así que duplicar n
**no cambia f**. Duplicar k sí **sube f** (crece el trabajo paralelo y no el secuencial). Hacer crecer el
problema junto con los recursos es el argumento de **Gustafson** (escalabilidad débil); mantener n y k fijos y
aumentar hilos es la escalabilidad **fuerte** que acota Amdahl. Comprobación con las corridas del README:
k = 50 → f = 0.59; k = 200 → f = 0.86; k = 400 → f = 0.93.

</details>

## 3. Preparación para S13 (individual, 5 min)

El jueves 29 de octubre (10:30, salón 3208) se recibe H1 y se hace el **repaso de la Unidad III** rumbo al
Examen 2 (martes 3 de noviembre, 08:30). Como ese día coincide con un hito, el examen de práctica se resuelve
en casa cronometrado y en clase se corrige entre pares (`04-evaluacion.md`, §4); el profesor anuncia hoy dónde
está publicado y para cuándo.

1. Escribe en una línea tu **calificación esperada** en el Examen 2 (0–10). Se guarda y se compara después.
2. Escribe los **tres temas de la Unidad III** de los que te sientes menos seguro (regiones y alcance de
   variables; carreras y sincronización; `schedule`; tareas; medición y Amdahl; falso compartido; patrones y
   SIMD). Empieza a repasar por el que más te preocupe, con las `notas-estudiante.md` de esa sesión.
3. Conjetura: en el examen de práctica habrá un ítem de "encuentra la carrera". Escribe las tres cosas que vas
   a buscar primero en el código.

<details>
<summary>Clave de 3.3</summary>

Variables compartidas que se escriben dentro de la región (acumuladores sin `reduction`, contadores,
`arreglo[indice_calculado]`); variables declaradas **fuera** de la región y usadas como temporales adentro
(deberían ser `private`); y dependencias entre iteraciones (`a[i]` que usa `a[i-1]`, o lectura/escritura del
mismo arreglo en un *stencil* sin segundo arreglo). Después, confirmar con `-fsanitize=thread`.

</details>

Recordatorios de fechas: **Práctica 4 vence el domingo 1 de noviembre a las 23:59** (40 % del 2.º parcial);
**H1 se recibe el jueves 29 de octubre en clase** (12 %).
