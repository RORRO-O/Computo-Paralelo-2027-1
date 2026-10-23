# Protocolo de medición de rendimiento

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Se aplica en toda práctica, hito y reporte · versión 1.0

Una medición que no sigue este protocolo no se acepta como evidencia. No es burocracia: es lo que distingue
un *speedup* real de uno inventado por el ruido.

## 1. Antes de medir

1. **Compila con optimización**: `-O2` (C) o el valor por defecto de `nvcc`. Nunca se reporta `-O0`.
2. **Verifica correctitud primero** (`make test`). Un programa rápido y equivocado no tiene *speedup*.
3. **Escribe tu predicción**: "Con 4 hilos espero un *speedup* de ~3.2 porque la fracción secuencial medida
   es ~8 %". Se compara al final.
4. **Anota el entorno**: CPU (modelo, núcleos físicos/lógicos), RAM, sistema operativo, compilador y versión,
   flags, y en GPU el modelo (`nvidia-smi`). En Colab/Kaggle anota también la fecha, porque el hardware asignado cambia.
5. **Cierra lo demás**: navegador con muchas pestañas, compiladores en segundo plano, actualizaciones.

## 2. Al medir

| Regla | Valor | Por qué |
|---|---|---|
| Calentamiento | 1 ejecución que no se cuenta | Cachés frías, creación de hilos, carga de módulos |
| Repeticiones | ≥ 5 por configuración | Para estimar la variabilidad |
| Estadístico | **Mediana** (se reporta también mín y máx) | Robusta ante picos del sistema |
| Qué se cronometra | Solo la región de interés (no la lectura de archivos ni la impresión) | Es lo que se paraleliza |
| Reloj | `omp_get_wtime()`, `MPI_Wtime()`, `cudaEvent`, `perf_counter()` | Resolución adecuada; evita `clock()` (mide CPU de todos los hilos) |
| Tamaño del problema | Fijo y declarado; que la versión secuencial tarde ≥ 1 s | Si tarda milisegundos, mides la sobrecarga, no el trabajo |
| Hilos/procesos | 1, 2, 4, … hasta el número de núcleos **físicos** (y uno más allá, declarado) | Hyper-threading y sobre-suscripción se reportan aparte |
| Transferencias (GPU) | Se reportan **con** y **sin** copias anfitrión↔dispositivo | Las copias suelen dominar en problemas pequeños |

## 3. Qué se calcula

- *Speedup*: `S(p) = T(1) / T(p)`, donde `T(1)` es el **mejor programa secuencial** disponible (no la versión
  paralela con un hilo, salvo que se diga explícitamente y se reporten ambas).
- Eficiencia: `E(p) = S(p) / p`.
- Fracción secuencial estimada (Karp–Flatt): `f = (1/S − 1/p) / (1 − 1/p)`; si crece con `p`, hay sobrecarga creciente.
- Escalabilidad fuerte: tamaño fijo, `p` crece. Escalabilidad débil: tamaño por procesador fijo, `p` crece; se
  reporta la eficiencia débil `T(1, n) / T(p, p·n)`.

## 4. Cómo se reporta

Tabla mínima (CSV en `resultados/` y tabla en el reporte):

```
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
```

Gráfica mínima: *speedup* vs. hilos con la línea ideal `S = p`. Opcional: eficiencia vs. hilos.
Script de referencia: `herramientas/graficar_speedup.py`.

Texto mínimo de interpretación (3–6 líneas): dónde deja de escalar, por qué (fracción secuencial, memoria,
sincronización, comunicación, transferencias), y si coincide con la predicción del paso 1.3.

## 5. Errores que invalidan una medición

- Comparar contra la versión paralela con 1 hilo sin decirlo.
- Medir con `-O0` o con *sanitizers* activados.
- Una sola repetición. Promedio en lugar de mediana con picos evidentes.
- Problema tan pequeño que `T(1) < 0.1 s`.
- Cambiar el tamaño del problema entre configuraciones sin declararlo (eso es escalabilidad débil, no fuerte).
- Omitir el hardware. Omitir las transferencias en GPU.
- Reportar *speedup* superlineal sin explicarlo (caché) ni verificar correctitud.
