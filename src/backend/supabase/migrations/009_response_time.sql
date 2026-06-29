-- =====================================================
-- Migration 009: Tiempo de respuesta + timer en content
--
-- Cambios:
--  1. session_answers.response_time_secs — registra velocidad
--  2. save_step_answer agrega parámetro p_elapsed_secs
--  3. assemble_reto_version incluye time_secs en cada step
--  4. Re-ensambla expedicion-base como v2.1.0
--
-- Prerrequisito: 005_question_bank.sql, 007_reto_fase0.sql aplicadas
-- Ejecutar en Supabase SQL Editor (proyecto fwwkchcxildykvfhrcri)
-- =====================================================


-- ─── 1. Columna de tiempo de respuesta ──────────────

ALTER TABLE public.session_answers
  ADD COLUMN IF NOT EXISTS response_time_secs NUMERIC(6,2);

COMMENT ON COLUMN public.session_answers.response_time_secs IS
  'Tiempo que tardó el usuario en responder en segundos (con décimas). Null si el cliente no lo envió o es una sesión reanudada.';


-- ─── 2. save_step_answer con elapsed_secs ───────────
-- La firma cambia (3→4 args), hay que eliminar la anterior primero.

DROP FUNCTION IF EXISTS public.save_step_answer(UUID, INT, TEXT);

CREATE OR REPLACE FUNCTION public.save_step_answer(
  p_session_id   UUID,
  p_step_index   INT,
  p_option_key   TEXT,
  p_elapsed_secs NUMERIC DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_session     public.experience_sessions;
  v_version     public.experience_versions;
  v_idempotency TEXT;
  v_feedback    TEXT;
BEGIN
  -- 1. Validar sesión activa del usuario autenticado
  SELECT * INTO v_session
  FROM   public.experience_sessions
  WHERE  id            = p_session_id
    AND  user_id       = auth.uid()
    AND  status::TEXT  = 'in_progress';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'session_not_found_or_inactive';
  END IF;

  -- 2. Idempotency key: primera respuesta gana (response_time de la primera)
  v_idempotency := p_session_id::TEXT || ':' || p_step_index::TEXT;

  INSERT INTO public.session_answers
    (session_id, user_id, step_index, option_key, idempotency_key, response_time_secs)
  VALUES
    (p_session_id, auth.uid(), p_step_index, p_option_key, v_idempotency,
     CASE WHEN p_elapsed_secs IS NOT NULL AND p_elapsed_secs >= 0
          THEN round(p_elapsed_secs::numeric, 2)
          ELSE NULL
     END)
  ON CONFLICT (idempotency_key) DO NOTHING;

  -- 3. Avanzar current_step
  UPDATE public.experience_sessions
  SET    current_step  = GREATEST(current_step, p_step_index + 1),
         last_saved_at = now()
  WHERE  id = p_session_id;

  -- 4. Feedback del content JSONB (null para v2 — el cliente lo resuelve)
  SELECT * INTO v_version
  FROM   public.experience_versions
  WHERE  id = v_session.experience_version_id;

  v_feedback := v_version.content->'steps'->p_step_index->'feedback'->>p_option_key;

  RETURN jsonb_build_object(
    'saved',        true,
    'step_index',   p_step_index,
    'option_key',   p_option_key,
    'feedback',     v_feedback
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.save_step_answer(UUID, INT, TEXT, NUMERIC) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.save_step_answer(UUID, INT, TEXT, NUMERIC) TO authenticated;


-- ─── 3. assemble_reto_version con time_secs ─────────
-- Incluye avg_time_secs de cada pregunta en step.content.time_secs

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
  v_caller_role   TEXT;
  v_exp_name      TEXT;
  v_exp_desc      TEXT;
  v_q_count       INT;
  v_steps         JSONB := '[]'::jsonb;
  v_weights       JSONB := '{}'::jsonb;
  v_step_index    INT   := 0;
  v_q_id          UUID;
  v_q_title       TEXT;
  v_q_text        TEXT;
  v_q_time_secs   INT;
  v_opts_arr      JSONB;
  v_feedback_obj  JSONB;
  v_weights_part  JSONB;
  v_step          JSONB;
  v_version_id    UUID;
  v_version_label TEXT;
BEGIN
  -- Verificar rol cuando hay sesión de usuario (no en seeds)
  IF auth.uid() IS NOT NULL THEN
    SELECT role INTO v_caller_role
    FROM public.profiles WHERE id = auth.uid();
    IF COALESCE(v_caller_role, '') != 'sys_admin' THEN
      RAISE EXCEPTION 'forbidden: solo sys_admin puede ensamblar versiones';
    END IF;
  END IF;

  -- Obtener experiencia
  SELECT name, description
  INTO   v_exp_name, v_exp_desc
  FROM   public.experience_definitions
  WHERE  id = p_experience_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'experience_not_found: %', p_experience_id;
  END IF;

  -- Contar preguntas activas
  SELECT COUNT(*)
  INTO   v_q_count
  FROM   public.reto_compositions rc
  JOIN   public.questions q ON q.id = rc.question_id
  WHERE  rc.experience_id = p_experience_id
    AND  rc.is_active
    AND  q.is_active;

  IF v_q_count = 0 THEN
    RAISE EXCEPTION 'no_active_questions: la experiencia % no tiene preguntas activas', p_experience_id;
  END IF;

  -- Iterar preguntas en orden canonical
  FOR v_q_id, v_q_title, v_q_text, v_q_time_secs IN
    SELECT  q.id, q.title, q.text, q.avg_time_secs
    FROM    public.reto_compositions rc
    JOIN    public.questions q ON q.id = rc.question_id
    WHERE   rc.experience_id = p_experience_id
      AND   rc.is_active
      AND   q.is_active
    ORDER BY rc.sort_order, rc.created_at
  LOOP
    -- Opciones (array para el content)
    SELECT jsonb_agg(
             jsonb_build_object('key', qo.id::text, 'text', qo.text, 'visible', true)
             ORDER BY qo.sort_order
           )
    INTO   v_opts_arr
    FROM   public.question_options qo
    WHERE  qo.question_id = v_q_id AND qo.is_active;

    -- Feedback por opción
    SELECT jsonb_object_agg(qo.id::text, COALESCE(qo.feedback, ''))
    INTO   v_feedback_obj
    FROM   public.question_options qo
    WHERE  qo.question_id = v_q_id AND qo.is_active;

    -- Pesos DISC → scoring_rules.weights
    SELECT jsonb_object_agg(
             qo.id::text,
             jsonb_build_object('D', qo.disc_d, 'I', qo.disc_i, 'S', qo.disc_s, 'C', qo.disc_c)
           )
    INTO   v_weights_part
    FROM   public.question_options qo
    WHERE  qo.question_id = v_q_id AND qo.is_active;

    v_weights := v_weights || COALESCE(v_weights_part, '{}');

    -- Construir step (incluye time_secs para el timer del cliente)
    v_step := jsonb_build_object(
      'id',       v_q_id::text,
      'index',    v_step_index,
      'type',     'scenario',
      'required', true,
      'content',  jsonb_build_object(
        'title',     v_q_title,
        'narrative', v_q_text,
        'context',   null,
        'time_secs', v_q_time_secs
      ),
      'options',   COALESCE(v_opts_arr,    '[]'::jsonb),
      'feedback',  COALESCE(v_feedback_obj, '{}'::jsonb)
    );

    v_steps      := v_steps || v_step;
    v_step_index := v_step_index + 1;
  END LOOP;

  -- Etiqueta de versión automática
  IF p_version_label IS NULL THEN
    SELECT '2.' || (COUNT(*) + 1)::text || '.0'
    INTO   v_version_label
    FROM   public.experience_versions
    WHERE  experience_id = p_experience_id AND schema_version = '2.0';
  ELSE
    v_version_label := p_version_label;
  END IF;

  -- Insertar nueva versión publicada
  INSERT INTO public.experience_versions
    (experience_id, version, schema_version, scoring_version, status, content, scoring_rules, created_at)
  VALUES (
    p_experience_id,
    v_version_label,
    '2.0',
    '2.0',
    'published',
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
      'steps', v_steps,
      'result_template', jsonb_build_object(
        'type',          'disc_profile',
        'dimensions',    '["D","I","S","C"]'::jsonb,
        'normalization', 'sum_to_one'
      )
    ),
    jsonb_build_object(
      'version',    '2',
      'type',       'disc_weighted',
      'dimensions', '["D","I","S","C"]'::jsonb,
      'weights',    v_weights
    ),
    now()
  )
  RETURNING id INTO v_version_id;

  RETURN v_version_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.assemble_reto_version(UUID, TEXT, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.assemble_reto_version(UUID, TEXT, UUID) TO authenticated;


-- ─── 4. Re-ensamblar expedicion-base con time_secs ──

DO $$
DECLARE
  v_new_id UUID;
BEGIN
  -- Retirar v2.0.0 (sin time_secs)
  UPDATE public.experience_versions
  SET    status = 'retired'
  WHERE  experience_id = 'b0000000-0000-0000-0000-000000000001'
    AND  schema_version = '2.0'
    AND  status = 'published';

  -- Ensamblar v2.1.0 con time_secs por pregunta
  SELECT public.assemble_reto_version(
    'b0000000-0000-0000-0000-000000000001',
    '2.1.0',
    NULL
  ) INTO v_new_id;

  -- Migrar asignaciones activas
  UPDATE public.experience_assignments
  SET    experience_version_id = v_new_id
  WHERE  experience_id = 'b0000000-0000-0000-0000-000000000001'
    AND  status != 'completed';

  RAISE NOTICE 'v2.1.0 con time_secs publicada: %', v_new_id;
END $$;


-- ─── Verificación ────────────────────────────────────

SELECT
  'session_answers.response_time_secs' AS check,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'session_answers'
  AND column_name  = 'response_time_secs'

UNION ALL

SELECT
  'save_step_answer (4 args)' AS check,
  pg_get_function_arguments(oid)
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname = 'save_step_answer'

UNION ALL

SELECT
  'v2.1.0 publicada' AS check,
  version
FROM public.experience_versions
WHERE experience_id = 'b0000000-0000-0000-0000-000000000001'
  AND status = 'published';
