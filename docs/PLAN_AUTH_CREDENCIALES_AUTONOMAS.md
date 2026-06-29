# Plan — Credenciales Autónomas (Auth independiente del dashboard de Supabase)

**Fecha:** 2026-06-29  
**Responsable:** Andrés Muñoz (Tech Lead)  
**Estado:** Borrador — pendiente aprobación  
**Prioridad:** P0 (desbloquea BUG-HU-CA-001 y cierra deuda de seguridad)

---

## Problema

El sistema actual depende del **dashboard de Supabase** para gestionar credenciales:
- La recuperación de contraseña redirige a `reset-password.html` que **no existe** (BUG activo).
- Las plantillas de email son las de Supabase por defecto (sin branding, sin control).
- No hay 2FA ni flujo robusto de recuperación.
- El SysAdmin gestiona credenciales desde el dashboard externo, no desde la plataforma.
- No existe pantalla de perfil/configuración (HU-CA-004 en rojo).

## Objetivo

Construir una capa de gestión de credenciales **completamente dentro de la plataforma**, donde:
- Los administradores gestionen usuarios sin salir de la plataforma.
- Los emails sean personalizados y entregados por un proveedor propio.
- Exista 2FA para operaciones sensibles de recuperación.
- El usuario final nunca interactúe con interfaces de Supabase.

## Decisión de arquitectura

**Supabase Auth se mantiene como motor JWT** — no se reemplaza. Toda la RLS está construida sobre `auth.uid()` y reescribirla sería una migración de semanas. Lo que cambia es la **capa de gestión encima**:

| Antes | Después |
|---|---|
| Supabase dashboard para resetear contraseñas | Panel SysAdmin/OrgAdmin dentro de la plataforma |
| Emails de Supabase (sin branding) | SMTP propio con plantillas HTML personalizadas |
| `reset-password.html` inexistente | Página funcional con flujo completo |
| Sin 2FA | TOTP (Google Authenticator / Authy) para recuperación |

---

## Fase A — SMTP propio + plantillas personalizadas (1–2 días)

### 1. Proveedor de email

**Recomendación: Resend**
- Gratuito hasta 3.000 correos/mes
- SDK simple, respuestas claras, dominio propio
- Alternativas: SendGrid, AWS SES, Brevo

**Configuración:**
1. Crear cuenta en Resend, verificar dominio `@everestexperience.co` (o el dominio que corresponda)
2. En Supabase → Authentication → SMTP Settings → configurar SMTP externo con las credenciales de Resend
3. Esto hace que todos los emails de Supabase Auth pasen por Resend automáticamente

### 2. Tabla de plantillas de email

```sql
-- Migration nueva: email_templates
CREATE TABLE public.email_templates (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  slug         TEXT         NOT NULL UNIQUE,
  subject      TEXT         NOT NULL,
  body_html    TEXT         NOT NULL,
  variables    JSONB,
  is_active    BOOLEAN      NOT NULL DEFAULT true,
  updated_by   UUID         REFERENCES public.profiles(id),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Plantillas iniciales
INSERT INTO public.email_templates (slug, subject, body_html, variables) VALUES
  ('welcome',
   'Bienvenido/a a Everest Experience',
   '...html...',
   '["{{name}}","{{org_name}}","{{login_url}}"]'),
  ('password_reset',
   'Recupera tu acceso a Everest Experience',
   '...html...',
   '["{{name}}","{{reset_url}}","{{expires_in}}"]'),
  ('invitation',
   '{{inviter_name}} te invita a Everest Experience',
   '...html...',
   '["{{name}}","{{inviter_name}}","{{org_name}}","{{invite_url}}"]');

-- RLS: solo sys_admin puede gestionar plantillas
ALTER TABLE public.email_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY email_templates_sys_admin ON public.email_templates
  FOR ALL TO authenticated
  USING (public.i_am_sys_admin())
  WITH CHECK (public.i_am_sys_admin());
```

### 3. Edge Function `send-platform-email`

```
supabase/functions/send-platform-email/index.ts
```

Responsabilidades:
- Recibe: `{template_slug, recipient_id, variables: {}}`
- Valida que el llamador es `sys_admin` o `org_admin` (según template)
- Obtiene plantilla de la DB
- Reemplaza variables en HTML
- Envía via Resend API
- Registra en `email_log`

### 4. Log de emails enviados

```sql
CREATE TABLE public.email_log (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  template_slug TEXT         NOT NULL,
  recipient_id  UUID         REFERENCES public.profiles(id),
  sent_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
  status        TEXT         NOT NULL CHECK (status IN ('sent','failed','bounced')),
  provider_id   TEXT
);

COMMENT ON TABLE public.email_log IS
  'Auditoría de emails enviados. Sin contenido completo, sin email del destinatario.';
```

---

## Fase B — Flujo de recuperación completo (1 día)

### Problema actual

`requestPasswordReset(email)` en `auth.js` dispara el flujo de Supabase, que envía un link a `reset-password.html`. Ese archivo **no existe** → el usuario llega a un 404.

### Solución

**Crear `src/frontend/reset-password.html`** con su módulo JS correspondiente.

#### Flujo completo de recuperación

```
1. Usuario en login.html → "Olvidé mi contraseña"
2. Ingresa su email → auth.requestPasswordReset(email)
   - Supabase envía el link via SMTP propio (Resend)
   - La respuesta es siempre neutra (anti-enumeración de emails)
3. Usuario abre email → link apunta a reset-password.html?token=...
4. reset-password.html captura el token del hash de URL
5. Usuario ingresa nueva contraseña (2 veces)
6. Validación de fortaleza: mínimo 12 chars, mayúscula, minúscula, número, símbolo
7. Supabase updateUser() con el token → contraseña actualizada
8. Redirección a login.html con mensaje de éxito
```

#### Políticas de seguridad del flujo

| Política | Valor |
|---|---|
| Token expira en | 1 hora (configurable en Supabase Auth) |
| Máximo intentos fallidos | 3 por hora por email |
| Fortaleza mínima contraseña | 12 chars + mayúscula + minúscula + número + símbolo |
| Anti-enumeración | Mismo mensaje si email no existe o sí existe |
| Revocar sesiones activas al cambiar contraseña | Pendiente decisión (ver abajo) |

---

## Fase C — 2FA para recuperación (1–2 días)

### Alcance del 2FA

No se implementa 2FA para **inicio de sesión normal** (requeriría Pro plan o implementación custom). El 2FA aplica a:
- Configuración inicial de cuenta (primer login de SysAdmin)
- Proceso de recuperación de contraseña para cuentas con 2FA activado
- Cambio de contraseña desde el panel admin

### Implementación

**Supabase MFA (TOTP)** está disponible en el plan Free desde 2024.

```javascript
// Registrar dispositivo 2FA
const { data } = await supabase.auth.mfa.enroll({ factorType: 'totp' })
// data.totp.qr_code → mostrar QR al usuario para escanearlo con Authenticator

// Verificar TOTP al recuperar contraseña
const { data, error } = await supabase.auth.mfa.verify({
  factorId: factor.id,
  code: userEnteredCode
})
```

### Pantalla de configuración 2FA

Se agrega como sección dentro del futuro `profile.html` (HU-CA-004):

```
Seguridad de mi cuenta
├── Cambiar contraseña
├── Autenticación de dos factores
│   ├── Estado: Activa / Inactiva
│   ├── [Activar 2FA] → muestra QR para app autenticadora
│   ├── [Desactivar 2FA] → requiere confirmar TOTP actual
│   └── Dispositivos registrados
└── Sesiones activas
    └── [Cerrar todas las sesiones]
```

### ¿Es obligatorio para SysAdmin?

**[REQUIERE DECISIÓN DE ANDRÉS/ÓSCAR]**

| Opción | Ventaja | Riesgo |
|---|---|---|
| **Obligatorio para SysAdmin** | Seguridad máxima para el rol más privilegiado | Bloquea acceso hasta configurar app |
| **Obligatorio para SysAdmin + OrgAdmin** | Mayor superficie protegida | Fricción para OrgAdmins no técnicos |
| **Opcional para todos** | Sin fricción de adopción | Protección dependiente de decisión del usuario |

**Recomendación:** Obligatorio para SysAdmin, opcional (recomendado) para OrgAdmin.

---

## Fase D — Panel de gestión desde la plataforma (1–2 días)

### SysAdmin (`sysadmin.html` — nueva sección: Credenciales)

| Acción | Descripción | Implementación |
|---|---|---|
| Cambiar contraseña de cualquier usuario | Ya existe la Edge Function `sysadmin-set-password` | Mejorar UI + agregar motivo/ticket obligatorio |
| Enviar email de bienvenida | Para usuarios nuevos sin contraseña | Edge Function `send-platform-email` |
| Forzar reset en próximo login | Marca al usuario para obligar cambio | Flag en `profiles.force_password_reset BOOLEAN` |
| Ver sesiones activas de un usuario | Cuántos dispositivos tiene abiertos | Supabase Admin API `listUserSessions()` |
| Cerrar todas las sesiones de un usuario | Kick de seguridad | Supabase Admin API `signOut(userId, scope='others')` |
| Activar/desactivar 2FA | Para cuentas con problemas de acceso | Supabase MFA Admin API |

### OrgAdmin (`admin.html` — nueva sección en tab Usuarios)

| Acción | Descripción | Restricción |
|---|---|---|
| Enviar email de recuperación | Para users de su org | Solo trigger, no ven el link |
| Enviar email de bienvenida | Para users recién creados | Solo para su org |
| Ver estado de cuenta (activa/inactiva) | Panel de usuario | Solo su org |
| Activar/desactivar cuenta | No resetear contraseña | Solo su org |

> El OrgAdmin **no puede** cambiar contraseñas directamente. Solo puede disparar el flujo de recuperación por email para el usuario.

---

## Schema — resumen de cambios

```sql
-- Nuevas tablas
CREATE TABLE public.email_templates (...);  -- Plantillas de email
CREATE TABLE public.email_log (...);         -- Auditoría de envíos

-- Nuevas columnas en profiles
ALTER TABLE public.profiles
  ADD COLUMN force_password_reset BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN mfa_enrolled         BOOLEAN NOT NULL DEFAULT false;

-- Nueva columna en audit_events (ya tiene el enum audit_action)
-- Agregar al enum: 'password_reset_requested', 'password_reset_completed',
--                  'mfa_enrolled', 'mfa_removed', 'session_revoked'
```

---

## Nuevos archivos frontend requeridos

| Archivo | Descripción |
|---|---|
| `src/frontend/reset-password.html` | Página de nueva contraseña (recibe token en URL hash) |
| `src/frontend/js/reset-password.js` | Lógica: captura token, valida fortaleza, actualiza |
| `src/frontend/profile.html` | Perfil de usuario (HU-CA-004) — incluye 2FA |
| `src/frontend/js/profile.js` | Gestión de perfil y 2FA |

---

## Decisiones pendientes

| Decisión | Opciones | Responsable |
|---|---|---|
| ¿Proveedor de email? | Resend (recomendado), SendGrid, SES | Andrés/Óscar |
| ¿2FA obligatorio para SysAdmin? | Sí (recomendado) / Opcional | Andrés/Óscar |
| ¿Cambiar contraseña revoca sesiones activas? | Sí (más seguro) / No (más conveniente) | Andrés |
| ¿Dominio de email propio? | everestexperience.co o similar | Óscar |

---

## Dependencias con otros planes

- **Plan 2 (Fábrica):** Independiente. Puede ejecutarse en paralelo.
- **Plan 3 (Animación):** Independiente. Puede ejecutarse en paralelo.
- **HU-CA-001** (Auth y recuperación): Este plan la cierra.
- **HU-CA-004** (Perfil y configuración): Las Fases C y D la implementan parcialmente.

---

## Criterios de aceptación

- [ ] Usuario puede recuperar su contraseña sin salir de la plataforma
- [ ] `reset-password.html` existe y funciona con el token de email
- [ ] Los emails se envían desde dominio propio (no `noreply@supabase.io`)
- [ ] SysAdmin puede cambiar contraseña de cualquier usuario desde `sysadmin.html`
- [ ] OrgAdmin puede disparar recuperación de contraseña para usuarios de su org
- [ ] SysAdmin puede configurar 2FA
- [ ] Usuario con 2FA activo debe ingresar TOTP al recuperar contraseña
- [ ] Todos los eventos de credenciales quedan en `audit_events`
- [ ] No existe ningún flujo que requiera abrir el dashboard de Supabase

---

*Documento generado: 2026-06-29 | Versión: 1.0 | Responsable: Andrés Muñoz*
