# [HU-CA-008] Corrección de queries y columnas erróneas en Panel OrgAdmin

---

## Metadatos

| Campo | Valor |
|---|---|
| **ID** | HU-CA-008 |
| **Épica** | Consola de Identidad y Acceso — Panel OrgAdmin |
| **Módulo** | `src/frontend/js/admin.js` |
| **Sprint** | Por asignar |
| **Estado** | Desplegada — validación técnica aprobada, E2E manual pendiente |
| **Prioridad** | Crítica — bloquea asignación/reasignación y acceso de jugadores |
| **Estimación** | S (< 2 horas) |
| **Responsable** | Andrés |
| **Fecha de creación** | 2026-06-28 |
| **Detectado en** | Pruebas manuales del panel OrgAdmin |

---

## Historia de Usuario

**Como** OrgAdmin,  
**Quiero** que el panel de administración cargue correctamente las asignaciones, el progreso de sesiones y pueda crear nuevas asignaciones,  
**Para** gestionar a los players de mi organización sin errores de schema.

---

## Contexto y Justificación

`admin.js` fue generado con nombres de columna y FK hints que no corresponden al schema real definido en `001_core_schema.sql`. Esto produce 3 errores distintos visibles en el panel OrgAdmin. El flujo del Player (hub → runner → results) **no se ve afectado** — usa SECURITY DEFINER functions que bypasean PostgREST.

Los errores son puramente de nombres incorrectos, **no de arquitectura ni de lógica de negocio**.

---

## Análisis de Bugs Encontrados

### Bug 1 — `loadAssignments()`: FK hint incorrecto + columna inexistente en SELECT

**Archivo:** `admin.js`, función `loadAssignments()`, líneas ~204-210

**Error:** `"Could not find a relationship between 'experience_assignments' and 'experience_definitions' in the schema cache"`

**Causa:**
```javascript
// ❌ Actual — columna 'experience_definition_id' no existe en la tabla
experience_definitions!experience_definition_id (name, slug)

// ❌ Actual — columna 'due_date' no existe, es 'due_at'
.select('id, status, due_date, created_at, ...')
```

**Fix:**
```javascript
// ✅ Correcto — FK real: experience_assignments.experience_id → experience_definitions.id
experience_definitions!experience_id (name, slug)

// ✅ Correcto
.select('id, status, due_at, created_at, ...')
```

---

### Bug 2 — `loadProgress()`: FK hint incorrecto en join anidado

**Archivo:** `admin.js`, función `loadProgress()`, líneas ~279-281

**Error:** `"Could not find a relationship between 'experience_versions' and 'experience_definitions' in the schema cache"`

**Causa:**
```javascript
// ❌ Actual
experience_versions!experience_version_id (
  experience_definitions!experience_definition_id (name, slug)
)
```

**Fix:**
```javascript
// ✅ Correcto — FK real: experience_versions.experience_id → experience_definitions.id
experience_versions!experience_version_id (
  experience_definitions!experience_id (name, slug)
)
```

---

### Bug 3 — `setupAssignmentModal()`: INSERT con 4 errores en el payload

**Archivo:** `admin.js`, función `setupAssignmentModal()`, líneas ~400-408

**Error:** `"Could not find the 'due_date' column of 'experience_assignments' in the schema cache"`

**Causa (payload actual):**
```javascript
// ❌ 4 problemas en un solo INSERT
.insert({
  user_id:                  userId,
  experience_definition_id: expId,   // columna NO existe → debe ser 'experience_id'
  org_id:                   currentProfile.org_id,
  due_date:                 due,      // columna NO existe → debe ser 'due_at'
  status:                   'active', // valor NO válido en enum → debe ser 'assigned'
  // FALTA experience_version_id (NOT NULL en schema) → constraint violation
  // FALTA assigned_by
})
```

**Schema real de `experience_assignments`:**
```sql
user_id               UUID  NOT NULL  -- ✓ correcto
org_id                UUID  NOT NULL  -- ✓ correcto
experience_id         UUID  NOT NULL  -- FK → experience_definitions(id)
experience_version_id UUID  NOT NULL  -- FK → experience_versions(id) ← FALTA en insert
assigned_by           UUID            -- FK → profiles(id) ← debería ser currentProfile.id
status  assignment_status  DEFAULT 'assigned'  -- enum: 'assigned','in_progress','completed','revoked'
due_at  TIMESTAMPTZ        -- ← nombre real de la columna, NO 'due_date'
```

**Fix:**
```javascript
// ✅ Requiere también seleccionar qué experience_version asignar
// El modal necesita un selector de versión (o auto-seleccionar la última publicada)
.insert({
  user_id:               userId,
  experience_id:         expId,          // nombre correcto
  experience_version_id: versionId,      // campo nuevo en el modal — ver nota abajo
  org_id:                currentProfile.org_id,
  assigned_by:           currentProfile.id,
  due_at:                due || null,    // nombre correcto
  status:                'assigned',     // valor válido del enum
})
```

**Nota:** el modal actualmente solo tiene `sel-experience` (selecciona `experience_definitions`). Para completar el INSERT se necesita también seleccionar o inferir la `experience_version_id` (versión publicada más reciente de esa experiencia).

---

### Bug 4 — `renderAssignmentCard()`: columna inexistente en renderizado

**Archivo:** `admin.js`, función `renderAssignmentCard()`, línea ~233

**Causa:**
```javascript
// ❌ 'due_date' no existe en el resultado del SELECT
const dueText = assignment.due_date ? `Vence: ...` : 'Sin fecha límite';
```

**Fix:**
```javascript
// ✅
const dueText = assignment.due_at ? `Vence: ...` : 'Sin fecha límite';
```

---

## Resumen de Cambios Requeridos

| Ubicación | Error | Cambio |
|---|---|---|
| `loadAssignments()` SELECT | `due_date` | → `due_at` |
| `loadAssignments()` FK hint | `experience_definitions!experience_definition_id` | → `experience_definitions!experience_id` |
| `loadProgress()` FK hint | `experience_definitions!experience_definition_id` | → `experience_definitions!experience_id` |
| `setupAssignmentModal()` INSERT | `experience_definition_id` | → `experience_id` |
| `setupAssignmentModal()` INSERT | `due_date` | → `due_at` |
| `setupAssignmentModal()` INSERT | `status: 'active'` | → `status: 'assigned'` |
| `setupAssignmentModal()` INSERT | campo `experience_version_id` ausente | agregar (NOT NULL) |
| `setupAssignmentModal()` INSERT | campo `assigned_by` ausente | agregar (`currentProfile.id`) |
| `renderAssignmentCard()` | `assignment.due_date` | → `assignment.due_at` |
| Modal HTML | selector `sel-experience` sin `sel-version` | agregar selector o lógica de auto-selección de versión publicada |

---

## Criterios de Aceptación

```gherkin
Feature: Panel OrgAdmin — gestión de asignaciones y progreso

  Scenario 1: Ver lista de asignaciones de la organización
    Dado que el OrgAdmin está en la pestaña "Asignaciones"
    Cuando la página carga
    Entonces se muestra la lista de asignaciones sin errores de schema
    Y cada tarjeta muestra nombre del player, nombre de la experiencia y fecha límite (si existe)

  Scenario 2: Ver progreso de sesiones
    Dado que el OrgAdmin está en la pestaña "Progreso"
    Cuando la página carga
    Entonces se muestra la tabla de sesiones con nombre del player y nombre de experiencia
    Y los contadores (totales, completadas, en progreso, sin iniciar) son correctos

  Scenario 3: Crear nueva asignación válida
    Dado que el OrgAdmin selecciona un usuario y una experiencia en el modal
    Cuando hace clic en "Asignar"
    Entonces el sistema inserta el registro con status='assigned', experience_id y experience_version_id correctos
    Y la lista de asignaciones se recarga mostrando la nueva entrada

  Scenario 4: Error de asignación duplicada
    Dado que el player ya tiene asignada esa versión de la experiencia
    Cuando el OrgAdmin intenta asignarla de nuevo
    Entonces el modal muestra: "Este usuario ya tiene esta experiencia asignada"
    Y no se crea duplicado (UNIQUE constraint: user_id + experience_version_id)
```

---

## Dependencias

- `001_core_schema.sql` aplicada (schema fuente de verdad) ✓ ya aplicada
- `004_experience_meta.sql` aplicada ✓ ya aplicada
- `005_casete_base.sql` aplicada ✓ ya aplicada (hay al menos 1 versión publicada)
- **Nuevo:** el modal de asignación necesita cargar versiones publicadas por experiencia. Puede implementarse como:
  - Opción A: al seleccionar la experiencia, auto-seleccionar la última versión `status='published'`
  - Opción B: agregar un `<select>` de versión al modal (más flexible)

---

## No incluye (fuera de alcance de esta HU)

- Nuevas funcionalidades del panel admin (revocar asignaciones, filtros, paginación)
- RLS del panel admin (pendiente decisión DEC-P-01 sobre coaches multi-org)
- Panel de resultados individuales por player (HU futura)

---

## Definicion de Terminado (DoD)

- [ ] Los 3 errores de schema no aparecen en consola del navegador al abrir el panel OrgAdmin
- [ ] Tab "Asignaciones" carga la lista con datos reales de la organización
- [ ] Tab "Progreso" carga la tabla con nombre de experiencia visible
- [ ] Modal "Nueva asignación" crea el registro sin errores y recarga la lista
- [ ] La asignación creada aparece en el hub del player destinatario
- [ ] Probado con usuario `org_admin` de Alienytics Lab en staging

---

## Hallazgo de validación — 2026-06-29

La corrección de nombres de columnas fue aplicada, pero la HU no cumple todavía
su DoD:

- una asignación con sesión no puede eliminarse por la FK
  `experience_sessions.assignment_id`;
- una fila revocada conserva `UNIQUE(user_id, experience_version_id)` y bloquea
  una reasignación;
- existe en staging una asignación revocada con sesión `in_progress`;
- el runner entrega un error genérico a al menos un jugador asignado;
- no hay pruebas E2E ni de los estados revocar/reactivar/reiniciar.

La solución no debe ser `ON DELETE CASCADE`, porque destruiría historia y
resultados. Se requiere definir archivo/revocación y reinicio mediante operaciones
transaccionales auditadas.

Ver diagnóstico y plan en `docs/ESTADO_MVP_2026-06-29.md`.

### Intervención iniciada

Se preparó la migración `20260629000011_assignment_lifecycle.sql` y se reemplazó
la mutación directa del frontend por RPCs transaccionales. La HU no vuelve a
`Done` hasta aplicar la migración en staging y completar los diez casos de
`docs/INTERVENCION_P0_ASIGNACIONES.md`.

La migración fue aplicada en staging el 2026-06-29. Las comprobaciones técnicas
pasaron; permanece pendiente el recorrido E2E manual completo con OrgAdmin y
Player.

---

## Notas

- **No bloquea el MVP del player.** El flujo Hub → Runner → Resultados funciona de forma completamente independiente mediante SECURITY DEFINER functions.
- Los 3 errores reportados por el usuario son síntomas del mismo conjunto de bugs en `admin.js`; resolverlos juntos en un solo PR es más eficiente.
- Verificar con `NOTIFY pgrst, 'reload schema'` en SQL Editor de Supabase después de cualquier cambio de schema (aunque en este caso el schema ya es correcto — los bugs son solo de código JS).

---

## Historial de Cambios

| Fecha | Autor | Cambio |
|---|---|---|
| 2026-06-28 | Andrés (Claude Code) | HU creada a partir de 3 errores detectados en pruebas del panel OrgAdmin |
| 2026-06-29 | Codex | Reabierta por asignaciones bloqueadas y falta de validación E2E |
| 2026-06-29 | Codex | Implementación P0 preparada; pendiente despliegue y validación |
| 2026-06-29 | Codex | Migración desplegada y validación técnica aprobada |
| 2026-06-29 | Codex | Fecha explícita y apertura de runner validadas E2E con Óscar y Diego |
