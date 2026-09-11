"""Corre el modelo financiero y genera tablas Markdown + JSON para el reporte."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import modelo_financiero as mf

mf.cargar_lineas(os.path.join(os.path.dirname(__file__), 'lineas.json'))
L = mf.LINEAS
out = {}

def f(x):
    return f"{x:,.0f}"

# 1) Estructura de costo
print("## Costo mensual por tamaño de operación (pago de 22 días, sin IMSS)\n")
print("| Salones | PPL | Nómina | Indirectos | Admin | Total | $/h pagada | $/h productiva | $/PPL-mes |")
print("|---|---|---|---|---|---|---|---|---|")
costos = {}
for s in (4, 7, 10):
    c = mf.costo_mensual(s)
    costos[s] = c
    print(f"| {s} | {c['ppl']} | {f(c['nomina'])} | {f(c['total_indirectos'])} | {f(c['admin'])} | {f(c['total'])} | {c['costo_hora_pagada']:.1f} | {c['costo_hora_productiva']:.1f} | {f(c['costo_por_ppl_mes'])} |")
out['costos'] = {s: {k: v for k, v in c.items() if k != 'indirectos'} for s, c in costos.items()}
out['indirectos_4'] = costos[4]['indirectos']

print("\n## Sensibilidad del costo por hora productiva (4 salones)\n")
print("| Escenario | $/h productiva |")
print("|---|---|")
sens = {
    'Base (22 días, sin IMSS, productividad 0.80)': mf.costo_mensual(4),
    'Pago de 30.4 días/mes': mf.costo_mensual(4, dias_pagados=mf.DIAS_CALENDARIO_MES),
    'IMSS/Infonavit/prestaciones (+30%)': mf.costo_mensual(4, carga_social=0.30),
    '30.4 días + IMSS': mf.costo_mensual(4, dias_pagados=mf.DIAS_CALENDARIO_MES, carga_social=0.30),
    'Productividad 0.70': mf.costo_mensual(4, productividad=0.70),
    'Productividad 0.90': mf.costo_mensual(4, productividad=0.90),
    'SM 2028 (+11%/año)': mf.costo_mensual(4, sm=mf.SM_DIARIO_2026 * 1.11 ** 2),
    'SM 2030 (+11%/año)': mf.costo_mensual(4, sm=mf.SM_DIARIO_2026 * 1.11 ** 4),
}
out['sensibilidad'] = {}
for k, c in sens.items():
    print(f"| {k} | {c['costo_hora_productiva']:.1f} |")
    out['sensibilidad'][k] = round(c['costo_hora_productiva'], 1)

# 2) P&L por línea, 1 salón de 35 PPL (admin prorrateado)
print("\n## Resultado mensual por línea, un salón de 35 PPL (ingreso por persona-hora productiva)\n")
print("| Línea | $/h cons. | $/h base | $/h opt. | Ingreso base/mes | EBITDA cons. | EBITDA base | EBITDA opt. | Margen base | Capex | Payback base (meses) |")
print("|---|---|---|---|---|---|---|---|---|---|---|")
out['lineas'] = {}
for k, v in L.items():
    r = {e: mf.pyg_linea(k, 1, e) for e in ('conservador', 'base', 'optimista')}
    b = r['base']
    pb = f"{b['payback_meses']:.1f}" if b['payback_meses'] else '—'
    print(f"| {k} {v['nombre'][:60]} | {v['ingreso_persona_hora']['conservador']} | {v['ingreso_persona_hora']['base']} | {v['ingreso_persona_hora']['optimista']} | {f(b['ingreso_mensual'])} | {f(r['conservador']['ebitda_mensual'])} | {f(b['ebitda_mensual'])} | {f(r['optimista']['ebitda_mensual'])} | {b['margen']*100:.0f}% | {f(b['capex'])} | {pb} |")
    out['lineas'][k] = {e: {kk: vv for kk, vv in rr.items()} for e, rr in r.items()}

# 3) Portafolio por fases
fases = {
    'Hoy: 4 salones cosmética Totalplay': {'TP0': 4},
    'Fase 1 (0-6 m): 2 cosmética + 2 kit de alta + 1 CPE otros operadores': {'TP0': 2, 'A3': 2, 'A1': 1},
    'Fase 2 (6-12 m): + etiquetado NOM + salón flexible': {'TP0': 2, 'A3': 2, 'A1': 1, 'C2': 1, 'FLEX': 1},
    'Fase 3 (12-24 m): 10 salones (+ triage CPE, + 2ª ola otros operadores/accesorios)': {'TP0': 2, 'A3': 2, 'A1': 2, 'A2': 1, 'A5': 1, 'C2': 1, 'FLEX': 1},
}
print("\n## Portafolio por fases (mensual)\n")
print("| Fase | Salones | PPL | Ingreso cons. | Ingreso base | Ingreso opt. | EBITDA cons. | EBITDA base | EBITDA opt. | Margen base | Capex acumulado |")
print("|---|---|---|---|---|---|---|---|---|---|---|")
out['fases'] = {}
for nombre, asig in fases.items():
    p = {e: mf.portafolio(asig, e) for e in ('conservador', 'base', 'optimista')}
    b = p['base']
    print(f"| {nombre} | {b['salones']} | {b['ppl']} | {f(p['conservador']['ingreso_mensual'])} | {f(b['ingreso_mensual'])} | {f(p['optimista']['ingreso_mensual'])} | {f(p['conservador']['ebitda_mensual'])} | {f(b['ebitda_mensual'])} | {f(p['optimista']['ebitda_mensual'])} | {b['margen']*100:.0f}% | {f(b['capex'])} |")
    out['fases'][nombre] = {'asignacion': asig, **{e: {kk: vv for kk, vv in pp.items() if kk != 'filas'} for e, pp in p.items()}}

# 4) Proyección 2026-2030 del portafolio de 10 salones
asig10 = fases['Fase 3 (12-24 m): 10 salones (+ triage CPE, + 2ª ola otros operadores/accesorios)']
print("\n## Proyección 2026-2030, portafolio de 10 salones, escenario base\n")
print("| Año | SM diario | Precios +4%/año: ingreso/mes | EBITDA/mes | Margen | Precios indexados al SM (+11%): EBITDA/mes | Margen |")
print("|---|---|---|---|---|---|---|")
p4 = mf.proyeccion_2026_2030(asig10, 'base', alza_sm=0.11, alza_precios=0.04)
p11 = mf.proyeccion_2026_2030(asig10, 'base', alza_sm=0.11, alza_precios=0.11)
out['proyeccion'] = {'precios_4': p4, 'precios_11': p11}
for a, b in zip(p4, p11):
    print(f"| {a['anio']} | {a['sm_diario']:.2f} | {f(a['ingreso_mensual'])} | {f(a['ebitda_mensual'])} | {a['margen']*100:.0f}% | {f(b['ebitda_mensual'])} | {b['margen']*100:.0f}% |")

# 5) Punto de equilibrio: ingreso por persona-hora productiva necesario
print("\n## Ingreso mínimo por persona-hora productiva para no perder dinero\n")
print("| Escenario de costo | $/h productiva mínimo |")
print("|---|---|")
for k, c in sens.items():
    print(f"| {k} | {c['costo_hora_productiva']:.0f} |")

json.dump(out, open(os.path.join(os.path.dirname(__file__), 'resultados_modelo.json'), 'w'), ensure_ascii=False, indent=1, default=float)
