# Épica EB — Casete Expedición Base

**Objetivo:** Validar una exploración situacional de liderazgo de 10 escenarios.  
**Bloqueantes:** `DEC-P-01`, `DEC-P-02`, `DEC-L-01`.

---

## HU-EB-001 — Banco de 10 escenarios y matriz conductual

**Tipo:** Contenido + psicometría + juego  
**Prioridad:** Must · **Estimación:** 13 SP · **Responsables:** Psicología + Game Design + PO  
**Trazabilidad:** RC-01, RC-02

**Como** jugador, **quiero** responder escenarios plausibles de liderazgo, **para** observar tendencias sin preguntas obvias o moralizantes.

### Criterios de aceptación

```gherkin
Escenario: Cobertura
  DADO el casete completo
  CUANDO se revisa su matriz
  ENTONCES contiene 10 escenarios: presión, conflicto, cambio, influencia y calidad/riesgo
  Y cada contexto aparece dos veces

Escenario: Opciones
  DADO un escenario
  CUANDO se revisan sus cuatro opciones
  ENTONCES todas son comprensibles y plausibles
  Y ninguna declara o insinúa una dimensión como moralmente superior

Escenario: Scoring
  DADO una opción
  CUANDO se inspecciona la matriz privada
  ENTONCES tiene pesos documentados y evidencia esperada
  Y no depende de una asociación trivial A=D, B=I, C=S, D=C
```

### UX

- Texto breve: contexto, tensión y decisión.
- Lectura objetivo por escenario inferior a dos minutos.

### Técnica, datos y seguridad

- Contenido en contrato de casete; matriz privada fuera del payload previo a respuesta.
- Cada revisión crea una nueva versión.

### Dependencias y DoD específico

- Decisión de marco, licencia y claim.
- 100% revisado por Psicología, Game Design, Gobierno y PO.

---

## HU-EB-002 — Preparación y ejecución neutral

**Tipo:** Funcional + UX de casete  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** UX + Frontend  
**Trazabilidad:** RC-03, RX-13

**Como** jugador, **quiero** conocer las reglas y recorrer la exploración sin feedback parcial, **para** responder con menor sesgo.

### Criterios de aceptación

```gherkin
Escenario: Introducción
  DADO una sesión no iniciada
  CUANDO el jugador abre Expedición Base
  ENTONCES conoce propósito, duración, privacidad, pausa y ausencia de respuestas correctas
  Y se aclara que el resultado es exploratorio

Escenario: Ejecución
  DADO una sesión activa
  CUANDO confirma una respuesta
  ENTONCES avanza al siguiente escenario
  Y no muestra dimensión, puntaje ni valoración parcial

Escenario: Reanudación
  DADO una sesión pausada
  CUANDO regresa
  ENTONCES continúa en el primer escenario no confirmado
```

### UX

- Progreso `n/10`, sin temporizador y con “Guardar y salir”.
- Orden visual de opciones aleatorizable sin cambiar IDs o scoring.

### Técnica, datos y seguridad

- Configuración usa runner común; se registra orden presentado.
- No exponer pesos en DOM, red o bundle.

### Dependencias y DoD específico

- HU-EB-001, HU-CM-004 y HU-CM-005.
- Prueba de ausencia de feedback/score parcial.

---

## HU-EB-003 — Cálculo reproducible del perfil exploratorio

**Tipo:** Técnica + psicometría  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Backend/Data + Psicología  
**Trazabilidad:** RF-SC-01, RF-SC-02

**Como** jugador, **quiero** que mis respuestas produzcan un resultado consistente, **para** recibir una lectura explicable.

### Criterios de aceptación

```gherkin
Escenario: Resultado completo
  DADO 10 respuestas confirmadas
  CUANDO finaliza la sesión
  ENTONCES calcula las dimensiones con la versión aprobada
  Y conserva evidencias y limitaciones

Escenario: Reproducibilidad
  DADO las mismas respuestas y versión
  CUANDO se calcula en diferentes momentos
  ENTONCES obtiene el mismo resultado

Escenario: Cobertura insuficiente
  DADO una dimensión sin evidencia mínima
  CUANDO se construye el resultado
  ENTONCES se marca como no concluyente
  Y no se inventa una interpretación
```

### UX

- El usuario ve “Preparando tu lectura” sin falsa precisión.

### Técnica, datos y seguridad

- Golden fixtures aprobados; normalización documentada.
- Guardar valores crudos, normalizados, evidencia y versión.

### Dependencias y DoD específico

- HU-EB-001 y HU-CM-006.
- Revisión firmada del scoring y pruebas de límites.

---

## HU-EB-004 — Resultado conductual accesible y plan inicial

**Tipo:** Funcional + UX + contenido  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** UX + Frontend + Psicología  
**Trazabilidad:** RF-RS-01, RF-RS-02, RX-09, RX-10

**Como** jugador, **quiero** comprender mis tendencias y sus posibles costos, **para** elegir prácticas de liderazgo.

### Criterios de aceptación

```gherkin
Escenario: Resultado
  DADO una Expedición Base completada
  CUANDO el jugador abre el resultado
  ENTONCES ve radar, tabla, evidencias situadas, limitaciones y fecha/versión
  Y recibe tres prácticas proporcionales al resultado

Escenario: Accesibilidad
  DADO un usuario que no percibe el gráfico
  CUANDO navega la página con lector de pantalla
  ENTONCES obtiene la misma información mediante texto y tabla

Escenario: Lenguaje
  DADO cualquier combinación de puntajes
  CUANDO se presenta
  ENTONCES usa tendencias tentativas
  Y no etiqueta capacidad, personalidad fija o idoneidad laboral
```

### UX

- El radar no comunica “mejor/peor”; tabla y explicación son primarias.
- CTA siguiente: revisar prácticas o iniciar Expedición Cumbre.

### Técnica, datos y seguridad

- Datos desde resultado autoritativo; narrativa desde HU-IA-001 o fallback.
- Resultado propio protegido por RLS.

### Dependencias y DoD específico

- HU-EB-003, HU-RS-001, HU-IA-003.
- Revisión de lenguaje y prueba con lector de pantalla.

---

## HU-EB-005 — Piloto cognitivo y análisis de ítems

**Tipo:** Investigación + calidad  
**Prioridad:** Must antes de producción · **Estimación:** 8 SP · **Responsables:** Psicología + PM  
**Trazabilidad:** KPI-02, KPI-04, KPI-08, KPI-10

**Como** responsable de producto, **quiero** pilotear los escenarios, **para** detectar ambigüedad defectuosa, deseabilidad social y sesgos.

### Criterios de aceptación

```gherkin
Escenario: Entrevista cognitiva
  DADO un prototipo con contenido completo
  CUANDO 5 a 8 líderes lo recorren
  ENTONCES se documenta qué entendieron, cómo eligieron y qué sintieron evaluado

Escenario: Piloto
  DADO contenido ajustado
  CUANDO participa una muestra diversa de 15 a 30 líderes
  ENTONCES se analizan finalización, tiempos, distribución, abandono y confianza
  Y cada cambio recomendado queda trazado a una nueva versión
```

### UX

- Recoger percepción de respeto, privacidad y utilidad, no solo completitud.

### Técnica, datos y seguridad

- Datos de investigación con consentimiento y finalidad diferenciada.
- No declarar confiabilidad o validez con muestra insuficiente.

### Dependencias y DoD específico

- HU-EB-001 a HU-EB-004.
- Informe de piloto y decisión explícita de avanzar/ajustar.

