# Bitácora de errores y decisiones · cp-6bm1-equipoNN

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Se entrega con el repositorio (lunes 7 de diciembre de 2026, 10:30) y se resume en la sección 9 del reporte

<!-- Plantilla. Una fila por evento, en el momento en que ocurre (no al final). Formato de fecha
     obligatorio AAAA-MM-DD (el verificador cuenta las filas que empiezan así). Mínimo 3 entradas;
     un proyecto real tiene 10 o más. No se penaliza el error: se penaliza no saber por qué pasó. -->

## Errores (qué falló, cómo lo detectamos, qué cambiamos)

| Fecha | Versión | Qué falló (síntoma observable) | Cómo lo detectamos (prueba, herramienta, medición) | Causa | Qué cambiamos (commit) | Qué aprendimos (1 línea) |
|---|---|---|---|---|---|---|
| «2026-10-27» | «V1» | «checksum distinto en dos corridas con la misma semilla» | «tests/run_tests.sh caso 1» | «rand() sin semilla fija» | «usar el LCG de comun/problema.h (a1b2c3d)» | «la reproducibilidad empieza en los datos, no en el cronómetro» |
| «AAAA-MM-DD» | «V2» | «…» | «…» | «…» | «…» | «…» |
| «AAAA-MM-DD» | «V3» | «…» | «…» | «…» | «…» | «…» |

## Mediciones descartadas (y por qué)

| Fecha | Qué se midió | Por qué NO se usa en el reporte | Qué se hizo en su lugar |
|---|---|---|---|
| «AAAA-MM-DD» | «V2 con 8 hilos en laptop de 4 núcleos físicos» | «sobre-suscripción; protocolo §2» | «se reporta hasta 4 y 8 se marca aparte» |

## Predicciones vs. resultados (pre-mortem)

| Fecha | Antes de medir esperábamos… | Porque… | Resultado | Diferencia explicada en el reporte, sección |
|---|---|---|---|---|
| «AAAA-MM-DD» | «speedup ≈ 3.2 con 4 hilos» | «fracción secuencial medida ≈ 8 %» | «2.1» | «8.2» |

## Qué no entendemos todavía

- «…» (se lee en la defensa; es mejor escribirlo aquí que descubrirlo en las preguntas individuales)
