> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Práctica 4 · Procesamiento paralelo de datos con OpenMP · entrega domingo 1 de noviembre de 2026, 23:59

# `resultados/` · Qué va aquí (Parte D)

Esta carpeta guarda la **evidencia** de la Parte D. Se llena con `make medir` y `make graficar` desde la carpeta de
la práctica; no se edita a mano. Una medición que no se puede regenerar con esos comandos (o con los que declares en
`REPORTE.md`) no cuenta (`herramientas/protocolo-medicion.md`).

| Archivo | Lo produce | Contenido |
|---|---|---|
| `p4.csv` | `make medir` (vía `medir.sh`) | Una fila por configuración y número de hilos: `config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia`. Filas `C-seq` y `B-seq` = T(1) (programa secuencial); `C-<política>`, `C-<alternativa>` (o `C-omp` en calor) y `B-tareas` con 1, 2, 4 y 8 hilos |
| `salidas/<config>-<hilos>.txt` | `medir.sh` | La salida completa de cada corrida medida: iteraciones por hilo, `max/promedio`, checksums, tareas creadas. Es la fuente del dato que explica cada fila |
| `entorno.txt` | `medir.sh` | Fecha, CPU, núcleos, memoria, cuota de CPU si la hay, carga antes de medir, compilador y banderas, último comando |
| `p4_speedup.png` | `make graficar` | *Speedup* vs. hilos con la línea ideal S = p; puntos huecos = más hilos que núcleos |
| `p4_eficiencia.png` | `make graficar` | Eficiencia vs. hilos con las referencias E = 1 y E = 0.5 |
| `mandelbrot.png` | `make imagen` (opción Mandelbrot) | La imagen de 1300 × 1200 para el reporte (el `.pgm` intermedio no se versiona) |

Antes de medir: `make test` en `0 FAIL`, la máquina sin otros procesos pesados (`uptime`), y la predicción escrita.
Si mides en dos máquinas, usa un CSV por máquina (`make medir CSV=resultados/p4-laptop.csv`) y no mezcles filas: el
*speedup* solo tiene sentido contra el T(1) de la misma máquina.

Si `medir.sh` se detiene con "el programa terminó con error", el programa falló la verificación o tiene un
`TODO pendiente`: un programa equivocado no se mide.
