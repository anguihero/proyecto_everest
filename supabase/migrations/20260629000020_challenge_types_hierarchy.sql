-- =====================================================
-- Migration 020: challenge_types — Jerarquía de retos multi-metodología
-- Plan: PLAN_JERARQUIA_RETOS_MULTIMETODOLOGIA.md
-- Responsable: Andrés Muñoz | Fecha: 2026-06-29
--
-- Cambios:
--   1. Nueva tabla challenge_types (Nivel 1 de jerarquía)
--   2. FK challenge_type_id en experience_definitions (Nivel 2)
--   3. FK challenge_type_id + framework_notes en questions (Nivel 3)
--   4. Columna dimension_scores JSONB en question_options (Nivel 4, genérico)
--   5. Columna animation_config JSONB en experience_definitions
--   6. Trigger de integridad: reto_compositions valida tipo coincidente
--   7. Datos iniciales: DISC y VIA
--   8. Backfill: todos los registros existentes → DISC
-- =====================================================

-- ─── 1. Tabla challenge_types ───────────────────────

CREATE TABLE public.challenge_types (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT         NOT NULL UNIQUE,
  name            TEXT         NOT NULL,
  description     TEXT,
  dimensions      JSONB        NOT NULL DEFAULT '{}',
  result_template JSONB        NOT NULL DEFAULT '{}',
  scoring_engine  TEXT         NOT NULL DEFAULT 'disc_weighted',
  is_active       BOOLEAN      NOT NULL DEFAULT true,
  created_by      UUID         REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.challenge_types IS
  'Metodologías psicométricas disponibles (DISC, VIA, etc.). Nivel 1 de la jerarquía de retos.';
COMMENT ON COLUMN public.challenge_types.dimensions IS
  'Mapa de dimensiones evaluadas. DISC: {"D":{"label":"Dominancia",...},...}. VIA: {"creatividad":{"virtue":"sabiduria","label":"Creatividad"},...}';
COMMENT ON COLUMN public.challenge_types.result_template IS
  'Cómo visualizar el resultado: tipo de radar, ejes, normalización, colores.';
COMMENT ON COLUMN public.challenge_types.scoring_engine IS
  'Motor de scoring: disc_weighted | via_weighted | futuro.';

CREATE INDEX idx_challenge_types_slug ON public.challenge_types(slug);

-- RLS: autenticados ven tipos activos; solo sys_admin gestiona
ALTER TABLE public.challenge_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY challenge_types_read ON public.challenge_types
  FOR SELECT TO authenticated
  USING (is_active = true);

CREATE POLICY challenge_types_manage ON public.challenge_types
  FOR ALL TO authenticated
  USING     (public.i_am_sys_admin())
  WITH CHECK(public.i_am_sys_admin());

-- Trigger updated_at
CREATE TRIGGER trg_challenge_types_updated_at
  BEFORE UPDATE ON public.challenge_types
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ─── 2. Datos iniciales: DISC ────────────────────────

INSERT INTO public.challenge_types
  (id, slug, name, description, dimensions, result_template, scoring_engine)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'disc',
  'DISC',
  'Modelo de comportamiento conductual: Dominancia, Influencia, Estabilidad y Conformidad.',
  '{
    "D": {"label": "Dominancia",   "color": "#E53E3E",
          "description": "Orientación a resultados, decisión directa, control de entorno."},
    "I": {"label": "Influencia",   "color": "#ED8936",
          "description": "Entusiasmo, persuasión, optimismo, interacción social."},
    "S": {"label": "Estabilidad",  "color": "#38A169",
          "description": "Paciencia, consistencia, apoyo al equipo, aversión al cambio brusco."},
    "C": {"label": "Conformidad",  "color": "#3182CE",
          "description": "Precisión, análisis riguroso, cumplimiento de normas y estándares."}
  }',
  '{
    "type": "radar",
    "axes": ["D","I","S","C"],
    "normalization": "sum_to_one",
    "primary_label": "Dimensión predominante",
    "display_mode": "disc_profile"
  }',
  'disc_weighted'
);


-- ─── 3. Datos iniciales: VIA ─────────────────────────

INSERT INTO public.challenge_types
  (id, slug, name, description, dimensions, result_template, scoring_engine)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'via',
  'VIA Fortalezas de Carácter',
  '24 fortalezas de carácter clasificadas en 6 virtudes (Peterson & Seligman, 2004). Evaluación "Fortalezas en Conflicto".',
  '{
    "creatividad":            {"virtue":"sabiduria",     "label":"Creatividad",                "sort":1},
    "curiosidad":             {"virtue":"sabiduria",     "label":"Curiosidad",                 "sort":2},
    "apertura_mental":        {"virtue":"sabiduria",     "label":"Apertura mental",            "sort":3},
    "amor_aprendizaje":       {"virtue":"sabiduria",     "label":"Amor por el aprendizaje",    "sort":4},
    "perspectiva":            {"virtue":"sabiduria",     "label":"Perspectiva",                "sort":5},
    "valentia":               {"virtue":"coraje",        "label":"Valentía",                   "sort":6},
    "perseverancia":          {"virtue":"coraje",        "label":"Perseverancia",              "sort":7},
    "honestidad":             {"virtue":"coraje",        "label":"Honestidad",                 "sort":8},
    "vitalidad":              {"virtue":"coraje",        "label":"Vitalidad/Entusiasmo",       "sort":9},
    "amor":                   {"virtue":"humanidad",     "label":"Amor",                       "sort":10},
    "amabilidad":             {"virtue":"humanidad",     "label":"Amabilidad",                 "sort":11},
    "inteligencia_social":    {"virtue":"humanidad",     "label":"Inteligencia social",        "sort":12},
    "trabajo_equipo":         {"virtue":"justicia",      "label":"Trabajo en equipo",          "sort":13},
    "equidad":                {"virtue":"justicia",      "label":"Equidad",                    "sort":14},
    "liderazgo_via":          {"virtue":"justicia",      "label":"Liderazgo",                  "sort":15},
    "perdon":                 {"virtue":"templanza",     "label":"Perdón",                     "sort":16},
    "humildad":               {"virtue":"templanza",     "label":"Humildad",                   "sort":17},
    "prudencia":              {"virtue":"templanza",     "label":"Prudencia",                  "sort":18},
    "autorregulacion":        {"virtue":"templanza",     "label":"Autorregulación",            "sort":19},
    "gratitud":               {"virtue":"trascendencia", "label":"Gratitud",                   "sort":20},
    "esperanza":              {"virtue":"trascendencia", "label":"Esperanza",                  "sort":21},
    "humor":                  {"virtue":"trascendencia", "label":"Humor",                      "sort":22},
    "apreciacion_excelencia": {"virtue":"trascendencia", "label":"Apreciación de la excelencia","sort":23},
    "espiritualidad":         {"virtue":"trascendencia", "label":"Espiritualidad/Propósito",   "sort":24}
  }',
  '{
    "type": "virtue_radar",
    "virtues": {
      "sabiduria":     {"label":"Sabiduría",     "color":"#805AD5",
                        "keys":["creatividad","curiosidad","apertura_mental","amor_aprendizaje","perspectiva"]},
      "coraje":        {"label":"Coraje",         "color":"#E53E3E",
                        "keys":["valentia","perseverancia","honestidad","vitalidad"]},
      "humanidad":     {"label":"Humanidad",      "color":"#ED8936",
                        "keys":["amor","amabilidad","inteligencia_social"]},
      "justicia":      {"label":"Justicia",       "color":"#38A169",
                        "keys":["trabajo_equipo","equidad","liderazgo_via"]},
      "templanza":     {"label":"Templanza",      "color":"#3182CE",
                        "keys":["perdon","humildad","prudencia","autorregulacion"]},
      "trascendencia": {"label":"Trascendencia",  "color":"#D69E2E",
                        "keys":["gratitud","esperanza","humor","apreciacion_excelencia","espiritualidad"]}
    },
    "normalization": "virtue_average",
    "display_mode": "virtue_radar",
    "primary_label": "Virtud predominante"
  }',
  'via_weighted'
);


-- ─── 4. challenge_type_id en experience_definitions ─

ALTER TABLE public.experience_definitions
  ADD COLUMN IF NOT EXISTS challenge_type_id UUID REFERENCES public.challenge_types(id),
  ADD COLUMN IF NOT EXISTS animation_config   JSONB NOT NULL DEFAULT '{"type":"none","fallback":"tv_static"}';

COMMENT ON COLUMN public.experience_definitions.challenge_type_id IS
  'FK a challenge_types. Nivel 1 de la jerarquía. NOT NULL tras backfill.';
COMMENT ON COLUMN public.experience_definitions.animation_config IS
  'Config animación del runner. type: pixel_climber | tv_static | none.';

-- Backfill: todos los retos existentes son DISC
UPDATE public.experience_definitions
  SET challenge_type_id = '00000000-0000-0000-0000-000000000001'
  WHERE challenge_type_id IS NULL;

-- Animación para Expedición Base
UPDATE public.experience_definitions
  SET animation_config = '{
    "type": "pixel_climber",
    "theme": "aconcagua",
    "levels": 20,
    "summit_label": "Aconcagua 6.961m",
    "climber_sprite": "assets/sprite_climber_01.png",
    "background": "assets/bg_aconcagua_path.png"
  }'
  WHERE slug = 'expedicion-base';

ALTER TABLE public.experience_definitions
  ALTER COLUMN challenge_type_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_exp_def_challenge_type
  ON public.experience_definitions(challenge_type_id);


-- ─── 5. challenge_type_id + framework_notes en questions ─

ALTER TABLE public.questions
  ADD COLUMN IF NOT EXISTS challenge_type_id UUID REFERENCES public.challenge_types(id),
  ADD COLUMN IF NOT EXISTS framework_notes   TEXT;

COMMENT ON COLUMN public.questions.challenge_type_id IS
  'FK a challenge_types. Una pregunta pertenece a una sola metodología.';
COMMENT ON COLUMN public.questions.framework_notes IS
  'Notas internas: qué dimensión/virtud explora principalmente este escenario.';

-- Backfill: todas las preguntas existentes son DISC
UPDATE public.questions
  SET challenge_type_id = '00000000-0000-0000-0000-000000000001'
  WHERE challenge_type_id IS NULL;

ALTER TABLE public.questions
  ALTER COLUMN challenge_type_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_questions_challenge_type
  ON public.questions(challenge_type_id);


-- ─── 6. dimension_scores en question_options ─────────

ALTER TABLE public.question_options
  ADD COLUMN IF NOT EXISTS dimension_scores JSONB NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.question_options.dimension_scores IS
  'Pesos para metodologías distintas a DISC. VIA: {"creatividad":0.7,"curiosidad":0.1,...}. Para DISC se siguen usando disc_d/i/s/c (backward-compat).';


-- ─── 7. Trigger integridad jerárquica reto_compositions ─

CREATE OR REPLACE FUNCTION public.validate_reto_composition_type()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  v_exp_type UUID;
  v_q_type   UUID;
BEGIN
  SELECT challenge_type_id INTO v_exp_type
    FROM public.experience_definitions WHERE id = NEW.experience_id;

  SELECT challenge_type_id INTO v_q_type
    FROM public.questions WHERE id = NEW.question_id;

  IF v_exp_type IS DISTINCT FROM v_q_type THEN
    RAISE EXCEPTION
      'hierarchy_type_mismatch: la pregunta % (tipo %) no puede incluirse en el reto % (tipo %). Ambos deben compartir el mismo challenge_type.',
      NEW.question_id, v_q_type, NEW.experience_id, v_exp_type;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_reto_composition_type ON public.reto_compositions;
CREATE TRIGGER trg_validate_reto_composition_type
  BEFORE INSERT OR UPDATE ON public.reto_compositions
  FOR EACH ROW EXECUTE FUNCTION public.validate_reto_composition_type();

COMMENT ON FUNCTION public.validate_reto_composition_type() IS
  'Garantiza que preguntas y retos compartan el mismo challenge_type. Protege la integridad de la jerarquía.';


-- ─── 8. Verificación ─────────────────────────────────

SELECT 'challenge_types'          AS entidad, COUNT(*)::text AS total FROM public.challenge_types
UNION ALL
SELECT 'exp_def con FK DISC',              COUNT(*)::text FROM public.experience_definitions
  WHERE challenge_type_id = '00000000-0000-0000-0000-000000000001'
UNION ALL
SELECT 'questions con FK DISC',            COUNT(*)::text FROM public.questions
  WHERE challenge_type_id = '00000000-0000-0000-0000-000000000001'
UNION ALL
SELECT 'exp_def con animation_config',     COUNT(*)::text FROM public.experience_definitions
  WHERE animation_config->>'type' != 'none'
UNION ALL
SELECT 'trigger jerarquía activo',         COUNT(*)::text FROM pg_trigger
  WHERE tgname = 'trg_validate_reto_composition_type';
