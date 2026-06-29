-- =====================================================
-- Seed 005: Expedición Base + función get_player_hub()
-- HU-FB-001: Contrato estructurado de casete
-- HU-CM-001: Motor de experiencias — catálogo base
--
-- Prerrequisito: migration 004_experience_meta.sql aplicada
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


-- ─── 1. Definición del casete ────────────────────────

INSERT INTO public.experience_definitions
  (id, slug, name, description, type, is_active)
VALUES (
  'b0000000-0000-0000-0000-000000000001',
  'expedicion-base',
  'Expedición Base',
  'Explora tus tendencias de liderazgo en 3 escenarios situacionales. Resultado: perfil conductual exploratorio.',
  'exploration',
  true
)
ON CONFLICT (id) DO UPDATE
  SET name        = EXCLUDED.name,
      description = EXCLUDED.description,
      is_active   = EXCLUDED.is_active;


-- ─── 2. Versión 1.0.0 del casete ────────────────────
-- Contrato conforme a casete_contract_v1.json (schema_version 1.0)

INSERT INTO public.experience_versions
  (id, experience_id, version, schema_version, scoring_version, status, content, scoring_rules)
VALUES (
  'c0000000-0000-0000-0000-000000000001',
  'b0000000-0000-0000-0000-000000000001',
  '1.0.0',
  '1.0',
  '1.0',
  'published',

  -- CAMPO CONTENT (contrato del casete)
  $content${
    "schema_version": "1.0",
    "meta": {
      "name": "Expedición Base",
      "description": "Explora tus tendencias de liderazgo en 3 escenarios situacionales. Resultado: perfil conductual exploratorio.",
      "duration_minutes": 15,
      "total_steps": 3,
      "capabilities_required": ["disc_scoring", "sherpa_feedback", "state_tracking"]
    },
    "steps": [
      {
        "id": "s01",
        "index": 0,
        "type": "scenario",
        "required": true,
        "content": {
          "title": "El plazo imposible",
          "narrative": "Tu gerente te informa que el cliente quiere el informe final para mañana. Tienes 24 horas para un trabajo que normalmente toma una semana. Tu equipo ya está al límite de capacidad. ¿Cómo respondes?",
          "context": null
        },
        "options": [
          { "key": "A", "text": "Comunico al equipo que debemos trabajar esta noche. La fecha con el cliente no es negociable.", "visible": true },
          { "key": "B", "text": "Convoco al equipo a una sesión de trabajo; entre todos encontramos una forma creativa de lograrlo.", "visible": true },
          { "key": "C", "text": "Hablo con el gerente para entender qué es lo mínimo necesario y proteger al equipo de presión excesiva.", "visible": true },
          { "key": "D", "text": "Reviso el alcance original y le presento al cliente un plan realista con lo que es posible entregar.", "visible": true }
        ],
        "feedback": {
          "A": "Priorizas el cumplimiento y la acción inmediata. Eres directo con el equipo sobre las expectativas.",
          "B": "Buscas energizar al equipo y encontrar soluciones colaborativas bajo presión.",
          "C": "Proteges al equipo de presión innecesaria y buscas claridad antes de actuar.",
          "D": "Analizas los compromisos y gestionas las expectativas del cliente con evidencia."
        }
      },
      {
        "id": "s02",
        "index": 1,
        "type": "scenario",
        "required": true,
        "content": {
          "title": "El conflicto entre áreas",
          "narrative": "Ventas prometió al cliente algo que Operaciones dice que es imposible cumplir. El conflicto ya es visible y te piden que lideres la solución antes de que escale. ¿Qué haces?",
          "context": null
        },
        "options": [
          { "key": "A", "text": "Tomo la decisión: Operaciones debe encontrar la forma de cumplir. El cliente siempre es primero.", "visible": true },
          { "key": "B", "text": "Convoco a ambas áreas juntas para escuchar todas las perspectivas y construir un acuerdo.", "visible": true },
          { "key": "C", "text": "Escucho a cada área por separado primero para entender el fondo del conflicto antes de proponer nada.", "visible": true },
          { "key": "D", "text": "Reviso los contratos y procesos internos para determinar qué es factible sin incumplir compromisos.", "visible": true }
        ],
        "feedback": {
          "A": "Tomas el control de la situación y defines una dirección clara para que el equipo actúe.",
          "B": "Facilitas el diálogo y crees que la solución emerge cuando todos colaboran.",
          "C": "Prefieres comprender profundamente antes de intervenir; evitas soluciones superficiales.",
          "D": "Anclas la solución en hechos y procesos concretos para asegurar que sea sostenible."
        }
      },
      {
        "id": "s03",
        "index": 2,
        "type": "scenario",
        "required": true,
        "content": {
          "title": "El miembro que no rinde",
          "narrative": "Llevas tres semanas notando que uno de los miembros de tu equipo entrega trabajos incompletos y llega tarde a las reuniones. El resto del equipo empieza a resentirlo. ¿Cuál es tu primer movimiento?",
          "context": null
        },
        "options": [
          { "key": "A", "text": "Le digo directamente que su desempeño no está siendo aceptable y que necesito ver cambios concretos esta semana.", "visible": true },
          { "key": "B", "text": "Lo invito a una conversación informal para entender cómo se siente y qué está pasando con él.", "visible": true },
          { "key": "C", "text": "Espero un poco más antes de actuar; quiero asegurarme de que no sea algo temporal.", "visible": true },
          { "key": "D", "text": "Reviso si tiene claridad sobre sus responsabilidades y los estándares del equipo antes de hablarle.", "visible": true }
        ],
        "feedback": {
          "A": "Abordas el problema con franqueza y estableces expectativas claras de desempeño.",
          "B": "Buscas entender a la persona antes de juzgar el comportamiento.",
          "C": "Prefieres dar tiempo y espacio antes de intervenir; evitas reacciones apresuradas.",
          "D": "Diagnosticas primero si el problema es de expectativas o de capacidad antes de actuar."
        }
      }
    ],
    "result_template": {
      "type": "disc_profile",
      "dimensions": ["D", "I", "S", "C"],
      "normalization": "sum_to_one"
    }
  }$content$::jsonb,

  -- CAMPO SCORING_RULES (mapa opción → dimensión DISC + pesos)
  $scoring${
    "type": "disc",
    "steps": {
      "s01": { "A": "D", "B": "I", "C": "S", "D": "C" },
      "s02": { "A": "D", "B": "I", "C": "S", "D": "C" },
      "s03": { "A": "D", "B": "I", "C": "S", "D": "C" }
    },
    "weights": { "s01": 1, "s02": 1, "s03": 1 }
  }$scoring$::jsonb
)
ON CONFLICT (id) DO UPDATE
  SET content       = EXCLUDED.content,
      scoring_rules = EXCLUDED.scoring_rules,
      status        = EXCLUDED.status;


-- ─── 3. Función get_player_hub() ────────────────────
-- SECURITY DEFINER: bypasa RLS pero aplica filtro auth.uid()
-- SET search_path evita ataques de path injection

CREATE OR REPLACE FUNCTION public.get_player_hub()
RETURNS TABLE (
  assignment_id          UUID,
  experience_id          UUID,
  experience_version_id  UUID,
  experience_slug        TEXT,
  experience_type        TEXT,
  experience_name        TEXT,
  experience_description TEXT,
  session_id             UUID,
  session_status         TEXT,
  current_step           INT,
  assignment_status      TEXT,
  due_at                 TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT
    ea.id                         AS assignment_id,
    ea.experience_id,
    ea.experience_version_id,
    ed.slug                       AS experience_slug,
    ed.type::TEXT                 AS experience_type,
    ed.name                       AS experience_name,
    ed.description                AS experience_description,
    es.id                         AS session_id,
    es.status::TEXT               AS session_status,
    COALESCE(es.current_step, 0)  AS current_step,
    ea.status::TEXT               AS assignment_status,
    ea.due_at
  FROM   public.experience_assignments ea
  JOIN   public.experience_definitions ed ON ed.id = ea.experience_id
  JOIN   public.experience_versions    ev ON ev.id = ea.experience_version_id
  LEFT JOIN public.experience_sessions es ON es.assignment_id = ea.id
  WHERE  ea.user_id = auth.uid()
    AND  ea.status::TEXT != 'revoked'
    AND  ev.status::TEXT  = 'published'
  ORDER BY ea.assigned_at DESC;
$$;

REVOKE EXECUTE ON FUNCTION public.get_player_hub() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_player_hub() TO authenticated;


-- ─── 4. Asignaciones para los 4 usuarios de prueba ──
-- Solo inserta si el usuario no tiene ya una asignación
-- para esta experiencia (idempotente sin requerir UNIQUE constraint)

INSERT INTO public.experience_assignments
  (user_id, org_id, experience_id, experience_version_id, assigned_by, status, assigned_at)
SELECT
  p.id                                    AS user_id,
  'a0000000-0000-0000-0000-000000000001'  AS org_id,
  'b0000000-0000-0000-0000-000000000001'  AS experience_id,
  'c0000000-0000-0000-0000-000000000001'  AS experience_version_id,
  p.id                                    AS assigned_by,
  'assigned'                              AS status,
  now()                                   AS assigned_at
FROM public.profiles p
WHERE p.org_id = 'a0000000-0000-0000-0000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM public.experience_assignments ea
    WHERE  ea.user_id       = p.id
      AND  ea.experience_id = 'b0000000-0000-0000-0000-000000000001'
  );


-- ─── 5. Verificación ─────────────────────────────────

SELECT
  ed.name                       AS experiencia,
  ev.version,
  ev.status                     AS estado_version,
  count(ea.id)                  AS asignaciones,
  json_agg(p.preferred_name ORDER BY p.preferred_name) AS asignados_a
FROM   public.experience_definitions ed
JOIN   public.experience_versions    ev  ON ev.experience_id = ed.id
LEFT JOIN public.experience_assignments ea ON ea.experience_version_id = ev.id
LEFT JOIN public.profiles p ON p.id = ea.user_id
WHERE  ed.slug = 'expedicion-base'
GROUP BY ed.name, ev.version, ev.status;
