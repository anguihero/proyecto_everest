-- =====================================================
-- Fix: Corregir roles de los 4 usuarios de prueba
-- Ejecutar en Supabase SQL Editor
-- =====================================================

UPDATE public.profiles SET role = 'player'
WHERE id = (SELECT id FROM auth.users WHERE email = 'diegoms@alienyticslab.com');

UPDATE public.profiles SET role = 'coach'
WHERE id = (SELECT id FROM auth.users WHERE email = 'oscar@everest.oscar');

UPDATE public.profiles SET role = 'org_admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'andresms@alienyticslab.com');

UPDATE public.profiles SET role = 'sys_admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'everest@alienyticslab.com');

-- Verificación: deben aparecer los 4 con los roles correctos
SELECT u.email, p.preferred_name, p.role
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
WHERE u.email IN (
  'diegoms@alienyticslab.com',
  'oscar@everest.oscar',
  'andresms@alienyticslab.com',
  'everest@alienyticslab.com'
)
ORDER BY CASE p.role
  WHEN 'sys_admin'  THEN 1
  WHEN 'org_admin'  THEN 2
  WHEN 'coach'      THEN 3
  WHEN 'player'     THEN 4
END;
