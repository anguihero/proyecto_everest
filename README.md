# 🏔️ Everest Experience - Plataforma B2B de Gamificación Psicométrica para Coaching Corporativo

## 📖 Descripción del Proyecto

Everest Experience es una plataforma corporativa B2B orientada a psicólogos y coaches organizacionales para la gestión estratégica del talento humano. La solución ofrece consultoría automatizada, guías adaptativas y recomendaciones basadas en IA para identificar:

- Perfiles de liderazgo
- Dinámicas de resolución de conflictos organizacionales
- Mitigación del riesgo de burnout
- Niveles de estrés y desconfianza institucional

Todo esto se diagnostica y trabaja a través de la **gamificación de tests psicométricos tradicionales** en una experiencia inmersiva de escalada de alta montaña.

---

## 🎮 Experiencia Central: Everest Experience

Una experiencia web inmersiva donde el empleado (Usuario Jugador) se enfrenta a un desafío interactivo de escalada. El mapa permite tomar rutas estándar o senderos personalizados para alcanzar la cima. Durante el recorrido, se presentan retos de opción múltiple contextualizados en escenarios simulados que miden la toma de decisiones bajo presión y el estilo relacional.

### Componentes Principales

1. **Pantalla de Login** con autenticación corporativa
2. **Hub Central/Dashboard**: Datos organizacionales, perfil, avatar RPG personalizable, medallas y progreso
3. **Sherpa/Asistente NPC**: Agente conversacional de IA que guía el recorrido con feedback en tiempo real
4. **Panel Admin de Empresa**: Visualización analítica consolidada del desempeño del talento humano
5. **Módulo del Juego**: Renderizado de rutas, persistencia de estado, mecánicas RPG
6. **Panel del Coach**: Herramientas analíticas avanzadas para seguimiento psicométrico
7. **Panel SysAdmin**: Gestión global de multi-tenancy y licencias

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología | Propósito |
|------|------------|-----------|
| **Frontend** | HTML5, Vanilla JS/Framework liviano, CSS/Tailwind | Aplicación web nativa responsiva |
| **Backend** | Supabase (PostgreSQL + Auth + RLS + Realtime) | Infraestructura BaaS con Row Level Security para multi-tenancy |
| **Inteligencia Artificial** | Google Gemini API con Guardrail Prompting | Agente conversacional seguro para el Sherpa NPC |
| **Hosting** | Vercel/Netlify (Frontend) + Supabase Cloud | Despliegue serverless con SSL nativo |

---

## 📂 Estructura del Repositorio

```
everest-project/
├── README.md                          # Este archivo
├── docs/                              # Documentación del proyecto
│   ├── 01_planning/
│   │   ├── project_gantt_plan.md      # Cronograma detallado Gantt
│   │   └── agile_dynamics_workflow.md # Rituales ágiles y Kanban
│   ├── 02_governance/
│   │   ├── roles_raci_matrix.md       # Matriz RACI y roles del equipo
│   │   └── legal_compliance_ip.md     # NDA, Habeas Data y Propiedad Intelectual
│   └── 03_financials/
│       └── infrastructure_cost_analysis.md # Presupuesto e inversiones
├── user_stories/                      # Gestión de Historias de Usuario
│   ├── INDEX.md                       # Índice maestro de HU
│   ├── templates/                     # Plantillas y ejemplos
│   ├── backlog/                       # HU pendientes
│   ├── in_progress/                   # HU en desarrollo
│   └── done/                          # HU completadas
├── src/
│   ├── frontend/                      # Código del cliente web
│   └── backend/                       # Edge Functions y lógica de Supabase
```

---

## 📋 Documentación Técnica

### 📅 Planeación y Gestión

1. **[Cronograma del Proyecto (Gantt)](01_planning/project_gantt_plan.md)**
   - Plan de trabajo detallado por semanas (W1-W12)
   - Fases sincrónicas y asíncronas
   - Milestones y dependencias
   - **5 semanas dedicadas al levantamiento de historias de usuario**

2. **[Dinámicas Ágiles y Workflow](01_planning/agile_dynamics_workflow.md)**
   - Sprints de 2 semanas
   - Daily Scrum de 15 minutos
   - Estados del Kanban: TO DO, DOING, PAUSED, DONE

### 🏛️ Gobernanza y Cumplimiento

3. **[Roles y Matriz RACI](02_governance/roles_raci_matrix.md)**
   - Responsabilidades de Andrés (TL/Dev), Diego (UI/Analista) y Óscar (PO)
   - Protocolos de toma de decisiones arquitecturales vs. de negocio

4. **[Marco Legal y Compliance](02_governance/legal_compliance_ip.md)**
   - Acuerdo de Confidencialidad (NDA)
   - Tratamiento de Datos Sensibles (Habeas Data - Ley 1581)
   - Propiedad Intelectual del Software

### 💰 Financiero

5. **[Análisis de Costos de Infraestructura](03_financials/infrastructure_cost_analysis.md)**
   - Presupuesto detallado mensual y anual
   - Inversión de desarrollo: $2.000.000 COP
   - Costos operativos (Supabase, Gemini API, Hosting, Soporte)
   - Proyección a 1 y 3 años

### 📚 Historias de Usuario

6. **[Sistema de Gestión de HU](user_stories/README.md)**
   - Plantillas estandarizadas con criterios de aceptación Gherkin
   - Flujo Kanban: Backlog → In Progress → Done
   - [Índice maestro de todas las HU](user_stories/INDEX.md)
   - [Plantilla vacía](user_stories/templates/TEMPLATE.md) | [Ejemplo completo](user_stories/templates/EXAMPLE.md)

---

## 👥 Equipo

| Rol | Nombre | Responsabilidades |
|-----|--------|-------------------|
| **Líder Técnico / Full Stack Dev** | Andrés Muñoz Sánchez | Arquitectura, Backend, IA, Seguridad RLS, SDD |
| **Ingeniero / Diseñador UI** | Diego | Identidad corporativa, UI/UX, Frontend, Analítica de Producto |
| **Product Owner / Cliente** | Óscar | Visión estratégica, Backlog, Validación de negocio |

---

## 🚀 Metodología de Desarrollo

El proyecto se desarrolla bajo **Spec-Driven Development (SDD)** con enfoque ágil:

- **Sprints de 2 semanas** con ceremonias de planning, daily y review
- **Tablero Kanban** con límites WIP de 2 tareas por persona
- **Definición de Terminado (DoD)**: Código integrado, sin errores, RLS validado, aprobación visual
- **Milestones críticos** al final de las semanas 2, 4, 7 y 9

---

## 🔐 Seguridad y Privacidad

- **Row Level Security (RLS)** en Supabase para multi-tenancy seguro
- **Guardrail Prompting** en Gemini API para prevenir data leakage entre organizaciones
- **Datos sensibles protegidos** bajo Ley 1581 de Habeas Data
- **Anonimización y seudonimización** de logs psicométricos
- **Acceso basado en roles**: Jugador, Admin de Empresa, Coach, SysAdmin

---

## 📊 Arquitectura de Flujo de Datos

```
[Usuario Jugador] 
    ↓
[Aplicación Web: HTML5 + JS]
    ↓
[Supabase Backend]
    ├── PostgreSQL (RLS Multi-Tenant)
    ├── Auth (Autenticación corporativa)
    ├── Realtime (Guardado de partidas)
    └── Edge Functions → [Gemini API con Guardrails]
```

---

## 📅 Estado del Proyecto

**Fase Actual:** Configuración inicial del espacio de trabajo SDD  
**Siguiente Milestone:** M1 - Backlog completo firmado con todas las HU refinadas (Fin de Semana 5)

---

## 📝 Notas Importantes

- Este proyecto maneja **datos sensibles de salud mental laboral** (burnout, estrés, confianza institucional)
- La titularidad del código fuente se transfiere 100% a Óscar tras la liquidación del desarrollo
- Se reconoce el derecho moral de autoría a Andrés (arquitectura/código) y Diego (diseño/producto)
- Todos los componentes Open Source (Tailwind, Supabase, etc.) mantienen sus licencias originales

---

## 📞 Contacto y Colaboración

Para preguntas sobre la arquitectura técnica, contactar a **Andrés Muñoz Sánchez** (Líder Técnico).  
Para consultas de producto y negocio, contactar a **Óscar** (Product Owner).

---

**Última actualización:** Junio 2026  
**Versión de la documentación:** 1.0
