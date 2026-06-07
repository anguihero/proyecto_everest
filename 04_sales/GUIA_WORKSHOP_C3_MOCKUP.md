# A4 WORKSHOP FINAL: Guía de Ejecución
## Generación de C3 Mockup Interactivo con IA Asistente (Semana 7)

**Responsable:** Andrés (Coordinación), Diego (Validación Visual)  
**Participantes:** Equipo técnico + Óscar (PO) + Cliente  
**Duración Total:** 5 días de trabajo (Viernes Semana 6 → Jueves Semana 7)  

---

## Fase 1: Consolidación de Especificaciones (Viernes Semana 6)

### Actividad 1.1: Exportar Brandbook en Formato Estructurado

**Responsable:** Diego  
**Output:** Archivo `BRANDBOOK_SPECS.json`

```json
{
  "proyecto": "Everest Experience",
  "version": "1.0",
  "fecha": "2026-06-13",
  
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
    "primaria": {
      "nombre": "Inter",
      "enlace": "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap"
    },
    "titulo": {
      "familia": "Inter",
      "peso": 700,
      "tamaño": "32px",
      "linea_altura": 1.2
    },
    "cuerpo": {
      "familia": "Inter",
      "peso": 400,
      "tamaño": "14px",
      "linea_altura": 1.5
    },
    "boton": {
      "familia": "Inter",
      "peso": 600,
      "tamaño": "14px"
    }
  },
  
  "componentes": {
    "boton": {
      "padding": "12px 24px",
      "border_radius": "4px",
      "transicion": "0.3s ease"
    },
    "card": {
      "border_radius": "8px",
      "sombra": "0 2px 8px rgba(0,0,0,0.1)",
      "padding": "20px"
    },
    "avatar": {
      "tamaño": "64px",
      "border_radius": "50%",
      "borde": "3px solid #FFB300"
    }
  },
  
  "tonalidad_everest": "Aventura de montaña épica. Visual aventurero pero profesional. No es carnaval, es expedición corporativa.",
  "tonalidad_sherpa": "Sabio, accesible, con humor sutil. Es tu compañero de viaje, no tu jefe.",
  "tonalidad_general": "Gamificado pero serio. Lúdico pero confiable."
}
```

### Actividad 1.2: Consolidar Especificaciones Funcionales de Arquitectura

**Responsable:** Andrés  
**Output:** Archivo `FUNCIONALIDADES_C3.md`

```markdown
# Funcionalidades a Mockupear - C3 Everest Experience

## 1. Pantalla de Login
- Campo email corporativo con validación en tiempo real
- Campo contraseña con toggle de visibilidad
- Botón "Iniciar Sesión" con loader animado
- Link "Recuperar Contraseña"
- Mensaje de error si credenciales son incorrectas
- Recuerda que es la primera vez = mostrar onboarding breve

## 2. Hub Central del Jugador
- Avatar customizable con selector de apariencia
- Nombre del usuario y organización
- 3 widgets principales:
  - Progreso Global (barra porcentual)
  - Próximo Reto disponible (botón de inicio)
  - Medallas ganadas (galería de 6 medallas)
- Botón de "Comenzar Escalada" prominente

## 3. Mapa de Rutas del Everest
- Visualización de 3 rutas principales
  - Ruta Estándar (baja dificultad)
  - Ruta de Desafío (media dificultad)  
  - Ruta Extrema (alta dificultad)
- Estado de cada ruta: Bloqueada | Disponible | En Progreso | Completada
- Click en ruta → transición a pantalla de dilema

## 4. Pantalla de Dilema de Decisión
- Contexto del escenario (ej: "Tu equipo está en conflicto sobre la dirección del proyecto")
- 4 opciones de respuesta de opción múltiple
- Ilustración contextual (asset del Everest)
- Botón "Seleccionar" deshabilitado hasta elegir opción

## 5. Chat con el Sherpa NPC
- Área de mensajes con historial
- Sherpa siempre inicia (ej: "¡Hola! Veo que tomaste la ruta de Desafío...")
- 3 primeros intercambios pre-definidos
- Avatar del Sherpa (ilustración)
- Campo de input con botón "Enviar"

## 6. Panel de Resultados Parciales
- Tabla de dimensiones medidas hasta ahora
- Gráfico de radar con el perfil psicométrico actual
- Botón "Ver Análisis Completo" (será habilitado al finalizar)
```

### Actividad 1.3: Documentar Casos de Uso Específicos del Cliente

**Responsable:** Óscar (PO)  
**Input:** Feedback obtenido en sesiones previas  
**Output:** Archivo `CLIENTE_SPECS.md`

```markdown
# Especificaciones Específicas del Cliente

## Organización
Nombre: [Corporación XYZ]
Sector: [Tech / Manufactura / Servicios]
Empleados Totales: [N]
Líderes a Diagnosticar: [N]

## Preocupaciones/Deseos del Cliente
1. "No queremos que parezca un juego infantil" 
   → Tonalidad visual: Seria pero enganchante
   
2. "Nuestros líderes son muy pragmáticos"
   → Enfatizar ROI y datos desde la primera pantalla

3. "Queremos que el Sherpa se sienta como nuestro coach interno"
   → Personalización: Nombre del Sherpa = nombre de coach interno

## Restricciones Técnicas
- Debe funcionar en IE11? NO (solo navegadores modernos)
- Restricción de colores corporativos? SÍ → [Mostrar paleta permitida]
- Logo corporativo en cada pantalla? NO (solo en login)
```

### Actividad 1.4: Crear el Prompt Maestro Generativo

**Responsable:** Andrés  
**Output:** Archivo `PROMPT_GENERADOR_MOCKUP.txt`

```
Eres un experto en diseño UI/UX empresarial y desarrollo frontend.
Tu tarea es generar un mockup interactivo HTML/CSS/JS para Everest Experience.

CONTEXTO DEL PROYECTO:
- Plataforma de diagnóstico de liderazgo por gamificación
- Metáfora central: Escalar la montaña Everest representa el viaje del líder
- Audiencia: Líderes corporativos (25-55 años, pragmáticos, data-driven)

ESPECIFICACIONES A APLICAR EXACTAMENTE:
[Aquí va contenido de BRANDBOOK_SPECS.json]

FUNCIONALIDADES A IMPLEMENTAR:
[Aquí va contenido de FUNCIONALIDADES_C3.md]

RESTRICCIONES DEL CLIENTE:
[Aquí va contenido de CLIENTE_SPECS.md]

REQUISITOS TÉCNICOS DE SALIDA:
1. Archivo index.html único (embebido con CSS y JS)
2. Responsive (mobile first, funcional en 320px - 1920px)
3. Sin dependencias externas (no Bootstrap, no jQuery, no librerías)
4. CSS Grid / Flexbox nativo
5. Animaciones suaves (transiciones 0.3s)
6. Interactividad total: clics, hovers, cambios de estado
7. Comentarios en código explicando secciones principales
8. Al menos 2 variantes alternativas de pantalla [X]

TONALIDAD VISUAL:
- Paleta: Verde montaña + Azul cielo + Dorado (acentos)
- Tipografía: Limpia, profesional, legible en cualquier tamaño
- Espaciado: Generoso, no comprimido
- Íconos: Simples, monocromáticos, alineados a 24px grid

FLUJO INTERACTIVO:
Login → Hub Central → Seleccionar Ruta → Dilema → Chat Sherpa → Resultados

Genera el código completo y funcional. El HTML debe ser deployable inmediatamente.
```

---

## Fase 2: Generación del Mockup (Lunes-Martes Semana 7)

### Actividad 2.1: Alimentar el Agente Generativo

**Responsable:** Andrés  
**Herramienta:** Claude API con modo de respuesta larga (32K tokens)  
**Input:** PROMPT_GENERADOR_MOCKUP.txt + especificaciones

**Script Python para ejecutar:**

```python
import anthropic
import json

def generar_mockup_everest():
    client = anthropic.Anthropic(api_key="tu-api-key")
    
    # Leer especificaciones
    with open("PROMPT_GENERADOR_MOCKUP.txt", "r", encoding="utf-8") as f:
        prompt_maestro = f.read()
    
    with open("BRANDBOOK_SPECS.json", "r", encoding="utf-8") as f:
        brandbook = json.load(f)
    
    with open("FUNCIONALIDADES_C3.md", "r", encoding="utf-8") as f:
        funcionalidades = f.read()
    
    with open("CLIENTE_SPECS.md", "r", encoding="utf-8") as f:
        cliente_specs = f.read()
    
    # Construir prompt final
    prompt_completo = f"""{prompt_maestro}

ESPECIFICACIONES CONSOLIDADAS:

BRANDBOOK:
{json.dumps(brandbook, indent=2, ensure_ascii=False)}

FUNCIONALIDADES:
{funcionalidades}

CLIENTE:
{cliente_specs}

Por favor genera el código HTML/CSS/JS completo, funcional y deployable.
Incluye también una sección de comentarios al inicio explicando la arquitectura.
"""
    
    # Llamar a Claude
    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=32000,
        messages=[
            {"role": "user", "content": prompt_completo}
        ]
    )
    
    # Extraer y guardar el código generado
    html_generado = message.content[0].text
    
    # Guardar en archivo
    with open("mockup_generado.html", "w", encoding="utf-8") as f:
        f.write(html_generado)
    
    print("✅ Mockup generado exitosamente en mockup_generado.html")
    print(f"📊 Tokens utilizados: {message.usage.input_tokens + message.usage.output_tokens}")
    
    return html_generado

if __name__ == "__main__":
    generar_mockup_everest()
```

### Actividad 2.2: Validar y Refinar el Código Generado

**Responsable:** Andrés (Backend), Diego (Visual)  
**Checklist:**

- [ ] ¿El HTML se abre sin errores en navegadores modernos?
- [ ] ¿Se respeta exactamente la paleta de colores del brandbook?
- [ ] ¿Las tipografías son las especificadas?
- [ ] ¿Todas las funcionalidades listadas están implementadas?
- [ ] ¿Las transiciones son suaves (no abruptas)?
- [ ] ¿El layout es responsive en mobile (320px)?
- [ ] ¿Los textos tienen las palabras claves correctas?
- [ ] ¿El flujo narrativo (Login → Hub → Mapa → Dilema → Chat → Resultados) tiene sentido?

**Si hay ajustes necesarios:**

Crear un **prompt de refinamiento** específico:

```
El mockup generado está bien, pero necesito estos ajustes:
1. El botón de "Iniciar Sesión" debe ser más prominente (aumentar tamaño 20%)
2. Las medallas en el Hub Central deben tener efecto de hover con escala 1.1
3. El chat del Sherpa debe tener un avatar con animación de parpadeo suave

Por favor genera la versión refinada con estos cambios específicos.
```

### Actividad 2.3: Crear 2-3 Variantes Alternativas

**Responsable:** Andrés (Ejecutor), Diego (Director visual)

Generar variantes para una o dos pantallas clave (ej: Hub Central):

- **Variante A: Light Mode** (fondo blanco, textos oscuros)
- **Variante B: Dark Mode** (fondo oscuro, textos claros)
- **Variante C: High Contrast** (para accesibilidad)

```
Genera 3 variantes diferentes del Hub Central del Everest Experience:

VARIANTE 1 - "Profesional Minimalista": Fondo blanco, elementos dispersos, mucho whitespace
VARIANTE 2 - "Inmersiva Rica": Fondo con ilustración de montaña suave, elementos agrupados
VARIANTE 3 - "Dark Corporate": Fondo oscuro (gris charcoal), acentos en dorado brillante

Mantén exactamente el mismo contenido y funcionalidad, solo varía la propuesta visual.
Genera 3 archivos HTML separados.
```

### Actividad 2.4: Generar Documentación Interactiva

**Responsable:** Andrés  
**Output:** `MOCKUP_DOCUMENTATION.md`

```markdown
# Documentación del C3 Mockup Generado

## Navegación
- **URL de despliegue:** [localhost:3000 o URL pública]
- **Usuario de prueba:** demo@everest.com / password123
- **Navegación sugerida:** [Flujo paso a paso]

## Pantallas Incluidas
1. **Login** → Click "Iniciar Sesión"
2. **Hub Central** → Click "Comenzar Escalada"
3. **Mapa de Rutas** → Click en "Ruta de Desafío"
4. **Dilema de Decisión** → Selecciona opción + Click "Continuar"
5. **Chat Sherpa** → 3 intercambios automáticos
6. **Resultados** → Cierre del flujo

## Decisiones de Diseño Aplicadas
- Logo del cliente en login (personalizable)
- Sherpa con expresión amigable pero seria
- Progreso visual con indicadores claros
- Paleta limitada a 5 colores principales para coherencia

## Variantes Disponibles
- mockup_variante_minimalista.html
- mockup_variante_inmersiva.html
- mockup_variante_dark_mode.html

## Notas Técnicas
- Generado por: Claude Opus 4.7 (IA Asistente)
- Tiempo de generación: ~2 minutos
- Líneas de código: ~850 (HTML/CSS/JS combinado)
- Compatibilidad: Chrome, Safari, Firefox, Edge (últimas 2 versiones)
```

---

## Fase 3: Workshop de Validación (Miércoles-Jueves Semana 7)

### Pre-Workshop (Martes Noche)

**Responsable:** Óscar + Andrés  

- [ ] Confirmar asistencia del cliente (CEO/RRHH/Decisor)
- [ ] Enviar enlace de acceso al mockup por email
- [ ] Pedir que prueben antes (para no perder tiempo en sesión)
- [ ] Preparar lista de preguntas de validación

### Workshop - Día 1: Exploración (Miércoles, 2 horas)

**Facilitador:** Óscar  
**Acompañantes técnicos:** Andrés, Diego

#### Segmento 1: Intro (0:00-0:15)

"Hoy van a ver una versión interactiva del Everest Experience. Es importante aclarar:
- ✅ Esto es REAL: Pueden hacer clic, navegar, interactuar
- ❌ Esto NO es la versión final: El código real será diferente
- ✅ Los datos mostrados son de EJEMPLO
- 🎯 Su feedback va a CAMBIAR lo que ven"

#### Segmento 2: Cliente Navega Libre (0:15-0:45)

Cliente explora el mockup sin guía. El equipo observa en silencio, tomando notas sobre:
- ¿Qué pantalla genera más engagement?
- ¿Dónde se confunden?
- ¿Qué botones no encuentran?

#### Segmento 3: Q&A y Feedback Estructurado (0:45-1:15)

Preguntas guía:

1. **Sobre la Experiencia General**
   - "¿Siente que está escalando una montaña o jugando un videojuego corporativo?"
   - "¿Qué tan probable es que un líder de su organización se enganche?"

2. **Sobre el Diseño Visual**
   - "¿Los colores transmiten la seriedad que su organización necesita?"
   - "¿El Sherpa se siente como un aliado o como un bot?"

3. **Sobre la Funcionalidad**
   - "¿Entiende automáticamente qué hacer en cada pantalla?"
   - "¿Le falta alguna información crítica?"

4. **Sobre la Propuesta de Valor**
   - "¿Entiende cómo se conecta esto con medir el liderazgo?"
   - "¿Siente que este ejercicio puede revelar cosas sobre los líderes?"

#### Segmento 4: Feedback Operacionalizado (1:15-1:45)

El cliente dice: "Los colores están bien, pero queremos que el Sherpa sea más accesible. Ahora parece un NPC de videojuego."

**El equipo INMEDIATAMENTE responde:**
- Andrés toma nota
- Genera un nuevo prompt: "Rediseña el Sherpa para que sea un coach empresarial, no un personaje de fantasía"
- Ejecuta la generación (5 minutos)
- Muestra la nueva versión EN VIVO en la sesión

El cliente ve que el feedback se operacionaliza en HORAS, no en SEMANAS.

#### Segmento 5: Cierre y Roadmap (1:45-2:00)

- ✅ "Estos cambios van a ir al desarrollo real en Semanas 8-10"
- ✅ "El mockup que vieron hoy es el norte visual que Diego y Andrés van a seguir"
- 🎯 "Próxima validación: Semana 9, cuando el código real esté integrado"

### Workshop - Día 2: Refinamiento (Jueves, 1 hora)

**Actividad:** El equipo muestra variantes alternativas generadas

"Generamos 3 versiones diferentes del Hub Central. Ustedes eligen cuál es el tono que mejor representa a su organización:"

- **Variante A:** [Mostrar en vivo] Enfoque minimalista, mucho espacio blanco
- **Variante B:** [Mostrar en vivo] Enfoque inmersivo con ilustración de fondo
- **Variante C:** [Mostrar en vivo] Enfoque dark mode para reducir fatiga visual

Cliente elige. Esa variante se convierte en el norte visual del desarrollo.

---

## Salidas Finales del Workshop

### Para el Cliente

1. **mockup_interactivo_validado.html** — Versión final tras feedback
2. **Reporte de Decisiones Visuales.pdf** — 2-3 páginas explicando qué fue elegido y por qué
3. **Roadmap Visual Semanas 8-10** — Cómo el mockup se convierte en código real

### Para el Equipo Técnico

1. **ESPECIFICACIONES_FINALES.json** — Paleta, tipografía, componentes DEFINITIVOS
2. **MOCKUP_VALIDATED.html** — Versión de referencia para desarrollo
3. **NOTAS_FEEDBACK_CLIENTE.md** — Cambios de fondo vs. cambios cosméticos (priorizar)

---

## Métricas de Éxito del Workshop

| Métrica | Target | ¿Por qué? |
|---------|--------|----------|
| **Cliente genera 5+ observaciones específicas** | Sí | Muestra verdadero engagement |
| **Se implementan 2-3 iteraciones en vivo** | Sí | Demuestra velocidad de respuesta |
| **Cliente rechaza cero variantes** | No idealmente | Es okay si dice "No me gusta esta" |
| **Equipo documenta 100% del feedback** | Sí | Para no perder nada |
| **Cliente firma "Aprobado para desarrollo"** | Sí | Gate bloqueante para semana 8 |

---

## Plantilla de Email Post-Workshop

```
Subject: ✅ Mockup Validado + Roadmap Semanas 8-10

Estimado [Cliente],

Gracias por la sesión de ayer. Su feedback fue invaluable.

Adjunto encontrará:
1. mockup_final_validado.html (la versión que aprobaron)
2. Especificaciones_Visuales_Definitivas.json (para referencia del equipo)
3. Roadmap_Desarrollo_Semanas_8-10.pdf (cómo convertimos esto en código real)

Cambios incorporados del workshop:
✅ Sherpa rediseñado como coach, no como NPC
✅ Hub Central con variante inmersiva elegida
✅ Accesibilidad mejorada en formularios

Próximos hitos:
- Semana 8: Backend de autenticación integrado
- Semana 9: Frontend principal con datos reales
- Semana 10: Code freeze + QA

¿Alguna pregunta?

Saludos,
Equipo Everest Experience
```

---

## Riesgos y Mitigaciones

| Riesgo | Señal de Alerta | Mitigación |
|--------|-----------------|-----------|
| La IA genera código con errores | El mockup no carga | Tener versión backup manual + validar antes de mostrar |
| Cliente quiere cambios radicales | "Esto no es lo que queremos" | Recordar que es mockup, no versión final; es iterativo |
| El equipo no puede iterar rápido en vivo | Tardanza > 15 minutos por cambio | Pre-generar 2-3 variantes anticipadas |
| Cliente se distrae con UI y olvida validar lógica | Enfoque en "se ve bonito" | Redirigir: "¿Los datos tienen sentido? ¿El flujo es lógico?" |

---

## Checklist Final

### Antes del Workshop (Martes)
- [ ] mockup_generado.html probado en 3+ navegadores
- [ ] Variantes alternativas listas
- [ ] PROMPT_GENERADOR refinado y guardado
- [ ] Enlace al mockup compartido con cliente
- [ ] Sala de video reservada con pantalla compartida
- [ ] Andres + Diego listos para iterar en vivo

### Durante del Workshop (Miércoles-Jueves)
- [ ] Grabación de sesión para referencia futura
- [ ] Notas de feedback en documento compartido
- [ ] Fotografía de la pantalla con decisiones clave
- [ ] Email de confirmación de próximos pasos

### Después del Workshop (Viernes Semana 7)
- [ ] Especificaciones finales documentadas
- [ ] Mockup validado archivado
- [ ] Feedback mapeado a historias de usuario (Semanas 8-10)
- [ ] Reunion interna con Andres + Diego para planificar sprints

---

**Nota:** Este documento es un template flexible. Cada cliente puede requerir ajustes. La estructura general (Consolidar → Generar → Validar) es la que garantiza éxito.

