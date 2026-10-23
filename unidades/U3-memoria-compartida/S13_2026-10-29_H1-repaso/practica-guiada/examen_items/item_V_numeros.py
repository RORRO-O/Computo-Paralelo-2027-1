#!/usr/bin/env python3
"""item_V_numeros.py — Examen de práctica U3, sección V (problema numérico de rendimiento).
Calcula con los datos del enunciado los valores que fija la clave. Uso: python3 item_V_numeros.py
"""
perfil = {"lectura": (0.60, False), "nucleo A": (2.40, True), "nucleo B": (0.80, True), "combinacion": (0.20, False)}
t1 = sum(t for t, _ in perfil.values())
t_par = sum(t for t, p in perfil.values() if p)
f_p = t_par / t1                                   # fraccion paralelizable EN TIEMPO
p = 4
s_amdahl = 1.0 / ((1 - f_p) + f_p / p)
s_inf = 1.0 / (1 - f_p)
t4 = 1.90                                          # medido con 4 hilos (mediana de 5)
s_med = t1 / t4
e_med = s_med / p
f_kf = (1.0 / s_med - 1.0 / p) / (1.0 - 1.0 / p)   # Karp-Flatt
print(f"T(1)={t1:.2f} s  paralelizable={t_par:.2f} s  f_p={f_p:.2f}")
print(f"Amdahl: S(4)={s_amdahl:.2f}  S(inf)={s_inf:.1f}")
print(f"Medido: S(4)={s_med:.2f}  E(4)={e_med:.2f}")
print(f"Karp-Flatt: f={f_kf:.2f}  (1-f_p={1 - f_p:.2f}; exceso={f_kf - (1 - f_p):.2f})")
