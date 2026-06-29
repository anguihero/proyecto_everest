-- =====================================================
-- Migration 011: ciclo de vida seguro de asignaciones
-- HU-CA-008, HU-CM-003, HU-QA-003
--
-- Principios:
--   * No borrar asignaciones que ya tienen historia.
--   * Revocar pausa la sesión; reactivar conserva el progreso.
--   * Una fecha límite es inclusiva en America/Bogota.
--   * Una asignación solo puede tener una sesión.
-- =====================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_experience_sessions_assignment
  ON public.experience_sessions (assignment_id);

-- La escritura del ciclo de vida se centraliza en RPCs.
DROP POLICY IF EXISTS "assignment: org_admin elimina"
  ON public.experience_assignments;
DROP POLICY IF EXISTS "assignment: org_admin asigna"
  ON public.experience_assignments;
DROP POLICY IF EXISTS "assignment: org_admin revoca"
  ON public.experience_assignments;

-- Normaliza las fechas creadas por la UI anterior, que enviaba YYYY-MM-DD a
-- TIMESTAMPTZ y terminaba mostrándolas un día antes en Colombia.
UPDATE public.experience_assignments
SET due_at = (
  ((due_at AT TIME ZONE 'UTC')::date + 1)::timestamp
  AT TIME ZONE 'America/Bogota'
)
WHERE due_at IS NOT NULL
  AND (due_at AT TIME ZONE 'UTC')::time = TIME '00:00:00';

-- Repara el estado inválido observado en staging: asignación revocada con
-- sesión todavía activa.
UPDATE public.experience_sessions es
SET status = 'paused',
    last_saved_at = COALESCE(es.last_saved_at, now())
FROM public.experience_assignments ea
WHERE ea.id = es.assignment_id
  AND ea.status = 'revoked'
  AND es.status IN ('not_started', 'in_progress');


CREATE OR REPLACE FUNCTION public.assign_experience(
  p_user_id       UUID,
  p_experience_id UUID,
  p_due_date      DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_org_id       UUID;
  v_target       public.profiles;
  v_version_id   UUID;
  v_assignment   public.experience_assignments;
  v_due_at       TIMESTAMPTZ;
BEGIN
  IF NOT public.i_am_admin_or_above() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_org_id := public.get_my_org_id();

  SELECT * INTO v_target
  FROM public.profiles
  WHERE id = p_user_id
    AND org_id = v_org_id
    AND is_active = true
    AND role <> 'sys_admin';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'target_user_not_assignable';
  END IF;

  SELECT ev.id INTO v_version_id
  FROM public.experience_versions ev
  JOIN public.experience_definitions ed ON ed.id = ev.experience_id
  WHERE ev.experience_id = p_experience_id
    AND ev.status = 'published'
    AND ed.is_active = true
  ORDER BY ev.created_at DESC
  LIMIT 1;

  IF v_version_id IS NULL THEN
    RAISE EXCEPTION 'published_version_not_found';
  END IF;

  IF p_due_date IS NOT NULL AND p_due_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'due_date_in_past';
  END IF;

  -- La fecha seleccionada vence al terminar ese día en Bogotá.
  v_due_at := CASE
    WHEN p_due_date IS NULL THEN NULL
    ELSE (p_due_date + 1)::timestamp AT TIME ZONE 'America/Bogota'
  END;

  SELECT * INTO v_assignment
  FROM public.experience_assignments
  WHERE user_id = p_user_id
    AND experience_version_id = v_version_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_assignment.status = 'revoked' THEN
      UPDATE public.experience_assignments
      SET status = CASE
            WHEN EXISTS (
              SELECT 1 FROM public.experience_sessions
              WHERE assignment_id = v_assignment.id
            ) THEN 'in_progress'::public.assignment_status
            ELSE 'assigned'::public.assignment_status
          END,
          due_at = v_due_at,
          assigned_by = auth.uid(),
          assigned_at = now()
      WHERE id = v_assignment.id
      RETURNING * INTO v_assignment;

      UPDATE public.experience_sessions
      SET status = 'in_progress',
          last_saved_at = now()
      WHERE assignment_id = v_assignment.id
        AND status = 'paused';

      PERFORM public.log_audit_event(
        'security_event',
        'experience_assignment',
        v_assignment.id::text,
        jsonb_build_object('assignment_action', 'reactivated_by_assignment')
      );

      RETURN jsonb_build_object(
        'assignment_id', v_assignment.id,
        'status', v_assignment.status,
        'operation', 'reactivated'
      );
    END IF;

    RAISE EXCEPTION 'assignment_already_exists';
  END IF;

  INSERT INTO public.experience_assignments (
    user_id, org_id, experience_id, experience_version_id,
    assigned_by, status, assigned_at, due_at
  )
  VALUES (
    p_user_id, v_org_id, p_experience_id, v_version_id,
    auth.uid(), 'assigned', now(), v_due_at
  )
  RETURNING * INTO v_assignment;

  PERFORM public.log_audit_event(
    'experience_assigned',
    'experience_assignment',
    v_assignment.id::text,
    jsonb_build_object(
      'target_user_id', p_user_id,
      'experience_id', p_experience_id,
      'experience_version_id', v_version_id
    )
  );

  RETURN jsonb_build_object(
    'assignment_id', v_assignment.id,
    'status', v_assignment.status,
    'operation', 'created'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.assign_experience(UUID, UUID, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_experience(UUID, UUID, DATE) TO authenticated;


CREATE OR REPLACE FUNCTION public.manage_assignment(
  p_assignment_id UUID,
  p_action        TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_assignment public.experience_assignments;
  v_has_session BOOLEAN;
BEGIN
  IF NOT public.i_am_admin_or_above() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_assignment
  FROM public.experience_assignments
  WHERE id = p_assignment_id
    AND org_id = public.get_my_org_id()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'assignment_not_found';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.experience_sessions
    WHERE assignment_id = p_assignment_id
  ) INTO v_has_session;

  CASE p_action
    WHEN 'revoke' THEN
      IF v_assignment.status = 'completed' THEN
        RAISE EXCEPTION 'completed_assignment_is_immutable';
      END IF;

      UPDATE public.experience_assignments
      SET status = 'revoked'
      WHERE id = p_assignment_id;

      UPDATE public.experience_sessions
      SET status = 'paused',
          last_saved_at = now()
      WHERE assignment_id = p_assignment_id
        AND status IN ('not_started', 'in_progress');

    WHEN 'reactivate' THEN
      IF v_assignment.status <> 'revoked' THEN
        RAISE EXCEPTION 'assignment_not_revoked';
      END IF;

      UPDATE public.experience_assignments
      SET status = CASE
            WHEN v_has_session THEN 'in_progress'::public.assignment_status
            ELSE 'assigned'::public.assignment_status
          END
      WHERE id = p_assignment_id;

      UPDATE public.experience_sessions
      SET status = 'in_progress',
          last_saved_at = now()
      WHERE assignment_id = p_assignment_id
        AND status = 'paused';

    WHEN 'remove' THEN
      IF v_has_session THEN
        RAISE EXCEPTION 'assignment_has_history';
      END IF;

      PERFORM public.log_audit_event(
        'security_event',
        'experience_assignment',
        p_assignment_id::text,
        jsonb_build_object('assignment_action', 'removed_without_history')
      );

      DELETE FROM public.experience_assignments
      WHERE id = p_assignment_id;

      RETURN jsonb_build_object(
        'assignment_id', p_assignment_id,
        'status', 'removed',
        'operation', 'removed'
      );

    ELSE
      RAISE EXCEPTION 'unsupported_assignment_action';
  END CASE;

  PERFORM public.log_audit_event(
    'security_event',
    'experience_assignment',
    p_assignment_id::text,
    jsonb_build_object('assignment_action', p_action)
  );

  SELECT * INTO v_assignment
  FROM public.experience_assignments
  WHERE id = p_assignment_id;

  RETURN jsonb_build_object(
    'assignment_id', v_assignment.id,
    'status', v_assignment.status,
    'operation', p_action
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.manage_assignment(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_assignment(UUID, TEXT) TO authenticated;


-- Inicio/reanudación robusta: fija la versión de la sesión, registra el
-- consentimiento usado y convierte una carrera de INSERT en reanudación.
CREATE OR REPLACE FUNCTION public.start_or_resume_session(p_assignment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_assignment public.experience_assignments;
  v_version    public.experience_versions;
  v_session    public.experience_sessions;
  v_consent_id UUID;
BEGIN
  SELECT * INTO v_assignment
  FROM public.experience_assignments
  WHERE id = p_assignment_id
    AND user_id = auth.uid();

  IF NOT FOUND THEN RAISE EXCEPTION 'assignment_not_found'; END IF;
  IF v_assignment.status = 'revoked' THEN RAISE EXCEPTION 'assignment_revoked'; END IF;
  IF v_assignment.due_at IS NOT NULL AND now() >= v_assignment.due_at THEN
    RAISE EXCEPTION 'assignment_due_date_passed';
  END IF;

  SELECT id INTO v_consent_id
  FROM public.consent_records
  WHERE user_id = auth.uid()
    AND revoked_at IS NULL
    AND COALESCE((purposes->>'data_processing')::boolean, false)
  ORDER BY accepted_at DESC
  LIMIT 1;

  IF v_consent_id IS NULL THEN RAISE EXCEPTION 'consent_required'; END IF;

  SELECT * INTO v_session
  FROM public.experience_sessions
  WHERE assignment_id = p_assignment_id
  LIMIT 1;

  IF NOT FOUND THEN
    SELECT * INTO v_version
    FROM public.experience_versions
    WHERE id = v_assignment.experience_version_id
      AND status = 'published';

    IF NOT FOUND THEN RAISE EXCEPTION 'version_not_published'; END IF;

    BEGIN
      INSERT INTO public.experience_sessions (
        assignment_id, user_id, org_id, experience_version_id,
        consent_record_id, status, started_at, current_step
      )
      VALUES (
        p_assignment_id, auth.uid(), v_assignment.org_id,
        v_assignment.experience_version_id, v_consent_id,
        'in_progress', now(), 0
      )
      RETURNING * INTO v_session;
    EXCEPTION WHEN unique_violation THEN
      SELECT * INTO v_session
      FROM public.experience_sessions
      WHERE assignment_id = p_assignment_id;
    END;

    UPDATE public.experience_assignments
    SET status = 'in_progress'
    WHERE id = p_assignment_id AND status = 'assigned';
  END IF;

  IF v_session.user_id <> auth.uid() THEN
    RAISE EXCEPTION 'assignment_not_found';
  END IF;

  IF v_session.status = 'completed' THEN
    RETURN jsonb_build_object(
      'session_id', v_session.id,
      'status', 'completed',
      'current_step', v_session.current_step
    );
  END IF;

  -- La versión se toma de la sesión existente, nunca de una asignación mutada.
  SELECT * INTO v_version
  FROM public.experience_versions
  WHERE id = v_session.experience_version_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'session_version_not_found'; END IF;

  IF v_session.status IN ('not_started', 'paused') THEN
    UPDATE public.experience_sessions
    SET status = 'in_progress', last_saved_at = now()
    WHERE id = v_session.id
    RETURNING * INTO v_session;
  END IF;

  RETURN jsonb_build_object(
    'session_id', v_session.id,
    'status', v_session.status,
    'current_step', v_session.current_step,
    'started_at', v_session.started_at,
    'content', v_version.content,
    'total_steps', jsonb_array_length(v_version.content->'steps')
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.start_or_resume_session(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_or_resume_session(UUID) TO authenticated;
