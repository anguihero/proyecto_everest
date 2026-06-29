# Intervención — Acceso a resultados y credenciales

**Estado:** Desplegada y validada en staging.  
**Migración:** `20260629000013_result_access_matrix.sql`  
**Edge Function:** `sysadmin-set-password`  
**Fecha:** 2026-06-29

## Matriz vigente

| Rol | Resultados permitidos |
|---|---|
| Player | Únicamente los propios |
| Coach/Líder | Resultados de usuarios de su `org_id` |
| OrgAdmin | Resultados de usuarios de su `org_id` |
| SysAdmin | Todos los resultados de todas las organizaciones |

Tanto el listado como el detalle aplican la matriz en funciones
`SECURITY DEFINER`; ocultar enlaces en frontend no constituye el control de
seguridad.

Cada lectura de un resultado ajeno registra un `security_event` con:

- actor;
- rol de acceso;
- `result_id`;
- organización objetivo;
- timestamp.

## Biblioteca de resultados

`results-library.html` consume `list_accessible_results()` y ofrece acceso al
resultado completo. Se enlaza desde:

- Hub del líder;
- panel OrgAdmin;
- panel SysAdmin.

## Cambio de contraseña por SysAdmin

La Edge Function:

1. valida el JWT con `auth.getUser()`;
2. exige perfil activo con rol `sys_admin`;
3. valida el UUID objetivo;
4. exige mínimo 12 caracteres, mayúscula, minúscula, número y símbolo;
5. usa `service_role` solo dentro de la función;
6. actualiza mediante `auth.admin.updateUserById`;
7. registra un evento de auditoría sin email ni contraseña.

Player, Coach y OrgAdmin reciben `403`, incluso si llaman directamente al
endpoint.

## Evidencia

- Player Diego: 3 resultados propios.
- Coach Óscar: 4 resultados de su organización.
- OrgAdmin Andrés: 4 resultados de su organización.
- SysAdmin Everest: 4 resultados globales disponibles en el staging actual.
- Coach pudo abrir un resultado de Diego.
- Player no pudo abrir un resultado de Óscar (`result_not_found`).
- Player recibió `403` al invocar cambio de contraseña.
- SysAdmin con contraseña débil recibió `422` sin modificar la cuenta.
- 13/13 pruebas unitarias aprobadas.
- E2E de biblioteca de líder y modal SysAdmin aprobados.

## Deuda de seguridad pendiente

- Definir si cambiar contraseña debe revocar inmediatamente todas las sesiones
  activas del usuario.
- Añadir motivo/ticket obligatorio para cambios de contraseña en producción.
- Confirmar formalmente la política de privacidad que habilita al líder y al
  OrgAdmin para consultar resultados individuales.

