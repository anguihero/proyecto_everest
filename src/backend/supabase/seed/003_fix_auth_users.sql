-- =====================================================
-- Fix: columnas requeridas en auth.users para GoTrue 2024+
-- El crash 500 ocurre porque GoTrue busca por email_normalized
-- y/o encuentra el hash en un formato que no puede procesar.
-- =====================================================

-- PASO 1: Verificar columnas reales de auth.users en este proyecto
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'auth' AND table_name = 'users'
ORDER BY ordinal_position;

-- =====================================================
-- PASO 2: Establecer email_normalized (requerido por GoTrue 2024+)
-- Causa del crash 500: GoTrue busca por email_normalized, no por email.
-- Si email_normalized es NULL, GoTrue no encuentra el usuario y retorna 500.
-- =====================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name   = 'users'
      AND column_name  = 'email_normalized'
  ) THEN
    UPDATE auth.users
    SET email_normalized = LOWER(email)
    WHERE email IN (
      'diegoms@alienyticslab.com',
      'andresms@alienyticslab.com',
      'oscar@everest.oscar',
      'everest@alienyticslab.com'
    )
    AND (email_normalized IS NULL OR email_normalized <> LOWER(email));

    RAISE NOTICE 'email_normalized actualizado correctamente.';
  ELSE
    RAISE NOTICE 'La columna email_normalized NO existe — puede ignorar este paso.';
  END IF;
END;
$$;

-- =====================================================
-- PASO 3: Verificar estado final
-- =====================================================
SELECT
  u.email,
  u.email_confirmed_at IS NOT NULL  AS confirmado,
  LEFT(u.encrypted_password, 10)    AS hash_prefijo,
  p.role,
  p.is_active
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
WHERE u.email IN (
  'diegoms@alienyticslab.com',
  'andresms@alienyticslab.com',
  'oscar@everest.oscar',
  'everest@alienyticslab.com'
);
