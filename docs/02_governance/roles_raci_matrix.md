# 2. Estructura de Gobierno: Roles, Responsabilidades y Matriz RACI

Este documento establece la asignación de responsabilidades dentro del núcleo de desarrollo del proyecto. Garantiza una clara separación de funciones para optimizar el flujo de trabajo agentico y agilizar la toma de decisiones críticas.

## 👥 Definición de Roles del Equipo Técnico y de Negocio

* **Andrés Muñoz Sánchez (Líder Técnico / Senior Data Scientist / Full Stack Dev):**
    * *Responsabilidad:* Diseñar la arquitectura general de la plataforma, el modelo relacional en Supabase, la implementación de la capa de Inteligencia Artificial (Gemini API), las directrices de seguridad (RLS) y la automatización de flujos mediante Spec-Driven Development (SDD).
* **Diego (Ingeniero / Diseñador / Analista de Producto):**
    * *Responsabilidad:* Traducir las necesidades funcionales del negocio en especificaciones de producto, diseñar los elementos de identidad corporativa y la UI de la experiencia gamificada del Everest, y co-desarrollar los módulos frontend (HTML5/JS) asegurando usabilidad y adaptabilidad responsive.
* **Óscar (Dueño de Producto / Cliente / Stakeholder Principal):**
    * *Responsabilidad:* Proveer la visión estratégica de negocio y los fundamentos psicométricos del producto, refinar el backlog priorizando el valor comercial, validar que los entregables cumplan con los objetivos de fidelización corporativa y actuar como el enlace principal con el mercado.

---

## 📊 Matriz RACI del Proyecto

La matriz utiliza los siguientes códigos estándar:
* **R (Responsible):** El rol que ejecuta y construye la tarea directamente.
* **A (Accountable):** El rol con la autoridad final sobre el resultado; aprueba el trabajo. Solo hay uno por fila.
* **C (Consulted):** Expertos o partes interesadas cuyos insumos son requeridos antes o durante la tarea.
* **I (Informed):** Personas que reciben actualizaciones sobre el progreso o la finalización del entregable.

| Entregables / Actividades de Ingeniería | Andrés (TL / Dev) | Diego (Dev / UI) | Óscar (PO / Client) |
| :--- | :---: | :---: | :---: |
| Definición de Historias de Usuario y Criterios | C | R | A |
| Arquitectura Técnica y Contratos de APIs | R | I | A |
| Diseño de Identidad Corporativa y Assets Visuales | I | R | A |
| Desarrollo de la UI (Frontend del Everest Hub) | R | R | I |
| Configuración de Base de Datos y RLS en Supabase | R | I | I |
| Implementación de Agente Gemini con Guardrails | R | C | I |
| Despliegue de Infraestructura y CI/CD | R | I | I |
| Aceptación de Entrega E2E (Delivery) | C | C | A |

---

## ⚡ Gobernanza y Protocolo de Toma de Decisiones

Para evitar cuellos de botella en el desarrollo ágil, se implementa el siguiente marco de decisiones estructuradas:

1.  **Decisiones de Producto y Negocio (Ej. Cambios en la ruta del Everest, métricas de burnout a evaluar):**
    * *Lidera:* Óscar (PO). Involucra a Diego para viabilidad de experiencia de usuario y a Andrés para viabilidad técnica. La decisión final recae sobre Óscar.
2.  **Decisiones Arquitecturales y Tecnológicas (Ej. Estructura de tablas en Supabase, infraestructura de prompts):**
    * *Lidera:* Andrés (TL). Define los límites operacionales y de seguridad del software. Diego y Óscar se adaptan a las especificaciones arquitectónicas dadas por el TL.
3.  **Resolución de Conflictos Técnicos:**
    * En caso de empate o desacuerdo sobre la UI/UX o la lógica del producto, Diego y Andrés proponen dos alternativas evaluadas en tiempo de desarrollo. Óscar elige la que mejor maximice el retorno de inversión y fidelización según los objetivos del coach consultor.