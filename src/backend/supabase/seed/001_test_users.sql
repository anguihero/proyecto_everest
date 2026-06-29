-- =====================================================
-- Seed: Organización + 4 usuarios de prueba (un rol cada uno)
-- Fecha: 2026-06-28
-- ⚠️  SOLO PARA DESARROLLO — No ejecutar en producción
-- =====================================================
-- Usuarios creados:
--   diegoms@alienyticslab.com  → player    (Jugador / usuario final)
--   oscar@everest.oscar        → coach     (Coach externo, profesional en psicología)
--   andresms@alienyticslab.com → org_admin (Administrador de la organización: reportes, usuarios)
--   everest@alienyticslab.com  → sys_admin (Superadmin global: supervisión total, cambios de plataforma)
--
-- Contraseña para todos: EverestMVP2026!
-- =====================================================

-- Habilitar pgcrypto (viene incluida en Supabase)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ─────────────────────────────────────────────────────
-- PASO 1: Organización
-- ─────────────────────────────────────────────────────
INSERT INTO public.organizations (id, name, slug)
VALUES (
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'Alienytics Lab',
  'alienyticslab'
)
ON CONFLICT (slug) DO NOTHING;

-- ─────────────────────────────────────────────────────
-- PASO 2: Función auxiliar de seed (solo para desarrollo)
-- Crea usuario en auth.users + auth.identities.
-- El trigger handle_new_auth_user crea el profile automáticamente.
-- ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public._seed_create_user(
  p_email    TEXT,
  p_password TEXT,
  p_org_id   UUID,
  p_role     TEXT,
  p_name     TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id          UUID;
  v_now         TIMESTAMPTZ := now();
  v_instance_id UUID;
BEGIN
  -- Si el usuario ya existe, retornar su id sin modificarlo
  SELECT id INTO v_id FROM auth.users WHERE email = p_email LIMIT 1;
  IF v_id IS NOT NULL THEN
    RAISE NOTICE 'Usuario % ya existe, omitiendo.', p_email;
    RETURN v_id;
  END IF;

  -- Obtener instance_id real (el constraint único en auth.users es instance_id + email)
  SELECT id INTO v_instance_id FROM auth.instances LIMIT 1;
  IF v_instance_id IS NULL THEN
    v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
  END IF;

  v_id := gen_random_uuid();

  -- Insertar en auth.users (sin ON CONFLICT — ya verificamos existencia arriba)
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmation_sent_at,
    role,
    aud,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at
  ) VALUES (
    v_id,
    v_instance_id,
    p_email,
    crypt(p_password, gen_salt('bf', 10)),
    v_now,
    v_now,
    'authenticated',
    'authenticated',
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'org_id',         p_org_id::text,
      'role',           p_role,
      'preferred_name', p_name
    ),
    false,
    v_now,
    v_now
  );

  -- Insertar identity solo si no existe ya (provider_id = email en Supabase email/password)
  IF NOT EXISTS (
    SELECT 1 FROM auth.identities WHERE provider = 'email' AND provider_id = p_email
  ) THEN
    INSERT INTO auth.identities (
      id,
      user_id,
      provider_id,
      provider,
      identity_data,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_id,
      p_email,
      'email',
      jsonb_build_object(
        'sub',            v_id::text,
        'email',          p_email,
        'email_verified', true,
        'phone_verified', false
      ),
      v_now,
      v_now,
      v_now
    );
  END IF;

  RAISE NOTICE 'Usuario creado: % → %', p_email, p_role;
  RETURN v_id;
END;
$$;

-- ─────────────────────────────────────────────────────
-- PASO 3: Crear los 4 usuarios
-- ─────────────────────────────────────────────────────
DO $$
DECLARE
  v_org_id UUID := 'a0000000-0000-0000-0000-000000000001';
  v_pass   TEXT := 'EverestMVP2026!';
BEGIN
  PERFORM public._seed_create_user(
    'diegoms@alienyticslab.com',  v_pass, v_org_id, 'player',    'Diego'
  );
  PERFORM public._seed_create_user(
    'oscar@everest.oscar',        v_pass, v_org_id, 'coach',     'Óscar'
  );
  PERFORM public._seed_create_user(
    'andresms@alienyticslab.com', v_pass, v_org_id, 'org_admin', 'Andrés'
  );
  PERFORM public._seed_create_user(
    'everest@alienyticslab.com',  v_pass, v_org_id, 'sys_admin', 'Everest'
  );
END;
$$;

-- ─────────────────────────────────────────────────────
-- PASO 4: Limpiar función auxiliar (no debe quedar en producción)
-- ─────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public._seed_create_user;

-- ─────────────────────────────────────────────────────
-- PASO 5: Marcar onboarding como completado para usuarios de prueba.
-- En producción, el usuario completa el onboarding antes de ver el hub.
-- Para desarrollo, lo saltamos directamente.
-- ─────────────────────────────────────────────────────
UPDATE public.profiles
SET onboarding_version = '1.0'
WHERE id IN (
  SELECT u.id FROM auth.users u
  WHERE u.email IN (
    'diegoms@alienyticslab.com',
    'andresms@alienyticslab.com',
    'oscar@everest.oscar',
    'everest@alienyticslab.com'
  )
);

-- ─────────────────────────────────────────────────────
-- PASO 6: Insertar consent_records para usuarios de prueba.
-- En producción, el usuario acepta el consentimiento en la pantalla de consent.
-- (Datos: processing=true, ai_processing=true, coach_sharing=true)
-- ─────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────
-- VERIFICACIÓN: deben aparecer los 4 usuarios con sus roles
-- ─────────────────────────────────────────────────────
SELECT
  u.email,
  p.preferred_name  AS nombre,
  p.role,
  p.is_active,
  o.name            AS organizacion
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
JOIN public.organizations o ON o.id = p.org_id
ORDER BY
  CASE p.role
    WHEN 'sys_admin'  THEN 1
    WHEN 'org_admin'  THEN 2
    WHEN 'coach'      THEN 3
    WHEN 'player'     THEN 4
  END;
