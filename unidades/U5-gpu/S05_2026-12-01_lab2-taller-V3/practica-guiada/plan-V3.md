> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Plan de porte V2 → V3 (plantilla por equipo)

Copia este archivo a la carpeta `v3/` de tu repositorio (estructura de `proyecto/entrega-final/plantilla-repo/`) y llénalo durante el taller. Las secciones
1–5 se llenan en clase; 6–9 se terminan antes del jueves 3 de diciembre. El plan no se califica por separado:
es la base de la sección "V3" del reporte final (lunes 7 de diciembre, 10:30) y de las preguntas individuales de
la defensa (jueves 10 de diciembre). Rúbricas: `proyecto/entrega-final/` y `proyecto/defensa/`.

Equipo: ______ (número de equipo; los nombres van en el reporte) · Problema del proyecto: ______________________

## 1. Kernel candidato: el ciclo caliente de la V2

Del perfilado de la V1 (H1) y del *speedup* de la V2 (H2):

| Pregunta | Respuesta |
|---|---|
| ¿Qué ciclo concentra el tiempo? (archivo, función, líneas de la V2) | |
| ¿Qué porcentaje del tiempo total de la V1 es ese ciclo? (de tu perfilado de H1) | ______ % |
| ¿Qué calcula una iteración del ciclo interno? (una frase) | |
| ¿Cada elemento de salida depende solo de la entrada anterior (sin dependencias entre iteraciones del mismo paso)? | sí / no, porque |
| ¿Hay escrituras a una misma posición desde distintas iteraciones? (reducción, histograma, acumulador) | sí / no; cuáles |
| Si lo demás queda en CPU, ¿cuál es el *speedup* máximo total según Amdahl con la fracción de arriba? | S_max = 1 / (1 − f) = ______ |

## 2. Estructuras de datos: de 2D (o más) a 1D

Cada estructura que toca el *kernel*. Una `float **` o una lista de listas **no** se puede copiar a la GPU con una sola
`cudaMemcpy`; se aplana.

| Estructura en la V2 | Tipo y dimensiones | Aplanada como | Fórmula de índice | Tamaño en bytes (tu N real) |
|---|---|---|---|---|
| p. ej. `grid[h][w]` | `float **`, h × w | `float *grid`, h·w | `r*w + c` | 4·h·w = |
| | | | | |
| | | | | |

Total de bytes que viven en la GPU: ______ (la T4 tiene 15 GB; si pasas de 4–8 GB replantea).

## 3. Mapeo hilo → elemento

| Decisión | Tu respuesta | Por qué |
|---|---|---|
| Malla 1D o 2D | | |
| Tamaño de bloque inicial (múltiplo de 32; ≤ 1024) | | |
| Fórmula del número de bloques (con `ceil`) | | |
| Guardia de rango | `if (...) return;` | |
| ¿Un hilo por elemento de salida? Si no, ¿cuántos elementos por hilo y cómo los recorre? | | |

## 4. Esqueleto del *kernel* (fase Crear del PRIMM)

Escríbelo aquí tal como irá en el código (CUDA C, Numba `@cuda.jit` o CuPy `RawKernel`). Debe compilar con
`nvcc -c -arch=sm_75` o correr bajo `NUMBA_ENABLE_CUDASIM=1` con una entrada de juguete.

```
// firma: todos los arreglos como punteros 1D + dimensiones + parámetros escalares
__global__ void nombre_kernel(const float *in, float *out, int height, int width, ...)
{
    // índices (1D o 2D) y guardia

    // índice lineal del elemento de salida de este hilo

    // lectura de vecinos / entradas (¿de qué arreglo? nunca del que se escribe en este paso)

    // escritura: una posición por hilo; si varios hilos escriben la misma, atómica o rediseño
}
```

Llamada (con las fórmulas de `ceil`): ________________________________________________

## 5. Movimiento de datos: una vez, no por iteración

| Arreglo | Sube (H2D) | Baja (D2H) | Se queda en la GPU entre iteraciones |
|---|---|---|---|
| | una vez al inicio / cada iteración (justifica) | una vez al final / cada iteración (justifica) | sí / no |
| | | | |

Si hay dos búferes (lectura/escritura), ¿intercambias punteros o copias? ______________________

¿Qué se queda en CPU (lectura de archivos, inicialización, escritura de resultados) y cuánto tarda en la V1? ______

## 6. Verificación contra la V1

| Elemento | Tu respuesta |
|---|---|
| Qué se compara (arreglo completo, *checksum*, estadístico) | |
| Tolerancia y por qué (float vs. double, orden de las sumas, reducciones) | |
| Tamaños de prueba (al menos uno pequeño verificable a mano y uno no múltiplo del bloque) | |
| Comando o celda que corre la comparación e imprime PASS/FAIL | |
| ¿Se revisa `cudaGetLastError()` / `cudaDeviceSynchronize()` después de cada lanzamiento? | |

## 7. Medición (protocolo del curso, `herramientas/protocolo-medicion.md`)

Tabla mínima para el reporte. T(1) es la **V1** (mejor secuencial), no la V2 con un hilo, y dura **≥ 1 s** con el
tamaño que reportas (rúbrica de código, criterio C4).

| Config | Tamaño | Mediana de 5 (s) | Mín – máx (s) | *Speedup* vs. V1 |
|---|---|---|---|---|
| V1 (CPU, 1 hilo) | | | | 1.00 |
| V2 (OpenMP, p = ___) | | | | |
| V3 solo *kernels* (sin transferencias) | | | | |
| V3 con transferencias H2D/D2H | | | | |

Barrido de bloque: configuraciones que vas a probar (al menos 3, múltiplos de 32): ______________________

Entorno: GPU asignada (`nvidia-smi`), fecha, versión de `nvcc`/Numba, CPU de la V1 y V2: ______________________

Pre-mortem (antes de medir): "Esperamos un *speedup* con transferencias de ___ porque ______". Se compara al final.

## 8. Alternativa elegida y qué cuenta como V3

Marca una: [ ] CUDA C (`nvcc`) [ ] Numba CUDA (`@cuda.jit`) [ ] CuPy con `RawKernel` o `ElementwiseKernel` propio

| Cuenta como V3 | No cuenta como V3 completa | Dónde lo penaliza la rúbrica |
|---|---|---|
| Un *kernel* escrito por el equipo que resuelve el ciclo caliente de la V2 | Llamar a una biblioteca que ya hace todo (`cupy.matmul`, `cv2.cuda`, `torch`) sin un *kernel* propio | C3 queda en "En desarrollo" como máximo (`rubrica-codigo.md`, `faq-entrega.md` §2) |
| Verificación contra la V1 con tolerancia declarada | Una V3 que no se verifica contra la V1 (o que "se parece") | C1: "no se verificó contra V1 en la misma sesión (solo dio parecido)" es En desarrollo; resultados distintos de V1 sin explicación, Insuficiente |
| Tabla con y sin transferencias, mediana de 5, GPU declarada | Un solo tiempo, o solo el tiempo del *kernel* | C4: "GPU solo con o solo sin transferencias" es En desarrollo |
| Explicar en la defensa qué hace cada línea del *kernel* | Código que ningún integrante puede explicar | Prueba de propiedad (`docs/metodo/05-politica-ia.md`) y rúbrica de la defensa |

Está permitido usar bibliotecas **alrededor** del *kernel* (p. ej., `cupy.asarray` para subir datos, `numpy` para
la V1). Lo que debe ser propio es el *kernel* del ciclo caliente.

## 9. Lista de cotejo de porte (márcala antes de medir)

- [ ] El *kernel* candidato es el ciclo que domina el tiempo de la V1 (no el más fácil de portar).
- [ ] Todas las estructuras del *kernel* están aplanadas; ninguna `float **` cruza a la GPU.
- [ ] Mapeo hilo → elemento decidido y documentado; bloque múltiplo de 32; bloques calculados con `ceil`.
- [ ] Guardia de rango en todo *kernel*; probado con un tamaño no múltiplo del bloque.
- [ ] Sin escrituras compartidas entre hilos (o con atómica/reducción y una justificación de su costo).
- [ ] Los datos suben una vez y bajan una vez; entre iteraciones se intercambian punteros, no se copian.
- [ ] Se revisa `cudaGetLastError()` tras cada lanzamiento y `cudaDeviceSynchronize()` antes de leer resultados.
- [ ] Verificación contra la V1 con tolerancia, en al menos dos tamaños, con salida PASS/FAIL.
- [ ] Medición: calentamiento + 5 repeticiones + mediana; sincronización antes de detener el reloj.
- [ ] Se reportan **ambos** tiempos: solo *kernels* y con transferencias; T(1) es la V1.
- [ ] Barrido de al menos 3 tamaños de bloque, con la configuración elegida justificada.
- [ ] GPU, fecha y versiones anotadas (en Colab cambian).
- [ ] Bitácora de errores actualizada con lo que falló al portar.
- [ ] Declaración de uso de IA (`docs/metodo/05-politica-ia.md`) y *commits* de cada integrante.

## 10. Reparto y pendientes

| Integrante (número de lista) | Qué hace en la V3 | *Commits* esperados antes del lunes 7 de diciembre |
|---|---|---|
| | | |
| | | |
| | | |

**Qué no entendemos todavía** (se le dice al profesor en la ronda del taller; no es una debilidad, es el plan):

1.
2.
