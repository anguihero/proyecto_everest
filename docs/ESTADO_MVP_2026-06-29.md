# Estado verificado del MVP — 29 de junio de 2026

## Dictamen ejecutivo

El producto tiene un **vertical slice funcional de Expedición Base**: autenticación,
onboarding/consentimiento, Hub, asignación, runner de 20 preguntas, persistencia,
scoring DISC y resultados. El flujo fue verificado contra el Supabase remoto.

Eso permite considerarlo un **prototipo funcional demostrable**, pero no el MVP
modular completo definido en `user_stories/mvp_modular`. Faltan capacidades Must
de fábrica, Expedición Cumbre, IA, gobierno, observabilidad, seguridad y piloto.
Además, existen dos bugs operativos que impiden declarar listo el piloto:

1. las asignaciones iniciadas o revocadas pueden quedar bloqueadas;
2. algunos jugadores reciben un error genérico al abrir una experiencia asignada.

### Semáforo usado

- ✅ Implementada: hay evidencia funcional suficiente para el alcance actual.
- 🟡 Parcial: existe implementación, pero falta parte del criterio de aceptación,
  validación o cierre de calidad.
- 🔴 No implementada: no hay flujo funcional correspondiente.
- 🐞 Regresión/bloqueo: existe implementación, pero un bug impide aceptarla.

## Estado actualizado de todas las HUs

### Consola de identidad y acceso

| HU | Estado | Evidencia o brecha |
|---|---|---|
| HU-CA-001 Autenticación y recuperación | 🟡 Parcial | Login/logout funcionan. Recuperación redirige a `reset-password.html`, archivo inexistente. |
| HU-CA-002 Organización, rol y autorización | 🟡 Parcial | Perfiles, roles y RLS implementados; falta suite de aislamiento y mínimo privilegio. |
| HU-CA-003 Consentimiento informado | ✅ Implementada | Registro versionado integrado al onboarding y exigido al iniciar sesión. |
| HU-CA-004 Perfil y configuración | 🔴 No implementada | No existe pantalla o flujo de edición de preferencias. |
| HU-CA-005 Hub y catálogo personal | ✅ Implementada | `get_player_hub` y tarjetas por estado operan contra Supabase. |
| HU-CA-006 Onboarding inicial | ✅ Implementada | Flujo de tres pasos y versión persistida. |
| HU-CA-007 Gestión de usuarios | 🟡 Parcial | Listado e invitación presentes; faltan activar/inactivar/editar y pruebas E2E. |
| HU-CA-008 Asignación y seguimiento | 🐞 Regresión/bloqueo | Crear/listar funciona parcialmente; eliminar/reasignar puede quedar bloqueado y falta contrato de cancelación. |

### Motor modular y fábrica

| HU | Estado | Evidencia o brecha |
|---|---|---|
| HU-CM-001 Catálogo técnico | 🟡 Parcial | Definiciones/versiones y filtro `published` existen; sin pruebas de aislamiento/compatibilidad. |
| HU-CM-002 Asignabilidad y compatibilidad | 🟡 Parcial | Se selecciona última versión publicada, pero no se validan capabilities ni vigencia completa. |
| HU-CM-003 Inicio de sesión versionada | 🐞 Regresión/bloqueo | RPC desplegada; manejo de error oculta causa y falta protección concurrente `UNIQUE(assignment_id)`. |
| HU-CM-004 Runner genérico | 🟡 Parcial | Ejecuta escenarios de opciones; no soporta todos los tipos/capabilities declarados. |
| HU-CM-005 Autosave y concurrencia | 🟡 Parcial | Guardado por paso e idempotency key; sin resolución de conflictos ni pruebas concurrentes. |
| HU-CM-006 Scoring y finalización | 🟡 Parcial avanzado | Scoring autoritativo v1/v2, evidencia, fingerprint e IDs auditables; sigue acoplado a DISC y falta suite golden. |
| HU-CM-007 Telemetría común | 🔴 No implementada | Hay estructura SQL, pero el flujo no emite la taxonomía requerida ni existe monitoreo. |
| HU-FB-001 Contrato de casete | 🟡 Parcial | Schema y ensamblador presentes; no existe pipeline obligatorio de validación semántica. |
| HU-FB-002 Ciclo de vida y versiones | 🟡 Parcial | Estados y trigger de inmutabilidad existen; scripts migran asignaciones activas entre versiones. |
| HU-FB-003 Validación prepublicación | 🔴 No implementada | No hay validador, fixtures ni bloqueo de publicación inválida. |
| HU-FB-004 Modo de prueba | 🔴 No implementada | No existe sandbox/piloto aislado. |
| HU-FB-005 Publicación y retiro | 🟡 Parcial | Se realiza mediante SQL; sin workflow aprobado, UI ni auditoría completa. |

### Expedición Base

| HU | Estado | Evidencia o brecha |
|---|---|---|
| HU-EB-001 Banco de escenarios Base | 🟡 Parcial | Banco de 20 preguntas cargado; falta evidencia de aprobación editorial/psicológica. |
| HU-EB-002 Ejecución neutral Base | 🟡 Parcial | Runner funcional, pero muestra feedback durante la ejecución e incorpora temporizador contrario a RX-14. |
| HU-EB-003 Scoring Base | 🟡 Parcial | Ponderación DISC v2 implementada; falta validación psicométrica y golden tests. |
| HU-EB-004 Resultado conductual | 🟡 Parcial | Pantalla DISC básica; faltan limitaciones, evidencia explicable y contenido aprobado. |
| HU-EB-005 Piloto de ítems | 🔴 No implementada | No hay protocolo, métricas ni resultados de piloto. |

### Expedición Cumbre

| HU | Estado | Evidencia o brecha |
|---|---|---|
| HU-EC-001 a HU-EC-008 | 🔴 No implementadas | No existe casete Cumbre ejecutable, estados empresariales, coaches, VIA, cierre ni piloto. |

### IA, resultados, gobierno y calidad

| HU | Estado | Evidencia o brecha |
|---|---|---|
| HU-IA-001 a HU-IA-004 | 🔴 No implementadas | Existen tablas, pero no generación Gemini, guardrails, fallback ni trazabilidad funcional. |
| HU-RS-001 Resultados accesibles | 🟡 Parcial avanzado | Radar SVG accesible, distribución textual y métrica de tiempo implementados; falta auditoría WCAG integral. |
| HU-RS-002 Separación conceptual | 🔴 No implementada | Solo existe resultado DISC. |
| HU-RS-003 Historial personal | 🟡 Parcial avanzado | Biblioteca por alcance implementada; faltan filtros/paginación e historial dedicado del Player. |
| HU-GO-001 Derechos del titular | 🔴 No implementada | Sin UI de revocación, revisión o eliminación. |
| HU-GO-002 Compartición consentida | 🟡 Requiere decisión | Líder y OrgAdmin acceden por organización según decisión solicitada; falta conciliarlo formalmente con consentimiento individual. |
| HU-GO-003 Métricas agregadas | 🔴 No implementada | No hay agregación con umbral de privacidad. |
| HU-GO-004 Soporte auditado | 🔴 No implementada | Sin flujo de acceso excepcional. |
| HU-GO-005 Auditoría transversal | 🟡 Parcial | Tablas/funciones base presentes; acciones críticas no están instrumentadas integralmente. |
| HU-QA-001 Accesibilidad y performance | 🟡 Parcial | Hay HTML responsive y foco básico; faltan mediciones y auditoría WCAG 2.2 AA. |
| HU-QA-002 Revisión de contenido | 🔴 No implementada | No hay matriz ni evidencia de aprobación. |
| HU-QA-003 Observabilidad y errores | 🐞 Regresión/bloqueo | El runner sustituye el error backend por un mensaje genérico y no registra correlación. |
| HU-QA-004 Suite de seguridad | 🔴 No implementada | No existen pruebas automatizadas. |
| HU-QA-005 Piloto integral | 🔴 No implementada | No existe evidencia de piloto ni criterios de salida. |

## Bugs reproducidos y deuda prioritaria

### BUG-01 — Asignaciones revocadas/iniciadas quedan bloqueadas (P0)

**Evidencia remota:** existe una asignación `revoked` que conserva una sesión
`in_progress`. El frontend ofrece “Eliminar”, pero `experience_sessions.assignment_id`
referencia la asignación sin `ON DELETE`. PostgreSQL impide borrarla.

Además, `UNIQUE(user_id, experience_version_id)` permanece ocupado por la fila
revocada. El administrador no puede borrarla ni crear otra para la misma versión.

**Causa:** se mezclan tres conceptos incompatibles:

- revocar acceso;
- eliminar físicamente;
- reiniciar/reasignar una experiencia.

**Intervención recomendada:**

1. prohibir DELETE físico cuando existe historia;
2. reemplazar “Eliminar” por “Archivar” o “Revocar”;
3. definir “Reiniciar” mediante RPC transaccional y auditada;
4. decidir si una nueva tentativa crea nueva asignación o un `attempt`;
5. mantener sesiones/resultados históricos, nunca borrarlos en cascada;
6. corregir la restricción única según el modelo aprobado.

### BUG-02 — Experiencia asignada muestra “No pudimos cargar…” (P0)

La RPC `start_or_resume_session` fue verificada con una sesión real y devuelve
contenido v2.0 con 20 pasos. Por tanto, no es una caída general de Supabase.

El problema no puede aislarse para el usuario afectado porque `runner.js`:

- compara solamente `err.message` exacto;
- descarta `code`, `details`, `hint` y el request/error id;
- muestra el mismo mensaje para errores de consentimiento, versión, datos o SQL;
- no registra un evento de fallo.

**Casos que deben verificarse para el usuario afectado:**

1. consentimiento activo `data_processing=true`;
2. asignación no revocada y perteneciente al mismo usuario;
3. versión aún `published`;
4. sesión y asignación ligadas a la misma versión;
5. contenido con `steps`, `meta` y capabilities soportadas;
6. ausencia de múltiples sesiones para la misma asignación.

**Intervención recomendada:** crear un RPC de diagnóstico seguro o telemetría
server-side, normalizar errores por `code`, conservar un correlation id y mostrar
mensajes accionables sin exponer datos internos.

### BUG-03 — Calendario/fecha límite sin contrato funcional (P1)

El calendario es un `<input type="date">` que envía `YYYY-MM-DD` directamente a
`TIMESTAMPTZ`. No valida fecha pasada, zona horaria ni efecto de vencimiento.
`start_or_resume_session` tampoco comprueba `due_at`; hoy la fecha es decorativa.

### BUG-04 — Cierre incorrecto de HU-CA-008 (P1)

La HU de correcciones estaba marcada `Done` aunque su DoD no estaba verificado.
Debe permanecer en validación hasta cubrir creación, revocación, reinicio,
eliminación/archivo, duplicados y aparición en el Hub.

## Deuda técnica adicional

1. Hay dos árboles de migraciones (`supabase/migrations` y
   `src/backend/supabase/migrations`) y varias funciones productivas viven en
   `seed`; no existe una fuente única reproducible.
2. No hay tests unitarios, de integración, RLS, contrato ni E2E.
3. `start_or_resume_session` no tiene garantía única por asignación ante carrera.
4. `save_step_answer` no valida estrictamente paso actual, rango y opción autorizada.
5. La migración 009 cambia asignaciones activas de versión, riesgo contrario a la
   promesa de sesiones versionadas e inmutables.
6. El timer contradice el requisito global RX-14: “No usar temporizadores”.
7. La UI y el scoring siguen acoplados a DISC.
8. Recuperación de contraseña apunta a una página inexistente.
9. El repositorio tiene casi todo el desarrollo sin versionar en Git, lo que impide
   una trazabilidad y rollback confiables.

## Plan de intervención

> Intervención iniciada: la Fase 1 ya cuenta con implementación local para el
> ciclo de asignaciones y el diagnóstico del runner. Está pendiente aplicar la
> migración en staging y ejecutar la validación descrita en
> `docs/INTERVENCION_P0_ASIGNACIONES.md`.

### Fase 0 — Congelar y hacer reproducible el estado (0,5–1 día)

- crear rama/commit de baseline;
- respaldar esquema y datos de staging;
- consolidar migraciones en `supabase/migrations`;
- registrar qué scripts están realmente aplicados;
- separar staging de cualquier entorno de demostración.

**Salida:** base reproducible desde cero y rollback definido.

### Fase 1 — Estabilización P0 de asignaciones y runner (1–2 días)

- diseñar estados `assigned/in_progress/completed/revoked/archived`;
- sustituir DELETE físico por RPC de revocación/archivo;
- crear RPC auditada de reinicio/reasignación;
- reparar filas bloqueadas existentes sin perder historia;
- capturar errores estructurados en runner y añadir correlation id;
- diagnosticar el caso exacto del jugador afectado;
- añadir `UNIQUE(assignment_id)` o modelo explícito de intentos.

**Salida:** un OrgAdmin puede asignar, revocar, reactivar/reiniciar y consultar sin
filas huérfanas; todo jugador elegible puede abrir su experiencia.

### Fase 2 — Pruebas del vertical slice (1–2 días)

- integración de Auth, consentimiento, asignación y RPC;
- pruebas RLS cross-tenant;
- concurrencia de inicio y doble respuesta;
- E2E: asignar → Hub → iniciar → pausar → completar → resultado;
- fixtures de errores: sin consentimiento, revocada, retirada e incompleta.

**Salida:** CA-002, CA-008, CM-003, CM-005, CM-006 y QA-003 con evidencia.

### Fase 3 — Cierre del MVP funcional Base (2–4 días)

- implementar recuperación de contraseña completa;
- validar contrato y opciones server-side;
- retirar o aprobar formalmente el timer;
- cerrar contenido/scoring con revisión experta;
- completar accesibilidad, observabilidad y auditoría;
- ejecutar piloto controlado y corregir hallazgos.

**Salida:** vertical slice Base candidato a piloto.

### Fase 4 — Decisión de alcance del MVP modular

Producto debe elegir y documentar una de estas dos salidas:

1. **MVP Base:** declarar Cumbre, IA avanzada, fábrica completa y gobierno avanzado
   como posteriores al MVP; o
2. **MVP modular original:** mantenerlas como Must y continuar las HUs actualmente
   rojas antes de declarar culminación.

## Criterio de culminación recomendado

No declarar el MVP listo para piloto mientras exista algún P0 y no haya al menos:

- despliegue reproducible;
- flujo E2E automatizado;
- pruebas RLS;
- cero asignaciones bloqueadas;
- diagnóstico observable de errores;
- contenido y scoring aprobados;
- decisión formal sobre el alcance Base vs. modular completo.
