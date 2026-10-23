---
name: graficar
description: "Genera speedup.png, eficiencia.png y la tabla Markdown (mediana, mín, máx, speedup, eficiencia, f de Karp–Flatt) a partir de un CSV del protocolo de medición. Úsalo cuando se pida graficar resultados, comparar configuraciones o preparar las figuras y la tabla del reporte de una práctica."
argument-hint: "resultados/mediciones.csv [--salida CARPETA] [--titulo texto] [--n N] [--base CONFIG] [--recalcular]"
allowed-tools: Bash(python3 herramientas/graficar_speedup.py:*), Bash(python3 ./graficar.py:*), Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/plot.py:*), Bash(make:*), Read, Glob
---
# /graficar — figuras y tabla del protocolo

Argumentos recibidos: `$ARGUMENTS`

## Qué herramienta usar
1. Si existe `herramientas/graficar_speedup.py` (o `graficar.py` en la carpeta de la práctica), **úsalo**:
   `python3 herramientas/graficar_speedup.py resultados/mediciones.csv [--salida resultados] [--titulo "…"] [--base secuencial]`.
   Si la práctica tiene `make graficar`, prefiérelo.
2. Si no existe en esta rama, usa el respaldo con las mismas opciones y el mismo CSV:
   `python3 ${CLAUDE_SKILL_DIR}/scripts/plot.py resultados/mediciones.csv [--salida …] [--titulo …] [--base …] [--amdahl]`.

## Qué produce
- `speedup.png`: S(p) por `config` con la línea ideal S = p (y, con `--amdahl`, la curva ajustada y su f).
- `eficiencia.png`: E(p) con las referencias E = 1 y E = 0.5; marca la sobre-suscripción si p > núcleos.
- Tabla Markdown en pantalla con mediana, mín, máx, speedup, eficiencia y f de Karp–Flatt: pégala tal cual en el reporte.

## Reglas
- La línea base T(1) debe ser la `config` secuencial (`--base secuencial` o `*-seq`). Si el CSV solo tiene la paralela
  con 1 hilo, dilo en el pie de figura y en la interpretación.
- No edites el CSV ni "suavices" puntos. Si una fila es ruidosa, se repite la medición con `/medir`, no se borra.
- Pie de figura obligatorio en el reporte: programa, n, número de repeticiones, hardware (de `entorno.txt`).
- Después de graficar, pasa la tabla y las figuras a `perf-analyst` para la interpretación (3–6 líneas con datos).
