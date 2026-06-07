# 4. Marco Legal: Confidencialidad, Tratamiento de Datos (Habeas Data) y Propiedad Intelectual

Este documento regula las directrices legales que rigen el desarrollo, despliegue y explotación comercial de la plataforma, asegurando el estricto cumplimiento normativo vigente en materia de protección de datos organizacionales y del talento humano.

## 🔐 1. Acuerdo de Tratamiento de Datos Personales (Habeas Data - Ley 1581)

Dado que la plataforma almacena métricas psicométricas críticas (estrés laboral, perfiles de liderazgo, riesgos de burnout y desconfianza institucional), la base de datos se clasifica bajo protección de **Datos Sensibles y Privados**.

* **Logs y Captura de Eventos:** Cada interacción en la experiencia Everest (rutas elegidas, respuestas a preguntas de opción múltiple, configuraciones de avatar) genera un log estructurado. Estos datos se guardan anonimizados o seudonimizados vinculados a un ID de Organización.
* **Acceso Restringido:** Las políticas de seguridad a nivel de fila (RLS - Row Level Security) configuradas por Andrés en Supabase garantizan que:
    1.  El **Usuario Jugador** solo vea su progreso individual y medallas.
    2.  El **Propietario/Admin de la Empresa** vea reportes analíticos consolidados agregados, mitigando la exposición de respuestas individuales que causen represalias internas, a menos que el consentimiento explícito de la estrategia de gestión humana disponga lo contrario.
    3.  El **Coach** acceda a reportes consolidados para estructurar sus sesiones de consultoría externa.
* **Seguridad del Agente de IA (Gemini Guardrails):** El agente de procesamiento de lenguaje natural de Gemini cuenta con instrucciones de sistema inalterables (*Guardrails*). Queda estrictamente prohibido que el agente exponga información identificable entre diferentes organizaciones (*Cross-Tenant Data Leakage*).

---

## 📄 2. Acuerdo de Confidencialidad (NDA)

El equipo de desarrollo (Andrés y Diego) y la contraparte de negocio (Óscar) se obligan a mantener en estricta reserva tecnológica y comercial:
* Los algoritmos de ponderación psicométrica embebidos en el juego.
* Las bases de datos de las organizaciones clientes y los resultados de sus empleados.
* Las llaves de API, credenciales de Supabase y estructuras del prompt del sistema del agente inteligente.

---

## 🏢 3. Propiedad Intelectual del Software Desarrollado

* **Titularidad:** Los derechos patrimoniales sobre el código fuente, bases de datos, manuales técnicos y parametrizaciones del juego pertenecen en un 100% a la personería jurídica u organización determinada por el Dueño de Producto (**Óscar**), una vez se liquide la totalidad del costo de desarrollo acordado ($5.600.000 COP por 4 meses de MVP, conforme al tabulador de $1.400.000 COP/mes).
* **Reconocimiento Autoral:** Se reconoce el derecho moral de autoría sobre el diseño arquitectónico y de código a **Andrés Muñoz Sánchez** y sobre el diseño visual y analítica de producto a **Diego**.
* **Uso de Tecnologías Abiertas:** La propiedad intelectual del desarrollo no restringe el uso de componentes de código abierto o software como servicio de terceros (Supabase, Google Gemini API, Tailwind CSS), los cuales se rigen bajo sus propias licencias de uso (MIT, Apache 2.0).