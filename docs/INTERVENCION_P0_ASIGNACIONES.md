# Intervención P0 — Asignaciones y carga del runner

**Estado:** Desplegada en staging; validación técnica aprobada y E2E manual pendiente.  
**Fecha:** 2026-06-29

## Cambios preparados

- `assign_experience`: crea o reactiva una asignación de forma transaccional.
- `manage_assignment`: revoca, reactiva o elimina únicamente asignaciones sin historia.
- una asignación solo puede tener una sesión;
- las sesiones de asignaciones revocadas se reparan a `paused`;
- la fecha límite vence al terminar el día seleccionado en `America/Bogota`;
- `start_or_resume_session` conserva la versión fijada en la sesión;
- el runner reconoce errores aunque PostgREST agregue código o detalles;
- OrgAdmin ya no hace INSERT/UPDATE/DELETE directo sobre asignaciones;
- se agregaron pruebas de contrato y manejo seguro de errores.

## Despliegue en staging

La migración `20260629000011_assignment_lifecycle.sql` fue aplicada al proyecto
`fwwkchcxildykvfhrcri` el 2026-06-29.

Aplicar, con una cuenta autorizada, la migración:

`supabase/migrations/20260629000011_assignment_lifecycle.sql`

O enlazar primero el proyecto y revisar el diff:

```powershell
npx supabase login
npx supabase link --project-ref fwwkchcxildykvfhrcri
npx supabase db push --dry-run
npx supabase db push
```

No ejecutar `db reset` contra staging.

### Evidencia técnica posterior al despliegue

- historial local/remoto alineado hasta `20260629000011`;
- `manage_assignment` responde y rechaza IDs inexistentes;
- `assign_experience` rechaza una asignación activa duplicada;
- la sesión de la asignación revocada observada quedó reparada de
  `in_progress` a `paused`;
- las fechas históricas quedaron normalizadas al fin del día en Bogotá;
- `start_or_resume_session` devolvió HTTP 200, la misma sesión, schema 2.0 y
  20 pasos;
- 9/9 pruebas unitarias aprobadas.

## Corrección de regresiones UI — 2026-06-29

- Corregido el `TypeError` del runner causado por escribir `className` en un
  elemento SVG. Se usa `setAttribute`, compatible con Chromium.
- La fecha nativa fue reemplazada por selectores explícitos de día, mes y año.
- Se validan fechas incompletas, inexistentes y pasadas antes de invocar Supabase.
- E2E real aprobado para Óscar y Diego: login → Hub → runner → 20 preguntas.
- E2E de OrgAdmin aprobado: modal de asignación con 31 días, 12 meses y seis años.
- Suite unitaria ampliada a 9 pruebas.

## Validación obligatoria posterior

1. OrgAdmin crea una asignación con fecha futura.
2. El jugador la ve en el Hub.
3. El jugador inicia y aparece una sola sesión.
4. OrgAdmin revoca: la asignación queda `revoked` y la sesión `paused`.
5. El jugador deja de verla en el Hub.
6. OrgAdmin reactiva: conserva la misma sesión y el mismo progreso.
7. “Eliminar sin iniciar” funciona únicamente si nunca existió una sesión.
8. Intentar eliminar con historia devuelve `assignment_has_history`.
9. Una fecha pasada devuelve `due_date_in_past`.
10. Un error del runner muestra un código de referencia seguro.

## Pruebas locales

```powershell
npm test
```

Resultado actual: 6 pruebas aprobadas.
