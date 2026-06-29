-- =====================================================
-- Migration 024: añadir scoring_engine y result_template a get_session_result
-- Motivo: results.js necesita saber la metodología del resultado para elegir
--         entre renderizado DISC (4 ejes) o VIA (radar hexagonal 6 virtudes).
-- Responsable: Andrés Muñoz | Fecha: 2026-06-29
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_session_result(p_session_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller public.profiles;
  v_target RECORD;
  v_result JSONB;
BEGIN
  SELECT * INTO v_caller
  FROM public.profiles
  WHERE id = auth.uid() AND is_active = true;

  IF NOT FOUND THEN RAISE EXCEPTION 'forbidden'; END IF;

  SELECT es.user_id, es.org_id
  INTO v_target
  FROM public.experience_sessions es
  WHERE es.id = p_session_id AND es.status = 'completed';

  IF NOT FOUND THEN RAISE EXCEPTION 'result_not_found'; END IF;

  IF NOT (
    v_target.user_id = v_caller.id
    OR v_caller.role = 'sys_admin'
    OR (v_caller.role IN ('coach', 'org_admin') AND v_target.org_id = v_caller.org_id)
  ) THEN
    RAISE EXCEPTION 'result_not_found';
  END IF;

  SELECT jsonb_build_object(
    'result_id',             sr.id,
    'result_reference',      'EV-' || upper(left(replace(sr.id::text, '-', ''), 12)),
    'session_id',            es.id,
    'user_id',               es.user_id,
    'participant_name',      p.preferred_name,
    'organization_name',     o.name,
    'experience_id',         ed.id,
    'experience_version_id', ev.id,
    'experience_name',       ed.name,
    'experience_slug',       ed.slug,
    'experience_version',    ev.version,
    'schema_version',        ev.schema_version,
    'scoring_version',       sr.scoring_version,
    'completed_at',          es.completed_at,
    'calculated_at',         sr.calculated_at,
    'scores',                sr.scores,
    -- ↓ NUEVOS: metodología y template de visualización
    'scoring_engine',        COALESCE(ev.scoring_rules->>'type', 'disc_weighted'),
    'result_template',       ev.content->'result_template',
    -- ↑
    'total_steps',           jsonb_array_length(ev.content->'steps'),
    'answered_steps',        metrics.answered_steps,
    'timed_answers',         metrics.timed_answers,
    'average_response_secs', metrics.average_response_secs,
    'answer_fingerprint',    metrics.answer_fingerprint
  )
  INTO v_result
  FROM public.experience_sessions es
  JOIN public.score_results sr ON sr.session_id = es.id
  JOIN public.profiles p ON p.id = es.user_id
  JOIN public.organizations o ON o.id = es.org_id
  JOIN public.experience_versions ev ON ev.id = es.experience_version_id
  JOIN public.experience_definitions ed ON ed.id = ev.experience_id
  LEFT JOIN LATERAL (
    SELECT
      count(*)::int AS answered_steps,
      count(sa.response_time_secs)::int AS timed_answers,
      round(avg(sa.response_time_secs), 1) AS average_response_secs,
      md5(COALESCE(string_agg(
        sa.step_index::text || ':' || sa.option_key,
        '|' ORDER BY sa.step_index
      ), '')) AS answer_fingerprint
    FROM public.session_answers sa
    WHERE sa.session_id = es.id
  ) metrics ON true
  WHERE es.id = p_session_id;

  IF v_caller.id <> v_target.user_id THEN
    INSERT INTO public.audit_events (
      user_id, org_id, action, resource_type, resource_id, metadata
    ) VALUES (
      v_caller.id,
      v_caller.org_id,
      'security_event',
      'score_result',
      v_result->>'result_id',
      jsonb_build_object(
        'event',          'result_viewed',
        'access_role',    v_caller.role,
        'target_org_id',  v_target.org_id
      )
    );
  END IF;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_session_result(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_session_result(UUID) TO authenticated;

COMMENT ON FUNCTION public.get_session_result(UUID) IS
  'Resultado con auditoría, métricas de tiempo, scoring_engine y result_template. Soporta DISC y VIA.';
