# Changelog - Everest Experience

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Sin versión] - 2026-06-07

### ✅ Agregado

- **Estructura inicial del repositorio**
  - Carpetas de documentación: `docs/01_planning/`, `docs/02_governance/`, `docs/03_financials/`
  - Carpetas de código fuente: `src/frontend/`, `src/backend/`
  
- **Documentación Técnica Completa (SDD)**
  - `project_gantt_plan.md`: Cronograma detallado de 9 semanas con diagrama Gantt en Markdown
  - `agile_dynamics_workflow.md`: Rituales ágiles (Sprints de 2 semanas, Daily Scrum, Kanban)
  - `roles_raci_matrix.md`: Matriz RACI con roles de Andrés, Diego y Óscar
  - `legal_compliance_ip.md`: NDA, Habeas Data (Ley 1581) y cláusulas de Propiedad Intelectual
  - `infrastructure_cost_analysis.md`: Análisis financiero con costos mensuales y proyección a 1-3 años
  
- **Documentación de Referencia**
  - `README.md` principal con descripción completa del proyecto
  - `README.md` en `src/frontend/` con arquitectura planificada del cliente
  - `README.md` en `src/backend/` con diseño de base de datos y Edge Functions
  - `.gitignore` con reglas para secretos, dependencias y archivos temporales

### 🔧 Cambiado

- Reorganización de archivos de documentación desde `docs/docs_XX_...` a la estructura de carpetas `docs/XX_category/`
- Corrección de cálculos financieros en `infrastructure_cost_analysis.md`:
  - Costo acumulado 3 años: $8.990.000 → $9.000.000
  - Agregada columna de "Costo Mensual" para transparencia de gastos recurrentes
  - Clarificación de costos de Supabase: Free Tier en Año 1, Plan Pro en Años 2-3

### 📊 Métricas del Proyecto

- **Documentos técnicos creados:** 5 (100% de la fase de planeación SDD)
- **Cronograma planificado:** 9 semanas (Sprint 0 - W9)
- **Presupuesto total estimado a 3 años:** $9.000.000 COP
- **Inversión de desarrollo inicial:** $2.000.000 COP

---

## Próximos Hitos

### [M1] - Fin de Semana 2 (Planificado)
- [ ] Backlog firmado por Óscar (Product Owner)
- [ ] Arquitectura técnica aprobada por Andrés (Tech Lead)
- [ ] Definición completa de historias de usuario con criterios de aceptación

### [M2] - Fin de Semana 4 (Planificado)
- [ ] Esquema de base de datos en Supabase con RLS configurado
- [ ] Diseño completo de la interfaz UI del Everest
- [ ] Identidad corporativa y assets visuales finalizados

### [M3] - Fin de Semana 7 (Planificado)
- [ ] Code Freeze con frontend y backend integrados
- [ ] Cobertura básica de pruebas unitarias
- [ ] Agente Gemini con Guardrails implementado

### [M4] - Fin de Semana 9 (Planificado)
- [ ] Plataforma desplegada en producción
- [ ] Transferencia de conocimiento y entrega formal
- [ ] Firma de acta de conformidad del delivery

---

## Notas de Desarrollo

- **Metodología:** Spec-Driven Development (SDD) con rituales ágiles
- **Sprints:** Ciclos de 2 semanas con Daily Scrum de 15 minutos
- **Control de calidad:** Definición de Terminado (DoD) estricta con validación de RLS y aprobación visual

---

**Formato de versionado futuro:** `MAJOR.MINOR.PATCH`
- **MAJOR:** Cambios incompatibles en la API o arquitectura
- **MINOR:** Nueva funcionalidad compatible con versiones anteriores
- **PATCH:** Correcciones de bugs y mejoras menores
