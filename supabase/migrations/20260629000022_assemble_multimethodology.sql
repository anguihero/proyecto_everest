-- =====================================================
-- Migration 022: assemble_reto_version() multi-metodología
-- Plan: PLAN_JERARQUIA_RETOS_MULTIMETODOLOGIA.md
-- Responsable: Andrés Muñoz | Fecha: 2026-06-29
--
-- Cambios:
--   - Reemplaza assemble_reto_version() para soportar DISC y VIA
--   - DISC: backward-compat con disc_d/i/s/c (columnas existentes)
--   - VIA:  lee dimension_scores JSONB (nueva columna)
--   - content.result_template se toma de challenge_types.result_template
--   - scoring_rules incluye scoring_engine y dimensions del tipo
--   - Nueva función: get_challenge_types() para el frontend de fábrica
--   - Nueva función: get_questions_by_type() para el frontend de fábrica
-- =====================================================

-- ─── 1. assemble_reto_version() actualizada ─────────

CREATE OR REPLACE FUNCTION public.assemble_reto_version(
  p_experience_id UUID,
  p_version_label TEXT DEFAULT NULL,
  p_created_by    UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_role    TEXT;
  v_exp_name       TEXT;
  v_exp_desc       TEXT;
  v_scoring_engine TEXT;
  v_ct_dimensions  JSONB;
  v_ct_result_tmpl JSONB;
  v_q_count        INT;
  v_steps          JSONB := '[]'::jsonb;
  v_weights        JSONB := '{}'::jsonb;
  v_step_index     INT   := 0;
  v_q_id           UUID;
  v_q_title        TEXT;
  v_q_text         TEXT;
  v_opts_arr       JSONB;
  v_feedback_obj   JSONB;
  v_weights_part   JSONB;
  v_step           JSONB;
  v_version_id     UUID;
  v_version_label  TEXT;
BEGIN
  -- Verificar rol cuando hay sesión de usuario (no en seeds internos)
  IF auth.uid() IS NOT NULL THEN
    SELECT role INTO v_caller_role
    FROM public.profiles WHERE id = auth.uid();

    IF COALESCE(v_caller_role, '') != 'sys_admin' THEN
      RAISE EXCEPTION 'forbidden: solo sys_admin puede ensamblar versiones';
    END IF;
  END IF;

  -- Obtener experiencia + tipo de metodología
  SELECT
    ed.name,
    ed.description,
    ct.scoring_engine,
    ct.dimensions,
    ct.result_template
  INTO
    v_exp_name,
    v_exp_desc,
    v_scoring_engine,
    v_ct_dimensions,
    v_ct_result_tmpl
  FROM public.experience_definitions ed
  JOIN public.challenge_types ct ON ct.id = ed.challenge_type_id
  WHERE ed.id = p_experience_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'experience_not_found: %', p_experience_id;
  END IF;

  -- Contar preguntas activas
  SELECT COUNT(*) INTO v_q_count
  FROM public.reto_compositions rc
  JOIN public.questions q ON q.id = rc.question_id
  WHERE rc.experience_id = p_experience_id
    AND rc.is_active AND q.is_active;

  IF v_q_count = 0 THEN
    RAISE EXCEPTION 'no_active_questions: la experiencia % no tiene preguntas activas', p_experience_id;
  END IF;

  -- Iterar preguntas en orden canónico
  FOR v_q_id, v_q_title, v_q_text IN
    SELECT q.id, q.title, q.text
    FROM   public.reto_compositions rc
    JOIN   public.questions q ON q.id = rc.question_id
    WHERE  rc.experience_id = p_experience_id
      AND  rc.is_active AND q.is_active
    ORDER BY rc.sort_order, rc.created_at
  LOOP
    -- Opciones del paso
    SELECT jsonb_agg(
             jsonb_build_object('key', qo.id::text, 'text', qo.text, 'visible', true)
             ORDER BY qo.sort_order
           )
    INTO v_opts_arr
    FROM public.question_options qo
    WHERE qo.question_id = v_q_id AND qo.is_active;

    -- Feedback del paso
    SELECT jsonb_object_agg(qo.id::text, COALESCE(qo.feedback, ''))
    INTO v_feedback_obj
    FROM public.question_options qo
    WHERE qo.question_id = v_q_id AND qo.is_active;

    -- Pesos según scoring_engine
    IF v_scoring_engine = 'disc_weighted' THEN
      -- DISC: columnas disc_d/i/s/c (backward-compat)
      SELECT jsonb_object_agg(
               qo.id::text,
               jsonb_build_object('D', qo.disc_d, 'I', qo.disc_i, 'S', qo.disc_s, 'C', qo.disc_c)
             )
      INTO v_weights_part
      FROM public.question_options qo
      WHERE qo.question_id = v_q_id AND qo.is_active;

    ELSIF v_scoring_engine = 'via_weighted' THEN
      -- VIA: dimension_scores JSONB
      SELECT jsonb_object_agg(qo.id::text, qo.dimension_scores)
      INTO v_weights_part
      FROM public.question_options qo
      WHERE qo.question_id = v_q_id AND qo.is_active;

    ELSE
      -- Futuro: scoring genérico — usar dimension_scores
      SELECT jsonb_object_agg(qo.id::text, qo.dimension_scores)
      INTO v_weights_part
      FROM public.question_options qo
      WHERE qo.question_id = v_q_id AND qo.is_active;
    END IF;

    v_weights    := v_weights || COALESCE(v_weights_part, '{}');
    v_step_index := v_step_index + 1;

    v_step := jsonb_build_object(
      'id',       v_q_id::text,
      'index',    v_step_index - 1,
      'type',     'scenario',
      'required', true,
      'content',  jsonb_build_object(
        'title',     v_q_title,
        'narrative', v_q_text,
        'context',   null
      ),
      'options',  COALESCE(v_opts_arr,    '[]'::jsonb),
      'feedback', COALESCE(v_feedback_obj, '{}'::jsonb)
    );

    v_steps := v_steps || v_step;
  END LOOP;

  -- Etiqueta de versión automática
  IF p_version_label IS NULL THEN
    SELECT '2.' || (COUNT(*) + 1)::text || '.0'
    INTO v_version_label
    FROM public.experience_versions
    WHERE experience_id = p_experience_id AND schema_version = '2.0';
  ELSE
    v_version_label := p_version_label;
  END IF;

  -- Insertar nueva versión publicada
  INSERT INTO public.experience_versions
    (experience_id, version, schema_version, scoring_version, status,
     content, scoring_rules, published_by, published_at, created_at)
  VALUES (
    p_experience_id,
    v_version_label,
    '2.0',
    '2.0',
    'published',
    -- content v2 (result_template viene del challenge_type)
    jsonb_build_object(
      'schema_version', '2.0',
      'meta', jsonb_build_object(
        'name',                  v_exp_name,
        'description',           v_exp_desc,
        'duration_minutes',      v_q_count * 2,
        'total_steps',           v_q_count,
        'capabilities_required', '["disc_scoring","sherpa_feedback","state_tracking"]'::jsonb,
        'randomize_questions',   true,
        'randomize_options',     true
      ),
      'steps',           v_steps,
      'result_template', v_ct_result_tmpl
    ),
    -- scoring_rules v2 (incluye engine y dimensions del tipo)
    jsonb_build_object(
      'version',    '2',
      'type',       v_scoring_engine,
      'dimensions', v_ct_dimensions,
      'weights',    v_weights
    ),
    p_created_by,
    CASE WHEN p_created_by IS NOT NULL THEN now() ELSE NULL END,
    now()
  )
  RETURNING id INTO v_version_id;

  RETURN v_version_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.assemble_reto_version(UUID, TEXT, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.assemble_reto_version(UUID, TEXT, UUID) TO authenticated;

COMMENT ON FUNCTION public.assemble_reto_version(UUID, TEXT, UUID) IS
  'Ensambla un casete desde el banco relacional. Soporta DISC (disc_d/i/s/c) y VIA (dimension_scores JSONB). Solo sys_admin.';


-- ─── 2. get_challenge_types() — para fábrica frontend ─

CREATE OR REPLACE FUNCTION public.get_challenge_types()
RETURNS TABLE (
  id             UUID,
  slug           TEXT,
  name           TEXT,
  description    TEXT,
  dimensions     JSONB,
  result_template JSONB,
  scoring_engine TEXT,
  reto_count     BIGINT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT
    ct.id,
    ct.slug,
    ct.name,
    ct.description,
    ct.dimensions,
    ct.result_template,
    ct.scoring_engine,
    COUNT(ed.id) AS reto_count
  FROM public.challenge_types ct
  LEFT JOIN public.experience_definitions ed
    ON ed.challenge_type_id = ct.id AND ed.is_active
  WHERE ct.is_active
  GROUP BY ct.id
  ORDER BY ct.name;
$$;

REVOKE EXECUTE ON FUNCTION public.get_challenge_types() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_challenge_types() TO authenticated;


-- ─── 3. get_questions_by_type() — para fábrica frontend ─

CREATE OR REPLACE FUNCTION public.get_questions_by_type(
  p_challenge_type_id UUID,
  p_include_inactive  BOOLEAN DEFAULT false
)
RETURNS TABLE (
  id              UUID,
  title           TEXT,
  text            TEXT,
  difficulty      SMALLINT,
  avg_time_secs   INT,
  context_notes   TEXT,
  framework_notes TEXT,
  is_active       BOOLEAN,
  options_count   BIGINT,
  created_at      TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT
    q.id,
    q.title,
    q.text,
    q.difficulty,
    q.avg_time_secs,
    q.context_notes,
    q.framework_notes,
    q.is_active,
    COUNT(qo.id) AS options_count,
    q.created_at
  FROM public.questions q
  LEFT JOIN public.question_options qo ON qo.question_id = q.id AND qo.is_active
  WHERE q.challenge_type_id = p_challenge_type_id
    AND (p_include_inactive OR q.is_active)
  GROUP BY q.id
  ORDER BY q.created_at DESC;
$$;

REVOKE EXECUTE ON FUNCTION public.get_questions_by_type(UUID, BOOLEAN) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_questions_by_type(UUID, BOOLEAN) TO authenticated;


-- ─── 4. create_question() — fábrica desde UI ─────────

CREATE OR REPLACE FUNCTION public.create_question(
  p_challenge_type_id UUID,
  p_title             TEXT,
  p_text              TEXT,
  p_difficulty        SMALLINT DEFAULT 2,
  p_avg_time_secs     INT      DEFAULT 60,
  p_context_notes     TEXT     DEFAULT NULL,
  p_framework_notes   TEXT     DEFAULT NULL,
  p_options           JSONB    DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_role TEXT;
  v_question_id UUID;
  v_opt         JSONB;
  v_sort        SMALLINT := 0;
BEGIN
  -- Solo sys_admin puede crear preguntas
  SELECT role INTO v_caller_role FROM public.profiles WHERE id = auth.uid();
  IF COALESCE(v_caller_role, '') != 'sys_admin' THEN
    RAISE EXCEPTION 'forbidden: solo sys_admin puede crear preguntas';
  END IF;

  -- Validar challenge_type existe
  IF NOT EXISTS (SELECT 1 FROM public.challenge_types WHERE id = p_challenge_type_id AND is_active) THEN
    RAISE EXCEPTION 'invalid_challenge_type: %', p_challenge_type_id;
  END IF;

  -- Insertar pregunta
  INSERT INTO public.questions
    (challenge_type_id, title, text, difficulty, avg_time_secs,
     context_notes, framework_notes, created_by)
  VALUES
    (p_challenge_type_id, p_title, p_text, p_difficulty, p_avg_time_secs,
     p_context_notes, p_framework_notes, auth.uid())
  RETURNING id INTO v_question_id;

  -- Insertar opciones si se proveen
  IF p_options IS NOT NULL AND jsonb_array_length(p_options) > 0 THEN
    FOR v_opt IN SELECT * FROM jsonb_array_elements(p_options)
    LOOP
      INSERT INTO public.question_options
        (question_id, text, feedback, disc_d, disc_i, disc_s, disc_c,
         dimension_scores, sort_order)
      VALUES (
        v_question_id,
        v_opt->>'text',
        v_opt->>'feedback',
        COALESCE((v_opt->>'disc_d')::NUMERIC, 0.25),
        COALESCE((v_opt->>'disc_i')::NUMERIC, 0.25),
        COALESCE((v_opt->>'disc_s')::NUMERIC, 0.25),
        COALESCE((v_opt->>'disc_c')::NUMERIC, 0.25),
        COALESCE(v_opt->'dimension_scores', '{}'),
        v_sort
      );
      v_sort := v_sort + 1;
    END LOOP;
  END IF;

  RETURN v_question_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_question(UUID,TEXT,TEXT,SMALLINT,INT,TEXT,TEXT,JSONB) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.create_question(UUID,TEXT,TEXT,SMALLINT,INT,TEXT,TEXT,JSONB) TO authenticated;


-- ─── 5. Verificación ─────────────────────────────────

SELECT proname AS funcion, prosecdef AS security_definer
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'assemble_reto_version',
    'get_challenge_types',
    'get_questions_by_type',
    'create_question'
  )
ORDER BY proname;
