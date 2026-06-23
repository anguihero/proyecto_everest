# Everest Experience — Archivo de Contexto Maestro

> Documento vivo. Agregar información a medida que el proyecto evoluciona.  
> Última actualización: 2026-06-22

---

## 1. Visión General del Producto

**Everest Experience** es una plataforma de diagnóstico de liderazgo y desarrollo de habilidades directivas que combina psicometría (modelo DISC) con gamificación. Está diseñada para el mercado **B2B / B2B2C corporativo**: las organizaciones contratan la plataforma y sus líderes la usan para auto-conocerse y desarrollarse.

### Metáfora central
Escalar el Monte Everest = el viaje de desarrollo del líder. Cada ruta, campamento y decisión en la montaña refleja un reto de liderazgo real. El jugador no escala físicamente: toma decisiones, resuelve dilemas y recibe retroalimentación psicométrica en cada paso.

### Propuesta de valor
| Para quién | Qué obtiene |
|---|---|
| CEO / RRHH (comprador B2B) | Datos objetivos sobre el perfil de liderazgo de sus equipos, sin depender de consultoras caras |
| Líder / Colaborador (usuario final B2B2C) | Auto-conocimiento de su estilo DISC + desarrollo práctico a través de retos gamificados |
| Coach interno o externo | Panel con analytics del progreso individual y grupal para guiar conversaciones de coaching |

---

## 2. Arquitectura Funcional de la Plataforma

### Flujo principal del usuario (player journey)
```
Login / Onboarding
    ↓
Prueba Diagnóstica DISC (inicial)
    ↓
Hub Central (avatar, progreso, medallas)
    ↓
Mapa de Rutas del Everest (3 rutas por dificultad)
    ↓
Selección de Ruta → Dilemas de Decisión (opciones múltiples)
    ↓
Interacción con el Sherpa NPC (coach IA)
    ↓
Panel de Resultados Parciales / Perfil Psicométrico
    ↓
(iterativo) Más retos → perfil refinado → cierre de escalada
```

### Roles de usuario en la plataforma
| Rol | Descripción |
|---|---|
| **Player (Líder)** | Usuario final que hace el diagnóstico y juega los retos |
| **Coach** | Visualiza los resultados de su grupo, guía el proceso de reflexión |
| **OrgAdmin** | Gestiona los usuarios de su organización, reportes agregados |
| **SysAdmin** | Administración técnica de la plataforma (Andrés) |

### Pantallas principales
1. **Login** — Email corporativo + contraseña. Primera vez → onboarding breve.
2. **Hub Central** — Avatar, progreso global, próximo reto, medallas ganadas.
3. **Mapa de Rutas** — 3 rutas (Estándar, Desafío, Extrema). Estados: Bloqueada / Disponible / En Progreso / Completada.
4. **Pantalla de Dilema** — Escenario de liderazgo + 4 opciones de respuesta.
5. **Chat con el Sherpa** — NPC IA coach: sabio, accesible, con humor sutil. Powered by Gemini API.
6. **Panel de Resultados** — Tabla de dimensiones + Gráfico radar del perfil psicométrico.

---

## 3. Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | HTML5, CSS (Tailwind / CSS Grid / Flexbox nativo), JavaScript vanilla |
| Backend / DB | Supabase (Auth, RLS, Storage, Edge Functions) |
| IA Coach (Sherpa) | Gemini API con guardrails psicométricos vía Edge Function de Supabase |
| Despliegue | Supabase hosting + CI/CD |
| Metodología | Spec-Driven Development (SDD) + Agile (sprints de 2 semanas) |

---

## 4. Equipo y Roles

| Persona | Rol | Responsabilidades clave |
|---|---|---|
| **Andrés Muñoz Sánchez** | Tech Lead / Senior Data Scientist / Full Stack Dev | Arquitectura, Supabase, IA (Gemini), RLS, SDD |
| **Diego** | Ingeniero / Diseñador / Analista de Producto | UI/UX, identidad visual, assets del Everest, frontend |
| **Óscar** | Product Owner / Cliente / Stakeholder principal | Visión de negocio, fundamentos psicométricos, backlog |

### Marco de decisiones
- **Producto / negocio:** Óscar decide (consulta Diego para UX, Andrés para viabilidad técnica).
- **Arquitectura técnica:** Andrés decide. Diego y Óscar se adaptan.
- **Conflictos UI vs. lógica:** Diego + Andrés proponen 2 alternativas → Óscar elige por ROI.

---

## 5. Cronograma (12 semanas)

| Fase | Semanas | Entregable clave |
|---|---|---|
| A — Requerimientos e HU | W1–W5 | Backlog completo refinado (JSON/MD), criterios de aceptación Gherkin |
| B — Infraestructura y Estado del Arte | W5–W6 | Modelo ER preliminar, benchmark de gamificación |
| C — Arquitectura | W6–W7 | Diagramas de componentes, API contracts, prompt del agente |
| D — Identidad Visual | W6–W8 | Brandbook, assets del Everest, UI Kit |
| E — Frontend | W8–W10 | SPA web responsiva (Login, Hub, Mapa, Dilemas, Chat, Resultados) |
| F — Backend | W8–W10 | Supabase schema + RLS + Edge Function del Sherpa |
| G — Integración y QA | W11 | Plataforma en staging, pruebas de integración |
| H — Delivery | W12 | Producción, onboarding, entrega de repositorio |

### Milestones
- **M1 (W5):** Backlog firmado por Óscar, todas las HU estimadas.
- **M2 (W7):** DB diseñada, arquitectura definida, UI del Everest lista para codificar.
- **M3 (W10):** Code freeze — frontend + backend integrados, pruebas unitarias básicas.
- **M4 (W12):** Entrega formal en producción + acta de conformidad.

---

## 6. Identidad Visual y Brandbook

```json
{
  "paleta_colores": {
    "primario": "#2E7D32",
    "primario_oscuro": "#1B5E20",
    "secundario": "#FFB300",
    "neutro_claro": "#F5F5F5",
    "neutro_oscuro": "#212121",
    "acento_error": "#D32F2F",
    "acento_exito": "#388E3C",
    "montaña_base": "#5D4E37",
    "cielo_cima": "#87CEEB"
  },
  "tipografia": {
    "primaria": "Inter (400/600/700)",
    "titulo": "Inter Bold 32px / line-height 1.2",
    "cuerpo": "Inter Regular 14px / line-height 1.5"
  }
}
```

**Tonalidad:** Aventura épica de montaña. Visual aventurero pero profesional. *No es carnaval, es expedición corporativa.*

**Sherpa:** Sabio, accesible, con humor sutil. Compañero de viaje, no jefe. Coach empresarial, no NPC de fantasía.

---

## 7. Modelo DISC — Conceptos Clave (para dummies)

### ¿Qué es DISC?
DISC es un modelo de comportamiento humano desarrollado por William Moulton Marston (1928) que clasifica los estilos de conducta en cuatro dimensiones. No es un test de inteligencia ni de salud mental: mide *cómo* actúa una persona, no *cuán bien* actúa.

### Las 4 dimensiones

| Dimensión | Nombre | Pregunta central | En el liderazgo |
|---|---|---|---|
| **D** | Dominance (Dominancia) | ¿Cómo resuelvo problemas y enfrento retos? | Orientado a resultados, directo, decidido, asume riesgos |
| **I** | Influence (Influencia) | ¿Cómo influyo en otros? | Comunicador, entusiasta, construye relaciones, persuade |
| **S** | Steadiness (Estabilidad) | ¿Cómo respondo al ritmo y los cambios? | Paciente, leal, colaborativo, prefiere entornos estables |
| **C** | Conscientiousness (Conformidad) | ¿Cómo respondo a las reglas y procedimientos? | Analítico, preciso, orientado a la calidad, sigue normas |

### Cómo se mide
Se aplica un cuestionario de situaciones o preferencias. El resultado es un **perfil** (no un tipo único): cada persona tiene las cuatro dimensiones en diferente intensidad. El perfil se representa como un gráfico de barras o radar.

### Perfiles frecuentes en líderes
- **D alto:** Líderes de alto rendimiento, visionarios, a veces imponentes.
- **I alto:** Líderes inspiradores, buenos motivadores, pueden ser poco detallistas.
- **S alto:** Líderes estables, de confianza, resistentes al cambio disruptivo.
- **C alto:** Líderes técnicos, analíticos, pueden sobre-analizar antes de decidir.

### Cómo se integra en Everest Experience
1. **Diagnóstico inicial (pre-escalada):** El usuario responde el cuestionario DISC antes de comenzar la montaña. Establece la línea base de su perfil.
2. **Retos en la ruta:** Cada dilema de decisión en la montaña está diseñado para activar comportamientos D, I, S o C. Las elecciones revelan el perfil real en acción.
3. **Retroalimentación del Sherpa:** El coach IA conecta las elecciones del usuario con las dimensiones DISC, sugiriendo reflexiones.
4. **Panel de resultados:** El perfil DISC se actualiza y refina con cada reto. Al final, el usuario ve su perfil de liderazgo consolidado y áreas de desarrollo.

### Consideración ética importante
DISC es descriptivo, no prescriptivo. Ningún perfil es "mejor". El objetivo de Everest Experience es la autoconciencia y el desarrollo, no la clasificación de personas.

---

## 8. Gamificación — Principios Clave (para dummies)

### ¿Qué es gamificación?
Aplicar elementos y mecánicas del diseño de juegos en contextos no lúdicos para aumentar motivación, engagement y aprendizaje. No es "hacer todo un juego": es usar la *psicología* de los juegos para que las personas quieran participar.

### Framework de motivación: Octalysis (Yu-kai Chou)
Ocho impulsores de motivación que todo sistema gamificado debería activar:

| # | Impulsor | Cómo se aplica en Everest |
|---|---|---|
| 1 | **Épico y propósito** | La narrativa del Everest: "Tu viaje como líder es épico" |
| 2 | **Logro y dominio** | Medallas, progreso en rutas, badges de habilidades |
| 3 | **Empoderamiento creativo** | El usuario elige su ruta y su avatar |
| 4 | **Propiedad y posesión** | El avatar y el perfil son suyos y evolucionan |
| 5 | **Influencia social** | Rankings por organización, comparativas con el equipo |
| 6 | **Escasez y antecipación** | Rutas bloqueadas que se desbloquean con progreso |
| 7 | **Imprevisibilidad** | Dilemas que no tienen respuesta "obvia" — sorpresa en la retroalimentación |
| 8 | **Pérdida y evasión** | Campamentos que "expiran" si no se completan en un plazo |

### Mecánicas específicas del juego

**Rutas de progreso:**
- Tres rutas de escalada (Estándar, Desafío, Extrema) con dificultad creciente.
- Cada ruta tiene campamentos (checkpoints) donde se guardan el progreso y las reflexiones.

**Sistema de recompensas:**
- **Medallas:** Por completar retos, explorar perfil DISC, primeras interacciones.
- **XP (Puntos de Experiencia):** Acumulados por cada dilema respondido.
- **Avatar personalizable:** Ropa de montañismo, accesorios desbloqueables.

**Sherpa NPC:**
- Personaje no jugador que actúa como coach de IA.
- Da retroalimentación personalizada tras cada dilema.
- No juzga, no da respuestas correctas: hace preguntas poderosas.

**Bucle de juego (game loop):**
```
Dilema → Elección → Retroalimentación del Sherpa → XP/Medalla → Próximo campamento
```

### Buenas prácticas de gamificación B2B

1. **El juego no reemplaza al aprendizaje, lo facilita.** Los datos del juego deben conectarse con conversaciones de coaching reales.
2. **Progresión visible pero no punitiva.** Mostrar siempre cuánto falta, nunca hacer sentir al usuario "perdedor".
3. **Autonomía sobre competencia.** En B2B, el ranking público puede ser tóxico. Preferir comparativas opcionales o anónimas.
4. **Onboarding en 60 segundos.** Si el usuario no entiende qué hacer en el primer minuto, se pierde. La metáfora del Everest debe ser obvia desde el login.
5. **Feedback inmediato.** Cada acción debe tener respuesta visual o narrativa en menos de 300ms.
6. **Narrativa coherente.** Nunca romper la metáfora del Everest con jerga corporativa fría dentro del juego.

---

## 9. UX para B2B — Principios Aplicados

### El usuario B2B no es voluntario
A diferencia del consumidor B2C, el usuario B2B muchas veces llega a la plataforma porque *su empresa lo indica*, no porque lo buscó. Esto implica:
- El onboarding debe justificar el tiempo invertido desde el primer minuto ("¿para qué sirve esto?").
- La experiencia debe ser digna del tiempo de un ejecutivo: sin fricciones, sin bugs visibles, sin textos largos.
- El sistema debe funcionar en el primer intento (sin curva de aprendizaje).

### Los 8 principios UX clave para esta plataforma

| Principio | Aplicación en Everest Experience |
|---|---|
| **Claridad sobre creatividad** | Cada pantalla tiene un único call-to-action evidente. Nunca dos botones del mismo peso visual. |
| **Progreso siempre visible** | Barra de progreso global en el Hub Central. El usuario siempre sabe dónde está en la escalada. |
| **Error prevention first** | Formularios con validación en tiempo real. El botón "Continuar" deshabilitado hasta que se cumplan las condiciones. |
| **Carga cognitiva mínima** | Un dilema a la vez. Máximo 4 opciones de respuesta. Sin información irrelevante en pantalla. |
| **Feedback inmediato** | Animaciones de confirmación tras cada elección. El Sherpa responde en segundos. |
| **Accesibilidad básica** | Contraste mínimo WCAG AA, textos legibles sin zoom, navegación por teclado posible. |
| **Mobile first** | Responsivo desde 320px. Los ejecutivos usan el celular en viajes. |
| **Consistencia visual** | Un solo sistema de diseño. Botones iguales hacen lo mismo siempre. |

### Anti-patrones a evitar (B2B corporativo)

- **Dark patterns:** No usar urgencia falsa, no esconder el logout, no hacer el cierre de sesión difícil.
- **Gamificación forzada:** No poner puntos o badges donde no agregan valor. Un CEO puede sentirse infantilizado.
- **Exceso de notificaciones:** El ejecutivo no quiere ser bombardeado. Notificaciones solo por hitos importantes.
- **Formularios interminables:** El perfil debe construirse progresivamente a lo largo del juego, no en un formulario inicial de 20 campos.
- **Lenguaje infantil:** La narrativa es épica y aventurera, pero el vocabulario es profesional.

### Heurísticas de Nielsen (las 10 — aplicadas al contexto)

1. **Visibilidad del estado del sistema** → Loader, barra de progreso, estado de la ruta siempre visible.
2. **Match con el mundo real** → La metáfora del Everest es universal y comprensible.
3. **Control y libertad** → El usuario puede pausar, volver al Hub, reanudar desde donde lo dejó.
4. **Consistencia y estándares** → Un solo sistema de diseño. Iconografía estándar (no inventada).
5. **Prevención de errores** → Validación proactiva, confirmación antes de acciones irreversibles.
6. **Reconocimiento sobre recuerdo** → Opciones siempre visibles. No pedir que el usuario recuerde reglas.
7. **Flexibilidad y eficiencia** → El coach puede acceder al panel analítico sin pasar por el juego.
8. **Diseño estético y minimalista** → Solo la información relevante en cada pantalla.
9. **Ayuda a reconocer y recuperarse de errores** → Mensajes de error claros, con solución propuesta.
10. **Ayuda y documentación** → Tooltip del Sherpa como mecanismo de ayuda contextual inline.

---

## 10. Fases del Proyecto — Estado Actual

> Actualizar este bloque con cada avance significativo.

| Fase | Estado | Notas |
|---|---|---|
| A — Requerimientos e HU | En progreso | Workshop inicial completado (W1) |
| B — Infraestructura | Pendiente | — |
| C — Arquitectura | Pendiente | — |
| D — Identidad Visual | En progreso | Brandbook v1 definido, assets pendientes |
| E — Frontend | Pendiente | — |
| F — Backend | Pendiente | — |
| G — Integración / QA | Pendiente | — |
| H — Delivery | Pendiente | — |

---

## 11. Decisiones y Acuerdos Registrados

| Fecha | Decisión | Responsable |
|---|---|---|
| 2026-06 | Stack: Supabase + Gemini + HTML/CSS/JS vanilla | Andrés |
| 2026-06 | Metodología: SDD (Spec-Driven Development) | Andrés |
| 2026-06 | Duración MVP: 12 semanas | Óscar + equipo |
| 2026-06 | Mockup generado con IA antes de codificación real (C3 Workshop) | Andrés + Diego |
| 2026-06 | Sherpa = coach empresarial, no NPC de fantasía | Feedback de cliente |
| 2026-06 | Tipografía: Inter | Diego |
| 2026-06 | Paleta: Verde montaña + Dorado + Azul cielo | Diego |

---

## 12. Glosario del Proyecto

| Término | Definición |
|---|---|
| **Sherpa** | El NPC coach IA de la plataforma. Guía al usuario con retroalimentación psicométrica. |
| **Hub Central** | La pantalla principal del jugador: avatar, progreso, medallas. |
| **Campamento** | Checkpoint dentro de una ruta. Guarda el progreso y muestra reflexiones. |
| **Dilema** | Escenario de liderazgo con 4 opciones de respuesta que activan dimensiones DISC. |
| **Ruta** | Camino de escalada en el mapa del Everest. Hay 3: Estándar, Desafío, Extrema. |
| **SDD** | Spec-Driven Development. Las especificaciones completas guían la generación de código. |
| **RLS** | Row Level Security de Supabase. Controla qué datos ve cada rol de usuario. |
| **C3 Mockup** | Workshop de generación de mockup interactivo con IA para validar con el cliente antes de codificar. |
| **DISC** | Modelo psicométrico de 4 dimensiones (Dominancia, Influencia, Estabilidad, Conformidad). |
| **OrgAdmin** | Rol de administrador de una organización dentro de la plataforma. |
| **Player** | El líder / colaborador que realiza el diagnóstico y juega la escalada. |

---

## 13. Preguntas Abiertas y Pendientes

> Mover a "Decisiones Registradas" cuando se resuelvan.

- [ ] ¿Cuántos retos por ruta? ¿Cuántos campamentos?
- [ ] ¿El diagnóstico DISC inicial es obligatorio antes del primer reto?
- [ ] ¿Cómo se manejan los resultados cuando una organización tiene múltiples equipos?
- [ ] ¿El ranking es visible entre players de una misma organización?
- [ ] ¿Se integra SSO (Single Sign-On) corporativo desde el inicio o es fase 2?
- [ ] ¿Qué pasa si el usuario abandona un dilema a mitad de camino? ¿Se guarda el estado?
- [ ] ¿Los coaches tienen acceso al historial completo de elecciones del player?
- [ ] ¿Cuál es el modelo de precios / licenciamiento para los clientes B2B?
