# Épicas CM y FB — Motor modular y fábrica de casetes

**Objetivo:** Construir la consola reusable y el ciclo controlado de creación/publicación de experiencias.

---

## HU-CM-001 — Catálogo técnico de casetes

**Tipo:** Habilitadora técnica  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsable:** Backend  
**Trazabilidad:** RF-EX-01, RT-13

**Como** consola, **quiero** consultar definiciones y versiones autorizadas, **para** ejecutar diferentes casetes sin lógica específica embebida.

### Criterios de aceptación

```gherkin
Escenario: Versión disponible
  DADO un casete publicado y asignado
  CUANDO la consola solicita sus metadatos
  ENTONCES recibe únicamente la versión autorizada y compatible

Escenario: Borrador
  DADO una versión en borrador
  CUANDO un jugador intenta acceder
  ENTONCES no se entrega su contenido

Escenario: Aislamiento
  DADO un casete restringido a otra organización
  CUANDO se consulta desde la organización actual
  ENTONCES no se revela su existencia ni contenido
```

### UX

- No aplica interfaz directa; debe habilitar estados claros en Hub y runner.

### Técnica, datos y seguridad

- `experience_definitions`, `experience_versions`; metadatos separados de payload.
- Cache solo por versión inmutable y alcance autorizado.

### Dependencias y DoD específico

- HU-FB-001 y HU-CA-002.
- Pruebas de estado, organización y versión.

---

## HU-CM-002 — Asignabilidad y compatibilidad de casetes

**Tipo:** Habilitadora técnica + funcional  
**Prioridad:** Must · **Estimación:** 3 SP · **Responsable:** Backend  
**Trazabilidad:** RF-EX-01, RF-AD-01

**Como** administrador, **quiero** que solo se asignen casetes compatibles y vigentes, **para** evitar experiencias que la consola no pueda ejecutar.

### Criterios de aceptación

```gherkin
Escenario: Compatible
  DADO una versión publicada compatible con la consola
  CUANDO se asigna a una audiencia permitida
  ENTONCES la asignación es creada

Escenario: Incompatible
  DADO una versión que requiere capacidades no disponibles
  CUANDO se intenta asignar
  ENTONCES se rechaza con una razón accionable
```

### UX

- El administrador ve estado, compatibilidad y motivo de bloqueo.

### Técnica, datos y seguridad

- Declarar `schema_version`, capacidades requeridas y audiencia.
- Validación server-side, no solo deshabilitado visual.

### Dependencias y DoD específico

- HU-FB-001, HU-FB-003.
- Casos de compatibilidad automatizados.

---

## HU-CM-003 — Inicio de sesión versionada de experiencia

**Tipo:** Funcional + técnica  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsable:** Backend  
**Trazabilidad:** RF-EX-02, RT-05

**Como** jugador, **quiero** iniciar una experiencia asignada, **para** recorrer exactamente la versión que acepté comenzar.

### Criterios de aceptación

```gherkin
Escenario: Inicio válido
  DADO una asignación vigente y consentimiento válido
  CUANDO el jugador inicia
  ENTONCES se crea una única sesión ligada a la versión publicada
  Y el primer paso queda disponible

Escenario: Inicio repetido
  DADO una sesión activa
  CUANDO el jugador pulsa iniciar otra vez
  ENTONCES se devuelve la sesión existente
  Y no se duplica el progreso

Escenario: Casete actualizado
  DADO una sesión iniciada con versión 1 y una versión 2 publicada
  CUANDO el jugador continúa
  ENTONCES conserva la versión 1
```

### UX

- Mostrar duración, propósito, privacidad y CTA “Iniciar expedición”.
- Evitar doble envío y comunicar creación/reanudación.

### Técnica, datos y seguridad

- `experience_sessions` con versión, estado e idempotency key de inicio.
- Validar asignación, consentimiento, rol y organización en una transacción.

### Dependencias y DoD específico

- HU-CA-003, HU-CM-001.
- Pruebas concurrentes de inicio único.

---

## HU-CM-004 — Runner genérico de pasos y elecciones

**Tipo:** Funcional + UX + frontend  
**Prioridad:** Must · **Estimación:** 13 SP · **Responsables:** UX + Frontend + Backend  
**Trazabilidad:** RF-EX-03, RF-EX-07, RX-02, RX-03, RX-04

**Como** jugador, **quiero** recorrer escenarios consistentes, **para** concentrarme en una decisión a la vez.

### Criterios de aceptación

```gherkin
Escenario: Renderizado
  DADO una sesión activa con un paso pendiente
  CUANDO se carga el runner
  ENTONCES muestra narrativa, opciones, progreso y acciones definidas por el casete
  Y no expone pesos ni reglas privadas

Escenario: Confirmación
  DADO una opción seleccionada
  CUANDO el jugador confirma
  ENTONCES bloquea temporalmente un segundo envío
  Y delega el guardado autoritativo al backend

Escenario: Estado no soportado
  DADO contenido inválido o capacidad no soportada
  CUANDO el runner intenta cargar
  ENTONCES muestra error recuperable
  Y registra diagnóstico sin PII
```

### UX

- Un escenario por pantalla, radios/controles nativos y CTA deshabilitado hasta elegir.
- Progreso `n de total`, “Guardar y salir” y feedback local <300 ms.
- Estados carga, vacío, error, guardando, guardado, completado y acceso denegado.

### Técnica, datos y seguridad

- Componentes configurables: ScenarioCard, ChoiceGroup, Progress, CoachSlot y FeedbackPanel.
- Sanitizar contenido; no usar HTML arbitrario desde el casete.
- Pesos y claves de scoring no llegan al cliente antes de responder.

### Dependencias y DoD específico

- HU-FB-001, HU-CM-003.
- Tests de componentes, teclado, mobile, doble envío y contenido inválido.

---

## HU-CM-005 — Autosave, pausa, reanudación y concurrencia

**Tipo:** Funcional + técnica  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Frontend + Backend  
**Trazabilidad:** RF-EX-04, RF-EX-05, RT-06, RT-07, RT-08, RT-12

**Como** jugador, **quiero** que cada decisión confirmada se conserve, **para** retomar sin perder progreso.

### Criterios de aceptación

```gherkin
Escenario: Guardado idempotente
  DADO un paso pendiente
  CUANDO se confirma dos veces con la misma clave
  ENTONCES existe una sola respuesta autoritativa
  Y se devuelve el mismo resultado de operación

Escenario: Reanudación
  DADO una sesión pausada con tres pasos confirmados
  CUANDO el jugador regresa
  ENTONCES abre el cuarto paso
  Y conserva estados y consumos acumulados

Escenario: Conflicto
  DADO la misma sesión abierta en dos pestañas
  CUANDO una pestaña avanza y la otra intenta responder un paso anterior
  ENTONCES se rechaza el estado obsoleto
  Y se ofrece recargar sin sobrescribir datos
```

### UX

- Indicadores guardando/guardado mediante `aria-live`.
- Una selección no confirmada no se considera respuesta.
- Salir no penaliza ni obliga a confirmar.

### Técnica, datos y seguridad

- Transacción por paso; índice único `(session_id, step_id)`.
- Optimistic concurrency/version counter.
- `localStorage` solo guarda señal de recuperación no sensible.

### Dependencias y DoD específico

- HU-CM-003 y HU-CM-004.
- Pruebas offline, refresh, timeout, pestañas concurrentes e idempotencia.

---

## HU-CM-006 — Scoring y finalización determinísticos

**Tipo:** Técnica + funcional crítica  
**Prioridad:** Must · **Estimación:** 13 SP · **Responsable:** Backend/Data  
**Trazabilidad:** RF-EX-06, RF-SC-01, RF-SC-02, RT-09

**Como** responsable de producto, **quiero** resultados reproducibles y explicables, **para** que la IA y el frontend no alteren la medición.

### Criterios de aceptación

```gherkin
Escenario: Finalización
  DADO una sesión con todos los pasos requeridos
  CUANDO se finaliza
  ENTONCES el backend calcula una vez con la versión ligada
  Y persiste puntajes, evidencia, limitaciones y estado completado

Escenario: Repetición
  DADO una sesión completada
  CUANDO se solicita finalizar nuevamente
  ENTONCES devuelve el resultado existente
  Y no recalcula con reglas nuevas

Escenario: Incompleta
  DADO una sesión con pasos obligatorios pendientes
  CUANDO se intenta finalizar
  ENTONCES se rechaza indicando los pasos pendientes
```

### UX

- Mostrar estado de cálculo sin puntajes parciales que sesguen la experiencia.
- Si falla, conservar respuestas y permitir reintentar.

### Técnica, datos y seguridad

- Función autoritativa, versionada y cubierta con fixtures conocidos.
- `score_results` y `result_evidence`; hashes/versiones de reglas.
- La IA recibe el resultado, nunca participa del cálculo.

### Dependencias y DoD específico

- Scoring aprobado por experto y HU-FB-003.
- Golden tests de resultados y auditoría de versión.

---

## HU-FB-001 — Contrato estructurado de casete

**Tipo:** Arquitectura + fábrica  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsable:** Backend/Arquitectura  
**Trazabilidad:** RF-FB-01, RT-04, RT-13

**Como** diseñador de experiencias, **quiero** una especificación común de casete, **para** crear rutas sin modificar el runner.

### Criterios de aceptación

```gherkin
Escenario: Contrato válido
  DADO una definición con identidad, pasos, dimensiones, reglas, feedback y resultado
  CUANDO se valida contra el schema
  ENTONCES se acepta y produce una versión normalizada

Escenario: Contrato inválido
  DADO referencias rotas, IDs duplicados o capacidad desconocida
  CUANDO se valida
  ENTONCES se rechaza con errores por ruta de propiedad

Escenario: Extensibilidad
  DADO dos casetes de tipos diferentes
  CUANDO los ejecuta la consola
  ENTONCES ambos usan el mismo ciclo de sesión
  Y sus capacidades particulares se declaran explícitamente
```

### UX

- Los mensajes de validación deben ser accionables para el equipo creador.

### Técnica, datos y seguridad

- JSON Schema o equivalente versionado; sin código ejecutable dentro del contenido.
- IDs estables, referencias internas, locales de texto y capabilities.
- El contrato no debe asumir DISC, VIA, 10 pasos o 4 opciones.

### Dependencias y DoD específico

- `DEC-T-01`.
- Schema, ejemplos Base/Cumbre y suite válida/inválida documentados.

---

## HU-FB-002 — Ciclo de vida y versionado del casete

**Tipo:** Fábrica + gobierno  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsable:** Backend  
**Trazabilidad:** RF-FB-02, RT-05

**Como** editor autorizado, **quiero** crear nuevas versiones sin mutar las publicadas, **para** conservar reproducibilidad.

### Criterios de aceptación

```gherkin
Escenario: Nueva versión
  DADO un casete existente
  CUANDO se inicia una revisión
  ENTONCES se crea un borrador con nueva versión
  Y la publicada permanece inmutable

Escenario: Transición inválida
  DADO un casete retirado o un usuario sin permiso
  CUANDO intenta cambiar su estado
  ENTONCES se rechaza y audita el intento
```

### UX

- Mostrar claramente borrador, piloto, publicado y retirado.

### Técnica, datos y seguridad

- Máquina de estados explícita; contenido publicado append-only.
- Permisos editor, revisor y publicador, aunque inicialmente recaigan en SysAdmin.

### Dependencias y DoD específico

- HU-FB-001 y matriz de permisos de fábrica.
- Pruebas de inmutabilidad y transiciones.

---

## HU-FB-003 — Validación integral prepublicación

**Tipo:** Fábrica + QA técnica  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Backend + QA  
**Trazabilidad:** RF-FB-03

**Como** publicador, **quiero** validar un casete antes de liberarlo, **para** evitar experiencias incompletas o no explicables.

### Criterios de aceptación

```gherkin
Escenario: Validación aprobada
  DADO una versión completa
  CUANDO se ejecuta la validación
  ENTONCES verifica schema, referencias, cobertura, scoring, resultados y fallbacks
  Y genera un reporte aprobado

Escenario: Error bloqueante
  DADO una opción sin consecuencia o una dimensión sin evidencia suficiente
  CUANDO se valida
  ENTONCES se bloquea la publicación
  Y el reporte identifica el elemento exacto
```

### UX

- Reporte agrupado por errores bloqueantes y advertencias.

### Técnica, datos y seguridad

- Validadores automáticos más checks de aprobaciones humanas.
- Conservar reporte, versión de validador y responsable.

### Dependencias y DoD específico

- HU-FB-001, matriz de revisión psicológica/editorial.
- Fixtures que demuestren cada regla.

---

## HU-FB-004 — Modo de prueba de casetes

**Tipo:** Fábrica + funcional  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Frontend + Backend  
**Trazabilidad:** RF-FB-04

**Como** revisor autorizado, **quiero** ejecutar un borrador en modo prueba, **para** revisar la experiencia antes de publicarla.

### Criterios de aceptación

```gherkin
Escenario: Preview autorizado
  DADO un revisor y un borrador válido
  CUANDO inicia modo prueba
  ENTONCES recorre el runner con una marca visible de preview
  Y los datos no se mezclan con métricas ni resultados reales

Escenario: Jugador no autorizado
  DADO un usuario final
  CUANDO intenta abrir el enlace de preview
  ENTONCES se deniega el acceso
```

### UX

- Banner persistente “Modo prueba”, selector de paso y reinicio controlado.

### Técnica, datos y seguridad

- Sesiones de prueba separadas o marcadas y excluidas de KPI.
- No compartir URLs que eludan autorización.

### Dependencias y DoD específico

- HU-CM-004, HU-FB-002.
- Pruebas de exclusión analítica y permisos.

---

## HU-FB-005 — Publicación, retiro y auditoría

**Tipo:** Fábrica + gobierno  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Backend + Gobierno  
**Trazabilidad:** RF-FB-05, RF-FB-06, RT-10

**Como** publicador autorizado, **quiero** publicar o retirar una versión aprobada, **para** controlar qué experiencias pueden iniciarse.

### Criterios de aceptación

```gherkin
Escenario: Publicación
  DADO un borrador con validaciones y aprobaciones vigentes
  CUANDO el publicador confirma
  ENTONCES la versión queda inmutable y asignable
  Y se auditan actor, fecha, reporte y aprobaciones

Escenario: Retiro
  DADO una versión publicada
  CUANDO se retira con motivo
  ENTONCES no admite nuevas sesiones
  Y las sesiones iniciadas e históricas siguen su política aprobada
```

### UX

- Confirmación que explica consecuencias; motivo obligatorio para retiro.

### Técnica, datos y seguridad

- Operación transaccional y con privilegio server-side.
- Auditoría append-only; nunca borrar la definición usada por resultados.

### Dependencias y DoD específico

- HU-FB-003 y aprobaciones definidas.
- Pruebas de publicación, retiro y continuidad histórica.

---

## HU-CM-007 — Telemetría común de experiencias

**Tipo:** Técnica + analítica  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsable:** Backend/Data  
**Trazabilidad:** RF-TL-01, RNF-09

**Como** equipo de producto, **quiero** eventos comunes entre casetes, **para** medir uso y detectar fallos sin invadir privacidad.

### Criterios de aceptación

```gherkin
Escenario: Eventos funcionales
  DADO una sesión
  CUANDO inicia, responde, pausa, consulta coach, finaliza o falla
  ENTONCES se registra un evento con versión, tipo y timestamp
  Y no incluye texto libre, respuesta completa ni PII innecesaria

Escenario: Reintento
  DADO una entrega repetida del mismo evento
  CUANDO se procesa
  ENTONCES no duplica las métricas
```

### UX

- La telemetría no bloquea la acción principal.

### Técnica, datos y seguridad

- Taxonomía versionada, correlation IDs e idempotencia.
- Retención y acceso diferenciados de los datos de resultado.

### Dependencias y DoD específico

- Política de analítica aprobada.
- Diccionario de eventos y pruebas de ausencia de PII.

