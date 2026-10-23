> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · Recuperación de inicio

Individual, por escrito, sin apuntes ni dispositivos. Tienes **4 minutos**. Después se muestran las
respuestas y se cuenta a mano alzada quién acertó cada una. No se califica el acierto; cuenta el intento.

## Preguntas

**1. (Unidad III · lo que evaluó el Examen 2)** Con 4 hilos, ¿qué valores puede imprimir este fragmento?
¿Qué cláusula lo corrige y por qué?

```c
int total = 0;
#pragma omp parallel for
for (int i = 0; i < 1000; i++)
    total += 1;
printf("%d\n", total);
```

**2. (Unidad III · rendimiento)** Mediste un *speedup* de 2.8 con 4 hilos. (a) ¿Cuál es la eficiencia?
(b) Si la fracción secuencial medida es 10 %, ¿qué *speedup* máximo predice Amdahl con 4 hilos? (c) ¿Es
consistente con lo que mediste?

**3. (Unidad I)** Una laptop con 4 núcleos y un clúster de 4 nodos conectados por red ejecutan el mismo
programa paralelo. ¿En cuál de los dos puede un hilo o proceso **leer directamente** una variable que escribió
otro? ¿En qué categoría de Flynn cae cada uno?

**4. (Unidad II · método de Foster)** ¿Qué significa *aglomerar*? ¿Es lo mismo que juntar todas las tareas
en un solo proceso?

**5. (Anticipa el tema de hoy)** Lanzas 4 copias del mismo ejecutable al mismo tiempo. Cada copia declara
`int total = 0;`. ¿Cuántas variables `total` existen en memoria? Si una copia ejecuta `total = 7;`, ¿qué ven
las otras tres?

## Respuestas

<details>
<summary>Mostrar respuestas</summary>

1. Un valor no determinista ≤ 1000 (en teoría cualquiera entre 2 y 1000). Medido con 4 hilos: con `-O0` salen
   valores como 362, 456 o 630; con `-O2` el compilador acumula por hilo y hace una sola suma al final, así que casi
   siempre sale 1000, y aun así hay carrera. `total += 1` es
   leer-modificar-escribir sobre una variable compartida: condición de carrera (*data race*). Se corrige con
   `reduction(+:total)`: cada hilo acumula en una copia privada y al final OpenMP combina las copias. Que
   "salga 1000 una vez" no demuestra que no haya carrera (Anexo A, idea 7).
2. (a) E = S/p = 2.8/4 = 0.70 (70 %). (b) S_max = 1/(0.10 + 0.90/4) = 1/0.325 ≈ 3.08. (c) Sí: 2.8 está por
   debajo de la cota de Amdahl; la diferencia (3.08 vs. 2.8) se explica por sobrecarga de creación de hilos,
   sincronización o memoria, que Amdahl no modela.
3. Solo en la laptop (memoria compartida): los hilos ven el mismo espacio de direcciones. En el clúster cada
   nodo tiene su memoria; para "ver" un dato ajeno hay que enviarlo por la red. Los dos son MIMD (múltiples
   flujos de instrucciones sobre múltiples datos); la distinción compartida/distribuida es de organización de
   memoria, no de Flynn.
4. Aglomerar es agrupar tareas finas en tareas más gruesas para reducir la comunicación y la sobrecarga,
   **conservando** paralelismo suficiente para los procesadores disponibles. Juntar todo en un solo proceso
   elimina el paralelismo: no es aglomerar, es volver al programa secuencial (Anexo A, idea 28).
5. Cuatro, una por proceso, en cuatro espacios de direcciones distintos. Las otras tres copias siguen viendo
   `total == 0`: nada cambió para ellas. Para que se enteraran, el proceso tendría que **enviarles** el valor.
   Ese es el modelo de memoria distribuida de hoy.

</details>
