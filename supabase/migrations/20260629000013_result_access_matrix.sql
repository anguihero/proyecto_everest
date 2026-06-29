-- =====================================================
-- Migration 013: matriz de acceso a resultados
-- Player: propios. Coach/OrgAdmin: su organización. SysAdmin: todos.
-- HU-RS-003, HU-GO-002, HU-CA-002
-- =====================================================

CREATE OR REPLACE FUNCTION public.list_accessible_results()
RETURNS TABLE (
  result_id UUID,
  result_reference TEXT,
  session_id UUID,
  participant_id UUID,
  participant_name TEXT,
  org_id UUID,
  organization_name TEXT,
  experience_name TEXT,
  experience_version TEXT,
  scoring_version TEXT,
  completed_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  WITH caller AS (
    SELECT id, org_id, role, is_active
    FROM public.profiles
    WHERE id = auth.uid()
  )
  SELECT
    sr.id,
    'EV-' || upper(left(replace(sr.id::text, '-', ''), 12)),
    es.id,
    p.id,
    p.preferred_name,
    o.id,
    o.name,
    ed.name,
    ev.version,
    sr.scoring_version,
    es.completed_at
  FROM caller c
  JOIN public.experience_sessions es ON es.status = 'completed'
  JOIN public.score_results sr ON sr.session_id = es.id
  JOIN public.profiles p ON p.id = es.user_id
  JOIN public.organizations o ON o.id = es.org_id
  JOIN public.experience_versions ev ON ev.id = es.experience_version_id
  JOIN public.experience_definitions ed ON ed.id = ev.experience_id
  WHERE c.is_active
    AND (
      es.user_id = c.id
      OR c.role = 'sys_admin'
      OR (c.role IN ('coach', 'org_admin') AND es.org_id = c.org_id)
    )
  ORDER BY es.completed_at DESC;
$$;

REVOKE EXECUTE ON FUNCTION public.list_accessible_results() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_accessible_results() TO authenticated;


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
    OR (
      v_caller.role IN ('coach', 'org_admin')
      AND v_target.org_id = v_caller.org_id
    )
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
        'event', 'result_viewed',
        'access_role', v_caller.role,
        'target_org_id', v_target.org_id
      )
    );
  END IF;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_session_result(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_session_result(UUID) TO authenticated;

