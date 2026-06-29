-- =====================================================
-- Migration 021: Auth autónoma — email templates, log, perfil
-- Plan: PLAN_AUTH_CREDENCIALES_AUTONOMAS.md
-- Responsable: Andrés Muñoz | Fecha: 2026-06-29
--
-- Cambios:
--   1. Tabla email_templates: plantillas HTML gestionadas desde la plataforma
--   2. Tabla email_log: auditoría de envíos (sin PII)
--   3. Columnas en profiles: force_password_reset, mfa_enrolled
--   4. Extensión del enum audit_action con eventos de credenciales
--   5. Plantillas iniciales: welcome, password_reset, invitation
-- =====================================================

-- ─── 1. Extensión del enum audit_action ─────────────
-- Se agregan nuevas acciones de credenciales
-- (ALTER TYPE ... ADD VALUE no requiere transacción en Postgres 12+)

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.audit_action'::regtype
      AND enumlabel = 'password_reset_requested'
  ) THEN
    ALTER TYPE public.audit_action ADD VALUE 'password_reset_requested';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.audit_action'::regtype
      AND enumlabel = 'password_reset_completed'
  ) THEN
    ALTER TYPE public.audit_action ADD VALUE 'password_reset_completed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.audit_action'::regtype
      AND enumlabel = 'mfa_enrolled'
  ) THEN
    ALTER TYPE public.audit_action ADD VALUE 'mfa_enrolled';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.audit_action'::regtype
      AND enumlabel = 'mfa_removed'
  ) THEN
    ALTER TYPE public.audit_action ADD VALUE 'mfa_removed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.audit_action'::regtype
      AND enumlabel = 'session_revoked'
  ) THEN
    ALTER TYPE public.audit_action ADD VALUE 'session_revoked';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.audit_action'::regtype
      AND enumlabel = 'password_changed_by_admin'
  ) THEN
    ALTER TYPE public.audit_action ADD VALUE 'password_changed_by_admin';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.audit_action'::regtype
      AND enumlabel = 'invitation_sent'
  ) THEN
    ALTER TYPE public.audit_action ADD VALUE 'invitation_sent';
  END IF;
END $$;


-- ─── 2. Tabla email_templates ────────────────────────

CREATE TABLE IF NOT EXISTS public.email_templates (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT         NOT NULL UNIQUE,
  subject     TEXT         NOT NULL,
  body_html   TEXT         NOT NULL,
  variables   JSONB        NOT NULL DEFAULT '[]',
  is_active   BOOLEAN      NOT NULL DEFAULT true,
  updated_by  UUID         REFERENCES public.profiles(id) ON DELETE SET NULL,
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.email_templates IS
  'Plantillas HTML de email gestionadas desde la plataforma. Nunca dependen del dashboard de Supabase.';
COMMENT ON COLUMN public.email_templates.slug IS
  'Identificador único: welcome | password_reset | invitation | account_deactivated';
COMMENT ON COLUMN public.email_templates.variables IS
  'Lista de variables disponibles en la plantilla. Ej: ["{{name}}","{{reset_url}}","{{expires_in}}"]';

ALTER TABLE public.email_templates ENABLE ROW LEVEL SECURITY;

-- Solo sys_admin gestiona plantillas
CREATE POLICY email_templates_sys_admin ON public.email_templates
  FOR ALL TO authenticated
  USING     (public.i_am_sys_admin())
  WITH CHECK(public.i_am_sys_admin());

-- Trigger updated_at
CREATE TRIGGER trg_email_templates_updated_at
  BEFORE UPDATE ON public.email_templates
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ─── 3. Tabla email_log ──────────────────────────────

CREATE TABLE IF NOT EXISTS public.email_log (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  template_slug  TEXT         NOT NULL,
  recipient_id   UUID         REFERENCES public.profiles(id) ON DELETE SET NULL,
  triggered_by   UUID         REFERENCES public.profiles(id) ON DELETE SET NULL,
  status         TEXT         NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending','sent','failed','bounced')),
  provider_id    TEXT,
  error_message  TEXT,
  sent_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.email_log IS
  'Auditoría de emails enviados por la plataforma. Sin contenido completo, sin email del destinatario.';
COMMENT ON COLUMN public.email_log.recipient_id IS
  'Referencia al perfil. El email real nunca se almacena aquí.';
COMMENT ON COLUMN public.email_log.provider_id IS
  'ID del envío en el proveedor externo (Resend, SendGrid, etc.) para trazabilidad.';

CREATE INDEX idx_email_log_recipient  ON public.email_log(recipient_id);
CREATE INDEX idx_email_log_status     ON public.email_log(status);
CREATE INDEX idx_email_log_sent_at    ON public.email_log(sent_at DESC);

ALTER TABLE public.email_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY email_log_sys_admin ON public.email_log
  FOR ALL TO authenticated
  USING     (public.i_am_sys_admin())
  WITH CHECK(public.i_am_sys_admin());


-- ─── 4. Columnas nuevas en profiles ─────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS force_password_reset BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS mfa_enrolled         BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_password_change TIMESTAMPTZ;

COMMENT ON COLUMN public.profiles.force_password_reset IS
  'Si true, el usuario debe cambiar su contraseña en el próximo inicio de sesión.';
COMMENT ON COLUMN public.profiles.mfa_enrolled IS
  'Indica si el usuario tiene 2FA/TOTP configurado via Supabase MFA.';
COMMENT ON COLUMN public.profiles.last_password_change IS
  'Timestamp del último cambio de contraseña (actualizado por Edge Function sysadmin-set-password).';


-- ─── 5. Plantillas iniciales ─────────────────────────

INSERT INTO public.email_templates (slug, subject, body_html, variables) VALUES

-- Bienvenida
('welcome',
 'Bienvenido/a a Everest Experience 🏔️',
 '<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bienvenida</title>
<style>
  body{font-family:Inter,Arial,sans-serif;background:#f9fafb;margin:0;padding:0}
  .container{max-width:560px;margin:40px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)}
  .header{background:#1B5E20;padding:32px 40px;text-align:center}
  .header h1{color:#fff;font-size:22px;margin:0;font-weight:700;letter-spacing:.5px}
  .header p{color:#A5D6A7;font-size:13px;margin:8px 0 0}
  .body{padding:40px}
  .body p{color:#374151;font-size:15px;line-height:1.7;margin:0 0 16px}
  .btn{display:inline-block;background:#2E7D32;color:#fff!important;text-decoration:none;
       padding:14px 32px;border-radius:8px;font-weight:600;font-size:15px;margin:8px 0 24px}
  .footer{background:#f3f4f6;padding:20px 40px;text-align:center;color:#9CA3AF;font-size:12px}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>EVEREST EXPERIENCE</h1>
    <p>Plataforma de desarrollo de liderazgo</p>
  </div>
  <div class="body">
    <p>Hola <strong>{{name}}</strong>,</p>
    <p>Tu cuenta en <strong>Everest Experience</strong> ha sido creada exitosamente dentro de la organización <strong>{{org_name}}</strong>.</p>
    <p>Ya puedes iniciar sesión y comenzar tu expedición de liderazgo:</p>
    <a href="{{login_url}}" class="btn">Iniciar sesión →</a>
    <p>Si tienes preguntas, responde este correo o contacta a tu administrador.</p>
    <p>¡Buen ascenso,<br>El equipo de Everest</p>
  </div>
  <div class="footer">
    Este correo fue generado automáticamente. No compartas tu contraseña con nadie.
  </div>
</div>
</body></html>',
 '["{{name}}","{{org_name}}","{{login_url}}"]'),

-- Recuperación de contraseña
('password_reset',
 'Recupera tu acceso a Everest Experience',
 '<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Recuperar acceso</title>
<style>
  body{font-family:Inter,Arial,sans-serif;background:#f9fafb;margin:0;padding:0}
  .container{max-width:560px;margin:40px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)}
  .header{background:#1B5E20;padding:32px 40px;text-align:center}
  .header h1{color:#fff;font-size:22px;margin:0;font-weight:700}
  .header p{color:#A5D6A7;font-size:13px;margin:8px 0 0}
  .body{padding:40px}
  .body p{color:#374151;font-size:15px;line-height:1.7;margin:0 0 16px}
  .btn{display:inline-block;background:#2E7D32;color:#fff!important;text-decoration:none;
       padding:14px 32px;border-radius:8px;font-weight:600;font-size:15px;margin:8px 0 24px}
  .warning{background:#FFF3CD;border-left:4px solid #FFB300;padding:12px 16px;border-radius:4px;
           color:#856404;font-size:13px;margin:16px 0}
  .footer{background:#f3f4f6;padding:20px 40px;text-align:center;color:#9CA3AF;font-size:12px}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>EVEREST EXPERIENCE</h1>
    <p>Recuperación de acceso</p>
  </div>
  <div class="body">
    <p>Hola <strong>{{name}}</strong>,</p>
    <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta. Haz clic en el botón para crear una nueva:</p>
    <a href="{{reset_url}}" class="btn">Crear nueva contraseña →</a>
    <div class="warning">
      ⚠️ Este enlace expira en <strong>{{expires_in}}</strong>. Si no solicitaste este cambio, ignora este correo — tu cuenta sigue protegida.
    </div>
    <p>Por seguridad, el enlace solo puede usarse una vez.</p>
    <p>El equipo de Everest</p>
  </div>
  <div class="footer">
    Solicitud generada el {{requested_at}}. Si no reconoces esta acción, contacta a tu administrador de inmediato.
  </div>
</div>
</body></html>',
 '["{{name}}","{{reset_url}}","{{expires_in}}","{{requested_at}}"]'),

-- Invitación
('invitation',
 '{{inviter_name}} te invita a Everest Experience',
 '<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Invitación</title>
<style>
  body{font-family:Inter,Arial,sans-serif;background:#f9fafb;margin:0;padding:0}
  .container{max-width:560px;margin:40px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)}
  .header{background:#1B5E20;padding:32px 40px;text-align:center}
  .header h1{color:#fff;font-size:22px;margin:0;font-weight:700}
  .header p{color:#A5D6A7;font-size:13px;margin:8px 0 0}
  .body{padding:40px}
  .body p{color:#374151;font-size:15px;line-height:1.7;margin:0 0 16px}
  .btn{display:inline-block;background:#2E7D32;color:#fff!important;text-decoration:none;
       padding:14px 32px;border-radius:8px;font-weight:600;font-size:15px;margin:8px 0 24px}
  .highlight{background:#E8F5E9;border-radius:8px;padding:16px;margin:16px 0;color:#1B5E20;font-weight:600;text-align:center;font-size:16px}
  .footer{background:#f3f4f6;padding:20px 40px;text-align:center;color:#9CA3AF;font-size:12px}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>EVEREST EXPERIENCE</h1>
    <p>Plataforma de desarrollo de liderazgo</p>
  </div>
  <div class="body">
    <p>Hola <strong>{{name}}</strong>,</p>
    <p><strong>{{inviter_name}}</strong> te ha invitado a unirte a <strong>Everest Experience</strong> como parte de la organización <strong>{{org_name}}</strong>.</p>
    <div class="highlight">🏔️ Tu expedición de liderazgo comienza aquí</div>
    <p>Acepta la invitación y configura tu cuenta:</p>
    <a href="{{invite_url}}" class="btn">Aceptar invitación →</a>
    <p>Si no esperabas esta invitación, puedes ignorar este correo.</p>
    <p>¡Hasta la cima,<br>El equipo de Everest</p>
  </div>
  <div class="footer">
    Esta invitación expira en 7 días. Generada por {{inviter_name}} el {{invited_at}}.
  </div>
</div>
</body></html>',
 '["{{name}}","{{inviter_name}}","{{org_name}}","{{invite_url}}","{{invited_at}}"]')

ON CONFLICT (slug) DO UPDATE
  SET subject   = EXCLUDED.subject,
      body_html = EXCLUDED.body_html,
      variables = EXCLUDED.variables,
      updated_at = now();


-- ─── 6. Verificación ─────────────────────────────────

SELECT 'email_templates'     AS entidad, COUNT(*)::text AS total FROM public.email_templates
UNION ALL
SELECT 'email_log (vacío)',              COUNT(*)::text           FROM public.email_log
UNION ALL
SELECT 'profiles con force_pw_reset',   COUNT(*)::text           FROM public.profiles WHERE force_password_reset
UNION ALL
SELECT 'profiles con mfa_enrolled',     COUNT(*)::text           FROM public.profiles WHERE mfa_enrolled
UNION ALL
SELECT 'audit_actions nuevas',          COUNT(*)::text
  FROM pg_enum
  WHERE enumtypid = 'public.audit_action'::regtype
    AND enumlabel IN (
      'password_reset_requested','password_reset_completed',
      'mfa_enrolled','mfa_removed','session_revoked',
      'password_changed_by_admin','invitation_sent'
    );
