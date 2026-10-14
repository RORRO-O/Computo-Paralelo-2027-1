# Evidencia y bibliografía del método

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Evidencia verificada del marco pedagógico · versión 1.0 · 14 de octubre de 2026

Este documento sostiene a `00-resumen-ejecutivo.md`, `01-marco-pedagogico.md` y `05-politica-ia.md`. Cada
afirmación empírica del método tiene aquí su fuente, su grado de certeza y sus límites. Lo que no está aquí no se
cita en el curso. La §5 explica cómo se verificó.

## 1. Principios, afirmaciones y fuentes verificadas

Grado de certeza (escala de este curso):

- **Alta**: metaanálisis o ensayos controlados aleatorizados (ECA) replicados, en universitarios o en el dominio.
- **Media**: estudios sólidos pero de otro nivel educativo, observacionales, cuasiexperimentales o correlacionales; síntesis narrativas.
- **Baja**: evidencia descriptiva, teórica o inexistente para la intervención concreta.
- **Diseño**: decisión del curso que no pretende respaldo empírico propio.

| Principio (01 §2) | Afirmación que usamos | Fuente(s) verificada(s) | Grado de certeza | Aplicabilidad a este curso |
|---|---|---|---|---|
| **P1.** Fundamentos antes que proyectos | Los novatos aprenden más con instrucción explícita y ejemplos resueltos que con guía mínima; la ventaja de la guía se desvanece sólo con conocimiento previo suficiente (reversión por pericia). La "falla productiva" funciona si el problema previo está diseñado y lo sigue instrucción explícita y contrastiva. | Kirschner, Sweller y Clark (2006); Sweller (1988); Sweller y Cooper (1985); Kalyuga et al. (2001, 2003); Kalyuga (2007); Rosenshine (2012); Sinha y Kapur (2021): 53 estudios, g = 0.36 [IC 95 % 0.20, 0.51], 0.37–0.58 con alta fidelidad; Ashman, Kalyuga y Sweller (2020): con alta interactividad de elementos gana instrucción-explícita-primero. | **Alta** para ejemplo resuelto, reversión por pericia y PS-I (metaanálisis). **Media** para Rosenshine: evidencia sobre todo de educación básica; se usa como heurística convergente, no como efecto medido en universitarios. | Directa. OpenMP, MPI y CUDA tienen alta interactividad de elementos: modelar primero, desvanecer después. PS-I sólo para conceptos (p. ej., inventar cómo repartir iteraciones antes de enseñar `schedule`), nunca para sintaxis o API. |
| **P2.** Recuperar, espaciar, intercalar | Recuperar de la memoria enseña más que releer. Espaciar la práctica supera a concentrarla. Intercalar temas ayuda, con evidencia más limitada. | Roediger y Karpicke (2006): a una semana, ≈56 % vs 42 % (Exp. 1) y 61 % vs 40 % (Exp. 2), pese a mayor confianza al releer; Karpicke y Blunt (2011): 67 % recuperación vs 45 % mapa conceptual vs 49 % estudio repetido; Dunlosky et al. (2013): recuperación y práctica distribuida de utilidad **alta**, intercalado de utilidad **moderada**; Cepeda et al. (2006): 317 experimentos; Cepeda et al. (2008): intervalo óptimo ≈10–20 % del intervalo de retención; Bjork (1994); Bjork y Bjork (2011). | **Alta** para recuperación y espaciado (universitarios, textos académicos). **Media** para intercalado. | Recuperación de 5 min en toda sesión; tareas con un ejercicio intercalado; repasos a 1, 3 y 8 semanas; exámenes 2 y 3 con 10–20 % de unidades previas. Para código, combinar recuperación con rastreo y "explicar en lenguaje natural" (P4). |
| **P3.** Ejemplos resueltos con autoexplicación y desvanecimiento | Estudiar un ejemplo resuelto supera a resolver el problema a ciegas en novatos; con pericia la relación se invierte, por eso el andamiaje se retira. Autoexplicarse cada paso ayuda. | Sweller y Cooper (1985); Kalyuga et al. (2003); Kalyuga (2007); Sweller, van Merriënboer y Paas (2019); Dunlosky et al. (2013): autoexplicación de utilidad moderada. | **Alta** para ejemplo resuelto y reversión por pericia (experimental). **Media** para autoexplicación. Las referencias a Renkl y Atkinson que aparecían en 01 no se verificaron y se retiraron. | Muy alta. `ejemplo-resuelto.md` con pausas de autoexplicación; problemas por completar (*completion problems*) al inicio de cada tema; desvanecimiento dentro de la misma unidad para no perjudicar a los más avanzados. |
| **P4.** Leer y predecir antes de escribir | Rastrear y explicar código precede a saber escribirlo. PRIMM ordena esa secuencia. Los problemas de Parsons ahorran tiempo con aprendizaje equivalente. | Lopez et al. (2008); Lister, Fidge y Teague (2009); Murphy et al. (2012): respuestas relacionales en "explain in plain English" correlacionan con escribir código correcto; Corney et al. (2011); Sentance, Waite y Kallia (2019): 13 escuelas, 493 estudiantes de 11–14 años, cuasiexperimental, p < .05, sin tamaño de efecto; Parsons y Haden (2006); Ericson, Margulieux y Rick (2017): menos tiempo, sin diferencia en ganancia ni retención; Ericson, Foley y Rick (2018); Ericson et al. (2022). | **Media**: la línea Lister es correlacional en CS1 (Fowler et al., 2022, la matiza); PRIMM es cuasiexperimental en secundaria, sin evaluación universitaria publicada; Parsons mejora eficiencia, no aprendizaje. | Alta. Kernels CUDA y programas MPI dados como punto de partida; Parsons para sintaxis (pragmas, `MPI_Init…MPI_Finalize`, lanzamiento de kernels) y después escritura completa; "explica qué hace este kernel y qué carrera tiene" como ítem de examen barato de calificar y resistente a la IA. |
| **P5.** Hacer pensar a todos, todo el tiempo | El aprendizaje activo sube calificaciones y baja la reprobación en STEM; la cátedra fluida produce sensación de aprender, no aprendizaje; la instrucción entre pares reduce la reprobación en cursos de computación; programar en parejas mejora terminación y permanencia. | Freeman et al. (2014): 225 estudios, +0.47 DE, reprobación 33.8 % vs 21.8 %, razón de momios 1.95, mayor efecto en grupos ≤ 50; Deslauriers et al. (2019): +0.46 DE en aprendizaje, −0.56 DE en sensación de aprender; Crouch y Mazur (2001): ⟨g⟩ 0.25 → 0.49–0.74; Porter, Bailey Lee y Simon (2013): 16 ofertas de 4 cursos (incluida arquitectura), reprobación −61 % en promedio (≈20 % → 7 %), observacional; McDowell et al. (2003, 2006); Werner, Hanks y McDowell (2004): permanencia en carreras afines 59.5 % vs 22.2 % (mujeres) y 74.0 % vs 47.2 % (hombres). | **Alta** para aprendizaje activo e instrucción entre pares (metaanálisis + ECA en universitarios, incluida computación). **Media** para programación en parejas: evidencia de CS1; en un curso avanzado el beneficio esperado es menor. | Muy alta. Grupo de 35 cae en la franja de mayor efecto. Instrucción entre pares sin *clickers* (tarjetas o formulario). Explicar el hallazgo de Deslauriers al grupo en la primera sesión para anticipar la resistencia. Parejas con roles y rotación en depuración paralela. |
| **P6.** Evaluación formativa continua | Saber hoy quién no entendió qué cambia la sesión de mañana. El *exit ticket* es una herramienta de evaluación formativa de bajo costo; la calificación por especificaciones aclara criterios y permite reentregas. | Black y Wiliam (1998a, 1998b): revisión de ≈250 fuentes; el "0.4–0.7" es un rango narrativo, no un promedio ponderado; Kingston y Nash (2011): 13 estudios, media ponderada 0.20, mediana 0.25; *exit tickets*: sin estudio experimental que mida su efecto (literatura descriptiva o de percepción); Nilson (2015): propuesta sin evaluación experimental propia; Howitz, McKnelly y Link (2025): 90 publicaciones, evidencia mayormente anecdótica e inconsistente; Bloom (1984) y Kulik, Kulik y Bangert-Drowns (1990): aprendizaje para el dominio ≈0.5 DE en 108 evaluaciones, no "2 sigma". | **Media** para evaluación formativa en general. **Baja** para el *exit ticket* como intervención propia: se justifica por la práctica de recuperación (P2) y por el uso docente de la información. **Diseño** para la calificación por especificaciones. | Alta en viabilidad: un docente y 35 estudiantes pueden sostener 2–3 ítems de salida por sesión y revisarlos en 10 min. No prometer "0.4–0.7" ni "2 sigma". |
| **P7.** Proyecto auténtico como culminación | El proyecto funciona porque llega después de los fundamentos, con andamiaje e hitos. El ABP bien andamiado no es guía mínima. | Kirschner et al. (2006) y las réplicas de *Educational Psychologist* 42(2), 2007 (Hmelo-Silver, Duncan y Chinn; Schmidt et al.; Kuhn); de Jong et al. (2023): combinar indagación e instrucción directa; Sinha y Kapur (2021): PS-I rinde más en comprensión conceptual y transferencia cuando lo sigue instrucción explícita. | **Media**: síntesis y debate, no un metaanálisis de ABP en ingeniería. **Diseño** para la rendición de cuentas individual en equipos (las citas a Slavin y Johnson y Johnson que aparecían en 01 no se verificaron y se retiraron). | Alta como diseño: V1 → V2 → V3 con hitos H1/H2, rúbrica analítica y defensa con preguntas individuales. |
| **P8.** La IA como tutor socrático | La IA sin guardarraíles mejora el desempeño inmediato y daña el aprendizaje medido sin ayuda; con diseño de tutor el daño desaparece; un tutor diseñado con principios pedagógicos puede superar a la clase activa; los novatos con IA se dividen entre quienes aceleran y quienes luchan con una falsa sensación de avance. | Bastani et al. (2025): ECA, ≈1,000 estudiantes de preparatoria (Turquía, matemáticas); práctica +48 % (Base) y +127 % (Tutor); examen sin acceso: Base −17 % vs control, Tutor igual al control; Kestin et al. (2025): ECA cruzado, n = 194, física en Harvard; posprueba mediana 4.5 vs 3.5, 49 min vs 60; dos lecciones, posprueba inmediata, tutor ad hoc; Prather et al. (2024, ICER '24): 20 de 21 terminan, pero se abre la brecha; "false sense of progress"; Prather et al. (2023, ITiCSE-WGR; TOCHI); Bassner et al. (2025): mejores puntajes y menos estrés, sin diferencia en comprensión conceptual; Lehmann, Cornelius y Sting (2025): tutor ayuda, sustituto daña, más a los débiles; Nie et al. (2024); Pankiewicz y Baker (2024); Kazemitabaar et al. (2023); De Simone et al. (2025): +0.23 DE en inglés, documento de trabajo; Liu et al. (2024): CS50 es descriptivo, no ECA. | **Media**: patrón convergente pero reciente, de corto plazo y de contextos distintos (preparatoria, física, CS1). No existe un ECA universitario en programación con ganancia neta de aprendizaje por un tutor LLM. | Directa. Semáforo, declaración de uso, prueba de propiedad, zonas sin IA; evaluar siempre con tareas sin asistencia (examen, defensa oral, rastreo). Andamiar a los estudiantes con menor autorregulación. |
| **P9.** Metacognición y hábitos de ingeniería | Los estudiantes juzgan mal cuánto y con qué aprenden; conviene hacerlos predecir y comparar. Bitácora de errores y "pre-mortem" de rendimiento. | Deslauriers et al. (2019): correlación negativa entre aprendizaje real y percibido; Roediger y Karpicke (2006): releer aumentó la confianza y redujo la retención; Karpicke y Blunt (2011): los estudiantes predijeron lo contrario de lo que ocurrió; Prather et al. (2024): dificultades metacognitivas con IA. | **Alta** para el fenómeno de descalibración. **Diseño** para las intervenciones concretas (predicción de calificación, bitácora, pre-mortem): sin fuente verificada en el informe (las citas a Dunlosky y Metcalfe y a Gollwitzer se retiraron de 01). | Bajo costo. La "brecha de calibración" se mide en 01 §5. |
| **P10.** Equidad y escala | El costo de la guía mínima recae en quien tiene menos conocimiento previo o apoyo; la IA abre brechas entre novatos; la GPU en la nube iguala el acceso. | Kirschner et al. (2006); Prather et al. (2024); Werner, Hanks y McDowell (2004): parejas y permanencia de mujeres; Nie et al. (2024): efecto heterogéneo por país. B4 (TIMSS, correlacional) **no** se usa como prueba de secuencia explícito → aplicación. | **Media**: inferencia a partir de evidencia indirecta, no ECA sobre equidad en ingeniería. | Alta como restricción de diseño: material autocontenido, asesoría por protocolo, Colab/Kaggle para que nadie dependa de su hardware. |
| **P11.** Disciplina al servicio del criterio | Las reglas producen ingenieros confiables, no obediencia; cada regla lleva su razón. | Sin fuente empírica. Coherente con Willingham (2007, 2009): el criterio se construye sobre conocimiento y práctica. | **Diseño**. | Directa: fechas, *commits* por integrante, protocolo de medición. |

## 2. Qué dijeron otros asistentes de IA y qué encontramos

Afirmaciones que circularon en la conversación de origen (varios asistentes de IA discutiendo la "escuela
ideal") y lo que el verificador encontró.

| # | Afirmación que circuló | Qué encontramos | Veredicto | Uso en este curso |
|---|---|---|---|---|
| B1 | ECA nacional en EE. UU. (PNAS 2025) con casi 3,000 niños; Montessori supera en lectura, matemáticas, función ejecutiva y comprensión social; ahorro ≈ US$13,000 por niño en tres años. | Lillard et al. (2025), *PNAS*, 122(43): lotería en 24 escuelas Montessori públicas, **588 niños** (intención de tratar). Sin efectos al final de PK3 ni PK4. Al final de kínder: lectura (letra-palabra), memoria de corto plazo, función ejecutiva y comprensión social, g = 0.20–0.29; **matemáticas sólo tendencia, no significativa**. Costo ≈ US$13,000 menos por niño en tres años. | Parcialmente verificado; **falso** en el tamaño de muestra y en matemáticas. | Ninguno (preescolar). Si se menciona, sólo como ejemplo de ECA educativo bien hecho, con las cifras corregidas. |
| B2 | Sistemas de tutoría inteligente: hasta 42 % más *engagement*, 65 % menos ideas erróneas, 30 % más ganancia pos-prueba. | Ninguna fuente primaria ni secundaria reporta esas cifras, juntas ni por separado. Lo que existe: VanLehn (2011), ITS paso a paso d = 0.76; Ma et al. (2014) y Kulik y Fletcher (2016): g ≈ 0.4–0.6 en medidas locales, mucho menor en pruebas estandarizadas. | **No verificado** (muy probablemente fabricado o de marketing). | No usar. Sustituir por VanLehn (2011) y Kulik y Fletcher (2016) con sus cifras reales. |
| B3 | Un estudio comparativo de 2026 identificó factores comunes de Finlandia, Estonia y Singapur. | No existe tal estudio. La OCDE publicó PISA 2025 el 8 de septiembre de 2026. Con respaldo: OECD (2023), *PISA 2022 Results*, Vol. I y II; OECD (2024), Vol. V: asociaciones (no causales) entre apoyo docente, clima de aula, pertenencia, uso moderado de dispositivos, involucramiento parental y desempeño. | **No verificado** (inexistente). | No citar. PISA mide a jóvenes de 15 años y es correlacional; sin aplicabilidad directa a docencia universitaria. |
| B4 | Análisis de más de 8,000 estudiantes de octavo grado: se benefician de enseñanza estructurada y explícita antes de pasar a tareas de aplicación. | Candidato: Zhu et al. (2026), *British Journal of Sociology of Education*, 47(5), con TIMSS 2019, 8.º grado, EE. UU. (≈8,700; n exacto no confirmado). Correlacional, con autoinforme de prácticas: la instrucción centrada en el docente se asocia con mayor logro en matemáticas y menor brecha socioeconómica. **No** prueba una secuencia explícito → aplicación. TIMSS 2023: 487 vs 458 puntos con alta vs baja claridad instruccional (asociación). | Parcialmente verificado; hallazgo **reinterpretado**. | Si se usa: "análisis correlacionales de TIMSS (8.º grado, EE. UU.) asocian la instrucción dirigida por el docente con mayor logro y menor brecha socioeconómica (Zhu et al., 2026)". La secuencia se sostiene con P1 (Sweller, Kirschner, Ashman), que sí es experimental. |
| B5 | Rockefeller: "No quiero una nación de pensadores, quiero una nación de trabajadores"; Gates (1913); GEB con US$180 M iniciales. | La cita de Rockefeller no tiene fuente primaria; Snopes (2023) la califica *Unproven*; la atribución más antigua es un documental de 2006. El texto auténtico es de Gates (1913), *The Country School of To-morrow*, p. 6 ("We shall not try to make these people or any of their children into philosophers or men of learning or of science…"). GEB: fundado en 1902; donativo inicial de Rockefeller US$1 M; ≈US$180 M en total aportados por Rockefeller; US$324.6 M apropiados por el GEB hasta 1964. | Rockefeller: **apócrifa**. Gates: **verificada**. Cifras: **parcialmente** correctas. | El mito no forma parte del curso (01 §1). Si se menciona, citar a Gates textualmente, decir que la frase de Rockefeller carece de fuente y corregir las cifras. |

## 3. Afirmaciones que NO deben usarse en el documento del método

1. "ECA Montessori con casi 3,000 niños" y "superaron en matemáticas" (B1): n = 588; matemáticas no significativa.
2. "42 % más engagement, 65 % menos misconceptions, 30 % más ganancia" para tutores inteligentes (B2): sin fuente.
3. "Estudio comparativo de 2026 sobre Finlandia, Estonia y Singapur" (B3): inexistente; usar OCDE PISA 2022/2025 con cautela.
4. "Análisis de 8,000 estudiantes de 8.º muestra que se benefician de instrucción explícita antes de la aplicación" (B4) tal como está redactado: el estudio es correlacional y no prueba secuencia.
5. Cita "No quiero una nación de pensadores…" atribuida a Rockefeller (B5): apócrifa.
6. "$180 M inicial" del GEB (B5): fue el total de Rockefeller; el inicial fue $1 M.
7. "Metaanálisis de 2023 de Sinha & Kapur" (A14): es 2021; y "el fallo productivo casi triplica el efecto de un buen docente" (frase de prensa de los autores): usar g = 0.36 [0.20, 0.51] y 0.37–0.58 con alta fidelidad.
8. "Interleaving es de utilidad alta según Dunlosky" (A5): es moderada.
9. "Black & Wiliam: la evaluación formativa tiene efecto de 0.4–0.7" presentado como metaanálisis o como efecto de los exit tickets (A18): es un rango narrativo; Kingston & Nash estiman ≈0.20.
10. "Bloom demostró 2 sigma" como efecto replicable (A17): basado en dos tesis pequeñas; réplicas dan ≈0.5–0.8.
11. Tamaños de efecto tomados de Hattie como argumento principal (A15).
12. "Un ECA del pato de CS50 mostró…" (A19): el artículo de CS50 es descriptivo, no un ECA.
13. "El tutor de IA de Harvard duplicó el aprendizaje" sin matices (A19): dos lecciones, posprueba inmediata, tutor diseñado ad hoc; no generalizable a "usar ChatGPT".
14. "Nigeria: la IA produjo 2 años de aprendizaje en 6 semanas" (A19): +0.31 DE en índice compuesto, +0.23 DE en inglés; la equivalencia en años es una conversión de costo-efectividad; documento de trabajo con facilitación docente.
15. "Prather et al. hablan de 'ilusión de competencia'" como cita textual (A20): el término del artículo es "false sense/illusion of progress".
16. "Los problemas de Parsons mejoran el aprendizaje" (A11): mejoran la eficiencia (tiempo) con aprendizaje equivalente.
17. Cifras "92 % vs 76 %" o "46 % vs 11 %" para programación en parejas (A12): no confirmadas; usar 59.5 % vs 22.2 % (mujeres) y 74.0 % vs 47.2 % (hombres).
18. "'It's weird that it knows what I want' se publicó en TOCE" (A20): es TOCHI.
19. "PRIMM tiene evidencia experimental universitaria" (A10): evidencia cuasiexperimental en secundaria (11–14 años).

Los códigos A1–A21 y B1–B5 remiten a las entradas del informe de verificación del 14 de octubre de 2026 (ver §5).

## 4. Bibliografía verificada (APA 7)

(Las referencias marcadas con (*) tienen DOI tomado de registro bibliográfico/memoria; confirmar en Crossref.)

Ashman, G., Kalyuga, S., & Sweller, J. (2020). Problem-solving or explicit instruction: Which should go first when element interactivity is high? *Educational Psychology Review, 32*(1), 229–247. https://doi.org/10.1007/s10648-019-09500-5

Bassner, P., Lenk-Ostendorf, B., Beinstingel, L., Wasner, [inicial por verificar], & Krusche, S. (2025). Less stress, better scores, same learning: The dissociation of performance and learning in AI-supported programming education. *Computers and Education: Artificial Intelligence*, 100537. https://doi.org/10.1016/j.caeai.2025.100537

Bastani, H., Bastani, O., Sungu, A., Ge, H., Kabakcı, Ö., & Mariman, R. (2025). Generative AI without guardrails can harm learning: Evidence from high school mathematics. *Proceedings of the National Academy of Sciences, 122*(26), e2422633122. https://doi.org/10.1073/pnas.2422633122 (*)

Bergeron, P.-J., & Rivard, L. (2017). How to engage in pseudoscience with real data: A criticism of John Hattie's arguments in *Visible Learning* from the perspective of a statistician. *McGill Journal of Education, 52*(1), 237–246. https://doi.org/10.7202/1040816ar

Bjork, E. L., & Bjork, R. A. (2011). Making things hard on yourself, but in a good way: Creating desirable difficulties to enhance learning. In M. A. Gernsbacher, R. W. Pew, L. M. Hough, & J. R. Pomerantz (Eds.), *Psychology and the real world: Essays illustrating fundamental contributions to society* (pp. 56–64). Worth.

Bjork, R. A. (1994). Memory and metamemory considerations in the training of human beings. In J. Metcalfe & A. P. Shimamura (Eds.), *Metacognition: Knowing about knowing* (pp. 185–205). MIT Press.

Black, P., & Wiliam, D. (1998a). Assessment and classroom learning. *Assessment in Education: Principles, Policy & Practice, 5*(1), 7–74. https://doi.org/10.1080/0969595980050102

Black, P., & Wiliam, D. (1998b). Inside the black box: Raising standards through classroom assessment. *Phi Delta Kappan, 80*(2), 139–148.

Bloom, B. S. (1984). The 2 sigma problem: The search for methods of group instruction as effective as one-to-one tutoring. *Educational Researcher, 13*(6), 4–16. https://doi.org/10.3102/0013189X013006004

Cepeda, N. J., Pashler, H., Vul, E., Wixted, J. T., & Rohrer, D. (2006). Distributed practice in verbal recall tasks: A review and quantitative synthesis. *Psychological Bulletin, 132*(3), 354–380. https://doi.org/10.1037/0033-2909.132.3.354

Cepeda, N. J., Vul, E., Rohrer, D., Wixted, J. T., & Pashler, H. (2008). Spacing effects in learning: A temporal ridgeline of optimal retention. *Psychological Science, 19*(11), 1095–1102.

Corney, M., Lister, R., & Teague, D. (2011). Early relational reasoning and the novice programmer: Swapping as the "Hello World" of relational reasoning. In *Proceedings of the 13th Australasian Computing Education Conference (ACE 2011)*, CRPIT 114 (pp. 95–104). ACS.

Crouch, C. H., & Mazur, E. (2001). Peer Instruction: Ten years of experience and results. *American Journal of Physics, 69*(9), 970–977. https://doi.org/10.1119/1.1374249

de Jong, T., Lazonder, A. W., Chinn, C. A., Fischer, F., Gobert, J., Hmelo-Silver, C. E., Koedinger, K. R., Krajcik, J. S., Kyza, E. A., Linn, M. C., Pedaste, M., Scheiter, K., & Zacharia, Z. C. (2023). Let's talk evidence – The case for combining inquiry-based and direct instruction. *Educational Research Review, 39*, 100536. https://doi.org/10.1016/j.edurev.2023.100536

De Simone, M., Tiberti, F., Barron Rodriguez, M., Manolio, F., Mosuro, W., & Dikoru, E. J. (2025). *From chalkboards to chatbots: Evaluating the impact of generative AI on learning outcomes in Nigeria* (Policy Research Working Paper No. 11125). World Bank.

Dekker, S., Lee, N. C., Howard-Jones, P., & Jolles, J. (2012). Neuromyths in education: Prevalence and predictors of misconceptions among teachers. *Frontiers in Psychology, 3*, 429. https://doi.org/10.3389/fpsyg.2012.00429

Deslauriers, L., McCarty, L. S., Miller, K., Callaghan, K., & Kestin, G. (2019). Measuring actual learning versus feeling of learning in response to being actively engaged in the classroom. *Proceedings of the National Academy of Sciences, 116*(39), 19251–19257. https://doi.org/10.1073/pnas.1821936116

Dunlosky, J., Rawson, K. A., Marsh, E. J., Nathan, M. J., & Willingham, D. T. (2013). Improving students' learning with effective learning techniques: Promising directions from cognitive and educational psychology. *Psychological Science in the Public Interest, 14*(1), 4–58. https://doi.org/10.1177/1529100612453266

Ericson, B. J., Foley, J. D., & Rick, J. (2018). Evaluating the efficiency and effectiveness of adaptive Parsons problems. In *Proceedings of the 2018 ACM Conference on International Computing Education Research (ICER '18)* (pp. 60–68). ACM. https://doi.org/10.1145/3230977.3231000 (*)

Ericson, B. J., Margulieux, L. E., & Rick, J. (2017). Solving Parsons problems versus fixing and writing code. In *Proceedings of the 17th Koli Calling International Conference on Computing Education Research* (pp. 20–29). ACM. https://doi.org/10.1145/3141880.3141895

Ericson, B. J., Denny, P., Prather, J., Duran, R., Hellas, A., Leinonen, J., Miller, C. S., Morrison, B. B., Pearce, J. L., & Rodger, S. H. (2022). Parsons problems and beyond: Systematic literature review and empirical study designs. In *Proceedings of the 2022 Working Group Reports on Innovation and Technology in Computer Science Education (ITiCSE-WGR '22)* (pp. 191–234). ACM. https://doi.org/10.1145/3571785.3574127 (*)

Freeman, S., Eddy, S. L., McDonough, M., Smith, M. K., Okoroafor, N., Jordt, H., & Wenderoth, M. P. (2014). Active learning increases student performance in science, engineering, and mathematics. *Proceedings of the National Academy of Sciences, 111*(23), 8410–8415. https://doi.org/10.1073/pnas.1319030111

Gates, F. T. (1913). *The country school of to-morrow* (Occasional Papers No. 1). General Education Board.

Hake, R. R. (1998). Interactive-engagement versus traditional methods: A six-thousand-student survey of mechanics test data for introductory physics courses. *American Journal of Physics, 66*(1), 64–74.

Howitz, W. J., McKnelly, K. J., & Link, R. D. (2025). Delving into the design and implementation of specifications grading systems in higher education: A systematic review. *Education Sciences, 15*(1), 83. https://doi.org/10.3390/educsci15010083 (*)

Kalyuga, S. (2007). Expertise reversal effect and its implications for learner-tailored instruction. *Educational Psychology Review, 19*(4), 509–539. https://doi.org/10.1007/s10648-007-9054-3

Kalyuga, S., Ayres, P., Chandler, P., & Sweller, J. (2003). The expertise reversal effect. *Educational Psychologist, 38*(1), 23–31. https://doi.org/10.1207/S15326985EP3801_4 (*)

Kalyuga, S., Chandler, P., Tuovinen, J., & Sweller, J. (2001). When problem solving is superior to studying worked examples. *Journal of Educational Psychology, 93*(3), 579–588.

Kapur, M. (2008). Productive failure. *Cognition and Instruction, 26*(3), 379–424. https://doi.org/10.1080/07370000802212669

Kapur, M. (2016). Examining productive failure, productive success, unproductive failure, and unproductive success in learning. *Educational Psychologist, 51*(2), 289–299. https://doi.org/10.1080/00461520.2016.1155457

Karpicke, J. D., & Blunt, J. R. (2011). Retrieval practice produces more learning than elaborative studying with concept mapping. *Science, 331*(6018), 772–775. https://doi.org/10.1126/science.1199327

Kazemitabaar, M., Chow, J., Ma, C. K. T., Ericson, B. J., Weintrop, D., & Grossman, T. (2023). Studying the effect of AI code generators on supporting novice learners in introductory programming. In *Proceedings of the 2023 CHI Conference on Human Factors in Computing Systems* (Article 455). ACM. https://doi.org/10.1145/3544548.3580919

Kestin, G., Miller, K., Klales, A., Milbourne, T., & Ponti, G. (2025). AI tutoring outperforms in-class active learning: An RCT introducing a novel research-based design in an authentic educational setting. *Scientific Reports, 15*, 17458. https://doi.org/10.1038/s41598-025-97652-6

Kingston, N., & Nash, B. (2011). Formative assessment: A meta-analysis and a call for research. *Educational Measurement: Issues and Practice, 30*(4), 28–37. https://doi.org/10.1111/j.1745-3992.2011.00220.x (*)

Kirschner, P. A., Sweller, J., & Clark, R. E. (2006). Why minimal guidance during instruction does not work: An analysis of the failure of constructivist, discovery, problem-based, experiential, and inquiry-based teaching. *Educational Psychologist, 41*(2), 75–86. https://doi.org/10.1207/s15326985ep4102_1 (*)

Kraft, M. A. (2020). Interpreting effect sizes of education interventions. *Educational Researcher, 49*(4), 241–253. https://doi.org/10.3102/0013189X20912798 (*)

Kulik, C.-L. C., Kulik, J. A., & Bangert-Drowns, R. L. (1990). Effectiveness of mastery learning programs: A meta-analysis. *Review of Educational Research, 60*(2), 265–299. https://doi.org/10.3102/00346543060002265

Kulik, J. A., & Fletcher, J. D. (2016). Effectiveness of intelligent tutoring systems: A meta-analytic review. *Review of Educational Research, 86*(1), 42–78.

Lehmann, M., Cornelius, P. B., & Sting, F. J. (2025). *AI meets the classroom: When do large language models harm learning?* arXiv:2409.09047 (v2).

Lillard, A. S., Loeb, D., Berg, J., Escueta, M., Manship, K., Hauser, A., & Daggett, E. D. (2025). A national randomized controlled trial of the impact of public Montessori preschool at the end of kindergarten. *Proceedings of the National Academy of Sciences, 122*(43), e2506130122. https://doi.org/10.1073/pnas.2506130122

Lister, R., Fidge, C., & Teague, D. (2009). Further evidence of a relationship between explaining, tracing and writing skills in introductory programming. In *Proceedings of the 14th Annual ACM SIGCSE Conference on Innovation and Technology in Computer Science Education (ITiCSE '09)* (pp. 161–165). ACM. https://doi.org/10.1145/1562877.1562930 (*)

Liu, R., Zenke, C., Liu, C., Holmes, A., Thornton, P., & Malan, D. J. (2024). Teaching CS50 with AI: Leveraging generative artificial intelligence in computer science education. In *Proceedings of the 55th ACM Technical Symposium on Computer Science Education (SIGCSE TS 2024)* (pp. 750–756). ACM.

Loibl, K., Roll, I., & Rummel, N. (2017). Towards a theory of when and how problem solving followed by instruction supports learning. *Educational Psychology Review, 29*(4), 693–715.

Lopez, M., Whalley, J., Robbins, P., & Lister, R. (2008). Relationships between reading, tracing and writing skills in introductory programming. In *Proceedings of the Fourth International Workshop on Computing Education Research (ICER '08)* (pp. 101–112). ACM.

Ma, W., Adesope, O. O., Nesbit, J. C., & Liu, Q. (2014). Intelligent tutoring systems and learning outcomes: A meta-analysis. *Journal of Educational Psychology, 106*(4), 901–918.

McDowell, C., Werner, L., Bullock, H. E., & Fernald, J. (2003). The impact of pair programming on student performance, perception and persistence. In *Proceedings of the 25th International Conference on Software Engineering (ICSE '03)* (pp. 602–607). IEEE.

McDowell, C., Werner, L., Bullock, H. E., & Fernald, J. (2006). Pair programming improves student retention, confidence, and program quality. *Communications of the ACM, 49*(8), 90–95. https://doi.org/10.1145/1145287.1145293

Murphy, L., Fitzgerald, S., Lister, R., & McCauley, R. (2012). Ability to 'explain in plain English' linked to proficiency in computer-based programming. In *Proceedings of the Ninth Annual International Conference on International Computing Education Research (ICER '12)* (pp. 111–118). ACM. https://doi.org/10.1145/2361276.2361299 (*)

Newton, P. M., & Salvi, A. (2020). How common is belief in the learning styles neuromyth, and does it matter? A pragmatic systematic review. *Frontiers in Education, 5*, 602451.

Nie, A., et al., & Piech, C. (2024). *The GPT surprise: Offering large language model chat in a massive coding class reduced engagement but increased adopters' exam performances.* arXiv:2407.09975.

Nilson, L. B. (2015). *Specifications grading: Restoring rigor, motivating students, and saving faculty time*. Stylus.

OECD. (2023). *PISA 2022 results (Volume I): The state of learning and equity in education*. OECD Publishing. https://doi.org/10.1787/53f23881-en

OECD. (2023). *PISA 2022 results (Volume II): Learning during – and from – disruption*. OECD Publishing. https://doi.org/10.1787/a97db61c-en

OECD. (2024). *PISA 2022 results (Volume V): Learning strategies and attitudes for life*. OECD Publishing.

Pankiewicz, M., & Baker, R. S. (2024). Navigating compiler errors with AI assistance – A study of GPT hints in an introductory programming course. In *Proceedings of ITiCSE 2024*. ACM.

Parsons, D., & Haden, P. (2006). Parson's programming puzzles: A fun and effective learning tool for first programming courses. In *Proceedings of the 8th Australasian Conference on Computing Education (ACE 2006)*, CRPIT 52 (pp. 157–163). ACS.

Pashler, H., McDaniel, M., Rohrer, D., & Bjork, R. (2008). Learning styles: Concepts and evidence. *Psychological Science in the Public Interest, 9*(3), 105–119. https://doi.org/10.1111/j.1539-6053.2009.01038.x

Porter, L., Bailey Lee, C., & Simon, B. (2013). Halving fail rates using peer instruction: A study of four computer science courses. In *Proceedings of the 44th ACM Technical Symposium on Computer Science Education (SIGCSE '13)* (pp. 177–182). ACM. https://doi.org/10.1145/2445196.2445250

Prather, J., Denny, P., Leinonen, J., Becker, B. A., Albluwi, I., Craig, M., Keuning, H., Kiesler, N., Kohn, T., Luxton-Reilly, A., MacNeil, S., Petersen, A., Pettit, R., Reeves, B. N., & Savelka, J. (2023). The robots are here: Navigating the generative AI revolution in computing education. In *Proceedings of the 2023 Working Group Reports on Innovation and Technology in Computer Science Education (ITiCSE-WGR '23)* (pp. 108–159). ACM. https://doi.org/10.1145/3623762.3633499

Prather, J., Reeves, B. N., Denny, P., Becker, B. A., Leinonen, J., Luxton-Reilly, A., Powell, G., Finnie-Ansley, J., & Santos, E. A. (2023). "It's weird that it knows what I want": Usability and interactions with Copilot for novice programmers. *ACM Transactions on Computer-Human Interaction, 31*(1), Article 4. https://doi.org/10.1145/3617367

Prather, J., Reeves, B. N., Leinonen, J., MacNeil, S., Randrianasolo, A. S., Becker, B. A., Kimmel, B., Wright, J., & Briggs, B. (2024). The widening gap: The benefits and harms of generative AI for novice programmers. In *Proceedings of the 2024 ACM Conference on International Computing Education Research (ICER '24)*. ACM. https://doi.org/10.1145/3632620.3671116 (*)

Roediger, H. L., III, & Karpicke, J. D. (2006). Test-enhanced learning: Taking memory tests improves long-term retention. *Psychological Science, 17*(3), 249–255. https://doi.org/10.1111/j.1467-9280.2006.01693.x

Rosenshine, B. (2012). Principles of instruction: Research-based strategies that all teachers should know. *American Educator, 36*(1), 12–19, 39.

Sentance, S., Waite, J., & Kallia, M. (2019). Teaching computer programming with PRIMM: A sociocultural perspective. *Computer Science Education, 29*(2–3), 136–176. https://doi.org/10.1080/08993408.2019.1608781

Simpson, A. (2017). The misdirection of public policy: Comparing and combining standardised effect sizes. *Journal of Education Policy, 32*(4), 450–466. https://doi.org/10.1080/02680939.2017.1280183

Sinha, T., & Kapur, M. (2021). When problem solving followed by instruction works: Evidence for productive failure. *Review of Educational Research, 91*(5), 761–798. https://doi.org/10.3102/00346543211019105

Snopes. (2023, 7 de julio). *Did John D. Rockefeller say 'I don't want a nation of thinkers, I want a nation of workers'?* https://www.snopes.com/fact-check/nation-of-workers/

Sweller, J. (1988). Cognitive load during problem solving: Effects on learning. *Cognitive Science, 12*(2), 257–285. https://doi.org/10.1207/s15516709cog1202_4

Sweller, J., & Cooper, G. A. (1985). The use of worked examples as a substitute for problem solving in learning algebra. *Cognition and Instruction, 2*(1), 59–89.

Sweller, J., van Merriënboer, J. J. G., & Paas, F. (2019). Cognitive architecture and instructional design: 20 years later. *Educational Psychology Review, 31*(2), 261–292. https://doi.org/10.1007/s10648-019-09465-5

VanLehn, K. (2011). The relative effectiveness of human tutoring, intelligent tutoring systems, and other tutoring systems. *Educational Psychologist, 46*(4), 197–221. https://doi.org/10.1080/00461520.2011.611369

Vickrey, T., Rosploch, K., Rahmanian, R., Pilarz, M., & Stains, M. (2015). Research-based implementation of peer instruction: A literature review. *CBE—Life Sciences Education, 14*(1), es3. https://doi.org/10.1187/cbe.14-11-0198

von Davier, M., Kennedy, A., Reynolds, K., Fishbein, B., Khorramdel, L., Aldrich, C., Bookbinder, A., Bezirhan, U., & Yin, L. (2024). *TIMSS 2023 international results in mathematics and science*. Boston College, TIMSS & PIRLS International Study Center.

Waterhouse, L. (2006). Multiple intelligences, the Mozart effect, and emotional intelligence: A critical review. *Educational Psychologist, 41*(4), 207–225.

Wecker, C., Vogel, F., & Hetmanek, A. (2017). Visionär und imposant – aber auch belastbar? Eine Kritik der Methodik von Hatties "Visible Learning". *Zeitschrift für Erziehungswissenschaft, 20*(1), 21–40. https://doi.org/10.1007/s11618-016-0696-0

Werner, L. L., Hanks, B., & McDowell, C. (2004). Pair-programming helps female computer science students. *ACM Journal on Educational Resources in Computing, 4*(1), Article 4.

Willingham, D. T. (2007). Critical thinking: Why is it so hard to teach? *American Educator, 31*(2), 8–19.

Willingham, D. T. (2009). *Why don't students like school? A cognitive scientist answers questions about how the mind works and what it means for the classroom*. Jossey-Bass. (2.ª ed., 2021)

Willingham, D. T., Hughes, E. M., & Dobolyi, D. G. (2015). The scientific status of learning styles theories. *Teaching of Psychology, 42*(3), 266–271.

## 5. Nota metodológica

- **Quién y cuándo.** Un verificador independiente (asistente de IA con herramientas de búsqueda) produjo el
  informe de evidencia el 14 de octubre de 2026 (entradas A1–A21 sobre fundamentos y B1–B5 sobre afirmaciones de
  otros asistentes). Un editor académico cruzó el informe con `00`, `01` y `05` y corrigió los textos. El profesor
  revisa antes de integrar a `main`.
- **Cómo.** La descarga directa de páginas estuvo bloqueada por política de red. La verificación se hizo con
  búsquedas (estándar y extendidas) que devuelven extractos textuales de fuentes primarias (páginas de editorial,
  PDF de los artículos, repositorios institucionales, resúmenes oficiales) y, cuando hizo falta, de cobertura
  secundaria. Cada entrada del informe indica qué dato proviene de fuente primaria y cuál sólo de secundaria.
- **Veredictos.** *Verificado*, *parcialmente*, *no verificado* o *falso*. En §1 se traducen a grado de certeza
  para este curso; en §3 se listan las formulaciones que quedan prohibidas.
- **Pendientes antes de imprimir.** Confirmar en Crossref los DOI marcados con (*); la inicial de Wasner en
  Bassner et al. (2025); la estimación ≈0.63 DE de Kestin et al. (2025), que sólo apareció en fuentes secundarias;
  el n exacto de Zhu et al. (2026); los valores del Exp. 1 de Roediger y Karpicke (2006), tomados de su Figura 1.
- **Regla de uso.** Ninguna cifra ni cita entra a los documentos del método si no está en este archivo. Lo que se
  quiera agregar se verifica y se agrega aquí primero.
