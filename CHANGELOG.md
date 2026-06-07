# Changelog - Everest Experience

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Sin versión] - 2026-06-07

### ✅ Agregado

- **Documentación Comercial**
  - `propuesta_comercial_everest.md`: Documento de ventas completo con propuesta de valor, casos de uso (líder nuevo vs. consolidado), y workshop final de C3 mockup generado por IA
  - Sección A4 WORKSHOP FINAL que describe proceso de validación visual en semana 7 usando agentes generativos para iterar diseño en tiempo real
  
- **Estructura inicial del repositorio**
  - Carpetas de documentación: `docs/01_planning/`, `docs/02_governance/`, `docs/03_financials/`, `docs/04_sales/`
  - Carpetas de código fuente: `src/frontend/`, `src/backend/`
  
- **Documentación Técnica Completa (SDD)**
  - `project_gantt_plan.md`: Cronograma detallado de 12 semanas con diagrama Gantt en Markdown (5 semanas de levantamiento de HU)
  - `agile_dynamics_workflow.md`: Rituales ágiles (Sprints de 2 semanas, Daily Scrum, Kanban)
  - `roles_raci_matrix.md`: Matriz RACI con roles de Andrés, Diego y Óscar
  - `legal_compliance_ip.md`: NDA, Habeas Data (Ley 1581) y cláusulas de Propiedad Intelectual
  - `infrastructure_cost_analysis.md`: Análisis financiero con costos mensuales y proyección a 1-3 años
  
- **Documentación de Referencia**
  - `README.md` principal con descripción completa del proyecto
  - `README.md` en `src/frontend/` con arquitectura planificada del cliente
  - `README.md` en `src/backend/` con diseño de base de datos y Edge Functions
  - `.gitignore` con reglas para secretos, dependencias y archivos temporales

### 🔧 Configuración Vigente

- **Modelo de Costos:** Tarifa mensual recurrente (sin one-time)
- **Tabulador de Desarrollo:** $1.400.000 COP/mes para MVP (4 meses) y posteriores desarrollos
- **Infraestructura Cloud:** Free Tier Año 1, Plan Pro $100.000/mes Años 2-3
- **Presupuesto Vigente:**
  - Año 1: $6.230.000 COP
  - Acumulado 3 años: $12.590.000 COP

### 📊 Métricas del Proyecto

- **Documentos técnicos creados:** 5 (100% de la fase de planeación SDD)
- **Cronograma planificado:** 12 semanas (5 semanas de levantamiento de HU + 7 semanas de diseño/desarrollo)
- **Presupuesto total estimado a 3 años:** $12.590.000 COP
- **Inversión de desarrollo inicial:** $5.600.000 COP (4 meses MVP)
- **Tabulador de nuevos desarrollos:** $1.400.000 COP/mes

---

## Próximos Hitos

### [M1] - Fin de Semana 5 (Planificado)
- [ ] Backlog completo firmado por Óscar (Product Owner)
- [ ] Todas las historias de usuario refinadas con criterios de aceptación
- [ ] Estimación de Story Points completada por el equipo técnico

### [M2] - Fin de Semana 7 (Planificado)
- [ ] Esquema de base de datos en Supabase con RLS configurado
- [ ] Arquitectura técnica aprobada por Andrés (Tech Lead)
- [ ] Diseño completo de la interfaz UI del Everest
- [ ] Identidad corporativa y assets visuales finalizados

### [M3] - Fin de Semana 10 (Planificado)
- [ ] Code Freeze con frontend y backend integrados
- [ ] Cobertura básica de pruebas unitarias
- [ ] Agente Gemini con Guardrails implementado

### [M4] - Fin de Semana 12 (Planificado)
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
