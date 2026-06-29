-- =====================================================
-- Migration 006: Funciones de sesión del motor
-- HU-CM-003: Inicio de sesión versionada
-- HU-CM-005: Autosave, pausa y reanudación
-- HU-CM-006: Scoring y finalización determinísticos
--
-- Ejecutar en Supabase SQL Editor DESPUÉS de 005_casete_base.sql
-- =====================================================


-- ─── 1. start_or_resume_session ─────────────────────
-- Crea o reanuda una sesión para la asignación dada.
-- Solo el dueño de la asignación puede llamarla.
-- SOLO envía content al cliente DESPUÉS de validar sesión.

CREATE OR REPLACE FUNCTION public.start_or_resume_session(p_assignment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_assignment  public.experience_assignments;
  v_version     public.experience_versions;
  v_session     public.experience_sessions;
  v_consent_ok  BOOLEAN;
BEGIN
  -- 1. Validar que la asignación pertenece al usuario autenticado
  SELECT * INTO v_assignment
  FROM   public.experience_assignments
  WHERE  id      = p_assignment_id
    AND  user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'assignment_not_found';
  END IF;

  IF v_assignment.status::TEXT = 'revoked' THEN
    RAISE EXCEPTION 'assignment_revoked';
  END IF;

  -- 2. Validar que la versión está publicada
  SELECT * INTO v_version
  FROM   public.experience_versions
  WHERE  id           = v_assignment.experience_version_id
    AND  status::TEXT = 'published';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'version_not_published';
  END IF;

  -- 3. Validar consentimiento activo
  SELECT EXISTS (
    SELECT 1 FROM public.consent_records
    WHERE  user_id    = auth.uid()
      AND  revoked_at IS NULL
      AND  (purposes->>'data_processing')::boolean = true
  ) INTO v_consent_ok;

  IF NOT v_consent_ok THEN
    RAISE EXCEPTION 'consent_required';
  END IF;

  -- 4. Buscar sesión existente
  SELECT * INTO v_session
  FROM   public.experience_sessions
  WHERE  assignment_id = p_assignment_id
    AND  user_id       = auth.uid()
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    -- 4a. Crear nueva sesión
    INSERT INTO public.experience_sessions
      (assignment_id, user_id, org_id, experience_version_id, status, started_at, current_step)
    VALUES
      (p_assignment_id, auth.uid(), v_assignment.org_id,
       v_assignment.experience_version_id, 'in_progress', now(), 0)
    RETURNING * INTO v_session;

    -- Actualizar estado de la asignación
    UPDATE public.experience_assignments
    SET    status = 'in_progress'
    WHERE  id = p_assignment_id AND status::TEXT = 'assigned';

  ELSIF v_session.status::TEXT IN ('not_started', 'paused') THEN
    -- 4b. Reanudar sesión pausada
    UPDATE public.experience_sessions
    SET    status = 'in_progress', last_saved_at = now()
    WHERE  id = v_session.id
    RETURNING * INTO v_session;

  ELSIF v_session.status::TEXT = 'completed' THEN
    -- 4c. Ya completada — devolver sin content (cliente redirige a resultados)
    RETURN jsonb_build_object(
      'session_id',   v_session.id,
      'status',       'completed',
      'current_step', v_session.current_step
    );
  END IF;
  -- 4d. in_progress: devolver tal cual (reanudación sin cambio de estado)

  -- 5. Devolver sesión + content (solo tras validación completa)
  RETURN jsonb_build_object(
    'session_id',   v_session.id,
    'status',       v_session.status,
    'current_step', v_session.current_step,
    'started_at',   v_session.started_at,
    'content',      v_version.content,
    'total_steps',  (v_version.content->'meta'->>'total_steps')::int
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.start_or_resume_session(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.start_or_resume_session(UUID) TO authenticated;


-- ─── 2. save_step_answer ────────────────────────────
-- Guarda la respuesta de un paso de forma idempotente.
-- Idempotency key: session_id:step_index (UNIQUE en session_answers).
-- Devuelve el feedback del casete para mostrarlo en pantalla.

CREATE OR REPLACE FUNCTION public.save_step_answer(
  p_session_id  UUID,
  p_step_index  INT,
  p_option_key  TEXT
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

  -- 2. Construir idempotency key
  v_idempotency := p_session_id::TEXT || ':' || p_step_index::TEXT;

  -- 3. Insertar respuesta (idempotente — no falla en duplicado)
  INSERT INTO public.session_answers
    (session_id, user_id, step_index, option_key, idempotency_key)
  VALUES
    (p_session_id, auth.uid(), p_step_index, p_option_key, v_idempotency)
  ON CONFLICT (idempotency_key) DO NOTHING;

  -- 4. Avanzar current_step (GREATEST para no retroceder en caso de reenvío)
  UPDATE public.experience_sessions
  SET    current_step  = GREATEST(current_step, p_step_index + 1),
         last_saved_at = now()
  WHERE  id = p_session_id;

  -- 5. Obtener feedback del content JSONB
  SELECT * INTO v_version
  FROM   public.experience_versions
  WHERE  id = v_session.experience_version_id;

  v_feedback := v_version.content->'steps'->p_step_index->'feedback'->>p_option_key;

  RETURN jsonb_build_object(
    'saved',       true,
    'step_index',  p_step_index,
    'option_key',  p_option_key,
    'feedback',    v_feedback
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.save_step_answer(UUID, INT, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.save_step_answer(UUID, INT, TEXT) TO authenticated;


-- ─── 3. complete_session ────────────────────────────
-- Calcula el perfil DISC de forma determinística y cierra la sesión.
-- La IA recibe el resultado; nunca participa del cálculo (DEC-T-01).
-- Idempotente: devuelve resultado existente si ya fue calculado.

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

  v_content := v_version.content;
  v_scoring := v_version.scoring_rules;

  -- 3. Validar completitud (todos los pasos requeridos respondidos)
  SELECT count(*) FILTER (WHERE (step->>'required')::boolean)
  INTO   v_total_required
  FROM   jsonb_array_elements(v_content->'steps') step;

  SELECT count(*) INTO v_answered
  FROM   public.session_answers
  WHERE  session_id = p_session_id;

  IF v_answered < v_total_required THEN
    RAISE EXCEPTION 'incomplete_session: % de % pasos requeridos respondidos', v_answered, v_total_required;
  END IF;

  -- 4. Calcular dimensiones DISC (sumar pesos por dimensión)
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

  -- 5. Normalizar (sum_to_one)
  v_total  := GREATEST(COALESCE(v_d,0) + COALESCE(v_i,0) + COALESCE(v_s,0) + COALESCE(v_c,0), 1);
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

  -- 7. Guardar evidencias
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


-- ─── 4. get_session_result ──────────────────────────
-- Devuelve resultado de una sesión para la pantalla de resultados.
-- Solo el dueño de la sesión puede acceder.

CREATE OR REPLACE FUNCTION public.get_session_result(p_session_id UUID)
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT jsonb_build_object(
    'session_id',       es.id,
    'experience_name',  ed.name,
    'experience_slug',  ed.slug,
    'completed_at',     es.completed_at,
    'scores',           sr.scores,
    'total_steps',      (ev.content->'meta'->>'total_steps')::int
  )
  FROM   public.experience_sessions   es
  JOIN   public.score_results         sr ON sr.session_id = es.id
  JOIN   public.experience_versions   ev ON ev.id = es.experience_version_id
  JOIN   public.experience_definitions ed ON ed.id = ev.experience_id
  WHERE  es.id      = p_session_id
    AND  es.user_id = auth.uid();
$$;

REVOKE EXECUTE ON FUNCTION public.get_session_result(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_session_result(UUID) TO authenticated;


-- ─── 5. Verificación ─────────────────────────────────
SELECT
  proname                               AS funcion,
  pg_get_function_arguments(oid)        AS argumentos,
  prosecdef                             AS security_definer
FROM   pg_proc
WHERE  pronamespace = 'public'::regnamespace
  AND  proname IN (
    'start_or_resume_session',
    'save_step_answer',
    'complete_session',
    'get_session_result',
    'get_player_hub'
  )
ORDER BY proname;
