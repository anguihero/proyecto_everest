# Everest Experience — Contexto de Ideación del MVP Modular

**Estado:** Borrador para revisión  
**Fecha:** 2026-06-28  
**Propósito:** Consolidar el conocimiento generado durante la sesión de ideación y servir como entrada para el levantamiento posterior de historias de usuario.  
**Aprobación pendiente:** Óscar (producto), Andrés (arquitectura), Diego (experiencia visual) y revisión de Psicología/Gobierno.

> Este documento expresa una propuesta de producto. No reemplaza todavía el contexto maestro, el backlog ni las decisiones aprobadas del proyecto.

---

## 1. Resumen ejecutivo

Everest Experience se concibe como un portal web B2B/B2B2C de autoconocimiento y desarrollo de liderazgo. El MVP debe permitir que un usuario autenticado recorra dos experiencias independientes:

1. **Expedición Base:** exploración situacional de preferencias de liderazgo mediante 10 escenarios inspirados en DISC.
2. **Expedición Cumbre:** simulación de 10 decisiones empresariales ambiguas, asistidas por tres perspectivas de coaching y analizadas mediante una selección de fortalezas del modelo VIA.

El principio de producto y arquitectura para el crecimiento de la plataforma será:

> **Construiremos una consola de experiencias y, al mismo tiempo, una fábrica de casetes.**

La **consola** es la plataforma estable: identidad, autenticación, permisos, ejecución de experiencias, persistencia, scoring, feedback, resultados, IA, analítica y administración.

Los **casetes** son paquetes de contenido versionados e intercambiables: rutas diagnósticas, simulaciones empresariales y futuras experiencias de aprendizaje. Cada casete utiliza contratos comunes para que pueda agregarse, actualizarse o retirarse sin reescribir la consola.

Este enfoque evita que DISC, VIA o una narrativa específica queden codificados rígidamente en la aplicación. El MVP validará la consola con dos casetes iniciales.

---

## 2. Origen de esta propuesta

La sesión de ideación reunió las perspectivas de los ocho agentes principales definidos en `.claude/CLAUDE.md`:

| Agente | Contribución |
|---|---|
| PM / Product Manager | Alcance, priorización, métricas y secuencia de entrega |
| Gobierno y Gobernanza | Privacidad, trazabilidad, claims, licencias y control de alcance |
| UX/UI | Journeys, pantallas, accesibilidad y carga cognitiva |
| Frontend Modular | Componentes reutilizables, estados y factibilidad técnica |
| Game Designer | Game loops, retos, coaches, consecuencias y progresión |
| Gamificación | Motivación B2B, engagement y prevención de mecánicas dañinas |
| IA Conversacional / Sherpa | Generación controlada, prompts, guardrails y fallbacks |
| Psicología Empresarial Colombia | Validez, ética, lenguaje y adecuación cultural |

Los agentes Backend, QA y Documentación deberán participar en la siguiente fase, cuando esta propuesta sea revisada y convertida en historias de usuario y especificaciones.

---

## 3. Visión del producto

Everest Experience debe permitir a una organización ofrecer experiencias privadas y estructuradas para que sus líderes:

- reconozcan tendencias de comportamiento;
- practiquen decisiones bajo ambigüedad;
- comprendan los trade-offs de sus elecciones;
- observen fortalezas movilizadas, subutilizadas o posiblemente sobreutilizadas;
- reciban preguntas y prácticas de desarrollo;
- conversen con un coach humano a partir de evidencias, no de etiquetas.

La plataforma no debe:

- emitir diagnósticos clínicos;
- clasificar personas como buenas o malas;
- predecir por sí sola desempeño o idoneidad laboral;
- tomar decisiones de selección, promoción, sanción o despido;
- presentar una simulación corta como instrumento psicométrico validado;
- combinar constructos distintos en un único puntaje sin sustento.

---

## 4. Metáfora arquitectónica: consola y casetes

### 4.1 La consola

La consola contiene capacidades transversales que no dependen de una experiencia particular:

- autenticación y recuperación de acceso;
- perfiles, organizaciones, roles y permisos;
- consentimiento, privacidad y derechos del titular;
- catálogo de experiencias disponibles;
- inicio, pausa, guardado y reanudación;
- motor de pasos, escenarios y elecciones;
- control de ayudas o coaches;
- scoring determinístico y versionado;
- motor de consecuencias y estado acumulado;
- generación de lecturas mediante IA;
- fallbacks determinísticos;
- visualización accesible de resultados;
- progreso y telemetría;
- administración de usuarios y contenidos;
- auditoría de versiones y accesos.

### 4.2 Los casetes

Un casete es una definición de experiencia que la consola sabe ejecutar. Puede representar:

- un diagnóstico o exploración;
- una simulación;
- una ruta de aprendizaje;
- una experiencia de refuerzo;
- una experiencia específica para una industria o nivel de liderazgo.

Cada casete debería declarar, como mínimo:

| Elemento | Descripción |
|---|---|
| Identidad | ID, nombre, descripción y versión |
| Tipo | Exploración, simulación, aprendizaje u otro |
| Audiencia | Roles, organización, segmento o cohorte |
| Narrativa | Tema, introducción, cierre y tono |
| Pasos | Orden, escenarios, opciones y reglas |
| Dimensiones | Constructos observados y sus definiciones |
| Scoring | Pesos, normalización, evidencia mínima y versión |
| Estado | Variables que cambian durante la experiencia |
| Ayudas | Coaches, pistas, costos y límites |
| Feedback | Consecuencias, explicaciones y contrafactuales |
| Resultado | Visuales, textos, acciones y disclaimers |
| IA | Plantillas, datos permitidos, formato y fallback |
| Telemetría | Eventos y métricas de producto |
| Vigencia | Borrador, piloto, publicado, retirado |

### 4.3 La fábrica de casetes

La fábrica es el proceso mediante el cual se diseñan, validan, versionan y publican nuevas experiencias.

Para el MVP no se propone construir un editor visual completo. La fábrica inicial puede operar mediante contenido estructurado, revisión humana y publicación técnica controlada.

Flujo esperado:

```text
Idea de experiencia
        ↓
Brief pedagógico y psicológico
        ↓
Diseño de escenarios, opciones y scoring
        ↓
Revisión de Psicología, Gobierno y Game Design
        ↓
Prueba de contenido y entrevistas cognitivas
        ↓
Versionado y publicación
        ↓
Ejecución en la consola
        ↓
Telemetría, aprendizaje y nueva versión
```

### 4.4 Principios de modularidad

1. El contenido no debe quedar embebido directamente en componentes de interfaz.
2. La consola no debe asumir que toda experiencia utiliza DISC, VIA, cuatro opciones o diez pasos.
3. El MVP puede configurar esas cantidades, aunque inicialmente publique experiencias de 10 pasos.
4. Toda experiencia y todo scoring deben tener versión.
5. Una sesión debe conservar la versión exacta del casete con la que comenzó.
6. Actualizar un casete no debe cambiar retrospectivamente resultados terminados.
7. El frontend nunca será la fuente autoritativa del scoring.
8. La IA no define puntajes, reglas ni consecuencias.
9. Un casete debe poder probarse antes de publicarse.
10. Los datos de distintas organizaciones deben permanecer aislados.

---

## 5. Usuarios y roles

La solicitud inicial plantea cuatro roles: **jugador, líder, soporte y admin**. El repositorio vigente utiliza `player`, `coach`, `org_admin` y `sys_admin`. Antes de levantar las historias definitivas se debe aprobar una nomenclatura y matriz única.

Propuesta inicial:

| Rol de negocio | Rol técnico tentativo | Responsabilidad |
|---|---|---|
| Jugador | `player` | Realiza experiencias y consulta sus propios resultados |
| Líder / Coach | `coach` | Acompaña jugadores o equipos autorizados |
| Admin | `org_admin` | Gestiona usuarios, asignaciones y métricas de su organización |
| Soporte | Rol técnico limitado por definir | Atiende incidencias sin acceso innecesario a contenido psicométrico |
| Administrador global | `sys_admin` | Opera la plataforma y las organizaciones |

### Decisiones pendientes sobre roles

- ¿“Líder” es un supervisor jerárquico, un coach o ambos?
- ¿Soporte necesita un rol propio o permisos temporales auditados?
- ¿El administrador global será visible como rol del producto?
- ¿Qué resultados individuales puede ver un coach?
- ¿Qué información recibe un administrador organizacional?
- ¿Cómo se obtiene y revoca el consentimiento para compartir resultados?

---

## 6. Journey general del jugador

```text
Login / recuperación
        ↓
Consentimiento y onboarding
        ↓
Hub de experiencias
        ↓
Expedición Base — 10 escenarios
        ↓
Resultado conductual + lectura + prácticas
        ↓
Expedición Cumbre — 10 retos empresariales
        ↓
Resultado empresarial + patrones VIA + plan de práctica
        ↓
Perfil histórico del jugador
```

Principios UX:

- un escenario por pantalla;
- un CTA principal;
- progreso siempre visible;
- guardado automático después de cada confirmación;
- posibilidad de pausar y reanudar;
- feedback visual inmediato;
- ausencia de temporizadores en el MVP;
- navegación mobile-first desde 320 px;
- operación completa mediante teclado;
- ninguna dimensión comunicada únicamente mediante color;
- todo radar acompañado por una tabla o descripción equivalente;
- tono épico y sobrio, sin infantilizar al usuario.

---

## 7. Casete 1: Expedición Base

### 7.1 Objetivo

Ofrecer una exploración situacional de tendencias de liderazgo mediante escenarios ambientados en la escalada del Everest.

### 7.2 Alcance

- 10 escenarios.
- 4 respuestas plausibles por escenario.
- Orden fijo para el MVP.
- Orden visual de respuestas aleatorizable para reducir sesgo de posición.
- Sin respuestas correctas o incorrectas visibles.
- Sin mostrar resultados parciales antes de completar la experiencia.
- Pausa, autosave y reanudación.

### 7.3 Cobertura temática sugerida

| Contexto | Cantidad |
|---|---:|
| Decisión bajo presión | 2 |
| Conflicto | 2 |
| Cambio e incertidumbre | 2 |
| Influencia y movilización | 2 |
| Calidad y riesgo | 2 |

### 7.4 Scoring

Cada opción debería aportar una matriz ponderada, no una etiqueta única. Ejemplo conceptual:

```json
{
  "D": 2,
  "I": 0,
  "S": -1,
  "C": 1
}
```

La fórmula, normalización, cobertura y límites de interpretación deberán ser revisados por un profesional competente.

### 7.5 Resultado

- radar D/I/S/C;
- tabla accesible con valores y descripciones;
- patrones situacionales observados;
- incertidumbre y limitaciones explícitas;
- lectura narrativa;
- tres prácticas de desarrollo;
- fecha y versión de la experiencia.

### 7.6 Lenguaje recomendado

Utilizar:

- “En estas decisiones apareció…”
- “Podría indicar…”
- “Esta tendencia puede ayudar cuando…”
- “Bajo presión también podría generar…”
- “Vale la pena experimentar con…”

Evitar:

- “Eres dominante.”
- “Careces de prudencia.”
- “Tu perfil demuestra que…”
- “Esta es tu debilidad.”
- “No eres apto para…”

### 7.7 Condición de validez

Con 10 escenarios propios no se debe afirmar que se aplica un instrumento DISC validado, salvo que se utilice un instrumento autorizado que permita esa interpretación.

Nombres provisionales:

- **Exploración situacional de liderazgo**
- **Perfil conductual exploratorio**
- **Tendencias de liderazgo observadas**

La denominación “diagnóstico DISC” queda pendiente de validación técnica, legal y de producto.

---

## 8. Casete 2: Expedición Cumbre

### 8.1 Objetivo

Permitir que el jugador dirija una empresa ficticia a través de decisiones ambiguas, información incompleta y consecuencias acumuladas.

### 8.2 Estados visibles de la empresa

- Caja.
- Confianza.
- Personas.
- Capacidad de ejecución.

Todos los impactos relevantes del MVP deben poder explicarse. No se recomiendan variables ocultas que hagan sentir al jugador que el sistema manipula el resultado.

### 8.3 Arco de los 10 retos

1. Definir el mandato y las prioridades.
2. Recuperar un cliente crítico.
3. Resolver una falla operacional.
4. Abordar un conflicto entre líderes.
5. Ejecutar un recorte presupuestal.
6. Evaluar una oportunidad ambigua.
7. Responder al desgaste del equipo.
8. Resolver un dilema ético o comercial.
9. Gestionar una crisis reputacional.
10. Integrar aprendizajes y decidir la continuidad de la empresa.

### 8.4 Diseño de decisiones

- Cada reto ofrece entre 3 y 4 opciones plausibles.
- No existe una respuesta universalmente correcta.
- La calidad depende del contexto, los estados acumulados y los trade-offs.
- Algunas consecuencias pueden ser inmediatas y otras diferidas.
- Las consecuencias se calculan con tablas determinísticas versionadas.
- La IA no modifica el estado de la empresa.

### 8.5 Coaches

| Coach | Lente principal | Fortalezas asociadas |
|---|---|---|
| Estratega | Sistema, escenarios y largo plazo | Perspectiva, prudencia, creatividad |
| Humano | Personas, legitimidad y cultura | Inteligencia social, amabilidad, equidad, trabajo en equipo |
| Ejecución | Velocidad, disciplina y viabilidad | Valentía, perseverancia, autorregulación, liderazgo |

Regla recomendada para el MVP:

- un coach disponible sin costo en cada reto;
- un segundo coach consume una de cinco fichas de oxígeno para toda la ruta;
- ningún coach conoce o revela una respuesta perfecta;
- cada coach aporta información diferente y tiene puntos ciegos;
- después de decidir se muestra qué perspectiva habrían añadido los coaches no consultados.

### 8.6 Feedback por reto

1. Consecuencia inmediata y cambio en los estados.
2. Fortaleza o combinación de fortalezas movilizadas.
3. Posible subuso o sobreuso contextual, solo cuando exista evidencia.
4. Contrafactual breve de una alternativa relevante.
5. Perspectivas que no se consultaron.
6. Pregunta de reflexión opcional.

El feedback no debe castigar retrospectivamente al jugador por no seleccionar un coach.

### 8.7 Cierre

El resultado final separará:

1. **Desenlace empresarial:** efecto acumulado de las decisiones dentro del modelo.
2. **Patrones de fortalezas:** evidencia contextual observada.
3. **Plan de práctica:** una fortaleza a modular y dos o tres acciones concretas.

El desenlace de la empresa no equivale a calidad moral ni a nivel de liderazgo.

---

## 9. Modelo VIA en el MVP

El modelo VIA organiza 24 fortalezas dentro de seis virtudes:

| Virtud | Fortalezas |
|---|---|
| Sabiduría | Creatividad, curiosidad, apertura mental, amor por el aprendizaje, perspectiva |
| Coraje | Valentía, perseverancia, honestidad, vitalidad |
| Humanidad | Amor, amabilidad, inteligencia social |
| Justicia | Trabajo en equipo, equidad, liderazgo |
| Templanza | Perdón, humildad, prudencia, autorregulación |
| Trascendencia | Gratitud, esperanza, humor, apreciación de la excelencia |

Para 10 retos no se pretende medir con igual robustez las 24 fortalezas.

### Recomendación

- seleccionar entre 6 y 8 fortalezas prioritarias;
- observar cada una en varios contextos;
- exigir al menos tres evidencias antes de presentar una conclusión;
- mostrar evidencias situadas, no solamente barras;
- utilizar “subuso”, “uso funcional” y “posible sobreuso contextual” con prudencia;
- no afirmar que la experiencia aplica el VIA Survey si no utiliza el instrumento autorizado;
- no usar normas poblacionales que no hayan sido validadas para el caso de uso.

### Relación con DISC

DISC y VIA no deben fusionarse:

- DISC describe preferencias conductuales.
- VIA ofrece un lenguaje de fortalezas y uso contextual.
- No existe equivalencia directa entre una dimensión DISC y una fortaleza VIA.
- Cada modelo debe tener visualización, explicación y limitaciones separadas.

Decisión recomendada para el MVP, pendiente de aprobación:

> Mantener DISC como mapa conductual exploratorio y utilizar una selección de fortalezas VIA como lenguaje de desarrollo dentro de la simulación, sin score combinado.

---

## 10. IA Conversacional y Sherpa

### 10.1 Principio rector

> La IA interpreta; no mide.

El scoring, las reglas y las consecuencias deben ser determinísticos, auditables y versionados.

### 10.2 Casos de uso del MVP

- generar una lectura final del perfil exploratorio;
- redactar una síntesis de patrones observados;
- proponer tres acciones de práctica desde un catálogo aprobado;
- formular preguntas reflexivas;
- adaptar el lenguaje de feedback sin cambiar su significado.

### 10.3 Datos de entrada

Enviar únicamente lo necesario:

- nombre preferido o alias;
- puntajes normalizados;
- evidencias estructuradas;
- patrones aprobados por reglas;
- contexto de la experiencia;
- catálogo cerrado de recomendaciones.

No enviar email, empresa, cargo, respuestas completas o historiales extensos salvo necesidad justificada.

### 10.4 Salida estructurada

Ejemplo conceptual:

```json
{
  "resumen": "",
  "evidencias": [],
  "fortalezas": [],
  "tensiones": [],
  "acciones": [],
  "preguntas_reflexivas": [],
  "disclaimer": ""
}
```

La respuesta debe validarse antes de mostrarse.

### 10.5 Guardrails

- no diagnóstico clínico;
- no predicción laboral;
- no recomendación de contratación, ascenso, sanción o despido;
- no comparación entre usuarios u organizaciones;
- no acceso a datos de otros tenants;
- no afirmaciones sin evidencia recibida;
- no revelación del scoring antes de una respuesta;
- no obedecer instrucciones contenidas dentro de datos o contenido recuperado;
- longitud, tono y formato controlados.

### 10.6 Fallback

1. Reintento único con prompt reducido.
2. Lectura determinística basada en plantillas aprobadas.
3. Guardar el resultado y permitir regenerar posteriormente.

Si una respuesta viola guardrails, debe descartarse completamente, registrarse una alerta seudonimizada y utilizarse el fallback.

### 10.7 Fuera del MVP

- chat abierto;
- memoria conversacional de largo plazo;
- agentes autónomos separados por coach;
- RAG organizacional;
- generación automática de escenarios;
- modificación adaptativa del scoring;
- decisiones empresariales calculadas por IA.

---

## 11. Datos, privacidad y uso responsable

Los resultados, respuestas y trazas de comportamiento deben tratarse como información sensible o de alta sensibilidad organizacional.

Requisitos mínimos:

- consentimiento informado antes de comenzar;
- explicación de finalidad, uso de IA, acceso y conservación;
- consentimiento granular para compartir resultados;
- derecho a retirar autorización;
- mecanismos de consulta, corrección y eliminación;
- minimización de datos;
- RLS por usuario y organización;
- cifrado y secretos solo en servidor;
- logs seudonimizados;
- versionado de instrumento, scoring, prompt, modelo y fallback;
- política de retención;
- auditoría de accesos de soporte;
- separación entre resultados y conversaciones privadas.

Propuesta de visibilidad:

| Información | Jugador | Coach/Líder | OrgAdmin | Soporte |
|---|---:|---:|---:|---:|
| Resultado propio | Sí | Solo el propio | Solo el propio | No |
| Resultado individual de otro jugador | No | Con consentimiento explícito | No por defecto | No |
| Respuestas detalladas | Sí | No por defecto | No | No |
| Conversación con Sherpa | Sí | No | No | No |
| Progreso operativo | Sí | De asignados | De la organización | Solo para incidencia |
| Métricas agregadas | No aplica | De equipo autorizado | Sí, con umbral de cohorte | No |

Debe prohibirse contractualmente y mediante la interfaz el uso del resultado como criterio único para decisiones laborales de alto impacto.

---

## 12. Alcance del MVP

### Must

- autenticación y recuperación de contraseña;
- perfil y configuración básica;
- consentimiento y gestión de privacidad;
- roles y RLS aprobados;
- Hub con catálogo de experiencias;
- motor modular de experiencias;
- Expedición Base de 10 escenarios;
- Expedición Cumbre de 10 retos;
- pausa, autosave y reanudación;
- scoring y consecuencias determinísticos;
- tres coaches con uso limitado;
- feedback inmediato y contrafactual;
- resultados separados y accesibles;
- lectura IA con fallback;
- perfil histórico básico;
- administración mínima de usuarios y asignaciones;
- telemetría y auditoría mínimas.

### Should

- segundo coach mediante fichas de oxígeno;
- panel básico para Coach/Líder;
- métricas organizacionales agregadas;
- exportación simple del resultado propio;
- anotación personal para contextualizar una respuesta;
- comparación descriptiva entre preferencia y conducta, sin causalidad.

### Could

- avatar básico;
- medallas privadas;
- notificaciones de progreso;
- biblioteca de prácticas;
- rutas adicionales;
- casetes específicos por industria.

### Fuera del MVP

- rutas Estándar, Desafío y Extrema;
- rankings públicos;
- tienda o moneda;
- avatar avanzado;
- multiplayer;
- sesiones sincronizadas;
- chat abierto;
- editor visual completo de casetes;
- generación de retos por IA;
- múltiples idiomas visibles;
- SSO corporativo;
- PWA offline completa;
- facturación y licenciamiento automatizados;
- PDF y analítica avanzada;
- uso para selección o predicción de desempeño.

---

## 13. Componentes conceptuales de la consola

Los nombres son orientativos y deberán validarse durante la arquitectura:

- `AuthAndIdentity`
- `RoleRouter`
- `ExperienceCatalog`
- `ExperienceRunner`
- `ScenarioCard`
- `ChoiceGroup`
- `CoachSelector`
- `StateTracker`
- `FeedbackPanel`
- `ScoringEngine`
- `ConsequenceEngine`
- `ResultNarrative`
- `RadarChart`
- `AccessibleScoreTable`
- `SessionPersistence`
- `ContentVersioning`
- `ConsentManager`
- `AuditTrail`

Estado conceptual de una sesión:

```json
{
  "experienceId": "",
  "experienceVersion": "",
  "sessionId": "",
  "userId": "",
  "currentStep": 0,
  "answers": [],
  "coachUses": [],
  "state": {},
  "status": "not_started",
  "lastSavedAt": ""
}
```

La base de datos será la fuente de verdad. El almacenamiento local solo podrá utilizarse como caché de recuperación y no deberá conservar perfiles sensibles completos.

---

## 14. Estados funcionales obligatorios

Cada experiencia debe contemplar:

- no iniciada;
- en progreso;
- guardando;
- guardada;
- pausada;
- completada;
- error recuperable;
- sin conexión;
- conflicto de sesión;
- contenido no disponible;
- IA lenta;
- IA fallida con fallback;
- acceso denegado;
- versión retirada;
- sesión expirada.

El guardado de respuestas debe ser idempotente y proteger contra doble envío.

---

## 15. Gamificación

La motivación debe provenir de autonomía, dominio y reflexión, no de competencia pública.

Reglas:

- XP reconoce avance, no calidad moral;
- no se entregan más puntos por expresar una dimensión o fortaleza específica;
- no hay rankings públicos;
- no hay vidas ni fracaso irreversible;
- no expiran campamentos;
- una decisión confirmada no se rebobina durante la primera pasada;
- la celebración debe ser sobria;
- las fichas de coach no se compran;
- las insignias, si se incluyen, describen patrones o hitos privados;
- el usuario puede pausar sin penalización.

---

## 16. Métricas del piloto

| Métrica | Objetivo inicial |
|---|---:|
| Inicio tras onboarding | ≥ 80% |
| Finalización Expedición Base | ≥ 75% |
| Finalización Expedición Cumbre | ≥ 65% |
| Comprensión del carácter no clínico | ≥ 80% |
| Utilidad percibida | ≥ 4/5 |
| Usuario identifica una acción | ≥ 70% |
| Uso de al menos un coach | ≥ 70% |
| Lenguaje percibido como respetuoso | ≥ 80% |
| Accesos indebidos entre organizaciones | 0 |
| Escenarios revisados por experto | 100% |
| Retos con abandono superior al 12% | Investigar individualmente |

Métricas adicionales:

- tiempo mediano por reto;
- distribución de opciones;
- distribución de coaches consultados;
- activación del fallback;
- errores de guardado;
- ítems interpretados como trampas;
- diferencias de comprensión por género, edad, región y nivel jerárquico;
- retorno para revisar una práctica a los 14 días.

No debe publicarse una cifra de confiabilidad o validez hasta contar con diseño, muestra y análisis apropiados.

---

## 17. Estrategia de validación

### Vertical slice

Antes de producir los 20 escenarios:

- un escenario completo de Expedición Base;
- dos retos conectados de Expedición Cumbre;
- tres coaches;
- una consecuencia diferida;
- un resultado preliminar;
- una lectura IA;
- un fallback determinístico;
- guardado y reanudación.

### Pruebas iniciales

1. Prueba UX con 5–8 líderes.
2. Entrevistas cognitivas sobre ambigüedad y comprensión.
3. Piloto de contenido con 15–30 líderes diversos.
4. Revisión experta del scoring.
5. Pruebas de RLS entre organizaciones.
6. Evaluación de IA con casos rojos:
   - fuga de información;
   - prompt injection;
   - lenguaje estigmatizante;
   - diagnóstico clínico;
   - afirmaciones sin evidencia;
   - consejo laboral indebido.

---

## 18. Riesgos principales

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Claims psicométricos excesivos | Alta | Alto | Usar lenguaje exploratorio y validar antes de comercializar |
| Confusión entre DISC y VIA | Alta | Alto | Resultados y explicaciones separados |
| Medir 24 fortalezas con 10 retos | Alta | Alto | Seleccionar 6–8 y exigir varias evidencias |
| Uso laboral indebido | Media | Alto | Privacidad por defecto y prohibiciones contractuales |
| Respuestas socialmente deseables | Alta | Alto | Opciones plausibles y transparencia sobre privacidad |
| IA inventa interpretaciones | Alta | Alto | Schema, evidencia estructurada, guardrails y fallback |
| Coaches revelan la respuesta | Media | Alto | Información parcial, puntos ciegos y pruebas editoriales |
| Consecuencias parecen manipuladas | Media | Alto | Reglas trazables y contrafactuales consistentes |
| Scope creep por dos módulos y paneles | Alta | Alto | Congelar Must y validar con vertical slice |
| Fábrica de casetes sobrediseñada | Media | Alto | Contenido estructurado y publicación técnica en el MVP |
| Pérdida o duplicación de respuestas | Media | Alto | Autosave idempotente y reanudación server-side |

---

## 19. Decisiones que requieren aprobación

1. **Marco de medición:** DISC licenciado, exploración inspirada en DISC o reemplazo.
2. **Arquitectura de doble lente:** DISC para conducta y VIA para desarrollo.
3. **Claims:** “diagnóstico”, “evaluación”, “perfil exploratorio” o “experiencia formativa”.
4. **Selección VIA:** fortalezas exactas que cubrirá la simulación.
5. **Roles:** significado y permisos de jugador, líder, soporte y admin.
6. **Visibilidad:** acceso individual, consentimiento y agregación.
7. **Coaches:** una consulta por reto y fichas para una segunda.
8. **Fábrica MVP:** contenido estructurado administrado técnicamente o interfaz administrativa mínima.
9. **Modelo de publicación:** quién aprueba y publica un casete.
10. **Propiedad intelectual:** licencias de DISC, VIA, bancos de ítems, nombres y traducciones.

---

## 20. Preparación de la siguiente iteración: historias de usuario

Una vez revisado y corregido este documento, la siguiente iteración deberá levantar las historias necesarias para construir tanto la consola como los primeros casetes.

### Épicas preliminares de la consola

1. Identidad, autenticación y organizaciones.
2. Roles, permisos y soporte.
3. Consentimiento, privacidad y auditoría.
4. Perfil y configuración del usuario.
5. Hub y catálogo de experiencias.
6. Definición y versionado de casetes.
7. Motor de ejecución de experiencias.
8. Persistencia y reanudación.
9. Motor de scoring.
10. Motor de consecuencias y estados.
11. Coaches y ayudas.
12. Feedback y contrafactuales.
13. Resultados y visualizaciones accesibles.
14. Sherpa e integración de IA.
15. Administración de usuarios y asignaciones.
16. Publicación y ciclo de vida de casetes.
17. Telemetría y analítica del producto.
18. Seguridad, RLS y cumplimiento.
19. Accesibilidad, performance y resiliencia.
20. QA y validación de contenido.

### Épicas preliminares de los casetes

1. Contenido de Expedición Base.
2. Scoring y resultado de Expedición Base.
3. Narrativa empresarial de Expedición Cumbre.
4. Estados y consecuencias empresariales.
5. Diseño y contenido de los tres coaches.
6. Matriz de fortalezas VIA seleccionadas.
7. Feedback por reto y cierre.
8. Piloto, entrevistas cognitivas y ajustes.

### Regla para redactar las historias

Cada HU deberá indicar si pertenece a:

- **Consola:** capacidad reutilizable para múltiples experiencias.
- **Fábrica:** capacidad para diseñar, validar, versionar o publicar casetes.
- **Casete:** contenido o regla específica de una experiencia.

Esto permitirá evitar que una necesidad particular de DISC o VIA se convierta accidentalmente en una restricción permanente de toda la plataforma.

---

## 21. Próximas acciones después de la revisión

1. Corregir y aprobar este contexto.
2. Registrar las decisiones aprobadas en el decision log.
3. Actualizar el contexto maestro y el glosario.
4. Definir la matriz final de roles y permisos.
5. Seleccionar el marco de medición y los claims autorizados.
6. Diseñar el contrato conceptual de un casete.
7. Levantar las historias de usuario por épica.
8. Priorizar las HU con MoSCoW.
9. Identificar el vertical slice y el primer sprint.
10. Someter las HU a revisión de Backend, QA, Psicología y Gobierno.

---

## 22. Referencias de orientación

- Peterson, C. y Seligman, M. E. P. (2004). *Character Strengths and Virtues: A Handbook and Classification*.
- Niemiec, R. M. (2019). *Finding the golden mean: the overuse, underuse, and optimal use of character strengths*.
- VIA Institute on Character. Clasificación y recursos de investigación sobre fortalezas del carácter.
- Ley 1581 de 2012 y normativa colombiana aplicable a protección de datos personales.

Las afirmaciones psicométricas, licencias y adecuación para población laboral colombiana deberán verificarse formalmente antes de incorporarse a marketing, contratos o reportes.

