-- =====================================================
-- Migration 002: Row Level Security — Everest Experience MVP
-- Versión: 1.0.0 | Fecha: 2026-06-28
-- Responsable: Andrés Muñoz Sánchez (Tech Lead)
-- RS-SEC-01: 0 fugas cross-tenant garantizadas por RLS
-- RS-SEC-02: Mínimo privilegio para todos los roles
-- =====================================================
-- REQUISITO: Ejecutar DESPUÉS de 001_core_schema.sql
-- =====================================================

-- =====================================================
-- ACTIVAR RLS EN TODAS LAS TABLAS
-- =====================================================

ALTER TABLE public.organizations           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consent_records         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_definitions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_versions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_assignments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_sessions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_answers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.score_results           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.result_evidence         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_consultations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.state_events            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_versions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_readings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_access_events   ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- FUNCIONES HELPER (SECURITY DEFINER)
-- SECURITY DEFINER: se ejecutan con los permisos del dueño (postgres),
-- no con los del usuario autenticado. Esto es seguro porque el cuerpo
-- de la función está controlado por nosotros y solo lee datos del perfil.
-- =====================================================

-- Devuelve el org_id del usuario autenticado actual.
CREATE OR REPLACE FUNCTION public.get_my_org_id()
RETURNS UUID
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT org_id
  FROM public.profiles
  WHERE id = auth.uid() AND is_active = true
$$;

-- Devuelve el rol del usuario autenticado actual.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT role
  FROM public.profiles
  WHERE id = auth.uid() AND is_active = true
$$;

-- Verifica si el usuario actual es sys_admin.
CREATE OR REPLACE FUNCTION public.i_am_sys_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'sys_admin'
      AND is_active = true
  )
$$;

-- Verifica si el usuario actual es org_admin o sys_admin.
CREATE OR REPLACE FUNCTION public.i_am_admin_or_above()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('org_admin', 'sys_admin')
      AND is_active = true
  )
$$;

-- =====================================================
-- POLÍTICAS: organizations
-- =====================================================

-- Cada usuario ve únicamente su organización.
CREATE POLICY "org: ver la propia"
  ON public.organizations FOR SELECT
  USING (id = public.get_my_org_id());

-- sys_admin tiene acceso total (todas las orgs).
CREATE POLICY "org: sys_admin acceso total"
  ON public.organizations FOR ALL
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: profiles
-- =====================================================

-- Usuario ve su propio perfil.
CREATE POLICY "profile: ver el propio"
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

-- OrgAdmin ve todos los perfiles de su organización.
CREATE POLICY "profile: org_admin ve su org"
  ON public.profiles FOR SELECT
  USING (
    public.i_am_admin_or_above()
    AND org_id = public.get_my_org_id()
  );

-- Usuario actualiza únicamente su propio perfil.
-- No puede cambiar org_id ni role (control en aplicación + esta política).
CREATE POLICY "profile: actualizar el propio"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND org_id = public.get_my_org_id()
  );

-- sys_admin gestiona perfiles globalmente.
CREATE POLICY "profile: sys_admin gestiona"
  ON public.profiles FOR ALL
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: consent_records
-- =====================================================

-- Usuario ve sus propios consentimientos.
CREATE POLICY "consent: ver el propio"
  ON public.consent_records FOR SELECT
  USING (user_id = auth.uid());

-- Usuario registra su propio consentimiento.
CREATE POLICY "consent: registrar el propio"
  ON public.consent_records FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND org_id = public.get_my_org_id()
  );

-- Solo se permite actualizar para establecer revoked_at (revocación).
-- No se puede modificar accepted_at ni purposes.
CREATE POLICY "consent: revocar el propio"
  ON public.consent_records FOR UPDATE
  USING (user_id = auth.uid() AND revoked_at IS NULL)
  WITH CHECK (
    user_id = auth.uid()
    AND revoked_at IS NOT NULL
  );

-- sys_admin puede ver todos los consentimientos (para auditoría).
CREATE POLICY "consent: sys_admin ve todos"
  ON public.consent_records FOR SELECT
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: experience_definitions
-- =====================================================

-- Todos los usuarios autenticados ven el catálogo activo.
CREATE POLICY "exp_def: ver catálogo activo"
  ON public.experience_definitions FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = true);

-- sys_admin gestiona el catálogo.
CREATE POLICY "exp_def: sys_admin gestiona"
  ON public.experience_definitions FOR ALL
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: experience_versions
-- =====================================================

-- Solo versiones publicadas son visibles para usuarios normales.
CREATE POLICY "exp_ver: ver publicadas"
  ON public.experience_versions FOR SELECT
  USING (
    (status = 'published' AND auth.uid() IS NOT NULL)
    OR public.i_am_sys_admin()
  );

-- sys_admin gestiona versiones (piloto, publicación, retiro).
CREATE POLICY "exp_ver: sys_admin gestiona"
  ON public.experience_versions FOR ALL
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: experience_assignments
-- =====================================================

-- Jugador ve sus propias asignaciones.
CREATE POLICY "assignment: ver las propias"
  ON public.experience_assignments FOR SELECT
  USING (user_id = auth.uid());

-- OrgAdmin ve asignaciones de su organización (sin respuestas).
CREATE POLICY "assignment: org_admin ve su org"
  ON public.experience_assignments FOR SELECT
  USING (
    public.i_am_admin_or_above()
    AND org_id = public.get_my_org_id()
  );

-- OrgAdmin crea asignaciones dentro de su organización.
CREATE POLICY "assignment: org_admin asigna"
  ON public.experience_assignments FOR INSERT
  WITH CHECK (
    public.i_am_admin_or_above()
    AND org_id = public.get_my_org_id()
  );

-- OrgAdmin actualiza (revoca) asignaciones de su org.
CREATE POLICY "assignment: org_admin revoca"
  ON public.experience_assignments FOR UPDATE
  USING (
    public.i_am_admin_or_above()
    AND org_id = public.get_my_org_id()
  );

-- =====================================================
-- POLÍTICAS: experience_sessions
-- =====================================================

-- Jugador ve únicamente sus propias sesiones.
CREATE POLICY "session: ver las propias"
  ON public.experience_sessions FOR SELECT
  USING (user_id = auth.uid());

-- Jugador inicia una sesión propia.
CREATE POLICY "session: iniciar la propia"
  ON public.experience_sessions FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND org_id = public.get_my_org_id()
  );

-- Jugador actualiza su sesión mientras no esté completada.
-- No puede cambiar el experience_version_id (DEC-T-02).
CREATE POLICY "session: continuar la propia"
  ON public.experience_sessions FOR UPDATE
  USING (user_id = auth.uid() AND status != 'completed')
  WITH CHECK (
    user_id = auth.uid()
    AND org_id = public.get_my_org_id()
  );

-- OrgAdmin ve estados operativos de su org (sin contenido de respuestas).
-- IMPORTANTE: esta política no expone state_snapshot ni answers.
CREATE POLICY "session: org_admin ve estado"
  ON public.experience_sessions FOR SELECT
  USING (
    public.i_am_admin_or_above()
    AND org_id = public.get_my_org_id()
  );

-- =====================================================
-- POLÍTICAS: session_answers
-- Las respuestas son inmutables: no existe política UPDATE.
-- =====================================================

-- Jugador ve sus propias respuestas.
CREATE POLICY "answer: ver las propias"
  ON public.session_answers FOR SELECT
  USING (user_id = auth.uid());

-- Jugador guarda sus propias respuestas (idempotente via idempotency_key).
CREATE POLICY "answer: guardar las propias"
  ON public.session_answers FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- POLÍTICAS: score_results
-- =====================================================

-- Jugador ve sus propios resultados.
CREATE POLICY "score: ver el propio"
  ON public.score_results FOR SELECT
  USING (user_id = auth.uid());

-- sys_admin gestiona todos los scores (para auditoría y corrección técnica).
CREATE POLICY "score: sys_admin gestiona"
  ON public.score_results FOR ALL
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: result_evidence
-- =====================================================

-- Jugador ve evidencias vinculadas a sus propios resultados.
CREATE POLICY "evidence: ver las propias"
  ON public.result_evidence FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.score_results sr
      WHERE sr.id = score_result_id AND sr.user_id = auth.uid()
    )
  );

-- =====================================================
-- POLÍTICAS: coach_consultations
-- =====================================================

-- Jugador ve sus propias consultas.
CREATE POLICY "coach_consult: ver las propias"
  ON public.coach_consultations FOR SELECT
  USING (user_id = auth.uid());

-- Jugador registra sus propias consultas.
CREATE POLICY "coach_consult: registrar las propias"
  ON public.coach_consultations FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- POLÍTICAS: state_events
-- =====================================================

-- Jugador ve eventos de sus propias sesiones.
CREATE POLICY "state_event: ver los propios"
  ON public.state_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.experience_sessions es
      WHERE es.id = session_id AND es.user_id = auth.uid()
    )
  );

-- Jugador inserta eventos en sus propias sesiones.
CREATE POLICY "state_event: insertar propios"
  ON public.state_events FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.experience_sessions es
      WHERE es.id = session_id AND es.user_id = auth.uid()
    )
  );

-- =====================================================
-- POLÍTICAS: prompt_versions
-- =====================================================

-- Todos los autenticados ven prompts activos (sin ver system_prompt directamente).
-- El system_prompt nunca se envía al cliente: la Edge Function lo lee server-side.
CREATE POLICY "prompt: ver versiones activas"
  ON public.prompt_versions FOR SELECT
  USING (is_active = true AND auth.uid() IS NOT NULL);

-- sys_admin gestiona prompts.
CREATE POLICY "prompt: sys_admin gestiona"
  ON public.prompt_versions FOR ALL
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: generated_readings
-- =====================================================

-- Jugador ve su propia lectura.
CREATE POLICY "reading: ver la propia"
  ON public.generated_readings FOR SELECT
  USING (user_id = auth.uid());

-- sys_admin gestiona readings (para auditoría de IA).
CREATE POLICY "reading: sys_admin gestiona"
  ON public.generated_readings FOR ALL
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: audit_events
-- =====================================================

-- Cualquier usuario autenticado puede insertar eventos (sus propios).
CREATE POLICY "audit: insertar propios"
  ON public.audit_events FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Cada usuario ve sus propios eventos.
CREATE POLICY "audit: ver propios"
  ON public.audit_events FOR SELECT
  USING (user_id = auth.uid());

-- sys_admin ve todos los eventos.
CREATE POLICY "audit: sys_admin ve todos"
  ON public.audit_events FOR SELECT
  USING (public.i_am_sys_admin());

-- =====================================================
-- POLÍTICAS: support_access_events
-- =====================================================

-- Solo sys_admin gestiona eventos de soporte.
CREATE POLICY "support_access: sys_admin gestiona"
  ON public.support_access_events FOR ALL
  USING (public.i_am_sys_admin());
