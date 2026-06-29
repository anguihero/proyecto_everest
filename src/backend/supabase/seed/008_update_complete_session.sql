-- =====================================================
-- Seed 008: Actualizar complete_session para scoring v2
-- HU-CM-006: Scoring DISC ponderado por opción (peso por UUID)
--
-- Cambios respecto a 006_session_functions.sql:
--  - Detecta scoring_rules.version ('1' vs '2')
--  - v1: sum por dimensión (lógica original intacta)
--  - v2: sum ponderado (disc_d/i/s/c por opción UUID)
--  - result_evidence v2: 4 filas por respuesta (una por dimensión)
--
-- Retrocompatibilidad: las sesiones v1 (3 preguntas) siguen funcionando.
-- Ejecutar DESPUÉS de 007_reto_fase0.sql
-- =====================================================

CREATE OR REPLACE FUNCTION public.complete_session(p_session_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_session         public.experience_sessions;
  v_version         public.experience_versions;
  v_content         JSONB;
  v_scoring         JSONB;
  v_scoring_ver     TEXT;
  v_total_required  INT;
  v_answered        INT;
  v_d               NUMERIC := 0;
  v_i               NUMERIC := 0;
  v_s               NUMERIC := 0;
  v_c               NUMERIC := 0;
  v_total           NUMERIC;
  v_scores          JSONB;
  v_result_id       UUID;
BEGIN
  -- 1. Validar sesión
  SELECT * INTO v_session
  FROM   public.experience_sessions
  WHERE  id      = p_session_id
    AND  user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  -- 1a. Idempotencia: ya completada → devolver resultado existente
  IF v_session.status::TEXT = 'completed' THEN
    SELECT jsonb_build_object(
      'session_id', p_session_id,
      'result_id',  sr.id,
      'scores',     sr.scores,
      'status',     'already_completed'
    )
    INTO v_scores
    FROM public.score_results sr
    WHERE sr.session_id = p_session_id;

    RETURN COALESCE(v_scores, jsonb_build_object(
      'session_id', p_session_id,
      'status',     'already_completed'
    ));
  END IF;

  IF v_session.status::TEXT != 'in_progress' THEN
    RAISE EXCEPTION 'session_not_active: %', v_session.status;
  END IF;

  -- 2. Obtener versión + reglas
  SELECT * INTO v_version
  FROM   public.experience_versions
  WHERE  id = v_session.experience_version_id;

  v_content     := v_version.content;
  v_scoring     := v_version.scoring_rules;
  v_scoring_ver := COALESCE(v_scoring->>'version', '1');

  -- 3. Validar completitud
  SELECT count(*) FILTER (WHERE (step->>'required')::boolean)
  INTO   v_total_required
  FROM   jsonb_array_elements(v_content->'steps') step;

  SELECT count(*) INTO v_answered
  FROM   public.session_answers
  WHERE  session_id = p_session_id;

  IF v_answered < v_total_required THEN
    RAISE EXCEPTION 'incomplete_session: % de % pasos requeridos respondidos', v_answered, v_total_required;
  END IF;

  -- 4. Calcular dimensiones DISC según versión de scoring
  IF v_scoring_ver = '2' THEN
    -- v2: cada opción (UUID) tiene pesos D/I/S/C individuales
    -- scoring_rules.weights = { "option-uuid": {"D": 0.70, "I": 0.10, "S": 0.10, "C": 0.10} }
    SELECT
      COALESCE(SUM((v_scoring->'weights'->sa.option_key->>'D')::numeric), 0),
      COALESCE(SUM((v_scoring->'weights'->sa.option_key->>'I')::numeric), 0),
      COALESCE(SUM((v_scoring->'weights'->sa.option_key->>'S')::numeric), 0),
      COALESCE(SUM((v_scoring->'weights'->sa.option_key->>'C')::numeric), 0)
    INTO v_d, v_i, v_s, v_c
    FROM public.session_answers sa
    WHERE sa.session_id = p_session_id
      AND (v_scoring->'weights'->sa.option_key) IS NOT NULL;

  ELSE
    -- v1: cada opción (letra A/B/C/D) mapea a UNA dimensión
    -- scoring_rules.steps = { "s01": { "A": "D", "B": "I", ... } }
    -- scoring_rules.weights = { "s01": 1, "s02": 1, ... }
    SELECT
      SUM(CASE WHEN dim = 'D' THEN w ELSE 0 END),
      SUM(CASE WHEN dim = 'I' THEN w ELSE 0 END),
      SUM(CASE WHEN dim = 'S' THEN w ELSE 0 END),
      SUM(CASE WHEN dim = 'C' THEN w ELSE 0 END)
    INTO v_d, v_i, v_s, v_c
    FROM (
      SELECT
        v_scoring->'steps'->( v_content->'steps'->sa.step_index->>'id' )->>sa.option_key AS dim,
        COALESCE(( v_scoring->'weights'->( v_content->'steps'->sa.step_index->>'id' ) )::numeric, 1.0) AS w
      FROM public.session_answers sa
      WHERE sa.session_id = p_session_id
    ) scored;
  END IF;

  -- 5. Normalizar (sum_to_one)
  v_total := GREATEST(
    COALESCE(v_d,0) + COALESCE(v_i,0) + COALESCE(v_s,0) + COALESCE(v_c,0),
    1
  );
  v_scores := jsonb_build_object(
    'D', round((COALESCE(v_d,0) / v_total)::numeric, 4),
    'I', round((COALESCE(v_i,0) / v_total)::numeric, 4),
    'S', round((COALESCE(v_s,0) / v_total)::numeric, 4),
    'C', round((COALESCE(v_c,0) / v_total)::numeric, 4)
  );

  -- 6. Guardar resultado (idempotente via UNIQUE session_id)
  INSERT INTO public.score_results
    (session_id, user_id, org_id, experience_version_id, scoring_version, scores, calculated_at)
  VALUES
    (p_session_id, auth.uid(), v_session.org_id,
     v_session.experience_version_id, v_version.scoring_version, v_scores, now())
  ON CONFLICT (session_id) DO NOTHING
  RETURNING id INTO v_result_id;

  IF v_result_id IS NULL THEN
    SELECT id INTO v_result_id FROM public.score_results WHERE session_id = p_session_id;
  END IF;

  -- 7. Guardar evidencias según versión de scoring
  IF v_scoring_ver = '2' THEN
    -- v2: 4 filas por respuesta (una por dimensión)
    INSERT INTO public.result_evidence
      (score_result_id, session_id, step_index, option_key, dimension, weight)
    SELECT
      v_result_id,
      sa.session_id,
      sa.step_index,
      sa.option_key,
      dim.d,
      COALESCE((v_scoring->'weights'->sa.option_key->>(dim.d))::numeric, 0)
    FROM public.session_answers sa
    CROSS JOIN (VALUES ('D'),('I'),('S'),('C')) AS dim(d)
    WHERE sa.session_id = p_session_id
      AND (v_scoring->'weights'->sa.option_key) IS NOT NULL
    ON CONFLICT DO NOTHING;

  ELSE
    -- v1: 1 fila por respuesta (dimensión única)
    INSERT INTO public.result_evidence
      (score_result_id, session_id, step_index, option_key, dimension, weight)
    SELECT
      v_result_id,
      sa.session_id,
      sa.step_index,
      sa.option_key,
      v_scoring->'steps'->( v_content->'steps'->sa.step_index->>'id' )->>sa.option_key,
      COALESCE(( v_scoring->'weights'->( v_content->'steps'->sa.step_index->>'id' ) )::numeric, 1.0)
    FROM public.session_answers sa
    WHERE sa.session_id = p_session_id
    ON CONFLICT DO NOTHING;
  END IF;

  -- 8. Marcar sesión completada
  UPDATE public.experience_sessions
  SET    status = 'completed', completed_at = now()
  WHERE  id = p_session_id;

  -- 9. Marcar asignación completada
  UPDATE public.experience_assignments
  SET    status = 'completed'
  WHERE  id = v_session.assignment_id;

  RETURN jsonb_build_object(
    'session_id', p_session_id,
    'result_id',  v_result_id,
    'scores',     v_scores,
    'status',     'completed'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.complete_session(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.complete_session(UUID) TO authenticated;


-- ─── Verificación ────────────────────────────────────

SELECT
  proname AS funcion,
  pg_get_function_arguments(oid) AS argumentos,
  prosecdef AS security_definer
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname = 'complete_session';
