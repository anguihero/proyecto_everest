-- =====================================================
-- Migration 001: Schema completo — Everest Experience MVP
-- Versión: 1.0.0 | Fecha: 2026-06-28
-- Responsable: Andrés Muñoz Sánchez (Tech Lead)
-- DEC-T-01: Contrato de casete como JSONB validado en PostgreSQL
-- DEC-T-02: Versionado semver inmutable; sesiones bloquean su versión al inicio
-- =====================================================
-- ORDEN DE EJECUCIÓN: 001 → 002 → 003
-- Ejecutar en Supabase SQL Editor con permisos de superuser
-- =====================================================

-- =====================================================
-- TIPOS ENUMERADOS
-- =====================================================

CREATE TYPE public.user_role AS ENUM (
  'player',     -- Jugador/usuario final: realiza experiencias
  'coach',      -- Coach/Líder: ve players autorizados con consentimiento
  'org_admin',  -- Administrador organizacional: gestiona su tenant
  'sys_admin'   -- Administrador global (Andrés): acceso irrestricto
);

CREATE TYPE public.experience_status AS ENUM (
  'draft',      -- Borrador: solo sys_admin puede ver y editar
  'pilot',      -- Piloto: acceso restringido para pruebas internas
  'published',  -- Publicado: disponible para asignación. Inmutable.
  'retired'     -- Retirado: inactivo, preserva historial existente
);

CREATE TYPE public.session_status AS ENUM (
  'not_started',   -- Asignada pero no iniciada
  'in_progress',   -- En ejecución activa
  'paused',        -- Pausada por el usuario
  'completed',     -- Finalizada con scoring calculado
  'expired'        -- Expirada por inactividad o versión retirada
);

CREATE TYPE public.assignment_status AS ENUM (
  'assigned',      -- Asignada, pendiente de inicio
  'in_progress',   -- El jugador ya inició la experiencia
  'completed',     -- El jugador completó la experiencia
  'revoked'        -- Revocada por OrgAdmin
);

CREATE TYPE public.audit_action AS ENUM (
  'login',
  'logout',
  'session_expired',
  'consent_given',
  'consent_revoked',
  'experience_started',
  'experience_paused',
  'experience_resumed',
  'experience_completed',
  'answer_saved',
  'coach_consulted',
  'reading_generated',
  'reading_fallback',
  'support_access',
  'user_created',
  'user_deactivated',
  'experience_assigned',
  'experience_published',
  'experience_retired',
  'data_export_requested',
  'data_deletion_requested',
  'security_event'
);

-- =====================================================
-- TABLA: organizations
-- Root del modelo multi-tenant. Una empresa = un tenant.
-- =====================================================
CREATE TABLE public.organizations (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT         NOT NULL,
  slug        TEXT         NOT NULL UNIQUE,
  is_active   BOOLEAN      NOT NULL DEFAULT true,
  metadata    JSONB,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.organizations IS 'Empresas clientes. Cada organización es un tenant aislado por RLS.';
COMMENT ON COLUMN public.organizations.slug IS 'Identificador URL-safe único. Ej: acme-corp';

-- =====================================================
-- TABLA: profiles
-- Extiende auth.users (Supabase). Relación 1:1.
-- El trigger handle_new_user (migration 003) la puebla automáticamente.
-- =====================================================
CREATE TABLE public.profiles (
  id                  UUID            PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id              UUID            NOT NULL REFERENCES public.organizations(id),
  role                public.user_role NOT NULL DEFAULT 'player',
  preferred_name      TEXT,
  is_active           BOOLEAN         NOT NULL DEFAULT true,
  onboarding_version  TEXT,
  created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'Perfil extendido de usuario. No almacena email ni contraseña (esos están en auth.users).';
COMMENT ON COLUMN public.profiles.onboarding_version IS 'Versión del onboarding completado. NULL = no ha completado onboarding.';

-- =====================================================
-- TABLA: consent_records
-- Inmutable — append-only. Nunca se modifica, solo se agrega.
-- Revocar = insertar un UPDATE con revoked_at (via política RLS).
-- =====================================================
CREATE TABLE public.consent_records (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID         NOT NULL REFERENCES public.profiles(id),
  org_id          UUID         NOT NULL REFERENCES public.organizations(id),
  policy_version  TEXT         NOT NULL,
  purposes        JSONB        NOT NULL,
  accepted_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  revoked_at      TIMESTAMPTZ,
  CONSTRAINT valid_purposes CHECK (
    jsonb_typeof(purposes) = 'object'
    AND (purposes ? 'data_processing')
  )
);

COMMENT ON TABLE public.consent_records IS 'Registro inmutable de consentimientos. RF-PR-01/02. Nunca se borran.';
COMMENT ON COLUMN public.consent_records.purposes IS 'Ej: {"data_processing": true, "ai_processing": true, "coach_sharing": false}';

-- =====================================================
-- TABLA: experience_definitions
-- Catálogo de experiencias disponibles (sin contenido ejecutable).
-- =====================================================
CREATE TABLE public.experience_definitions (
  id          UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT     NOT NULL UNIQUE,
  type        TEXT     NOT NULL CHECK (type IN ('exploration', 'simulation', 'learning')),
  is_active   BOOLEAN  NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.experience_definitions.slug IS 'Ej: expedicion-base, expedicion-cumbre';
COMMENT ON COLUMN public.experience_definitions.type IS 'exploration=Base (DISC-inspired), simulation=Cumbre (VIA+empresa)';

-- =====================================================
-- TABLA: experience_versions
-- Cada versión es un "casete". Inmutable una vez publicada.
-- content y scoring_rules son protegidos por trigger (migration 003).
-- DEC-T-01: content = contrato estructurado del casete (JSONB)
-- DEC-T-02: version = semver. Una sesión bloquea esta versión al inicio.
-- =====================================================
CREATE TABLE public.experience_versions (
  id                UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  experience_id     UUID                    NOT NULL REFERENCES public.experience_definitions(id),
  version           TEXT                    NOT NULL,
  schema_version    TEXT                    NOT NULL DEFAULT '1',
  status            public.experience_status NOT NULL DEFAULT 'draft',
  content           JSONB                   NOT NULL,
  scoring_rules     JSONB                   NOT NULL,
  scoring_version   TEXT                    NOT NULL,
  published_by      UUID                    REFERENCES public.profiles(id),
  published_at      TIMESTAMPTZ,
  retired_by        UUID                    REFERENCES public.profiles(id),
  retired_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ             NOT NULL DEFAULT now(),
  UNIQUE (experience_id, version)
);

COMMENT ON TABLE public.experience_versions IS 'Inmutable post-publicación. Trigger en 003 impide mutar content/scoring_rules.';
COMMENT ON COLUMN public.experience_versions.content IS 'Contrato completo del casete: pasos, escenarios, opciones, narrativa, coaches, feedback.';
COMMENT ON COLUMN public.experience_versions.scoring_rules IS 'Reglas de scoring determinísticas y versionadas. Nunca calculado por IA.';

-- =====================================================
-- TABLA: experience_assignments
-- Un jugador tiene asignado un casete específico (versión específica).
-- =====================================================
CREATE TABLE public.experience_assignments (
  id                    UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID                     NOT NULL REFERENCES public.profiles(id),
  org_id                UUID                     NOT NULL REFERENCES public.organizations(id),
  experience_id         UUID                     NOT NULL REFERENCES public.experience_definitions(id),
  experience_version_id UUID                     NOT NULL REFERENCES public.experience_versions(id),
  assigned_by           UUID                     REFERENCES public.profiles(id),
  status                public.assignment_status NOT NULL DEFAULT 'assigned',
  assigned_at           TIMESTAMPTZ              NOT NULL DEFAULT now(),
  due_at                TIMESTAMPTZ,
  UNIQUE (user_id, experience_version_id)
);

COMMENT ON TABLE public.experience_assignments IS 'RF-AD-01. Un jugador no puede tener la misma versión asignada dos veces.';

-- =====================================================
-- TABLA: experience_sessions
-- Estado de ejecución. Una sesión = una ejecución de una asignación.
-- DB es fuente de verdad. localStorage solo como caché no sensible.
-- =====================================================
CREATE TABLE public.experience_sessions (
  id                    UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id         UUID                  NOT NULL REFERENCES public.experience_assignments(id),
  user_id               UUID                  NOT NULL REFERENCES public.profiles(id),
  org_id                UUID                  NOT NULL REFERENCES public.organizations(id),
  experience_version_id UUID                  NOT NULL REFERENCES public.experience_versions(id),
  consent_record_id     UUID                  REFERENCES public.consent_records(id),
  status                public.session_status NOT NULL DEFAULT 'not_started',
  current_step          INTEGER               NOT NULL DEFAULT 0 CHECK (current_step >= 0),
  state_snapshot        JSONB,
  started_at            TIMESTAMPTZ,
  last_saved_at         TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ           NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.experience_sessions.state_snapshot IS 'Estado acumulado para Cumbre: {caja, confianza, personas, ejecucion}. NULL para Base.';
COMMENT ON COLUMN public.experience_sessions.experience_version_id IS 'DEC-T-02: bloqueada al inicio. Nunca cambia aunque se publiquen versiones nuevas.';

-- =====================================================
-- TABLA: session_answers
-- Append-only. Idempotente via idempotency_key. RF-EX-04.
-- Una respuesta confirmada NO se modifica (sin política UPDATE).
-- =====================================================
CREATE TABLE public.session_answers (
  id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id        UUID         NOT NULL REFERENCES public.experience_sessions(id),
  user_id           UUID         NOT NULL REFERENCES public.profiles(id),
  step_index        INTEGER      NOT NULL CHECK (step_index >= 0),
  option_key        TEXT         NOT NULL,
  idempotency_key   TEXT         NOT NULL UNIQUE,
  confirmed_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (session_id, step_index)
);

COMMENT ON COLUMN public.session_answers.idempotency_key IS 'Formato: {session_id}:{step_index}. Previene doble guardado en caso de retry.';

-- =====================================================
-- TABLA: score_results
-- Calculado determinísticamente al completar una sesión.
-- El cálculo ocurre en backend (Edge Function o función DB), nunca en cliente.
-- =====================================================
CREATE TABLE public.score_results (
  id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id            UUID         NOT NULL UNIQUE REFERENCES public.experience_sessions(id),
  user_id               UUID         NOT NULL REFERENCES public.profiles(id),
  org_id                UUID         NOT NULL REFERENCES public.organizations(id),
  experience_version_id UUID         NOT NULL REFERENCES public.experience_versions(id),
  scoring_version       TEXT         NOT NULL,
  scores                JSONB        NOT NULL,
  patterns              JSONB,
  metadata              JSONB,
  calculated_at         TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.score_results.scores IS 'Ej para Base: {"D": 0.72, "I": 0.45, "S": 0.38, "C": 0.61}. Para Cumbre: fortalezas VIA.';

-- =====================================================
-- TABLA: result_evidence
-- Evidencias individuales que respaldan los scores. RF-SC-02.
-- =====================================================
CREATE TABLE public.result_evidence (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  score_result_id UUID         NOT NULL REFERENCES public.score_results(id),
  session_id      UUID         NOT NULL REFERENCES public.experience_sessions(id),
  step_index      INTEGER      NOT NULL,
  option_key      TEXT         NOT NULL,
  dimension       TEXT,
  weight          NUMERIC      NOT NULL,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- =====================================================
-- TABLA: coach_consultations
-- Registro de consultas a coaches durante Cumbre. RF-SC-04/05.
-- =====================================================
CREATE TABLE public.coach_consultations (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID         NOT NULL REFERENCES public.experience_sessions(id),
  user_id         UUID         NOT NULL REFERENCES public.profiles(id),
  step_index      INTEGER      NOT NULL,
  coach_key       TEXT         NOT NULL CHECK (coach_key IN ('estratega', 'humano', 'ejecucion')),
  cost_type       TEXT         NOT NULL CHECK (cost_type IN ('free', 'token')),
  consulted_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (session_id, step_index, coach_key)
);

COMMENT ON COLUMN public.coach_consultations.cost_type IS 'free = primero gratis por reto. token = consume ficha de oxígeno (DEC-P-06 pendiente).';

-- =====================================================
-- TABLA: state_events
-- Historial de cambios en estados empresariales (solo Cumbre). RF-SC-03.
-- =====================================================
CREATE TABLE public.state_events (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID         NOT NULL REFERENCES public.experience_sessions(id),
  step_index      INTEGER      NOT NULL,
  option_key      TEXT         NOT NULL,
  state_before    JSONB        NOT NULL,
  state_after     JSONB        NOT NULL,
  impact_type     TEXT         CHECK (impact_type IN ('immediate', 'deferred')),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.state_events.state_before IS 'Snapshot del estado {caja, confianza, personas, ejecucion} antes del reto.';
COMMENT ON COLUMN public.state_events.impact_type IS 'immediate = efecto en este reto. deferred = efecto aparece en reto posterior.';

-- =====================================================
-- TABLA: prompt_versions
-- Versiones de prompts del Sherpa. Auditables. HU-IA-004.
-- =====================================================
CREATE TABLE public.prompt_versions (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  experience_type TEXT         NOT NULL CHECK (experience_type IN ('exploration', 'simulation')),
  version         TEXT         NOT NULL,
  system_prompt   TEXT         NOT NULL,
  schema_expected JSONB        NOT NULL,
  guardrails      JSONB        NOT NULL,
  is_active       BOOLEAN      NOT NULL DEFAULT true,
  created_by      UUID         REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (experience_type, version)
);

COMMENT ON TABLE public.prompt_versions IS 'HU-IA-004. Sin PII en system_prompt. Los guardrails son código ejecutable, no solo texto.';

-- =====================================================
-- TABLA: generated_readings
-- Lecturas del Sherpa. Validadas antes de mostrarse. HU-IA-001/002/003.
-- =====================================================
CREATE TABLE public.generated_readings (
  id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id          UUID         NOT NULL REFERENCES public.experience_sessions(id),
  user_id             UUID         NOT NULL REFERENCES public.profiles(id),
  prompt_version_id   UUID         REFERENCES public.prompt_versions(id),
  model_used          TEXT         NOT NULL,
  status              TEXT         NOT NULL CHECK (status IN ('pending', 'generated', 'validated', 'fallback', 'failed')),
  reading             JSONB,
  fallback_template   TEXT,
  guardrail_triggered BOOLEAN      NOT NULL DEFAULT false,
  generated_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.generated_readings.reading IS 'Schema: {resumen, evidencias, fortalezas, tensiones, acciones, preguntas_reflexivas, disclaimer}';
COMMENT ON COLUMN public.generated_readings.guardrail_triggered IS 'Si true, se usó fallback. La salida de Gemini fue descartada.';

-- =====================================================
-- TABLA: audit_events
-- Log de seguridad append-only. Sin PII en metadata. HU-GO-005.
-- =====================================================
CREATE TABLE public.audit_events (
  id            UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID                REFERENCES public.profiles(id),
  org_id        UUID                REFERENCES public.organizations(id),
  action        public.audit_action NOT NULL,
  resource_type TEXT,
  resource_id   TEXT,
  metadata      JSONB,
  created_at    TIMESTAMPTZ         NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.audit_events IS 'Nunca almacena PII, emails, contraseñas, prompts completos ni respuestas individuales.';

-- =====================================================
-- TABLA: support_access_events
-- Log de accesos excepcionales de soporte. HU-GO-004. RS-SEC-06.
-- =====================================================
CREATE TABLE public.support_access_events (
  id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  accessor_id      UUID         NOT NULL REFERENCES public.profiles(id),
  target_user_id   UUID         NOT NULL REFERENCES public.profiles(id),
  org_id           UUID         NOT NULL REFERENCES public.organizations(id),
  reason           TEXT         NOT NULL,
  ticket_ref       TEXT,
  accessed_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  duration_seconds INTEGER
);

COMMENT ON TABLE public.support_access_events IS 'DEC-P-04 provisional: soporte usa sys_admin con acceso mínimo auditado.';

-- =====================================================
-- ÍNDICES DE PERFORMANCE
-- =====================================================

CREATE INDEX idx_profiles_org_id         ON public.profiles(org_id);
CREATE INDEX idx_profiles_role            ON public.profiles(role);
CREATE INDEX idx_consent_user_active      ON public.consent_records(user_id, policy_version) WHERE revoked_at IS NULL;
CREATE INDEX idx_exp_ver_status           ON public.experience_versions(status);
CREATE INDEX idx_exp_ver_experience       ON public.experience_versions(experience_id);
CREATE INDEX idx_assignments_user         ON public.experience_assignments(user_id);
CREATE INDEX idx_assignments_org          ON public.experience_assignments(org_id);
CREATE INDEX idx_assignments_status       ON public.experience_assignments(status);
CREATE INDEX idx_sessions_user            ON public.experience_sessions(user_id);
CREATE INDEX idx_sessions_assignment      ON public.experience_sessions(assignment_id);
CREATE INDEX idx_sessions_status          ON public.experience_sessions(status);
CREATE INDEX idx_answers_session          ON public.session_answers(session_id);
CREATE INDEX idx_scores_user              ON public.score_results(user_id);
CREATE INDEX idx_scores_session           ON public.score_results(session_id);
CREATE INDEX idx_evidence_score           ON public.result_evidence(score_result_id);
CREATE INDEX idx_consultations_session    ON public.coach_consultations(session_id, step_index);
CREATE INDEX idx_state_events_session     ON public.state_events(session_id);
CREATE INDEX idx_readings_session         ON public.generated_readings(session_id);
CREATE INDEX idx_audit_user               ON public.audit_events(user_id);
CREATE INDEX idx_audit_action             ON public.audit_events(action);
CREATE INDEX idx_audit_created            ON public.audit_events(created_at DESC);
CREATE INDEX idx_support_accessor         ON public.support_access_events(accessor_id);
CREATE INDEX idx_support_target           ON public.support_access_events(target_user_id);
