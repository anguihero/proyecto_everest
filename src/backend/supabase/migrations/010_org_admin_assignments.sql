-- =====================================================
-- Migration 010: Gestión de asignaciones por OrgAdmin
--
-- Cambios:
--  1. DELETE policy — org_admin puede eliminar asignaciones de su org
--  2. INSERT policy — org_admin no puede asignar a sys_admin
--
-- Prerrequisito: 002_rls_policies.sql aplicada
-- Ejecutar en Supabase SQL Editor (proyecto fwwkchcxildykvfhrcri)
-- =====================================================


-- ─── 1. Política DELETE para org_admin ──────────────

CREATE POLICY "assignment: org_admin elimina"
  ON public.experience_assignments FOR DELETE
  USING (public.i_am_admin_or_above() AND org_id = public.get_my_org_id());


-- ─── 2. Reemplazar política INSERT: bloquear sys_admin ──

DROP POLICY IF EXISTS "assignment: org_admin asigna" ON public.experience_assignments;

CREATE POLICY "assignment: org_admin asigna"
  ON public.experience_assignments FOR INSERT
  WITH CHECK (
    public.i_am_admin_or_above()
    AND org_id = public.get_my_org_id()
    AND (SELECT role FROM public.profiles WHERE id = user_id) <> 'sys_admin'
  );


-- ─── Verificación ────────────────────────────────────

SELECT
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'experience_assignments'
ORDER BY policyname;
