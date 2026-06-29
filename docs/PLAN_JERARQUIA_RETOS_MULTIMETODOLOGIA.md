# Plan — Jerarquía de Retos y Fábrica Multi-Metodología

**Fecha:** 2026-06-29  
**Responsable:** Andrés Muñoz (Tech Lead)  
**Estado:** Borrador — pendiente aprobación  
**Prioridad:** P1 (habilita VIA y retos futuros sin romper DISC existente)

---

## Problema

El modelo de datos actual tiene la jerarquía de retos **implícita**, no estructurada:

| Nivel deseado | Entidad actual | Problema |
|---|---|---|
| 1 — Tipo de Reto (metodología) | No existe como tabla | El tipo está hardcodeado en `experience_definitions.type` y en las columnas `disc_d/i/s/c` |
| 2 — Reto (experiencia) | `experience_definitions` | Existe, pero sin FK a metodología |
| 3 — Preguntas | `questions` | Existe, pero sin FK a metodología |
| 4 — Respuestas | `question_options` | Existe, pero los pesos están en columnas DISC específicas, inextensible a VIA |

Consecuencias:
- No es posible agregar VIA (24 dimensiones) sin romper el schema o duplicar columnas.
- Una pregunta DISC puede asignarse (sin validación) a un reto VIA — jerarquía rota.
- No existe UI en la plataforma para crear retos nuevos; todo se hace via SQL manual.
- El SysAdmin no puede crear, previsualizar ni publicar contenido sin acceso al SQL Editor.

## Objetivo

1. Introducir `challenge_types` como nivel 1 de la jerarquía.
2. Conectar las entidades existentes (`experience_definitions`, `questions`, `question_options`) mediante FKs a `challenge_types`.
3. Generalizar el almacenamiento de pesos de opciones para soportar cualquier dimensionalidad.
4. Garantizar integridad referencial: una pregunta solo puede existir en un reto del mismo tipo de metodología.
5. Construir la UI de fábrica en `sysadmin.html` para gestionar todo el contenido sin SQL.

---

## Jerarquía target

```
challenge_types              ← NUEVO (Nivel 1)
│   DISC, VIA, [futuros]
│
└── experience_definitions   ← EXISTENTE + FK (Nivel 2)
    │   Expedición Base, Fortalezas en Conflicto...
    │
    └── questions            ← EXISTENTE + FK (Nivel 3)
        │   Escenarios/preguntas
        │
        └── question_options ← EXISTENTE + generalización (Nivel 4)
                Opciones A/B/C/D con pesos por metodología
```

---

## Fase 1 — Schema: nueva tabla `challenge_types` (0.5 días)

### DDL

```sql
-- Migration: challenge_types
CREATE TABLE public.challenge_types (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT         NOT NULL UNIQUE,
  name            TEXT         NOT NULL,
  description     TEXT,
  dimensions      JSONB        NOT NULL,
  result_template JSONB        NOT NULL,
  scoring_engine  TEXT         NOT NULL,
  is_active       BOOLEAN      NOT NULL DEFAULT true,
  created_by      UUID         REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.challenge_types.dimensions IS
  'Mapa de dimensiones evaluadas. DISC: {"D":"Dominancia","I":"Influencia","S":"Estabilidad","C":"Conformidad"}. VIA: {"creatividad":{"virtue":"sabiduria","label":"Creatividad"},...}';
COMMENT ON COLUMN public.challenge_types.result_template IS
  'Cómo presentar el resultado. Define tipo de visualización (radar), normalización y colores.';
COMMENT ON COLUMN public.challenge_types.scoring_engine IS
  'Identificador del motor de scoring: "disc_weighted" | "via_weighted" | futuro.';

-- RLS: todos los autenticados pueden ver tipos activos; solo sys_admin gestiona
ALTER TABLE public.challenge_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY challenge_types_read ON public.challenge_types
  FOR SELECT TO authenticated
  USING (is_active = true);

CREATE POLICY challenge_types_manage ON public.challenge_types
  FOR ALL TO authenticated
  USING (public.i_am_sys_admin())
  WITH CHECK (public.i_am_sys_admin());
```

### Datos iniciales — DISC

```sql
INSERT INTO public.challenge_types
  (id, slug, name, description, dimensions, result_template, scoring_engine)
VALUES (
  'ct000000-0000-0000-0000-000000000001',
  'disc',
  'DISC',
  'Modelo de comportamiento conductual (Dominancia, Influencia, Estabilidad, Conformidad).',
  '{
    "D": {"label": "Dominancia",  "color": "#E53E3E", "description": "Orientación a resultados, decisión, control."},
    "I": {"label": "Influencia",  "color": "#ED8936", "description": "Entusiasmo, persuasión, optimismo."},
    "S": {"label": "Estabilidad", "color": "#38A169", "description": "Paciencia, consistencia, apoyo al equipo."},
    "C": {"label": "Conformidad", "color": "#3182CE", "description": "Precisión, análisis, cumplimiento de normas."}
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
```

### Datos iniciales — VIA

```sql
INSERT INTO public.challenge_types
  (id, slug, name, description, dimensions, result_template, scoring_engine)
VALUES (
  'ct000000-0000-0000-0000-000000000002',
  'via',
  'VIA Fortalezas de Carácter',
  '24 fortalezas de carácter clasificadas en 6 virtudes (Peterson & Seligman, 2004).',
  '{
    "creatividad":           {"virtue": "sabiduria",      "label": "Creatividad"},
    "curiosidad":            {"virtue": "sabiduria",      "label": "Curiosidad"},
    "apertura_mental":       {"virtue": "sabiduria",      "label": "Apertura mental"},
    "amor_aprendizaje":      {"virtue": "sabiduria",      "label": "Amor por el aprendizaje"},
    "perspectiva":           {"virtue": "sabiduria",      "label": "Perspectiva"},
    "valentia":              {"virtue": "coraje",         "label": "Valentía"},
    "perseverancia":         {"virtue": "coraje",         "label": "Perseverancia"},
    "honestidad":            {"virtue": "coraje",         "label": "Honestidad"},
    "vitalidad":             {"virtue": "coraje",         "label": "Vitalidad/Entusiasmo"},
    "amor":                  {"virtue": "humanidad",      "label": "Amor"},
    "amabilidad":            {"virtue": "humanidad",      "label": "Amabilidad"},
    "inteligencia_social":   {"virtue": "humanidad",      "label": "Inteligencia social"},
    "trabajo_equipo":        {"virtue": "justicia",       "label": "Trabajo en equipo"},
    "equidad":               {"virtue": "justicia",       "label": "Equidad"},
    "liderazgo_via":         {"virtue": "justicia",       "label": "Liderazgo"},
    "perdon":                {"virtue": "templanza",      "label": "Perdón"},
    "humildad":              {"virtue": "templanza",      "label": "Humildad"},
    "prudencia":             {"virtue": "templanza",      "label": "Prudencia"},
    "autorregulacion":       {"virtue": "templanza",      "label": "Autorregulación"},
    "gratitud":              {"virtue": "trascendencia",  "label": "Gratitud"},
    "esperanza":             {"virtue": "trascendencia",  "label": "Esperanza"},
    "humor":                 {"virtue": "trascendencia",  "label": "Humor"},
    "apreciacion_excelencia":{"virtue": "trascendencia",  "label": "Apreciación de la excelencia"},
    "espiritualidad":        {"virtue": "trascendencia",  "label": "Espiritualidad/Propósito"}
  }',
  '{
    "type": "virtue_radar",
    "virtues": {
      "sabiduria":      {"label": "Sabiduría",    "color": "#805AD5", "keys": ["creatividad","curiosidad","apertura_mental","amor_aprendizaje","perspectiva"]},
      "coraje":         {"label": "Coraje",       "color": "#E53E3E", "keys": ["valentia","perseverancia","honestidad","vitalidad"]},
      "humanidad":      {"label": "Humanidad",   "color": "#ED8936", "keys": ["amor","amabilidad","inteligencia_social"]},
      "justicia":       {"label": "Justicia",     "color": "#38A169", "keys": ["trabajo_equipo","equidad","liderazgo_via"]},
      "templanza":      {"label": "Templanza",    "color": "#3182CE", "keys": ["perdon","humildad","prudencia","autorregulacion"]},
      "trascendencia":  {"label": "Trascendencia","color": "#D69E2E", "keys": ["gratitud","esperanza","humor","apreciacion_excelencia","espiritualidad"]}
    },
    "normalization": "virtue_average",
    "display_mode": "virtue_radar",
    "primary_label": "Virtud predominante"
  }',
  'via_weighted'
);
```

---

## Fase 2 — Conectar entidades existentes mediante FKs (0.5 días)

### Agregar `challenge_type_id` a `experience_definitions`

```sql
ALTER TABLE public.experience_definitions
  ADD COLUMN challenge_type_id UUID REFERENCES public.challenge_types(id);

-- Backfill: todos los retos existentes son DISC
UPDATE public.experience_definitions
  SET challenge_type_id = 'ct000000-0000-0000-0000-000000000001'
  WHERE challenge_type_id IS NULL;

-- Una vez confirmado el backfill, hacer NOT NULL
ALTER TABLE public.experience_definitions
  ALTER COLUMN challenge_type_id SET NOT NULL;

CREATE INDEX idx_exp_def_challenge_type
  ON public.experience_definitions(challenge_type_id);
```

### Agregar `challenge_type_id` a `questions`

```sql
ALTER TABLE public.questions
  ADD COLUMN challenge_type_id UUID REFERENCES public.challenge_types(id),
  ADD COLUMN framework_notes   TEXT;

COMMENT ON COLUMN public.questions.framework_notes IS
  'Notas internas: qué virtud/dimensión principal explora este escenario.';

-- Backfill: todas las preguntas existentes son DISC
UPDATE public.questions
  SET challenge_type_id = 'ct000000-0000-0000-0000-000000000001'
  WHERE challenge_type_id IS NULL;

ALTER TABLE public.questions
  ALTER COLUMN challenge_type_id SET NOT NULL;

CREATE INDEX idx_questions_challenge_type
  ON public.questions(challenge_type_id);
```

### Generalizar `question_options` para múltiples metodologías

Las columnas `disc_d`, `disc_i`, `disc_s`, `disc_c` **se mantienen** (backward-compatible con los 80 registros existentes y con `assemble_reto_version` v2). Se agrega un campo genérico:

```sql
ALTER TABLE public.question_options
  ADD COLUMN dimension_scores JSONB DEFAULT '{}';

COMMENT ON COLUMN public.question_options.dimension_scores IS
  'Pesos por dimensión para metodologías distintas a DISC. Ej VIA: {"creatividad":0.7,"curiosidad":0.1,...}. Para DISC se siguen usando disc_d/i/s/c.';
```

### Trigger de integridad jerárquica

Una pregunta solo puede usarse en un reto del **mismo tipo de metodología**:

```sql
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
      'type_mismatch: la pregunta % (tipo %) no puede incluirse en el reto % (tipo %)',
      NEW.question_id, v_q_type, NEW.experience_id, v_exp_type;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_reto_composition_type
  BEFORE INSERT OR UPDATE ON public.reto_compositions
  FOR EACH ROW EXECUTE FUNCTION public.validate_reto_composition_type();
```

---

## Fase 3 — Actualizar `assemble_reto_version()` para multi-metodología (0.5 días)

La función actual siempre produce `scoring_rules.type = 'disc_weighted'` y lee las columnas `disc_d/i/s/c`. Se actualiza para detectar el tipo y usar la fuente correcta:

```sql
-- Pseudo-lógica del update:
-- 1. Obtener challenge_type del experience_definitions
-- 2. Si scoring_engine = 'disc_weighted': usar columnas disc_d/i/s/c (backward compat)
-- 3. Si scoring_engine = 'via_weighted':  usar dimension_scores JSONB
-- 4. Incluir el scoring_engine y las dimensions en scoring_rules
-- 5. Incluir el result_template del challenge_type en content.result_template
```

El `content.result_template` del casete pasa de ser hardcodeado a tomarse de `challenge_types.result_template`, lo que permite que el runner y los resultados adapten su visualización automáticamente.

---

## Fase 4 — UI de Fábrica en SysAdmin (3–4 días)

### Sección nueva en `sysadmin.html`: "Fábrica de Contenido"

#### Tab 1 — Tipos de Reto

| Columna | Descripción |
|---|---|
| Nombre | DISC, VIA, etc. |
| Slug | Identificador técnico |
| Dimensiones | Número de dimensiones |
| Retos activos | Cuántos retos usan este tipo |
| Estado | Activo / Inactivo |
| Acciones | Ver, Editar (solo sys_admin) |

Formulario de creación/edición:
- Nombre y descripción
- Definición de dimensiones (JSON editor asistido)
- Scoring engine: dropdown (`disc_weighted`, `via_weighted`, ...)
- Vista previa del radar resultante

#### Tab 2 — Retos (experience_definitions)

Lista de retos con filtro por tipo de metodología.

Formulario de creación:
- Tipo de metodología (dropdown de `challenge_types`)
- Nombre y descripción
- Animación asociada (ver Plan 3): `disc` → pixel_climber; `via` → pendiente
- Estado inicial: draft

#### Tab 3 — Banco de Preguntas

Lista de preguntas filtradas por tipo.

Formulario de creación:
```
Tipo de metodología: [DISC ▼]
Título de la pregunta: [_____________]
Texto del escenario:   [_______________
                        _______________]
Dificultad:            [○ Fácil  ● Medio  ○ Difícil]
Tiempo estimado (seg): [60]
Notas de framework:    [Qué dimensión/virtud principal explora]

── Opción A ──────────────────────────────────────
Texto:    [_______________]
Feedback (Sherpa): [_______________]
Pesos DISC:  D [0.70] I [0.10] S [0.10] C [0.10]
             [Suma debe ser 1.0 ✓]

── Opción B ──────── (igual estructura × 4)
── Opción C ──────── 
── Opción D ──────── 

[Cancelar]  [Guardar pregunta]
```

Para VIA, los pesos muestran un selector de fortaleza (24 opciones) con el peso de esa fortaleza.

#### Tab 4 — Composición de Retos

Para cada reto:
- Lista de preguntas disponibles (del mismo tipo)
- Drag & drop para ordenar
- Toggle para activar/desactivar preguntas del reto
- Vista "Preguntas seleccionadas: 20/20"
- Preview del reto completo antes de publicar

Botones de acción:
- **[Previsualizar]** → abre el reto en modo test (sin guardar respuestas)
- **[Publicar versión]** → llama a `assemble_reto_version()`, genera nueva versión semver

#### Tab 5 — Versiones publicadas

Lista de todas las versiones por reto:
- Versión, fecha de publicación, estado, quién la publicó
- Botón [Retirar] para versiones publicadas
- Ver asignaciones activas por versión antes de retirar

---

## Scoring para VIA — Virtudes como radar de 6 ejes

El resultado VIA no muestra las 24 fortalezas directamente (sobrecarga cognitiva). Las agrupa en 6 virtudes:

```
score_results.scores para VIA:
{
  "sabiduria":     0.72,
  "coraje":        0.58,
  "humanidad":     0.45,
  "justicia":      0.61,
  "templanza":     0.38,
  "trascendencia": 0.52
}

patterns para VIA:
{
  "fortalezas_top3": ["creatividad", "liderazgo_via", "perseverancia"],
  "virtud_primaria": "sabiduria",
  "virtud_secundaria": "justicia"
}
```

El radar de resultados mostrará 6 ejes (uno por virtud) con los valores normalizados, análogo al radar DISC actual.

---

## Resumen de cambios al schema

| Cambio | Tipo | Riesgo | Mitigación |
|---|---|---|---|
| Nueva tabla `challenge_types` | Additive | Bajo | Ninguno, tabla nueva |
| FK `experience_definitions.challenge_type_id` | Modify + backfill | Medio | Backfill DISC antes de NOT NULL |
| FK `questions.challenge_type_id` | Modify + backfill | Medio | Backfill DISC antes de NOT NULL |
| Columna `question_options.dimension_scores JSONB` | Additive | Bajo | Default `{}`, no rompe nada |
| Trigger de integridad `reto_compositions` | Additive | Bajo | No afecta filas existentes (todas son DISC) |
| `assemble_reto_version()` multi-metodología | Replace function | Medio | Mantener v1 del comportamiento DISC |

---

## Plan de migración sin romper producción

```
1. Aplicar challenge_types + datos DISC y VIA       ← sin romper nada
2. Backfill challenge_type_id en experience_definitions (DISC)
3. Backfill challenge_type_id en questions (DISC)
4. Agregar columna dimension_scores a question_options
5. Agregar trigger de integridad reto_compositions
6. Actualizar assemble_reto_version() (backward-compat DISC)
7. Verificar: re-ensamblar expedicion-base produce resultado idéntico al v2.1.0
8. Crear reto "Fortalezas en Conflicto" (VIA) desde la UI de Fábrica
```

---

## Reto VIA — Diseño inicial "Fortalezas en Conflicto"

**Nombre:** Fortalezas en Conflicto  
**Metodología:** VIA Fortalezas de Carácter  
**Total preguntas:** 20  
**Duración estimada:** 25–30 minutos  
**Animación:** TV Sintonizando (hasta que Diego diseñe la animación específica)

### Diseño de preguntas VIA

Cada escenario pone en tensión **dos o tres fortalezas** (nunca las evalúa de forma obvia), de modo que la elección revela la jerarquía natural del individuo. Cada opción asigna su peso mayor a **una fortaleza específica** dentro de una virtud.

Ejemplo de pregunta VIA:

```
Escenario: "Tu equipo acaba de fallar un objetivo importante.
El ambiente está tenso y hay desacuerdo sobre la causa."

Opción A (Liderazgo/Justicia):     Asumo la responsabilidad públicamente y defino el camino a seguir.
Opción B (Honestidad/Coraje):      Expongo lo que vi con claridad, aunque genere más tensión inicialmente.
Opción C (Amabilidad/Humanidad):   Me enfoco en cómo se siente el equipo y facilito un espacio de diálogo.
Opción D (Prudencia/Templanza):    Espero a que baje la tensión y propongo una revisión estructurada.

Pesos:
  A → {"liderazgo_via":0.6, "perseverancia":0.2, "valentia":0.2}
  B → {"honestidad":0.7, "valentia":0.2, "perspectiva":0.1}
  C → {"amabilidad":0.6, "amor":0.2, "inteligencia_social":0.2}
  D → {"prudencia":0.6, "autorregulacion":0.3, "perspectiva":0.1}
```

---

## Dependencias con otros planes

- **Plan 1 (Auth):** Independiente.
- **Plan 3 (Animación):** El campo `animation_config` en `experience_definitions` que define el Plan 3 debe coordinarse con la migración de esta fase. Ambos agregan columnas a la misma tabla.
- **HU-FB-001 al 005:** La fábrica de contenido implementa directamente estas HUs.
- **HU-EC-001 (Expedición Cumbre / VIA):** Este plan es el prerequisito técnico.

---

## Criterios de aceptación

- [ ] `challenge_types` existe con DISC y VIA como tipos iniciales
- [ ] Toda `experience_definition` tiene `challenge_type_id` NOT NULL
- [ ] Toda `question` tiene `challenge_type_id` NOT NULL
- [ ] El trigger impide insertar en `reto_compositions` con tipos distintos
- [ ] Re-ensamblar expedicion-base produce resultado idéntico al anterior (regresión cero)
- [ ] SysAdmin puede crear un nuevo tipo de reto desde la plataforma
- [ ] SysAdmin puede crear preguntas para VIA con pesos por fortaleza
- [ ] SysAdmin puede componer un reto VIA y publicar su primera versión
- [ ] El runner ejecuta un reto VIA sin errores
- [ ] Los resultados VIA muestran radar de 6 virtudes

---

*Documento generado: 2026-06-29 | Versión: 1.0 | Responsable: Andrés Muñoz*
