# Épica EC — Casete Expedición Cumbre

**Objetivo:** Simular 10 decisiones conectadas para desarrollar liderazgo mediante trade-offs, coaches y fortalezas VIA seleccionadas.  
**Bloqueantes:** `DEC-P-05`, `DEC-P-06`, `DEC-L-01`.

---

## HU-EC-001 — Narrativa empresarial de 10 retos

**Tipo:** Contenido + game design  
**Prioridad:** Must · **Estimación:** 13 SP · **Responsables:** Game Design + Psicología + PO  
**Trazabilidad:** RC-04

**Como** jugador, **quiero** conducir una empresa a través de una historia coherente, **para** comprender cómo decisiones sucesivas crean consecuencias.

### Criterios de aceptación

```gherkin
Escenario: Arco completo
  DADO el casete Cumbre
  CUANDO se revisa su contenido
  ENTONCES incluye 10 retos conectados desde mandato y cliente hasta crisis y continuidad
  Y los hechos de un reto son consistentes con el estado acumulado

Escenario: Ambigüedad justa
  DADO cualquier reto
  CUANDO expertos revisan sus 3 o 4 opciones
  ENTONCES todas tienen beneficios, costos y condiciones plausibles
  Y ninguna es una trampa moral o respuesta evidentemente virtuosa
```

### UX

- Cada reto muestra contexto, tensión y decisión de forma escaneable.
- La empresa permanece central; Everest funciona como marco de expedición.

### Técnica, datos y seguridad

- IDs estables para retos, opciones, consecuencias y evidencias.
- Contenido versionado y sin lógica ejecutable.

### Dependencias y DoD específico

- Brief empresarial y guía de tono.
- Revisión de continuidad, sensibilidad cultural y lenguaje.

---

## HU-EC-002 — Brief de misión y progreso de la simulación

**Tipo:** Funcional + UX  
**Prioridad:** Must · **Estimación:** 3 SP · **Responsables:** UX + Frontend  
**Trazabilidad:** RX-13

**Como** jugador, **quiero** comprender la misión, variables y reglas, **para** tomar decisiones informadas sin conocer el scoring oculto.

### Criterios de aceptación

```gherkin
Escenario: Preparación
  DADO una sesión no iniciada
  CUANDO abre Expedición Cumbre
  ENTONCES conoce objetivo, duración, 10 retos, estados de empresa y uso de coaches
  Y se aclara que no existe una solución universal

Escenario: Progreso
  DADO una sesión activa
  CUANDO abre un reto
  ENTONCES ve campamento actual, total y estado empresarial vigente
  Y puede guardar y salir
```

### UX

- Sin tutorial largo ni términos financieros no explicados.
- Indicadores con número, etiqueta y cambio; nunca solo color.

### Técnica, datos y seguridad

- Usa runner común y capability `stateful_simulation`.

### Dependencias y DoD específico

- HU-EC-001, HU-CM-004.
- Prueba de comprensión con usuarios.

---

## HU-EC-003 — Motor de estados y consecuencias

**Tipo:** Técnica + juego  
**Prioridad:** Must · **Estimación:** 13 SP · **Responsables:** Backend/Data + Game Design  
**Trazabilidad:** RF-SC-03, RC-05, RC-06

**Como** jugador, **quiero** que mis decisiones cambien la empresa de forma consistente, **para** experimentar trade-offs explicables.

### Criterios de aceptación

```gherkin
Escenario: Impacto inmediato
  DADO un estado vigente de Caja, Confianza, Personas y Ejecución
  CUANDO se confirma una opción
  ENTONCES aplica una sola vez sus impactos inmediatos
  Y conserva el evento que explica cada cambio

Escenario: Impacto diferido
  DADO una consecuencia programada por una decisión anterior
  CUANDO llega su condición de activación
  ENTONCES aplica el efecto versionado
  Y lo vincula con la decisión original

Escenario: Reproducción
  DADO la misma secuencia y versión
  CUANDO se simula nuevamente en pruebas
  ENTONCES produce el mismo desenlace
```

### UX

- Mostrar qué cambió y por qué, sin exponer tablas internas.
- Evitar variables ocultas relevantes en el MVP.

### Técnica, datos y seguridad

- Event sourcing liviano mediante `state_events` o historial equivalente.
- Reglas backend, límites definidos y golden simulations.

### Dependencias y DoD específico

- HU-EC-001, HU-CM-005.
- Balance de trayectorias y pruebas de impactos diferidos.

---

## HU-EC-004 — Consulta de coaches y fichas de oxígeno

**Tipo:** Funcional + UX + juego  
**Prioridad:** Must/Should para segunda consulta · **Estimación:** 8 SP · **Responsables:** Frontend + Backend + Game Design  
**Trazabilidad:** RF-SC-04, RF-SC-05, RC-07

**Como** jugador, **quiero** consultar perspectivas especializadas antes de decidir, **para** ampliar la información sin recibir una solución.

### Criterios de aceptación

```gherkin
Escenario: Primera consulta
  DADO un reto pendiente
  CUANDO elige Estratega, Humano o Ejecución
  ENTONCES recibe su lente aprobada
  Y la consulta queda registrada sin alterar la empresa

Escenario: Segunda consulta
  DADO fichas disponibles
  CUANDO confirma consultar un segundo coach
  ENTONCES consume una ficha exactamente una vez
  Y muestra la segunda perspectiva

Escenario: Límite
  DADO un coach ya consultado o sin fichas
  CUANDO intenta repetir la acción
  ENTONCES no duplica consumo ni respuesta
  Y explica la regla
```

### UX

- Tarjetas muestran especialidad, lente y fichas restantes.
- Confirmación solo antes de consumir un recurso irreversible.

### Técnica, datos y seguridad

- `coach_consultations` con unicidad por sesión/reto/coach.
- Contenido preautorado o generación acotada; nunca scoring por IA.

### Dependencias y DoD específico

- `DEC-P-06`, HU-EC-001 y HU-CM-005.
- Pruebas concurrentes de consumo único.

---

## HU-EC-005 — Feedback, contrafactual y perspectiva omitida

**Tipo:** Funcional + UX + contenido  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Game Design + Psicología + Frontend  
**Trazabilidad:** RF-SC-06

**Como** jugador, **quiero** entender la consecuencia y perspectivas omitidas, **para** aprender sin sentir que fui castigado.

### Criterios de aceptación

```gherkin
Escenario: Feedback posterior
  DADO una decisión confirmada
  CUANDO se aplica su consecuencia
  ENTONCES se muestra efecto inmediato, trade-off y pregunta reflexiva
  Y no se permite cambiar la primera decisión

Escenario: Contrafactual
  DADO una alternativa relevante no elegida
  CUANDO se presenta el feedback
  ENTONCES explica qué podría haber ganado y qué costo habría asumido
  Y no afirma que era universalmente mejor

Escenario: Coach omitido
  DADO coaches no consultados
  CUANDO termina el reto
  ENTONCES se resume qué señal habrían hecho visible
  Y no se usa lenguaje de culpa
```

### UX

- Cuatro capas breves: consecuencia, fortaleza, contrafactual y lentes omitidas.
- CTA claro hacia el siguiente reto.

### Técnica, datos y seguridad

- Feedback proveniente de reglas/contenido de la versión.
- IA puede modular redacción, no hechos ni impactos.

### Dependencias y DoD específico

- HU-EC-003, HU-EC-004.
- Revisión psicológica de todos los mensajes.

---

## HU-EC-006 — Evidencia VIA seleccionada

**Tipo:** Psicología + scoring  
**Prioridad:** Must · **Estimación:** 13 SP · **Responsables:** Psicología + Data  
**Trazabilidad:** RC-08, RC-09

**Como** jugador, **quiero** observar fortalezas movilizadas en varios contextos, **para** elegir cómo usarlas con mayor equilibrio.

### Criterios de aceptación

```gherkin
Escenario: Catálogo acotado
  DADO la versión del casete
  CUANDO se revisa su matriz VIA
  ENTONCES contiene entre 6 y 8 fortalezas aprobadas
  Y cada una aparece en varios contextos

Escenario: Evidencia suficiente
  DADO una fortaleza con al menos tres observaciones válidas
  CUANDO se genera el cierre
  ENTONCES puede describir patrón, contexto y balance tentativo

Escenario: Evidencia insuficiente
  DADO menos de tres observaciones
  CUANDO se genera el cierre
  ENTONCES no se presenta una conclusión individual
  Y puede mostrarse como área aún no observada
```

### UX

- “Subuso”, “uso funcional” o “posible sobreuso” siempre acompañados de ejemplos.
- No presentar las 24 fortalezas como medidas.

### Técnica, datos y seguridad

- Pesos y umbrales versionados; evidencia enlazada a retos.
- Resultado VIA separado de estados empresariales y DISC.

### Dependencias y DoD específico

- `DEC-P-05`, revisión de licencia y HU-CM-006.
- Matriz firmada y golden tests.

---

## HU-EC-007 — Cierre empresarial y plan de práctica

**Tipo:** Funcional + UX + contenido  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** UX + Frontend + Psicología  
**Trazabilidad:** RF-RS-01, RF-RS-02

**Como** jugador, **quiero** cerrar la expedición con un desenlace y prácticas, **para** traducir la simulación a desarrollo personal.

### Criterios de aceptación

```gherkin
Escenario: Cierre
  DADO los 10 retos completados
  CUANDO abre el resultado
  ENTONCES ve desenlace empresarial, evolución de cuatro estados y decisiones clave
  Y en una sección separada ve patrones VIA sustentados

Escenario: Plan
  DADO patrones con evidencia suficiente
  CUANDO se construye el plan
  ENTONCES propone una fortaleza a modular y dos o tres microacciones
  Y permite seleccionar al menos una práctica

Escenario: Separación conceptual
  DADO un desenlace empresarial bajo
  CUANDO se presenta
  ENTONCES no se traduce en baja calidad moral o incapacidad de liderazgo
```

### UX

- Jerarquía: qué ocurrió, qué observé, qué practicaré.
- Sin ranking, nota académica o comparación nominal.

### Técnica, datos y seguridad

- Resultados empresariales y VIA en estructuras diferentes.
- Narrativa IA con fallback; práctica seleccionada persistible.

### Dependencias y DoD específico

- HU-EC-003, HU-EC-006, HU-IA-003.
- Validación de claridad y no estigmatización.

---

## HU-EC-008 — Piloto de balance y comprensión

**Tipo:** Investigación + calidad  
**Prioridad:** Must antes de producción · **Estimación:** 8 SP · **Responsables:** Game Design + Psicología + PM  
**Trazabilidad:** KPI-03, KPI-07, KPI-08, KPI-10

**Como** responsable de producto, **quiero** probar rutas y coaches, **para** balancear decisiones y evitar pistas dominantes.

### Criterios de aceptación

```gherkin
Escenario: Vertical slice
  DADO dos retos conectados con tres coaches y una consecuencia diferida
  CUANDO 5 a 8 líderes los prueban
  ENTONCES se evalúan comprensión, confianza, utilidad y percepción de justicia

Escenario: Balance
  DADO el piloto completo
  CUANDO se analizan elecciones y consultas
  ENTONCES se detectan opciones o coaches dominantes
  Y cada reto con abandono superior al 12% recibe investigación
```

### UX

- Entrevistar sobre sensación de trampa, culpa y claridad de consecuencias.

### Técnica, datos y seguridad

- Separar eventos de piloto y producción.
- Versionar ajustes de contenido y reglas.

### Dependencias y DoD específico

- HU-EC-001 a HU-EC-007.
- Informe de balance y aprobación para producción.

