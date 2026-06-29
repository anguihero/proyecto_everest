-- =====================================================
-- Migration 004: Metadatos de experiencias
-- Agrega name y description a experience_definitions
-- para mostrar en catálogos sin necesidad de leer el JSONB.
-- HU-CM-001, HU-CA-005
-- =====================================================

ALTER TABLE public.experience_definitions
  ADD COLUMN IF NOT EXISTS name        TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT;

COMMENT ON COLUMN public.experience_definitions.name        IS 'Nombre legible de la experiencia. Ej: Expedición Base';
COMMENT ON COLUMN public.experience_definitions.description IS 'Descripción breve visible en el catálogo y el Hub.';
