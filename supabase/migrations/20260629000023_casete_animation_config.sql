-- =====================================================
-- Migration 023: embedear animation_config en content.meta del casete
-- Problema: assemble_reto_version() no incluía animation_config en
--           content.meta, por lo que runner.js no podía leerla.
-- Solución: leer animation_config de experience_definitions y embeberla
--           en content.meta junto con los campos existentes.
-- Responsable: Andrés Muñoz | Fecha: 2026-06-29
-- =====================================================

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
  v_anim_config    JSONB;
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

  -- Obtener experiencia + tipo de metodología + animation_config
  SELECT
    ed.name,
    ed.description,
    ct.scoring_engine,
    ct.dimensions,
    ct.result_template,
    COALESCE(ed.animation_config, '{"type":"none","fallback":"tv_static"}'::jsonb)
  INTO
    v_exp_name,
    v_exp_desc,
    v_scoring_engine,
    v_ct_dimensions,
    v_ct_result_tmpl,
    v_anim_config
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
      SELECT jsonb_object_agg(
               qo.id::text,
               jsonb_build_object('D', qo.disc_d, 'I', qo.disc_i, 'S', qo.disc_s, 'C', qo.disc_c)
             )
      INTO v_weights_part
      FROM public.question_options qo
      WHERE qo.question_id = v_q_id AND qo.is_active;

    ELSE
      -- VIA y futuros: dimension_scores JSONB
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
    jsonb_build_object(
      'schema_version', '2.0',
      'meta', jsonb_build_object(
        'name',                  v_exp_name,
        'description',           v_exp_desc,
        'duration_minutes',      v_q_count * 2,
        'total_steps',           v_q_count,
        'capabilities_required', '["disc_scoring","sherpa_feedback","state_tracking"]'::jsonb,
        'randomize_questions',   true,
        'randomize_options',     true,
        'animation_config',      v_anim_config   -- ← NUEVO: embedido desde experience_definitions
      ),
      'steps',           v_steps,
      'result_template', v_ct_result_tmpl
    ),
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
  'Ensambla un casete desde el banco relacional. content.meta.animation_config embebido desde experience_definitions. Soporta DISC y VIA. Solo sys_admin.';
