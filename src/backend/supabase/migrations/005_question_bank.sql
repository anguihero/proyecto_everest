-- =====================================================
-- Migration 005: Question Bank — banco relacional de preguntas DISC
-- Tablas: questions, question_options, reto_compositions
-- Función: assemble_reto_version
--
-- Prerrequisito: 004_experience_meta.sql aplicada
-- Ejecutar en Supabase SQL Editor (proyecto fwwkchcxildykvfhrcri)
-- =====================================================


-- ─── 0. Validar prereqs ─────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE  table_schema = 'public'
      AND  table_name   = 'experience_definitions'
      AND  column_name  = 'name'
  ) THEN
    RAISE EXCEPTION '[005] Migration 004 no aplicada. Ejecuta 004_experience_meta.sql primero.';
  END IF;
END $$;


-- ─── 1. questions ────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.questions (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT         NOT NULL,
  text          TEXT         NOT NULL,
  difficulty    SMALLINT     NOT NULL DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 3),
  avg_time_secs INT          NOT NULL DEFAULT 60 CHECK (avg_time_secs > 0),
  context_notes TEXT,
  is_active     BOOLEAN      NOT NULL DEFAULT true,
  created_by    UUID         REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.questions IS 'Banco relacional de preguntas/escenarios para retos DISC.';
COMMENT ON COLUMN public.questions.difficulty IS '1=Fácil, 2=Medio, 3=Difícil';
COMMENT ON COLUMN public.questions.avg_time_secs IS 'Tiempo promedio de respuesta en segundos (usado para estimar duración del reto)';
COMMENT ON COLUMN public.questions.context_notes IS 'Notas internas: qué dimensión o competencia explora esta pregunta';


-- ─── 2. question_options ────────────────────────────

CREATE TABLE IF NOT EXISTS public.question_options (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID          NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  text        TEXT          NOT NULL,
  feedback    TEXT,
  disc_d      NUMERIC(4,3)  NOT NULL DEFAULT 0.25 CHECK (disc_d BETWEEN 0 AND 1),
  disc_i      NUMERIC(4,3)  NOT NULL DEFAULT 0.25 CHECK (disc_i BETWEEN 0 AND 1),
  disc_s      NUMERIC(4,3)  NOT NULL DEFAULT 0.25 CHECK (disc_s BETWEEN 0 AND 1),
  disc_c      NUMERIC(4,3)  NOT NULL DEFAULT 0.25 CHECK (disc_c BETWEEN 0 AND 1),
  sort_order  SMALLINT      NOT NULL DEFAULT 0,
  is_active   BOOLEAN       NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
  CONSTRAINT  disc_weights_sum CHECK (
    ABS(disc_d + disc_i + disc_s + disc_c - 1.0) < 0.01
  )
);

COMMENT ON COLUMN public.question_options.disc_d IS 'Peso Dominancia (0-1). Junto con I+S+C debe sumar 1.0';
COMMENT ON COLUMN public.question_options.disc_i IS 'Peso Influencia (0-1)';
COMMENT ON COLUMN public.question_options.disc_s IS 'Peso Estabilidad (0-1)';
COMMENT ON COLUMN public.question_options.disc_c IS 'Peso Conformidad/Consciencia (0-1)';
COMMENT ON COLUMN public.question_options.feedback IS 'Retroalimentación del Sherpa al seleccionar esta opción';

CREATE INDEX IF NOT EXISTS idx_question_options_question_id
  ON public.question_options(question_id);


-- ─── 3. reto_compositions ───────────────────────────

CREATE TABLE IF NOT EXISTS public.reto_compositions (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  experience_id UUID        NOT NULL REFERENCES public.experience_definitions(id) ON DELETE CASCADE,
  question_id   UUID        NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  sort_order    SMALLINT    NOT NULL DEFAULT 0,
  is_active     BOOLEAN     NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (experience_id, question_id)
);

COMMENT ON TABLE public.reto_compositions IS 'Qué preguntas componen cada reto (experience_definition). Permite reordenar, ocultar o agregar preguntas sin editar content JSONB.';

CREATE INDEX IF NOT EXISTS idx_reto_compositions_experience_id
  ON public.reto_compositions(experience_id);


-- ─── 4. Trigger updated_at ──────────────────────────

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_questions_updated_at') THEN
    CREATE TRIGGER trg_questions_updated_at
      BEFORE UPDATE ON public.questions
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_question_options_updated_at') THEN
    CREATE TRIGGER trg_question_options_updated_at
      BEFORE UPDATE ON public.question_options
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;


-- ─── 5. RLS ─────────────────────────────────────────

ALTER TABLE public.questions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_options   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reto_compositions  ENABLE ROW LEVEL SECURITY;

-- sys_admin: CRUD total sobre las tres tablas
CREATE POLICY questions_sys_admin ON public.questions
  FOR ALL TO authenticated
  USING     ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'sys_admin')
  WITH CHECK((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'sys_admin');

CREATE POLICY question_options_sys_admin ON public.question_options
  FOR ALL TO authenticated
  USING     ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'sys_admin')
  WITH CHECK((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'sys_admin');

CREATE POLICY reto_compositions_sys_admin ON public.reto_compositions
  FOR ALL TO authenticated
  USING     ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'sys_admin')
  WITH CHECK((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'sys_admin');

-- El resto de roles accede SOLO a través de SECURITY DEFINER functions
-- (start_or_resume_session, assemble_reto_version). Sin acceso directo.


-- ─── 6. assemble_reto_version ───────────────────────
-- Construye content (v2) + scoring_rules (v2) desde las tablas relacionales
-- y crea un nuevo experience_versions publicado.
-- Solo sys_admin puede invocarla con auth context.
-- Los seeds internos la llaman sin auth (auth.uid() = NULL).

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
  v_caller_role  TEXT;
  v_exp_name     TEXT;
  v_exp_desc     TEXT;
  v_q_count      INT;
  v_steps        JSONB := '[]'::jsonb;
  v_weights      JSONB := '{}'::jsonb;
  v_step_index   INT   := 0;
  v_q_id         UUID;
  v_q_title      TEXT;
  v_q_text       TEXT;
  v_opts_arr     JSONB;
  v_feedback_obj JSONB;
  v_weights_part JSONB;
  v_step         JSONB;
  v_version_id   UUID;
  v_version_label TEXT;
BEGIN
  -- Verificar rol cuando hay sesión de usuario (no en seeds internos)
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
    RAISE EXCEPTION 'no_active_questions: la experiencia % no tiene preguntas activas en compositions', p_experience_id;
  END IF;

  -- Iterar preguntas en orden canonical
  FOR v_q_id, v_q_title, v_q_text IN
    SELECT  q.id, q.title, q.text
    FROM    public.reto_compositions rc
    JOIN    public.questions q ON q.id = rc.question_id
    WHERE   rc.experience_id = p_experience_id
      AND   rc.is_active
      AND   q.is_active
    ORDER BY rc.sort_order, rc.created_at
  LOOP
    -- Opciones del paso (array de {key, text, visible})
    SELECT jsonb_agg(
             jsonb_build_object('key', qo.id::text, 'text', qo.text, 'visible', true)
             ORDER BY qo.sort_order
           )
    INTO   v_opts_arr
    FROM   public.question_options qo
    WHERE  qo.question_id = v_q_id AND qo.is_active;

    -- Feedback del paso (objeto {option_uuid: feedback_text})
    SELECT jsonb_object_agg(qo.id::text, COALESCE(qo.feedback, ''))
    INTO   v_feedback_obj
    FROM   public.question_options qo
    WHERE  qo.question_id = v_q_id AND qo.is_active;

    -- Pesos DISC de las opciones → scoring_rules.weights
    SELECT jsonb_object_agg(
             qo.id::text,
             jsonb_build_object('D', qo.disc_d, 'I', qo.disc_i, 'S', qo.disc_s, 'C', qo.disc_c)
           )
    INTO   v_weights_part
    FROM   public.question_options qo
    WHERE  qo.question_id = v_q_id AND qo.is_active;

    v_weights := v_weights || COALESCE(v_weights_part, '{}');

    -- Construir objeto de paso
    v_step := jsonb_build_object(
      'id',       v_q_id::text,
      'index',    v_step_index,
      'type',     'scenario',
      'required', true,
      'content',  jsonb_build_object(
        'title',     v_q_title,
        'narrative', v_q_text,
        'context',   null
      ),
      'options',   COALESCE(v_opts_arr,   '[]'::jsonb),
      'feedback',  COALESCE(v_feedback_obj, '{}'::jsonb)
    );

    v_steps      := v_steps || v_step;
    v_step_index := v_step_index + 1;
  END LOOP;

  -- Etiqueta de versión automática si no se provee
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
    -- content v2
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
    -- scoring_rules v2 (pesos por UUID de opción)
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


-- ─── 7. Verificación ─────────────────────────────────

SELECT 'questions'          AS tabla, COUNT(*) AS filas FROM public.questions
UNION ALL
SELECT 'question_options',          COUNT(*)             FROM public.question_options
UNION ALL
SELECT 'reto_compositions',         COUNT(*)             FROM public.reto_compositions;

SELECT
  proname AS funcion,
  prosecdef AS security_definer
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname = 'assemble_reto_version';
