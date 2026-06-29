-- =====================================================
-- Migration 003: Triggers y Funciones Helper
-- Versión: 1.0.0 | Fecha: 2026-06-28
-- Responsable: Andrés Muñoz Sánchez (Tech Lead)
-- =====================================================
-- REQUISITO: Ejecutar DESPUÉS de 001 y 002
-- =====================================================

-- =====================================================
-- TRIGGER: updated_at automático
-- Se aplica a tablas con columna updated_at.
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER organizations_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER exp_definitions_updated_at
  BEFORE UPDATE ON public.experience_definitions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- TRIGGER: inmutabilidad de versiones publicadas
-- DEC-T-01/T-02: impide modificar content o scoring_rules
-- de una versión que ya fue publicada o retirada.
-- =====================================================

CREATE OR REPLACE FUNCTION public.prevent_published_version_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status IN ('published', 'retired') THEN
    IF (OLD.content        IS DISTINCT FROM NEW.content)
    OR (OLD.scoring_rules  IS DISTINCT FROM NEW.scoring_rules)
    OR (OLD.scoring_version IS DISTINCT FROM NEW.scoring_version)
    THEN
      RAISE EXCEPTION
        'Inmutabilidad violada: una versión % (%) no puede modificar content ni scoring_rules. Crea una nueva versión.',
        OLD.version, OLD.status;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER protect_published_versions
  BEFORE UPDATE ON public.experience_versions
  FOR EACH ROW EXECUTE FUNCTION public.prevent_published_version_mutation();

-- =====================================================
-- TRIGGER: crear perfil automáticamente al registrar usuario
-- Se activa cuando Supabase Auth inserta un nuevo usuario en auth.users.
-- El OrgAdmin pasa org_id y role en raw_user_meta_data al crear la invitación.
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id        UUID;
  v_role          public.user_role;
  v_preferred_name TEXT;
BEGIN
  v_org_id         := (NEW.raw_user_meta_data ->> 'org_id')::UUID;
  v_role           := COALESCE(
                        (NEW.raw_user_meta_data ->> 'role')::public.user_role,
                        'player'
                      );
  v_preferred_name := NEW.raw_user_meta_data ->> 'preferred_name';

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'handle_new_auth_user: org_id requerido en raw_user_meta_data.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organizations WHERE id = v_org_id AND is_active = true
  ) THEN
    RAISE EXCEPTION 'handle_new_auth_user: organización % inválida o inactiva.', v_org_id;
  END IF;

  INSERT INTO public.profiles (id, org_id, role, preferred_name)
  VALUES (NEW.id, v_org_id, v_role, v_preferred_name);

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- =====================================================
-- FUNCIÓN: verificar consentimiento vigente
-- Usada por Edge Functions antes de iniciar una sesión.
-- Retorna true si el usuario tiene un consentimiento no revocado
-- para la versión de política especificada.
-- =====================================================

CREATE OR REPLACE FUNCTION public.has_valid_consent(
  p_user_id       UUID,
  p_policy_version TEXT
)
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.consent_records
    WHERE user_id = p_user_id
      AND policy_version = p_policy_version
      AND revoked_at IS NULL
  )
$$;

-- =====================================================
-- FUNCIÓN: obtener resumen del Hub para un jugador
-- Devuelve asignaciones + estado de sesión para la pantalla Hub.
-- Solo metadatos seguros — sin content del casete ni respuestas.
-- HU-CA-005.
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_player_hub(p_user_id UUID)
RETURNS TABLE (
  assignment_id         UUID,
  experience_slug       TEXT,
  experience_type       TEXT,
  version               TEXT,
  assignment_status     public.assignment_status,
  session_id            UUID,
  session_status        public.session_status,
  current_step          INTEGER,
  last_saved_at         TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ
)
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT
    ea.id                 AS assignment_id,
    ed.slug               AS experience_slug,
    ed.type               AS experience_type,
    ev.version,
    ea.status             AS assignment_status,
    es.id                 AS session_id,
    es.status             AS session_status,
    es.current_step,
    es.last_saved_at,
    es.completed_at
  FROM public.experience_assignments ea
  JOIN public.experience_definitions ed  ON ed.id = ea.experience_id
  JOIN public.experience_versions ev     ON ev.id = ea.experience_version_id
  LEFT JOIN public.experience_sessions es ON es.assignment_id = ea.id
  WHERE ea.user_id = p_user_id
    AND ea.status  != 'revoked'
  ORDER BY ea.assigned_at DESC
$$;

-- =====================================================
-- FUNCIÓN: iniciar sesión (idempotente)
-- Crea o reanuda una sesión para una asignación.
-- Verifica: asignación activa, consentimiento vigente, versión publicada.
-- HU-CM-003.
-- =====================================================

CREATE OR REPLACE FUNCTION public.start_or_resume_session(
  p_assignment_id    UUID,
  p_consent_record_id UUID,
  p_policy_version   TEXT
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_user_id         UUID;
  v_org_id          UUID;
  v_version_id      UUID;
  v_version_status  public.experience_status;
  v_session_id      UUID;
BEGIN
  -- Verificar que la asignación pertenece al usuario actual y está activa
  SELECT
    ea.user_id,
    ea.org_id,
    ea.experience_version_id,
    ev.status
  INTO v_user_id, v_org_id, v_version_id, v_version_status
  FROM public.experience_assignments ea
  JOIN public.experience_versions ev ON ev.id = ea.experience_version_id
  WHERE ea.id = p_assignment_id
    AND ea.user_id = auth.uid()
    AND ea.status != 'revoked';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Asignación no encontrada o no autorizada.';
  END IF;

  IF v_version_status = 'retired' THEN
    RAISE EXCEPTION 'Esta experiencia ya no está disponible.';
  END IF;

  -- Verificar consentimiento vigente
  IF NOT public.has_valid_consent(v_user_id, p_policy_version) THEN
    RAISE EXCEPTION 'Se requiere consentimiento informado vigente para iniciar.';
  END IF;

  -- Buscar sesión existente no completada (reanudación)
  SELECT id INTO v_session_id
  FROM public.experience_sessions
  WHERE assignment_id = p_assignment_id
    AND user_id = v_user_id
    AND status NOT IN ('completed', 'expired')
  LIMIT 1;

  -- Si no existe sesión, crearla
  IF v_session_id IS NULL THEN
    INSERT INTO public.experience_sessions (
      assignment_id,
      user_id,
      org_id,
      experience_version_id,
      consent_record_id,
      status,
      started_at
    )
    VALUES (
      p_assignment_id,
      v_user_id,
      v_org_id,
      v_version_id,
      p_consent_record_id,
      'in_progress',
      now()
    )
    RETURNING id INTO v_session_id;

    -- Actualizar estado de la asignación
    UPDATE public.experience_assignments
    SET status = 'in_progress'
    WHERE id = p_assignment_id;
  ELSE
    -- Reanudar sesión pausada
    UPDATE public.experience_sessions
    SET status = 'in_progress', last_saved_at = now()
    WHERE id = v_session_id;
  END IF;

  RETURN v_session_id;
END;
$$;

-- =====================================================
-- FUNCIÓN: guardar respuesta (idempotente)
-- Inserta una respuesta o ignora si ya existe (idempotency_key).
-- HU-CM-005. RF-EX-04.
-- =====================================================

CREATE OR REPLACE FUNCTION public.save_answer(
  p_session_id      UUID,
  p_step_index      INTEGER,
  p_option_key      TEXT,
  p_idempotency_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_session_user UUID;
  v_session_status public.session_status;
BEGIN
  -- Verificar que la sesión pertenece al usuario actual y está en progreso
  SELECT user_id, status
  INTO v_session_user, v_session_status
  FROM public.experience_sessions
  WHERE id = p_session_id;

  IF v_session_user IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Sesión no autorizada.';
  END IF;

  IF v_session_status NOT IN ('in_progress', 'paused') THEN
    RAISE EXCEPTION 'No se puede guardar respuestas en una sesión con estado %.', v_session_status;
  END IF;

  -- Insertar respuesta (ON CONFLICT = idempotente)
  INSERT INTO public.session_answers (
    session_id,
    user_id,
    step_index,
    option_key,
    idempotency_key
  )
  VALUES (
    p_session_id,
    auth.uid(),
    p_step_index,
    p_option_key,
    p_idempotency_key
  )
  ON CONFLICT (idempotency_key) DO NOTHING;

  -- Actualizar last_saved_at en la sesión
  UPDATE public.experience_sessions
  SET last_saved_at = now(),
      current_step  = GREATEST(current_step, p_step_index + 1)
  WHERE id = p_session_id;

  RETURN true;
END;
$$;

-- =====================================================
-- FUNCIÓN: registrar evento de auditoría
-- Sin PII. Llamada desde Edge Functions y cliente para eventos clave.
-- HU-GO-005.
-- =====================================================

CREATE OR REPLACE FUNCTION public.log_audit_event(
  p_action        public.audit_action,
  p_resource_type TEXT     DEFAULT NULL,
  p_resource_id   TEXT     DEFAULT NULL,
  p_metadata      JSONB    DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.audit_events (user_id, org_id, action, resource_type, resource_id, metadata)
  VALUES (
    auth.uid(),
    public.get_my_org_id(),
    p_action,
    p_resource_type,
    p_resource_id,
    p_metadata
  );
END;
$$;
