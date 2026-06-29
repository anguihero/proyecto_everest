-- =====================================================
-- Migration 012: resultados auditables y métricas de tiempo
-- HU-CM-006, HU-RS-001, HU-GO-005
-- =====================================================

-- Compatibilidad con entornos donde 009 fue aplicada manualmente.
ALTER TABLE public.session_answers
  ADD COLUMN IF NOT EXISTS response_time_secs NUMERIC(6,2);

CREATE OR REPLACE FUNCTION public.get_session_result(p_session_id UUID)
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT jsonb_build_object(
    'result_id',             sr.id,
    'result_reference',      'EV-' || upper(left(replace(sr.id::text, '-', ''), 12)),
    'session_id',            es.id,
    'user_id',               es.user_id,
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
  FROM public.experience_sessions es
  JOIN public.score_results sr ON sr.session_id = es.id
  JOIN public.experience_versions ev ON ev.id = es.experience_version_id
  JOIN public.experience_definitions ed ON ed.id = ev.experience_id
  LEFT JOIN LATERAL (
    SELECT
      count(*)::int AS answered_steps,
      count(sa.response_time_secs)::int AS timed_answers,
      round(avg(sa.response_time_secs), 1) AS average_response_secs,
      md5(COALESCE(
        string_agg(
          sa.step_index::text || ':' || sa.option_key,
          '|' ORDER BY sa.step_index
        ),
        ''
      )) AS answer_fingerprint
    FROM public.session_answers sa
    WHERE sa.session_id = es.id
  ) metrics ON true
  WHERE es.id = p_session_id
    AND es.user_id = auth.uid();
$$;

REVOKE EXECUTE ON FUNCTION public.get_session_result(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_session_result(UUID) TO authenticated;

COMMENT ON FUNCTION public.get_session_result(UUID) IS
  'Resultado propio con IDs de auditoría, versiones, fingerprint y promedio de tiempo. No expone respuestas.';

