# Épicas IA, RS, GO y QA — Inteligencia, resultados, gobierno y calidad

**Objetivo:** Convertir resultados estructurados en aprendizaje seguro, proteger los datos y establecer condiciones verificables de calidad.

---

## HU-IA-001 — Generación estructurada de lectura

**Tipo:** IA + backend  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** IA + Backend  
**Trazabilidad:** RF-IA-01, RT-03

**Como** jugador, **quiero** recibir una lectura comprensible de mis resultados, **para** traducir datos en reflexión y práctica.

### Criterios de aceptación

```gherkin
Escenario: Generación válida
  DADO un resultado final estructurado
  CUANDO se solicita una lectura
  ENTONCES la Edge Function envía solo datos mínimos y evidencia autorizada
  Y Gemini devuelve JSON conforme al schema esperado

Escenario: Evidencia
  DADO una afirmación generada
  CUANDO se valida
  ENTONCES corresponde a un indicador o evidencia recibida
  Y no agrega rasgos o hechos desconocidos
```

### UX

- Mostrar progreso breve y permitir continuar si la lectura tarda.
- Separar visualmente dato calculado de interpretación generada.

### Técnica, datos y seguridad

- Llamada solo desde Edge Function; secretos server-side.
- Salida: resumen, evidencias, tensiones, acciones, preguntas y disclaimer.

### Dependencias y DoD específico

- HU-CM-006 y catálogo de recomendaciones aprobado.
- Fixtures de entrada/salida y timeout configurado.

---

## HU-IA-002 — Validación y guardrails del Sherpa

**Tipo:** IA + seguridad  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** IA + Gobierno + Psicología  
**Trazabilidad:** RF-IA-02, RS-SEC-04, RS-SEC-07

**Como** propietario de producto, **quiero** validar toda respuesta del Sherpa, **para** impedir diagnósticos, filtraciones o recomendaciones laborales.

### Criterios de aceptación

```gherkin
Escenario: Respuesta permitida
  DADO una salida con schema, tono y evidencia válidos
  CUANDO pasa los guardrails
  ENTONCES puede mostrarse al usuario

Escenario: Violación
  DADO una salida con diagnóstico, comparación, PII ajena o consejo laboral
  CUANDO se valida
  ENTONCES se descarta por completo
  Y se activa fallback sin mostrar texto parcial

Escenario: Inyección
  DADO contenido de usuario o casete que contiene instrucciones
  CUANDO se arma el prompt
  ENTONCES se trata como dato delimitado
  Y no cambia las instrucciones del sistema
```

### UX

- Tono profesional, cálido, tentativo y colombiano neutral.
- No mostrar mensajes técnicos de moderación al jugador.

### Técnica, datos y seguridad

- Capas: sistema inmutable, plantilla por función, contexto delimitado y validador posterior.
- Suite roja: leakage, inyección, diagnóstico, estigma y consejo laboral.

### Dependencias y DoD específico

- Políticas aprobadas por Gobierno y Psicología.
- 100% de casos rojos bloqueados o sustituidos.

---

## HU-IA-003 — Fallback determinístico y reintento

**Tipo:** Resiliencia + IA  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Backend + Contenido  
**Trazabilidad:** RF-IA-03, RS-SEC-08, RNF-10

**Como** jugador, **quiero** recibir una lectura útil aunque la IA falle, **para** no perder el cierre de la experiencia.

### Criterios de aceptación

```gherkin
Escenario: Timeout
  DADO una generación que supera el umbral
  CUANDO expira
  ENTONCES se realiza como máximo un reintento reducido
  Y luego se entrega una plantilla determinística aprobada

Escenario: Violación
  DADO una respuesta rechazada por guardrails
  CUANDO se activa contingencia
  ENTONCES no se muestra ninguna parte de la salida
  Y se utiliza el fallback

Escenario: Regeneración posterior
  DADO un resultado guardado con fallback
  CUANDO el servicio vuelve a estar disponible y el usuario solicita reintentar
  ENTONCES puede generar una lectura sin recalcular el resultado
```

### UX

- El fallback no se presenta como error incompleto.
- Nunca usar spinner indefinido.

### Técnica, datos y seguridad

- Plantillas por dimensión/rango y casete, versionadas y revisadas.
- Registrar motivo de fallback sin prompt completo.

### Dependencias y DoD específico

- HU-IA-001, HU-IA-002.
- Pruebas de timeout, error de proveedor, schema inválido y bloqueo.

---

## HU-IA-004 — Trazabilidad de IA

**Tipo:** Técnica + gobierno  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Backend + Gobierno  
**Trazabilidad:** RF-IA-04, RT-14, RS-SEC-03

**Como** auditor autorizado, **quiero** conocer qué configuración produjo una lectura, **para** investigar y reproducir su contexto sin exponer PII.

### Criterios de aceptación

```gherkin
Escenario: Registro
  DADO una generación o fallback
  CUANDO finaliza
  ENTONCES registra versión de resultado, prompt, plantilla, modelo, guardrail y estado
  Y conserva un correlation ID

Escenario: Minimización
  DADO un evento de auditoría
  CUANDO se consulta
  ENTONCES no contiene contraseña, token, prompt completo ni respuestas crudas innecesarias
```

### UX

- Vista técnica restringida; no forma parte del perfil del jugador.

### Técnica, datos y seguridad

- Metadatos append-only y retención definida.
- Acceso solo a roles autorizados, auditado.

### Dependencias y DoD específico

- HU-GO-005 y política de logs.
- Prueba de redacción/minimización.

---

## HU-RS-001 — Componente accesible de resultados

**Tipo:** UX + frontend reusable  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** UX + Frontend  
**Trazabilidad:** RF-RS-01, RX-09, RX-10

**Como** jugador, **quiero** consultar resultados visuales y textuales equivalentes, **para** comprenderlos independientemente de mis capacidades.

### Criterios de aceptación

```gherkin
Escenario: Visualización
  DADO un resultado autorizado
  CUANDO abre la vista
  ENTONCES se muestran gráfico, tabla, explicación, evidencia y limitaciones
  Y ninguna interpretación depende solo de color o forma

Escenario: Tecnología asistiva
  DADO un lector de pantalla
  CUANDO recorre el resultado
  ENTONCES recibe etiquetas, valores, orden y explicación equivalentes

Escenario: Resultado parcial
  DADO datos no concluyentes
  CUANDO se renderizan
  ENTONCES se identifican como evidencia insuficiente
  Y no se inventa un cero o promedio
```

### UX

- Radar opcional como complemento; tabla y lenguaje llano como base.
- Responsive, foco lógico y descarga fuera del MVP.

### Técnica, datos y seguridad

- Componente recibe un contrato neutral, no campos `DISC` rígidos.
- Gráfico lazy-loaded; alternativa textual siempre disponible.

### Dependencias y DoD específico

- Contrato de resultados aprobado.
- Auditoría WCAG automatizada y manual.

---

## HU-RS-002 — Separación conceptual de resultados

**Tipo:** Funcional + UX + psicología  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** UX + Psicología  
**Trazabilidad:** RF-RS-02

**Como** jugador, **quiero** distinguir tendencias, fortalezas y desenlace empresarial, **para** no confundir constructos diferentes.

### Criterios de aceptación

```gherkin
Escenario: Dos experiencias completadas
  DADO resultados de Base y Cumbre
  CUANDO se muestran en el perfil
  ENTONCES aparecen en secciones y contratos separados
  Y no existe un puntaje combinado DISC–VIA–empresa

Escenario: Lenguaje
  DADO cualquier resultado
  CUANDO se explica
  ENTONCES distingue preferencia conductual, evidencia de fortaleza y resultado del modelo
```

### UX

- Etiquetas, iconografía y explicaciones propias por lente.
- No usar una única escala de “liderazgo”.

### Técnica, datos y seguridad

- Tipos de resultado discriminados y schemas independientes.

### Dependencias y DoD específico

- `DEC-P-02`, HU-RS-001.
- Prueba de comprensión con usuarios.

---

## HU-RS-003 — Historial personal versionado

**Tipo:** Funcional + datos  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Frontend + Backend  
**Trazabilidad:** RF-RS-03

**Como** jugador, **quiero** consultar mis resultados finalizados por fecha, **para** conservar mi recorrido sin que nuevas versiones lo alteren.

### Criterios de aceptación

```gherkin
Escenario: Historial propio
  DADO varias sesiones completadas autorizadas
  CUANDO abre su perfil
  ENTONCES ve casete, versión, fecha y acceso al resultado

Escenario: Nueva versión
  DADO un casete actualizado
  CUANDO abre un resultado histórico
  ENTONCES conserva datos, lenguaje y reglas de la versión original

Escenario: Acceso ajeno
  DADO el ID de un resultado de otro usuario
  CUANDO intenta consultarlo
  ENTONCES no recibe datos
```

### UX

- Orden cronológico, estados claros y sin comparación automática.

### Técnica, datos y seguridad

- Resultados inmutables; correcciones como nuevas revisiones auditadas.
- RLS por propietario y consentimientos de compartición.

### Dependencias y DoD específico

- HU-CM-006, HU-CA-002.
- Pruebas históricas y cross-user.

---

## HU-GO-001 — Derechos del titular y revocación

**Tipo:** Funcional + legal  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Gobierno + Backend  
**Trazabilidad:** RF-PR-03, RS-SEC-09

**Como** usuario, **quiero** solicitar revisión, revocación o eliminación, **para** ejercer control sobre mis datos.

### Criterios de aceptación

```gherkin
Escenario: Solicitud
  DADO un usuario autenticado
  CUANDO solicita consulta, corrección, revocación o eliminación
  ENTONCES recibe número, alcance y estado de la solicitud
  Y se registra sin ejecutar borrados irreversibles no revisados

Escenario: Revocación
  DADO una revocación válida
  CUANDO se procesa
  ENTONCES se impiden usos futuros afectados
  Y se aplica la política aprobada a datos y derivados
```

### UX

- Lenguaje claro, consecuencias antes de confirmar y canal alternativo.

### Técnica, datos y seguridad

- Workflow de solicitudes; eliminación/anonimización consistente en resultados, IA y logs.
- Preservar únicamente lo exigido por obligación legal, documentando razón.

### Dependencias y DoD específico

- Política de retención y procedimiento legal aprobados.
- Prueba end-to-end de solicitud.

---

## HU-GO-002 — Compartición individual consentida

**Tipo:** Funcional + privacidad  
**Prioridad:** Must si existe vista Coach · **Estimación:** 8 SP · **Responsables:** Gobierno + Backend + UX  
**Trazabilidad:** RF-PR-04

**Como** jugador, **quiero** decidir si un coach puede ver un resultado, **para** conservar control sobre su uso.

### Criterios de aceptación

```gherkin
Escenario: Autorizar
  DADO un coach asignado y un resultado propio
  CUANDO el jugador autoriza alcance y vigencia
  ENTONCES el coach puede consultar únicamente ese resultado
  Y la autorización queda auditada

Escenario: Revocar
  DADO una autorización activa
  CUANDO el jugador la revoca
  ENTONCES nuevos accesos son bloqueados
  Y los accesos anteriores permanecen en auditoría

Escenario: Sin consentimiento
  DADO un coach sin autorización
  CUANDO intenta consultar
  ENTONCES no recibe resultado, respuestas ni chat
```

### UX

- Mostrar quién, qué, para qué y hasta cuándo.
- Sin consentimiento condicionado o casillas premarcadas.

### Técnica, datos y seguridad

- Grants de acceso explícitos y expirables; RLS los consulta.

### Dependencias y DoD específico

- Definición del rol Líder/Coach.
- Pruebas de otorgamiento, expiración y revocación.

---

## HU-GO-003 — Métricas organizacionales agregadas

**Tipo:** Funcional + privacidad  
**Prioridad:** Should · **Estimación:** 8 SP · **Responsables:** Data + Gobierno + Frontend  
**Trazabilidad:** RF-AD-03, RS-SEC-10

**Como** OrgAdmin, **quiero** conocer adopción agregada, **para** evaluar el programa sin perfilar individuos.

### Criterios de aceptación

```gherkin
Escenario: Cohorte suficiente
  DADO una cohorte que cumple el umbral aprobado
  CUANDO consulta métricas
  ENTONCES ve asignación, inicio, finalización y agregados permitidos
  Y no puede derivar respuestas individuales

Escenario: Cohorte pequeña
  DADO una segmentación inferior al umbral
  CUANDO aplica el filtro
  ENTONCES los resultados sensibles se suprimen
  Y se explica la razón
```

### UX

- Vista de participación primero; no rankings ni listas ordenadas por perfil.

### Técnica, datos y seguridad

- Vistas/funciones agregadas server-side; controlar combinaciones de filtros.
- Umbral configurable por política, no en cliente.

### Dependencias y DoD específico

- Umbral y métricas aprobados.
- Pruebas de inferencia por filtros.

---

## HU-GO-004 — Acceso mínimo y auditado de soporte

**Tipo:** Técnica + seguridad + operación  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Backend + Gobierno  
**Trazabilidad:** RF-SP-01, RS-SEC-06

**Como** agente de soporte, **quiero** diagnosticar incidencias con acceso mínimo, **para** ayudar sin consultar datos psicométricos.

### Criterios de aceptación

```gherkin
Escenario: Diagnóstico operativo
  DADO un caso de soporte válido
  CUANDO el agente consulta estado técnico
  ENTONCES ve identificadores operativos, errores y estado de sesión permitidos
  Y no ve respuestas, lectura, chat ni puntajes

Escenario: Acceso excepcional
  DADO una necesidad aprobada que requiere mayor acceso
  CUANDO se concede temporalmente
  ENTONCES tiene alcance, expiración, motivo y aprobador
  Y cada consulta queda auditada
```

### UX

- Vista de soporte separada; datos sensibles redactados por defecto.

### Técnica, datos y seguridad

- Privilegios just-in-time o grants temporales; evitar bypass general de RLS.

### Dependencias y DoD específico

- `DEC-P-04`.
- Pruebas de mínimo privilegio y expiración.

---

## HU-GO-005 — Auditoría transversal

**Tipo:** Técnica + gobierno  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsable:** Backend  
**Trazabilidad:** RT-10

**Como** auditor autorizado, **quiero** rastrear acciones sensibles, **para** investigar cambios y accesos.

### Criterios de aceptación

```gherkin
Escenario: Evento auditable
  DADO una publicación, cambio de rol, acceso de soporte, consentimiento o compartición
  CUANDO ocurre
  ENTONCES registra actor, acción, recurso, organización, fecha y correlation ID

Escenario: Integridad
  DADO un usuario de aplicación
  CUANDO intenta modificar o eliminar auditoría
  ENTONCES se rechaza

Escenario: Consulta
  DADO un auditor con alcance
  CUANDO filtra eventos
  ENTONCES solo recibe eventos autorizados y minimizados
```

### UX

- Filtros por fecha, actor, acción y recurso; exportación fuera del MVP salvo obligación.

### Técnica, datos y seguridad

- Registro append-only, retención y acceso diferenciados.
- No guardar secretos ni contenido psicométrico completo.

### Dependencias y DoD específico

- Taxonomía de auditoría aprobada.
- Pruebas de integridad y alcance.

---

## HU-QA-001 — Accesibilidad, responsive y performance

**Tipo:** No funcional + UX  
**Prioridad:** Must transversal · **Estimación:** 8 SP inicial + validación continua  
**Responsables:** Frontend + QA + UX  
**Trazabilidad:** RX-05 a RX-11, RNF-01, RNF-02, RNF-07

**Como** usuario, **quiero** operar la plataforma con mi dispositivo y tecnología asistiva, **para** completar las experiencias sin barreras.

### Criterios de aceptación

```gherkin
Escenario: Teclado
  DADO cualquier flujo Must
  CUANDO se opera solo con teclado
  ENTONCES todas las acciones son alcanzables, visibles y ordenadas

Escenario: Responsive
  DADO un viewport desde 320 px
  CUANDO recorre login, Hub, runner y resultados
  ENTONCES no pierde contenido ni requiere scroll horizontal

Escenario: Performance
  DADO condiciones de prueba acordadas
  CUANDO carga la consola
  ENTONCES el contenido útil aparece en menos de 3 segundos
  Y cada acción ofrece feedback local en menos de 300 ms
```

### UX

- WCAG 2.2 AA, targets táctiles ≥44×44, foco visible, `aria-live`.
- `prefers-reduced-motion`, contraste AA y mensajes asociados a controles.

### Técnica, datos y seguridad

- Automatización axe/Lighthouse más pruebas manuales.
- Matriz de últimas dos versiones Chrome, Edge, Firefox y Safari.

### Dependencias y DoD específico

- Aplica a todas las HU con interfaz.
- Cero defectos críticos de accesibilidad abiertos al release.

---

## HU-QA-002 — Revisión editorial, psicológica y de juego

**Tipo:** Calidad de contenido  
**Prioridad:** Must transversal · **Estimación:** 8 SP por versión mayor  
**Responsables:** Psicología + Game Design + Gobierno  
**Trazabilidad:** RC-10, RX-12, KPI-10

**Como** responsable del producto, **quiero** revisión multidisciplinaria del contenido, **para** evitar sesgos, estigma, trampas y claims impropios.

### Criterios de aceptación

```gherkin
Escenario: Revisión completa
  DADO una versión candidata
  CUANDO se somete a revisión
  ENTONCES Psicología valida lenguaje y riesgo
  Y Game Design valida ambigüedad y balance
  Y Gobierno valida claims, privacidad y licencia

Escenario: Hallazgo bloqueante
  DADO un ítem moralizante, clínico o no licenciable
  CUANDO se registra el hallazgo
  ENTONCES la publicación queda bloqueada
  Y el ajuste requiere nueva revisión
```

### UX

- Guía de tono: evidencia situada → interpretación tentativa → pregunta → práctica.

### Técnica, datos y seguridad

- Checklist versionado y firmas/aprobaciones vinculadas a la versión.

### Dependencias y DoD específico

- Matriz de revisores y criterios acordada.
- 100% del contenido publicado cuenta con aprobaciones.

---

## HU-QA-003 — Observabilidad y manejo seguro de errores

**Tipo:** Técnica + operación  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Backend + Frontend + QA  
**Trazabilidad:** RF-TL-01, RNF-04, RNF-09

**Como** equipo de operación, **quiero** detectar y correlacionar fallos, **para** recuperar la experiencia sin exponer datos.

### Criterios de aceptación

```gherkin
Escenario: Error correlacionado
  DADO un fallo de API, guardado, scoring o IA
  CUANDO ocurre
  ENTONCES el usuario recibe un mensaje accionable con referencia
  Y los sistemas registran correlation ID, operación y código técnico sin PII

Escenario: Fallo de guardado
  DADO una respuesta confirmada no persistida
  CUANDO se detecta el error
  ENTONCES no se avanza silenciosamente
  Y el usuario puede reintentar con la misma clave idempotente

Escenario: Degradación de IA
  DADO indisponibilidad de Gemini
  CUANDO se genera el cierre
  ENTONCES se activa el fallback
  Y la experiencia puede completarse
```

### UX

- Mensajes narrativos sobrios, pero concretos; nunca ocultar que una acción no se guardó.

### Técnica, datos y seguridad

- Logging estructurado, alertas y redacción.
- Dashboards mínimos para tasa de error, fallback y latencia.

### Dependencias y DoD específico

- Taxonomía de errores/eventos.
- Pruebas de fallos inyectados en flujos críticos.

---

## HU-QA-004 — Suite de seguridad por rol y tenant

**Tipo:** QA técnica + seguridad  
**Prioridad:** Must · **Estimación:** 13 SP · **Responsables:** Backend + QA  
**Trazabilidad:** RNF-03, RS-SEC-01, RS-SEC-02

**Como** propietario de la plataforma, **quiero** una suite automatizada de autorización, **para** prevenir regresiones que expongan datos.

### Criterios de aceptación

```gherkin
Escenario: Matriz positiva
  DADO cuentas de cada rol y organización
  CUANDO ejecutan operaciones autorizadas
  ENTONCES reciben únicamente el alcance esperado

Escenario: Matriz negativa
  DADO IDs válidos de otro usuario u organización
  CUANDO se prueban lectura, escritura, actualización y borrado
  ENTONCES todas las operaciones no autorizadas fallan sin filtrar datos

Escenario: Service role
  DADO una función privilegiada
  CUANDO opera
  ENTONCES valida explícitamente actor, propósito y organización
  Y audita la acción
```

### UX

- No aplica interfaz; los errores 401/403 deben mapearse a estados comprensibles.

### Técnica, datos y seguridad

- Suite en CI con fixtures multi-tenant y políticas RLS reales.
- Cubrir tablas sensibles, Storage y Edge Functions.

### Dependencias y DoD específico

- HU-CA-002 y schema desplegable de prueba.
- Cero casos críticos fallidos antes de release.

---

## HU-QA-005 — Piloto integral y criterios de salida

**Tipo:** Validación de producto  
**Prioridad:** Must antes de release · **Estimación:** 13 SP · **Responsables:** PM + QA + Psicología  
**Trazabilidad:** KPI-01 a KPI-10

**Como** Product Owner, **quiero** evaluar el MVP con usuarios reales, **para** decidir si está listo para una organización piloto.

### Criterios de aceptación

```gherkin
Escenario: Piloto ejecutado
  DADO un MVP en staging con contenido aprobado
  CUANDO participa la muestra acordada
  ENTONCES se recogen activación, finalización, tiempos, coaches, comprensión, utilidad y respeto
  Y se registran defectos y aprendizajes

Escenario: Go/No-Go
  DADO resultados del piloto
  CUANDO el comité revisa umbrales y riesgos
  ENTONCES documenta decisión de liberar, ajustar o detener
  Y asigna responsable a cada condición pendiente
```

### UX

- Combinar métricas con entrevistas; no reducir la decisión a tasa de finalización.

### Técnica, datos y seguridad

- Separar cohortes y telemetría de prueba/producción.
- Consentimiento específico del piloto y análisis de sesgos.

### Dependencias y DoD específico

- HU-EB-005, HU-EC-008 y checklists de seguridad/accesibilidad.
- Acta de Go/No-Go aprobada.

