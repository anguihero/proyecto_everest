# Maestro de Requerimientos — MVP Modular Everest Experience

**Versión:** 0.1  
**Estado:** Borrador para revisión  
**Fecha:** 2026-06-28  
**Fuente de alcance:** `05_context/CONTEXTO_IDEACION_MVP_MODULAR.md`

---

## 1. Objetivo

Definir de manera trazable qué debe construir el MVP de Everest Experience como:

1. **Consola:** plataforma reusable que ejecuta experiencias.
2. **Fábrica:** proceso y capacidades para definir, validar, versionar y publicar casetes.
3. **Casetes iniciales:** Expedición Base y Expedición Cumbre.

---

## 2. Decisiones bloqueantes

| ID | Decisión | Responsable | Estado |
|---|---|---|---|
| DEC-P-01 | Definir si Expedición Base usa DISC licenciado, modelo inspirado o lenguaje genérico | Óscar + Psicología + Gobierno | Pendiente |
| DEC-P-02 | Aprobar “perfil exploratorio” como claim provisional | Óscar + Gobierno | Pendiente |
| DEC-P-03 | Definir si Líder equivale a Coach o supervisor | Óscar | Pendiente |
| DEC-P-04 | Definir permisos y mecanismo de acceso de Soporte | Andrés + Gobierno | Pendiente |
| DEC-P-05 | Aprobar 6–8 fortalezas VIA del casete Cumbre | Psicología + Óscar | Pendiente |
| DEC-P-06 | Aprobar regla de coaches: uno libre + segundo con fichas | Óscar + Game Design | Pendiente |
| DEC-T-01 | Aprobar formato y almacenamiento del contrato de casete | Andrés | Pendiente |
| DEC-T-02 | Aprobar estrategia de versionado inmutable de sesiones | Andrés | Pendiente |
| DEC-L-01 | Verificar licencias y marcas DISC/VIA | Gobierno | Pendiente |

Ninguna HU que dependa de una decisión bloqueante puede pasar a `READY` hasta resolverla.

---

## 3. Requerimientos funcionales

### Identidad y organización

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RF-ID-01 | Autenticar usuarios mediante email y contraseña | Must | HU-CA-001 |
| RF-ID-02 | Recuperar contraseña sin revelar existencia de cuentas | Must | HU-CA-001 |
| RF-ID-03 | Resolver organización y rol al iniciar sesión | Must | HU-CA-002 |
| RF-ID-04 | Permitir al usuario consultar y editar configuración básica | Must | HU-CA-004 |
| RF-ID-05 | Permitir al OrgAdmin crear, activar, inactivar y asignar usuarios | Must | HU-CA-007 |

### Consentimiento y acceso

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RF-PR-01 | Registrar consentimiento versionado antes de iniciar experiencias | Must | HU-CA-003 |
| RF-PR-02 | Mostrar finalidad, datos, IA, visibilidad, retención y derechos | Must | HU-CA-003 |
| RF-PR-03 | Permitir revocar consentimiento y solicitar eliminación/revisión | Must | HU-GO-001 |
| RF-PR-04 | Compartir resultados individuales solo con autorización explícita | Must | HU-GO-002 |

### Catálogo y ejecución

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RF-EX-01 | Mostrar al jugador los casetes asignados y su estado | Must | HU-CA-005 |
| RF-EX-02 | Iniciar una sesión con una versión inmutable del casete | Must | HU-CM-003 |
| RF-EX-03 | Renderizar pasos, escenarios y opciones desde configuración | Must | HU-CM-004 |
| RF-EX-04 | Guardar una respuesta confirmada de forma idempotente | Must | HU-CM-005 |
| RF-EX-05 | Pausar y reanudar desde el último paso confirmado | Must | HU-CM-005 |
| RF-EX-06 | Finalizar una sesión una sola vez y producir resultados | Must | HU-CM-006 |
| RF-EX-07 | Mantener estados de carga, error, acceso y versión retirada | Must | HU-CM-004 |

### Fábrica y versionado

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RF-FB-01 | Representar un casete mediante un contrato estructurado validable | Must | HU-FB-001 |
| RF-FB-02 | Crear versiones borrador, piloto, publicadas y retiradas | Must | HU-FB-002 |
| RF-FB-03 | Validar integridad antes de publicar | Must | HU-FB-003 |
| RF-FB-04 | Probar un casete sin exponerlo a usuarios finales | Must | HU-FB-004 |
| RF-FB-05 | Publicar y retirar sin alterar sesiones históricas | Must | HU-FB-005 |
| RF-FB-06 | Registrar quién aprobó y publicó una versión | Must | HU-FB-005 |

### Scoring, consecuencias y coaches

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RF-SC-01 | Calcular resultados mediante reglas determinísticas versionadas | Must | HU-CM-006 |
| RF-SC-02 | Conservar evidencia que explique cada resultado | Must | HU-CM-006 |
| RF-SC-03 | Actualizar estados empresariales con impactos inmediatos y diferidos | Must | HU-EC-003 |
| RF-SC-04 | Consultar una perspectiva de coach sin revelar la respuesta óptima | Must | HU-EC-004 |
| RF-SC-05 | Controlar el uso de una segunda consulta mediante fichas | Should | HU-EC-004 |
| RF-SC-06 | Mostrar perspectiva omitida después de decidir | Must | HU-EC-005 |

### Resultados e IA

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RF-RS-01 | Mostrar resultados propios con visual y alternativa textual | Must | HU-RS-001 |
| RF-RS-02 | Mantener separados los resultados DISC/VIA/empresa | Must | HU-RS-002 |
| RF-RS-03 | Conservar historial de resultados por versión y fecha | Must | HU-RS-003 |
| RF-IA-01 | Generar una lectura desde resultados estructurados | Must | HU-IA-001 |
| RF-IA-02 | Validar formato y guardrails antes de mostrar la lectura | Must | HU-IA-002 |
| RF-IA-03 | Usar fallback aprobado si Gemini falla o viola reglas | Must | HU-IA-003 |
| RF-IA-04 | Registrar versiones de prompt, modelo, plantilla y fallback | Must | HU-IA-004 |

### Administración, soporte y analítica

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RF-AD-01 | Asignar casetes a usuarios o cohortes | Must | HU-CA-008 |
| RF-AD-02 | Consultar avance operativo sin respuestas sensibles | Must | HU-CA-008 |
| RF-AD-03 | Mostrar métricas agregadas con umbral mínimo | Should | HU-GO-003 |
| RF-SP-01 | Atender incidencias mediante acceso mínimo y auditado | Must | HU-GO-004 |
| RF-TL-01 | Registrar eventos de inicio, respuesta, pausa, finalización y error | Must | HU-QA-003 |

---

## 4. Requerimientos UX y accesibilidad

| ID | Requerimiento | Umbral | HU |
|---|---|---|---|
| RX-01 | Onboarding comprensible | ≤60 segundos | HU-CA-006 |
| RX-02 | Mostrar un escenario por pantalla | Siempre | HU-CM-004 |
| RX-03 | Mostrar un único CTA principal | Siempre | HU-CM-004 |
| RX-04 | Mantener progreso visible | Paso actual / total | HU-CM-004 |
| RX-05 | Mostrar confirmación visual de interacción | <300 ms | HU-QA-001 |
| RX-06 | Permitir guardar y salir sin penalización | Siempre | HU-CM-005 |
| RX-07 | Operar desde viewport móvil | Desde 320 px | HU-QA-001 |
| RX-08 | Operar completamente con teclado | WCAG 2.2 AA | HU-QA-001 |
| RX-09 | No depender exclusivamente del color | Siempre | HU-RS-001 |
| RX-10 | Acompañar radares con tabla textual | Siempre | HU-RS-001 |
| RX-11 | Respetar reducción de movimiento | `prefers-reduced-motion` | HU-QA-001 |
| RX-12 | Evitar lenguaje clínico, fijo o estigmatizante | 100% del contenido | HU-QA-002 |
| RX-13 | Mostrar estimación de duración antes de iniciar | Siempre | HU-EB-002, HU-EC-002 |
| RX-14 | No usar temporizadores en el MVP | 0 temporizadores obligatorios | Todas |

---

## 5. Requerimientos técnicos y de datos

| ID | Requerimiento | Umbral | HU |
|---|---|---|---|
| RT-01 | Supabase Auth como proveedor de identidad | Arquitectura aprobada | HU-CA-001 |
| RT-02 | RLS por `user_id` y `org_id` | 0 fugas cross-tenant | HU-CA-002 |
| RT-03 | Edge Functions para secretos y Gemini | Sin llamadas directas cliente–Gemini | HU-IA-001 |
| RT-04 | Contrato de casete validado por schema | 100% antes de publicar | HU-FB-001 |
| RT-05 | Sesiones ligadas a versión inmutable | 100% | HU-CM-003 |
| RT-06 | Idempotency key por respuesta | Sin duplicados | HU-CM-005 |
| RT-07 | Base de datos como fuente de verdad | Siempre | HU-CM-005 |
| RT-08 | `localStorage` solo como caché no sensible | Sin perfiles completos | HU-CM-005 |
| RT-09 | Cálculo autoritativo en backend | 100% | HU-CM-006 |
| RT-10 | Auditoría de accesos y publicaciones | Actor, fecha y acción | HU-GO-005 |
| RT-11 | Primera carga usable | <3 segundos en objetivo acordado | HU-QA-001 |
| RT-12 | Manejo de conflicto de sesión | Sin pérdida silenciosa | HU-CM-005 |
| RT-13 | Separación de contenido y componentes UI | 100% de casetes | HU-FB-001 |
| RT-14 | Versionar scoring, prompt y resultado | 100% | HU-IA-004 |

### Entidades conceptuales

- `organizations`
- `profiles`
- `role_assignments`
- `consent_records`
- `experience_definitions`
- `experience_versions`
- `experience_assignments`
- `experience_sessions`
- `session_answers`
- `coach_consultations`
- `state_events`
- `score_results`
- `result_evidence`
- `generated_readings`
- `prompt_versions`
- `audit_events`
- `support_access_events`

Los nombres finales se definirán en el diseño de schema.

---

## 6. Requerimientos de seguridad, privacidad e IA

| ID | Requerimiento | Prioridad | HU |
|---|---|:---:|---|
| RS-SEC-01 | Impedir acceso entre organizaciones | Must | HU-CA-002 |
| RS-SEC-02 | Aplicar mínimo privilegio a todos los roles | Must | HU-CA-002 |
| RS-SEC-03 | No registrar prompts completos con PII | Must | HU-IA-004 |
| RS-SEC-04 | Separar conversaciones y resultados de otros usuarios | Must | HU-IA-002 |
| RS-SEC-05 | No revelar si una cuenta existe | Must | HU-CA-001 |
| RS-SEC-06 | Auditar accesos excepcionales de soporte | Must | HU-GO-004 |
| RS-SEC-07 | Prohibir diagnóstico clínico y decisión laboral automatizada | Must | HU-IA-002 |
| RS-SEC-08 | Descartar completamente salidas que violen guardrails | Must | HU-IA-003 |
| RS-SEC-09 | Permitir borrado/revisión según política aprobada | Must | HU-GO-001 |
| RS-SEC-10 | Agregar datos organizacionales bajo umbral de cohorte | Should | HU-GO-003 |

---

## 7. Requerimientos de contenido

| ID | Requerimiento | HU |
|---|---|---|
| RC-01 | Expedición Base contiene 10 escenarios y cuatro opciones plausibles | HU-EB-001 |
| RC-02 | Base cubre presión, conflicto, cambio, influencia y calidad/riesgo | HU-EB-001 |
| RC-03 | Base no muestra scoring ni feedback valorativo durante la ejecución | HU-EB-002 |
| RC-04 | Cumbre contiene una empresa y 10 retos conectados | HU-EC-001 |
| RC-05 | Cumbre usa Caja, Confianza, Personas y Ejecución | HU-EC-003 |
| RC-06 | Cada opción de Cumbre tiene trade-offs y consecuencias explicables | HU-EC-003 |
| RC-07 | Cada coach aporta una lente y un punto ciego | HU-EC-004 |
| RC-08 | VIA utiliza únicamente 6–8 fortalezas aprobadas | HU-EC-006 |
| RC-09 | Una conclusión VIA requiere al menos tres evidencias | HU-EC-006 |
| RC-10 | Todo contenido pasa revisión psicológica, editorial y de juego | HU-QA-002 |

---

## 8. Requerimientos no funcionales

| ID | Categoría | Requerimiento | Verificación |
|---|---|---|---|
| RNF-01 | Performance | Primera carga <3 s; feedback local <300 ms | Pruebas Lighthouse y navegador |
| RNF-02 | Accesibilidad | WCAG 2.2 AA, teclado y lector de pantalla | Auditoría automatizada + manual |
| RNF-03 | Seguridad | 0 accesos cross-tenant | Suite RLS con usuarios reales |
| RNF-04 | Resiliencia | Ninguna respuesta confirmada se pierde silenciosamente | Pruebas de red y refresh |
| RNF-05 | Trazabilidad | Toda sesión conserva versiones de casete y scoring | Consulta de auditoría |
| RNF-06 | Privacidad | Minimización, consentimiento y borrado verificables | Checklist legal y pruebas |
| RNF-07 | Compatibilidad | Últimas dos versiones de Chrome, Edge, Firefox y Safari | Matriz cross-browser |
| RNF-08 | Mantenibilidad | Contenido separado del runner | Revisión arquitectónica |
| RNF-09 | Observabilidad | Errores críticos correlacionables sin PII | Pruebas de logs |
| RNF-10 | IA segura | 100% de respuestas validadas o sustituidas por fallback | Suite de evals |

---

## 9. Métricas de producto

| ID | Métrica | Objetivo piloto |
|---|---|---:|
| KPI-01 | Inicio después del onboarding | ≥80% |
| KPI-02 | Finalización Expedición Base | ≥75% |
| KPI-03 | Finalización Expedición Cumbre | ≥65% |
| KPI-04 | Comprensión del carácter no clínico | ≥80% |
| KPI-05 | Utilidad percibida | ≥4/5 |
| KPI-06 | Identificación de una acción personal | ≥70% |
| KPI-07 | Uso de al menos un coach | ≥70% |
| KPI-08 | Lenguaje percibido como respetuoso | ≥80% |
| KPI-09 | Accesos indebidos entre organizaciones | 0 |
| KPI-10 | Escenarios revisados por expertos | 100% |

---

## 10. Matriz de trazabilidad por épica

| Épica | Resultado | Requerimientos principales | Archivo |
|---|---|---|---|
| CA | Acceso seguro y experiencia por rol | RF-ID, RF-PR, RF-AD | `01_CONSOLA_IDENTIDAD_Y_ACCESO.md` |
| CM | Consola reusable | RF-EX, RF-SC | `02_CONSOLA_MOTOR_Y_FABRICA.md` |
| FB | Fábrica controlada de casetes | RF-FB | `02_CONSOLA_MOTOR_Y_FABRICA.md` |
| EB | Exploración conductual | RC-01 a RC-03 | `03_CASETE_EXPEDICION_BASE.md` |
| EC | Simulación empresarial y VIA | RC-04 a RC-09 | `04_CASETE_EXPEDICION_CUMBRE.md` |
| IA/RS | Lectura y resultados seguros | RF-RS, RF-IA | `05_IA_RESULTADOS_GOBIERNO_Y_CALIDAD.md` |
| GO/QA | Privacidad, soporte y calidad | RS-SEC, RNF | `05_IA_RESULTADOS_GOBIERNO_Y_CALIDAD.md` |

---

## 11. Definition of Ready global

Una HU puede entrar a desarrollo cuando:

- sus decisiones bloqueantes están resueltas;
- tiene criterios de aceptación verificables;
- contrato de API o datos acordado cuando aplica;
- wireframe o flujo aprobado cuando aplica;
- contenido aprobado cuando aplica;
- dependencias identificadas;
- estimación refinada;
- requisitos de seguridad y privacidad revisados.

## 12. Definition of Done global

- criterios Gherkin verificados;
- pruebas unitarias/integración/E2E proporcionales al riesgo;
- estados de carga, vacío, error y éxito implementados;
- accesibilidad y responsive validados;
- RLS probada para todos los roles afectados;
- sin datos sensibles en logs o cliente;
- telemetría esperada emitida;
- documentación y trazabilidad actualizadas;
- revisión funcional, técnica y de UX completada;
- aceptación del PO en staging.

