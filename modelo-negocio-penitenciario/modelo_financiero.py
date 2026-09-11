"""Modelo financiero paramétrico: taller de manufactura/servicios con PPL en CEVASEP II (CDMX).

Todas las cifras en MXN. Supuestos tomados de la investigación (CONASAMI/DOF 2026, vacantes
2026 zona norte CDMX/Edomex, estimaciones propias documentadas en el reporte).
"""
import json

# ----------------------------- Supuestos base ---------------------------------
SM_DIARIO_2026 = 315.04          # salario mínimo general 2026 (DOF 9-dic-2025)
HORAS_DIA = 8                    # 9-13 y 14-18
DIAS_LABORADOS_MES = 22          # si el convenio permite pagar sólo días laborados
DIAS_CALENDARIO_MES = 30.4       # si la autoridad exige pagar mes completo
PRODUCTIVIDAD = 0.80             # pases de lista, revisiones, audiencias, traslados
PPL_POR_SALON = 35

# Costos indirectos mensuales dentro del penal (estimación propia, ver reporte)
def indirectos_mensuales(salones):
    ppl = salones * PPL_POR_SALON
    supervisores = 37_900 * salones + 45_000     # 1 supervisor/salón ($16,220 x 1.38 carga ≈ $22,400) + líder + coordinador + logística/ingreso
    logistica = 16_500 * salones                  # fletes 3.5 t, esperas en aduana del penal, manifiestos
    mermas = 107 * ppl                            # ~0.5% del valor manejado
    seguros = 2_500 * salones                     # RC + mercancía en depósito/tránsito
    capacitacion = 59 * ppl                       # reposición 15%/año x 15 días al SM
    herramientas = 57 * ppl                       # inventarios, candados, reposición, consumibles no reutilizables
    return dict(supervisores=supervisores, logistica=logistica, mermas=mermas, seguros=seguros,
                capacitacion=capacitacion, herramientas=herramientas)

ADMIN_FIJO_MENSUAL = 150_000     # gerencia, ventas, contabilidad, legal, cumplimiento LFPDPPP (estimación propia)


def costo_mensual(salones, dias_pagados=DIAS_LABORADOS_MES, carga_social=0.0, productividad=PRODUCTIVIDAD, sm=SM_DIARIO_2026):
    ppl = salones * PPL_POR_SALON
    nomina = ppl * sm * dias_pagados * (1 + carga_social)
    ind = indirectos_mensuales(salones)
    total_ind = sum(ind.values())
    horas_pagadas = ppl * HORAS_DIA * DIAS_LABORADOS_MES
    horas_productivas = horas_pagadas * productividad
    total = nomina + total_ind + ADMIN_FIJO_MENSUAL
    return dict(ppl=ppl, nomina=nomina, indirectos=ind, total_indirectos=total_ind, admin=ADMIN_FIJO_MENSUAL,
                total=total, horas_pagadas=horas_pagadas, horas_productivas=horas_productivas,
                costo_hora_pagada=total / horas_pagadas, costo_hora_productiva=total / horas_productivas,
                costo_por_ppl_mes=total / ppl)


# ----------------------------- Líneas de negocio ------------------------------
# ingreso por persona-hora PRODUCTIVA (MXN): conservador / base / optimista.
# capex por salón de 35 PPL (MXN). Se rellenan con los valores verificados por los escépticos.
LINEAS = {}

def cargar_lineas(path):
    global LINEAS
    LINEAS = json.load(open(path))


def pyg_linea(linea, salones, escenario='base', **kw):
    """P&L mensual de una línea ocupando `salones` salones completos."""
    ing_ph = LINEAS[linea]['ingreso_persona_hora'][escenario]
    c = costo_mensual(salones, **kw)
    # admin fijo se prorratea por salón sobre 10 salones para no castigar líneas individuales
    admin_prorrateado = ADMIN_FIJO_MENSUAL * salones / 10
    costo = c['nomina'] + c['total_indirectos'] + admin_prorrateado
    ingreso = ing_ph * c['horas_productivas']
    capex = LINEAS[linea]['capex_por_salon'] * salones
    ebitda = ingreso - costo
    return dict(linea=linea, salones=salones, ppl=c['ppl'], escenario=escenario, ingreso_mensual=ingreso,
                costo_mensual=costo, ebitda_mensual=ebitda, margen=ebitda / ingreso if ingreso else 0,
                capex=capex, payback_meses=(capex / ebitda) if ebitda > 0 else None,
                ingreso_por_ppl_mes=ingreso / c['ppl'], ebitda_por_ppl_mes=ebitda / c['ppl'])


def portafolio(asignacion, escenario='base', **kw):
    """asignacion: dict linea -> salones. Devuelve P&L consolidado."""
    filas = [pyg_linea(l, s, escenario, **kw) for l, s in asignacion.items() if s > 0]
    salones = sum(asignacion.values())
    c = costo_mensual(salones, **kw)
    ingreso = sum(f['ingreso_mensual'] for f in filas)
    costo = c['total']
    capex = sum(f['capex'] for f in filas)
    ebitda = ingreso - costo
    return dict(filas=filas, salones=salones, ppl=c['ppl'], ingreso_mensual=ingreso, costo_mensual=costo,
                ebitda_mensual=ebitda, margen=ebitda / ingreso if ingreso else 0, capex=capex,
                payback_meses=(capex / ebitda) if ebitda > 0 else None, costo_hora_productiva=c['costo_hora_productiva'])


def proyeccion_2026_2030(asignacion, escenario='base', alza_sm=0.11, alza_precios=0.04, **kw):
    """Proyección anual: el SM sube alza_sm por año; los precios de venta se reprecian alza_precios por año."""
    out = []
    for i, anio in enumerate(range(2026, 2031)):
        sm = SM_DIARIO_2026 * (1 + alza_sm) ** i
        factor_precio = (1 + alza_precios) ** i
        p = portafolio(asignacion, escenario, sm=sm, **kw)
        ingreso = p['ingreso_mensual'] * factor_precio
        # indirectos (supervisores, etc.) también suben con inflación salarial ~ alza_sm*0.6
        costo = p['costo_mensual'] + (p['costo_mensual'] - sum(f['costo_mensual'] for f in p['filas']) * 0) * 0
        # recomputar costo con indirectos indexados
        c = costo_mensual(p['salones'], sm=sm, **kw)
        indirectos_idx = c['total_indirectos'] * (1 + alza_sm * 0.6) ** i
        admin_idx = ADMIN_FIJO_MENSUAL * (1 + alza_precios) ** i
        costo = c['nomina'] + indirectos_idx + admin_idx
        ebitda = ingreso - costo
        out.append(dict(anio=anio, sm_diario=sm, ingreso_mensual=ingreso, costo_mensual=costo, ebitda_mensual=ebitda,
                        margen=ebitda / ingreso if ingreso else 0, ebitda_anual=ebitda * 12))
    return out


if __name__ == '__main__':
    for s in (4, 8, 10):
        c = costo_mensual(s)
        print(f"{s} salones / {c['ppl']} PPL: costo total {c['total']:,.0f}/mes | nómina {c['nomina']:,.0f} | indirectos {c['total_indirectos']:,.0f} | "
              f"por hora pagada {c['costo_hora_pagada']:.1f} | por hora productiva {c['costo_hora_productiva']:.1f} | por PPL {c['costo_por_ppl_mes']:,.0f}")
    print('--- sensibilidad 30.4 días:')
    c = costo_mensual(4, dias_pagados=DIAS_CALENDARIO_MES)
    print(f"4 salones pagando 30.4 días: {c['costo_hora_productiva']:.1f}/h productiva")
    c = costo_mensual(4, carga_social=0.30)
    print(f"4 salones con IMSS (+30%): {c['costo_hora_productiva']:.1f}/h productiva")
    c = costo_mensual(4, dias_pagados=DIAS_CALENDARIO_MES, carga_social=0.30)
    print(f"4 salones 30.4 días + IMSS: {c['costo_hora_productiva']:.1f}/h productiva")
