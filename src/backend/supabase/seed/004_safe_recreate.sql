-- =====================================================
-- Procedimiento: Recrear usuarios de prueba de forma segura
-- Fecha: 2026-06-28
-- MOTIVO: INSERT directo en auth.users deja registros incompatibles
-- con el modelo interno de GoTrue → "Database error querying schema" (500).
-- SOLUCIÓN: Eliminar y recrear via Dashboard (GoTrue crea el registro
-- con todos los campos internos correctos).
--
-- ⚠️  EJECUTAR EN BLOQUES — no todo de una sola vez.
--     Leer los comentarios antes de cada PASO.
-- =====================================================

-- ═══════════════════════════════════════════════════
-- DIAGNÓSTICO (seguro — solo lectura)
-- Corre esto primero para confirmar el estado actual.
-- ═══════════════════════════════════════════════════

SELECT
  u.email,
  u.email_confirmed_at IS NOT NULL  AS email_ok,
  LEFT(u.encrypted_password, 10)    AS hash,
  p.role,
  p.is_active,
  p.onboarding_version,
  EXISTS (
    SELECT 1 FROM public.consent_records c WHERE c.user_id = p.id
  )                                 AS tiene_consent
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email IN (
  'diegoms@alienyticslab.com',
  'andresms@alienyticslab.com',
  'oscar@everest.oscar',
  'everest@alienyticslab.com'
);

-- ═══════════════════════════════════════════════════
-- PASO A — Parchear trigger (SEGURO — no destructivo)
-- Permite que el Dashboard cree usuarios sin metadata.
-- Si org_id no viene en raw_user_meta_data → retorna sin crear perfil.
-- El perfil se crea manualmente en PASO C.
-- ═══════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id         UUID;
  v_role           public.user_role;
  v_preferred_name TEXT;
BEGIN
  v_org_id         := (NEW.raw_user_meta_data ->> 'org_id')::UUID;
  v_role           := COALESCE(
                        (NEW.raw_user_meta_data ->> 'role')::public.user_role,
                        'player'
                      );
  v_preferred_name := NEW.raw_user_meta_data ->> 'preferred_name';

  -- Si no hay org_id (usuario creado desde Dashboard sin metadata),
  -- retornar sin crear perfil. Se crea manualmente en PASO C.
  IF v_org_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organizations WHERE id = v_org_id AND is_active = true
  ) THEN
    RAISE EXCEPTION 'handle_new_auth_user: organización % inválida o inactiva.', v_org_id;
  END IF;

  INSERT INTO public.profiles (id, org_id, role, preferred_name)
  VALUES (NEW.id, v_org_id, v_role, v_preferred_name)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Verificar que el trigger sigue activo
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND tgname = 'on_auth_user_created';

-- ═══════════════════════════════════════════════════
-- PASO B — ELIMINAR USUARIOS EXISTENTES
-- ⚠️  DESTRUCTIVO — solicita aprobación antes de correr.
-- Elimina en orden correcto para respetar FK:
--   1. consent_records (FK → profiles)
--   2. auth.users (CASCADE → profiles)
-- ═══════════════════════════════════════════════════

-- B-1: Eliminar consent_records
DELETE FROM public.consent_records
WHERE user_id IN (
  SELECT p.id
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE u.email IN (
    'diegoms@alienyticslab.com',
    'andresms@alienyticslab.com',
    'oscar@everest.oscar',
    'everest@alienyticslab.com'
  )
);

-- B-2: Eliminar usuarios (CASCADE → profiles)
DELETE FROM auth.users
WHERE email IN (
  'diegoms@alienyticslab.com',
  'andresms@alienyticslab.com',
  'oscar@everest.oscar',
  'everest@alienyticslab.com'
);

-- Confirmar que no quedan rastros
SELECT COUNT(*) AS usuarios_restantes
FROM auth.users
WHERE email IN (
  'diegoms@alienyticslab.com',
  'andresms@alienyticslab.com',
  'oscar@everest.oscar',
  'everest@alienyticslab.com'
);
-- Resultado esperado: 0

-- ═══════════════════════════════════════════════════
-- PASO B.5 — ACCIÓN MANUAL EN SUPABASE DASHBOARD
-- ═══════════════════════════════════════════════════
--
-- Ir a: Authentication → Users → "Add user" → "Create new user"
-- Crear los 4 usuarios con la contraseña EverestMVP2026!
-- (NO marcar "Auto Confirm User" si lo pide — hacerlo manualmente si es necesario)
--
-- Usuario 1:
--   Email:    diegoms@alienyticslab.com
--   Password: EverestMVP2026!
--
-- Usuario 2:
--   Email:    andresms@alienyticslab.com
--   Password: EverestMVP2026!
--
-- Usuario 3:
--   Email:    oscar@everest.oscar
--   Password: EverestMVP2026!
--
-- Usuario 4:
--   Email:    everest@alienyticslab.com
--   Password: EverestMVP2026!
--
-- Después de crear los 4, continuar con PASO C.
-- ═══════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════
-- PASO C — Crear/actualizar perfiles (seguro post-Dashboard)
-- El trigger retornó sin crear perfil (org_id ausente en Dashboard).
-- Este UPSERT crea o completa el perfil de cada usuario.
-- ═══════════════════════════════════════════════════

INSERT INTO public.profiles (id, org_id, role, preferred_name, onboarding_version, is_active)
SELECT
  u.id,
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'player'::public.user_role,
  'Diego',
  '1.0',
  true
FROM auth.users u
WHERE u.email = 'diegoms@alienyticslab.com'
ON CONFLICT (id) DO UPDATE SET
  org_id             = EXCLUDED.org_id,
  role               = EXCLUDED.role,
  preferred_name     = EXCLUDED.preferred_name,
  onboarding_version = EXCLUDED.onboarding_version,
  is_active          = EXCLUDED.is_active;

INSERT INTO public.profiles (id, org_id, role, preferred_name, onboarding_version, is_active)
SELECT
  u.id,
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'org_admin'::public.user_role,
  'Andrés',
  '1.0',
  true
FROM auth.users u
WHERE u.email = 'andresms@alienyticslab.com'
ON CONFLICT (id) DO UPDATE SET
  org_id             = EXCLUDED.org_id,
  role               = EXCLUDED.role,
  preferred_name     = EXCLUDED.preferred_name,
  onboarding_version = EXCLUDED.onboarding_version,
  is_active          = EXCLUDED.is_active;

INSERT INTO public.profiles (id, org_id, role, preferred_name, onboarding_version, is_active)
SELECT
  u.id,
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'coach'::public.user_role,
  'Óscar',
  '1.0',
  true
FROM auth.users u
WHERE u.email = 'oscar@everest.oscar'
ON CONFLICT (id) DO UPDATE SET
  org_id             = EXCLUDED.org_id,
  role               = EXCLUDED.role,
  preferred_name     = EXCLUDED.preferred_name,
  onboarding_version = EXCLUDED.onboarding_version,
  is_active          = EXCLUDED.is_active;

INSERT INTO public.profiles (id, org_id, role, preferred_name, onboarding_version, is_active)
SELECT
  u.id,
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'sys_admin'::public.user_role,
  'Everest',
  '1.0',
  true
FROM auth.users u
WHERE u.email = 'everest@alienyticslab.com'
ON CONFLICT (id) DO UPDATE SET
  org_id             = EXCLUDED.org_id,
  role               = EXCLUDED.role,
  preferred_name     = EXCLUDED.preferred_name,
  onboarding_version = EXCLUDED.onboarding_version,
  is_active          = EXCLUDED.is_active;

-- ═══════════════════════════════════════════════════
-- PASO D — Insertar consent_records (idempotente)
-- ═══════════════════════════════════════════════════

INSERT INTO public.consent_records (user_id, org_id, policy_version, purposes)
SELECT
  p.id,
  p.org_id,
  '1.0',
  '{"data_processing": true, "ai_processing": true, "coach_sharing": true}'::jsonb
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
WHERE u.email IN (
  'diegoms@alienyticslab.com',
  'andresms@alienyticslab.com',
  'oscar@everest.oscar',
  'everest@alienyticslab.com'
)
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════
-- PASO E — VERIFICACIÓN COMPLETA
-- Corre esto al final. Todos los campos deben estar correctos.
-- ═══════════════════════════════════════════════════

SELECT
  u.email,
  u.email_confirmed_at IS NOT NULL                          AS email_confirmado,
  p.preferred_name,
  p.role,
  p.org_id = 'a0000000-0000-0000-0000-000000000001'::uuid  AS org_ok,
  p.is_active,
  p.onboarding_version,
  EXISTS (
    SELECT 1 FROM public.consent_records c
    WHERE c.user_id = p.id AND c.revoked_at IS NULL
  )                                                         AS consent_ok,
  o.name                                                    AS organizacion
FROM auth.users u
JOIN public.profiles p      ON p.id    = u.id
JOIN public.organizations o ON o.id    = p.org_id
WHERE u.email IN (
  'diegoms@alienyticslab.com',
  'andresms@alienyticslab.com',
  'oscar@everest.oscar',
  'everest@alienyticslab.com'
)
ORDER BY CASE p.role
  WHEN 'sys_admin'  THEN 1
  WHEN 'org_admin'  THEN 2
  WHEN 'coach'      THEN 3
  WHEN 'player'     THEN 4
END;

-- Resultado esperado: 4 filas, todos los campos en true/correcto.
