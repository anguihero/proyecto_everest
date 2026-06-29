# Plan — Animación Pixel Art del Escalador (Aconcagua)

**Fecha:** 2026-06-29  
**Responsable:** Andrés Muñoz (Tech Lead) + Diego (assets)  
**Estado:** Borrador — pendiente aprobación y entrega de assets  
**Prioridad:** P2 (mejora de experiencia, no bloquea el vertical slice)

---

## Concepto

Durante la ejecución de un reto (pantalla `runner.html`), se muestra un **panel de animación contextual** a la derecha de las preguntas (desktop) o arriba (mobile) que avanza visualmente con cada respuesta confirmada.

Para el reto **Expedición Base (DISC):**
- Un escalador pixel art sube por una ruta lineal de **20 niveles** en la montaña Cerro Aconcagua.
- Al confirmar cada respuesta, el escalador avanza un nivel.
- El nivel 21 (la cima) muestra la bandera ondeando. Es el estado final de celebración.

Para **todos los demás retos** que aún no tienen animación definida:
- Se muestra un panel estilo **TV retro sintonizando** (ruido estático animado en CSS).
- Mensaje: "Animación próximamente disponible".
- Sin dependencia de assets externos.

---

## Arquitectura

### Campo de configuración en base de datos

```sql
-- Agregar a experience_definitions (coordinar con migración Plan 2)
ALTER TABLE public.experience_definitions
  ADD COLUMN animation_config JSONB DEFAULT '{
    "type": "none",
    "fallback": "tv_static"
  }';

COMMENT ON COLUMN public.experience_definitions.animation_config IS
  'Configuración de la animación contextual del runner. type: pixel_climber | tv_static | none.';

-- Expedición Base → pixel climber Aconcagua
UPDATE public.experience_definitions
SET animation_config = '{
  "type": "pixel_climber",
  "theme": "aconcagua",
  "levels": 20,
  "summit_label": "Aconcagua 6.961m",
  "climber_sprite": "sprite_climber_01.png",
  "background": "bg_aconcagua_path.png",
  "colors": {
    "path":    "#C4A882",
    "terrain": "#4A7C59",
    "sky":     "#87CEEB"
  }
}'
WHERE slug = 'expedicion-base';
```

El runner lee `animation_config` del contenido del casete (ya presente en `content.meta` o como columna directa) y decide qué componente de animación renderizar.

---

## Diseño de pantalla (layout)

### Desktop (≥ 768px) — panel lateral

```
┌─────────────────────────────────────────┬──────────────────────┐
│  PASO 6 DE 20          ⏱ progreso      │  🏔️ ACONCAGUA       │
│  ─────────────────────────────────────  │                      │
│                                         │  ████ nivel 6/21     │
│  Tensiones entre dos personas clave     │                      │
│  Tu equipo está experimentando          │  [Montaña pixel art] │
│  tensiones internas entre...            │  con escalador en    │
│                                         │  punto 6 del camino  │
│  △  Reúno a ambos y los confronto...   │                      │
│  ●  Hablo con cada uno por separado... │  🎖️ +1 nivel         │
│  ■  Promuevo una actividad...          │  ← aparece tras      │
│  ◆  Documento lo ocurrido...           │    confirmar          │
│                                         │                      │
│  [      Confirmar decisión      ]       │                      │
└─────────────────────────────────────────┴──────────────────────┘
```

Proporciones: área preguntas 65% | panel animación 35%  
Ancho mínimo panel: 200px | Máximo: 280px

### Mobile (< 768px) — strip horizontal

```
┌──────────────────────────────────┐
│ 🧗━━━━━━━━━━━━━━━━━━━━━🏔️       │ ← 100px altura
│ nivel 6 ――――――――――――――― Cima    │
├──────────────────────────────────┤
│ PASO 6 DE 20                     │
│ Tensiones entre dos personas...  │
│ △ Opción A...                   │
│ ● Opción B...                   │
│ ■ Opción C...                   │
│ ◆ Opción D...                   │
│ [ Confirmar decisión ]           │
└──────────────────────────────────┘
```

En mobile, el escalador recorre un camino horizontal de izquierda a derecha. El fondo es una versión recortada del asset de montaña.

---

## Assets requeridos

| Asset | Descripción | Dimensiones sugeridas | Responsable | Estado |
|---|---|---|---|---|
| `bg_aconcagua_path.png` | Fondo pixel art de la montaña con camino serpenteante (la imagen 2 provista) | 400×700px (portrait) | Diego | **Ya existe** |
| `sprite_climber_01.png` | Spritesheet del escalador. 4 frames de walk cycle. Pixel art estilo 16px | 64×16px (4 frames de 16px) | Diego | Pendiente |
| `sprite_flag.png` | Bandera en la cima, 2 frames de ondeo | 32×32px | Diego | Pendiente |
| `overlay_level.png` | (Opcional) Overlay semitransparente para mostrar el nivel actual | — | Diego | Opcional |

### Fallback si los assets no están listos

Si `sprite_climber_01.png` no existe, el escalador se representa con un **emoji animado** (🧗) posicionado con CSS a lo largo del camino. Esto permite desarrollar la lógica completa antes de tener los assets finales.

---

## Implementación — Fase A: estructura y TV estático (0.5 días)

### 1. Agregar `animation_config` al schema (ver sección de DB arriba)

### 2. Modificar `runner.html` para incluir el panel

El layout actual del runner tiene una estructura de columna única. Se agrega un wrapper flex para separar el área de preguntas del panel de animación:

```html
<!-- runner.html — estructura nueva -->
<main class="runner-layout">
  <!-- Área principal: pregunta + opciones + botón -->
  <section class="runner-content" id="runner-content">
    <!-- contenido existente sin cambios -->
  </section>

  <!-- Panel de animación: se renderiza o no según animation_config -->
  <aside class="animation-panel" id="animation-panel" aria-label="Progreso visual">
    <!-- Inyectado por animation-panel.js -->
  </aside>
</main>
```

CSS en `runner.html` (Tailwind + clase propia):

```css
.runner-layout {
  display: flex;
  gap: 1.5rem;
  max-width: 1100px;
  margin: 0 auto;
  padding: 1rem;
}

.runner-content {
  flex: 1 1 0%;
  min-width: 0;
}

.animation-panel {
  flex: 0 0 260px;
  width: 260px;
}

@media (max-width: 767px) {
  .runner-layout    { flex-direction: column; }
  .animation-panel  { width: 100%; height: 100px; order: -1; }
}
```

### 3. Crear `src/frontend/js/animation-panel.js`

```javascript
// animation-panel.js
// Responsabilidad: decidir qué animación renderizar y manejar avances.

export class AnimationPanel {
  constructor(container, config, totalLevels) {
    this.container   = container;
    this.config      = config;       // animation_config del casete
    this.totalLevels = totalLevels;  // total_steps del casete (20)
    this.currentLevel = 0;
  }

  init() {
    const type = this.config?.type ?? 'none';
    if (type === 'pixel_climber') {
      this._initPixelClimber();
    } else {
      this._initTVStatic();
    }
  }

  // Llamado desde runner.js después de cada respuesta confirmada
  advanceLevel() {
    if (this.currentLevel >= this.totalLevels) return;
    this.currentLevel++;
    this._updateDisplay();
    this._showAdvanceCelebration();

    if (this.currentLevel === this.totalLevels + 1) {
      this._showSummitCelebration();
    }
  }

  _initPixelClimber() { /* ... ver Fase B */ }
  _initTVStatic()     { /* ... ver abajo  */ }
  _updateDisplay()    { /* ... mover escalador */ }
  _showAdvanceCelebration() { /* ... micro-animación de subida */ }
  _showSummitCelebration()  { /* ... bandera + mensaje especial */ }
}
```

### 4. TV Estático (fallback sin assets)

Implementado 100% en CSS + Canvas, sin imágenes:

```html
<!-- Inyectado por _initTVStatic() -->
<div class="tv-panel">
  <div class="tv-frame">
    <canvas id="tv-static-canvas" width="200" height="150"></canvas>
    <div class="tv-scanlines"></div>
    <p class="tv-label">Animación próximamente</p>
  </div>
  <div class="level-indicator">
    <span id="tv-level">Paso <span class="level-num">0</span> de 20</span>
  </div>
</div>
```

```javascript
// Ruido estático en canvas (sin librerías externas)
function drawStaticNoise(canvas) {
  const ctx  = canvas.getContext('2d');
  const data = ctx.createImageData(canvas.width, canvas.height);
  for (let i = 0; i < data.data.length; i += 4) {
    const v = Math.random() > 0.5 ? 200 : 50;
    data.data[i]     = v;  // R
    data.data[i + 1] = v;  // G
    data.data[i + 2] = v;  // B
    data.data[i + 3] = 180; // A
  }
  ctx.putImageData(data, 0, 0);
}
setInterval(() => drawStaticNoise(canvas), 80); // ~12fps
```

### 5. Integrar `animation-panel.js` en `runner.js`

```javascript
// En runner.js — agregar al inicio
import { AnimationPanel } from './animation-panel.js';

let animPanel = null;

// En startOrResume() — después de obtener content
const animConfig = data.content?.meta?.animation_config
  ?? window._experienceAnimConfig   // fallback desde experience_definitions
  ?? { type: 'none' };

animPanel = new AnimationPanel(
  document.getElementById('animation-panel'),
  animConfig,
  data.content.meta.total_steps
);
animPanel.init();

// En saveAnswer() — después de confirmar respuesta exitosa
animPanel?.advanceLevel();
```

---

## Implementación — Fase B: Pixel Art Climber (1–2 días)

### Definición de los 21 puntos de parada

El fondo (`bg_aconcagua_path.png`) tiene un camino serpenteante visible. Se definen 21 puntos de coordenadas (x%, y%) relativas al contenedor del panel, siguiendo el camino de la imagen:

```javascript
// Coordenadas del camino en bg_aconcagua_path.png
// [0] = base, [20] = nivel 20, [21] = cima (bandera)
const CLIMB_WAYPOINTS = [
  { x: 20, y: 92 },  // nivel 0 — base
  { x: 22, y: 86 },  // nivel 1
  { x: 28, y: 80 },  // nivel 2
  { x: 35, y: 76 },  // nivel 3
  { x: 30, y: 70 },  // nivel 4
  { x: 24, y: 64 },  // nivel 5
  { x: 30, y: 58 },  // nivel 6
  { x: 38, y: 54 },  // nivel 7
  { x: 45, y: 50 },  // nivel 8
  { x: 50, y: 45 },  // nivel 9
  { x: 55, y: 40 },  // nivel 10 — mitad
  { x: 60, y: 36 },  // nivel 11
  { x: 65, y: 32 },  // nivel 12
  { x: 70, y: 28 },  // nivel 13
  { x: 72, y: 24 },  // nivel 14
  { x: 68, y: 20 },  // nivel 15
  { x: 65, y: 16 },  // nivel 16
  { x: 68, y: 12 },  // nivel 17
  { x: 72, y: 9  },  // nivel 18
  { x: 75, y: 6  },  // nivel 19
  { x: 78, y: 4  },  // nivel 20
  { x: 80, y: 2  },  // nivel 21 — CIMA (bandera)
];
// Ajustar coordenadas exactas según el asset final de Diego
```

### Renderizado del escalador

```html
<!-- Container pixel climber -->
<div class="pixel-climber-panel" id="pixel-panel">
  <div class="mountain-container">
    <img src="assets/bg_aconcagua_path.png"
         class="mountain-bg"
         alt="Montaña Aconcagua — camino de ascenso"
         aria-hidden="true">

    <!-- Escalador (sprite o emoji de fallback) -->
    <div id="climber" class="climber-sprite" aria-hidden="true">
      <!-- Si sprite disponible: <img src="assets/sprite_climber_01.png"> -->
      <!-- Fallback: 🧗 -->
    </div>

    <!-- Bandera en la cima (oculta hasta nivel 21) -->
    <div id="summit-flag" class="summit-flag hidden" aria-hidden="true">🚩</div>
  </div>

  <!-- Indicador de nivel -->
  <div class="level-display" role="status" aria-live="polite">
    <div class="level-bar">
      <div id="level-fill" class="level-fill" style="width: 0%"></div>
    </div>
    <p class="level-text">
      Nivel <span id="current-level">0</span> de 20
    </p>
  </div>
</div>
```

```css
.mountain-container {
  position: relative;
  width: 100%;
  aspect-ratio: 4/7;       /* proporción del asset de montaña */
  overflow: hidden;
  border-radius: 8px;
  image-rendering: pixelated; /* preservar estética pixel art */
}

.mountain-bg {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
}

.climber-sprite {
  position: absolute;
  width: 16px;
  height: 16px;
  font-size: 14px;          /* si es emoji */
  transition: left 0.6s ease-in-out, top 0.6s ease-in-out;
  /* La posición se actualiza via JS con CLIMB_WAYPOINTS */
}

.level-fill {
  height: 6px;
  background: #2E7D32;
  border-radius: 3px;
  transition: width 0.4s ease;
}

/* Prefers-reduced-motion: sin transiciones */
@media (prefers-reduced-motion: reduce) {
  .climber-sprite { transition: none; }
  .level-fill     { transition: none; }
}
```

### Micro-celebración al avanzar

Al confirmar cada respuesta:
1. El escalador se mueve al siguiente waypoint (transición CSS 0.6s).
2. Aparece una etiqueta flotante "+" con el nivel ganado (CSS keyframe, 1.5s, luego desaparece).
3. La barra de progreso del nivel se actualiza.
4. Mensaje motivacional rotativo (texto pequeño bajo la barra):

```javascript
const CLIMB_MESSAGES = [
  "¡Buen paso!",
  "Sigue subiendo",
  "Cada decisión cuenta",
  "El Sherpa confía en ti",
  "Avanzando con criterio",
  "La cima se acerca",
  "Tu liderazgo se revela",
];

function getClimbMessage(level) {
  if (level === 10) return "¡Mitad del camino!";
  if (level === 20) return "¡Último paso!";
  return CLIMB_MESSAGES[level % CLIMB_MESSAGES.length];
}
```

### Celebración de cima (nivel 21)

Cuando el escalador llega al nivel 21 (después de confirmar la pregunta 20):
1. El escalador llega a la cima con animación de "llegada" (CSS keyframe de rebote).
2. La bandera aparece ondeando.
3. Texto: **"Aconcagua 6.961m — ¡Expedición completada!"**
4. Fondo del panel cambia a tonos dorados (css: filter: sepia(0.3) brightness(1.1)).
5. No bloquea la pantalla — el usuario puede seguir al botón de finalizar normalmente.

```javascript
_showSummitCelebration() {
  const flag = document.getElementById('summit-flag');
  flag.classList.remove('hidden');
  flag.classList.add('summit-wave');  // keyframe CSS de ondeo

  document.getElementById('level-text').textContent =
    'Aconcagua 6.961m — ¡Llegaste a la cima!';

  document.querySelector('.pixel-climber-panel')
    .classList.add('summit-reached');
}
```

---

## Extensibilidad — Otros tipos de animación

El campo `animation_config.type` acepta valores adicionales en el futuro:

| Tipo | Descripción | Cuándo |
|---|---|---|
| `pixel_climber` | Escalador pixel art (Aconcagua) | Expedición Base DISC |
| `tv_static` | TV retro sintonizando | Retos sin animación definida |
| `pixel_explorer` | Explorador en selva (futuro VIA) | Fortalezas en Conflicto |
| `space_rover` | Rover en planeta (futuro) | Reto de innovación |
| `none` | Sin panel lateral | Retos minimalistas |

La fábrica del Plan 2 incluirá un dropdown para que el SysAdmin seleccione el tipo de animación al crear un reto.

---

## Configuración final en la fábrica (Plan 2)

Cuando el SysAdmin crea un reto nuevo, el formulario incluye:

```
Animación del runner:
  [ TV Sintonizando (por defecto) ▼ ]
  ○ Ninguna
  ○ TV Sintonizando
  ● Escalador Pixel Art — Aconcagua
  ○ (Próximamente: Explorador VIA)
```

Al elegir "Escalador Pixel Art", se muestran campos opcionales:
- Etiqueta de cima (default: "Aconcagua 6.961m")
- Asset de fondo (default: bg_aconcagua_path.png)

---

## Checklist de assets para Diego

- [ ] `src/frontend/assets/bg_aconcagua_path.png` — confirmar que la imagen 2 (pixel art path) se usa como fondo del panel (400×700px, portrait)
- [ ] `src/frontend/assets/sprite_climber_01.png` — escalador pixel art, spritesheet 4 frames, 16px por frame, estilo pixel art 16-bit
- [ ] `src/frontend/assets/sprite_flag.png` — bandera pixel art, 2 frames de ondeo, 32×32px
- [ ] Paleta de colores consistente con el asset de fondo (tierra/montaña, cielo, vegetación)
- [ ] (Opcional) `src/frontend/assets/sfx_advance.mp3` — sonido corto de paso de escalada (< 0.5s)

---

## Consideraciones de accesibilidad

| Elemento | Implementación |
|---|---|
| El panel es decorativo | `aria-hidden="true"` en toda la animación |
| El progreso sí es informativo | `<div role="status" aria-live="polite">` para el nivel actual |
| Usuarios con `prefers-reduced-motion` | Sin transiciones de movimiento; solo cambio de texto del nivel |
| El panel no distrae en mobile | Ancho limitado a 100px en mobile, solo barra horizontal |
| El panel no es requerido para completar el reto | Si el JS de animación falla, el runner funciona igual |

---

## Archivos a crear/modificar

| Archivo | Acción | Descripción |
|---|---|---|
| `src/frontend/runner.html` | Modificar | Agregar layout flex + `<aside id="animation-panel">` |
| `src/frontend/js/animation-panel.js` | Crear | Módulo completo de animación |
| `src/frontend/js/runner.js` | Modificar | Importar AnimationPanel, llamar init() y advanceLevel() |
| `supabase/migrations/YYYYMMDD_animation_config.sql` | Crear | Agregar columna `animation_config` + backfill |
| `src/frontend/assets/bg_aconcagua_path.png` | Agregar | Asset de Diego (ya existe como imagen 2) |
| `src/frontend/assets/sprite_climber_01.png` | Agregar | Pendiente de Diego |
| `src/frontend/assets/sprite_flag.png` | Agregar | Pendiente de Diego |

---

## Dependencias con otros planes

- **Plan 1 (Auth):** Independiente.
- **Plan 2 (Fábrica):** La columna `animation_config` se agrega en la misma migración que agrega `challenge_type_id`. Coordinar para no duplicar migraciones. La UI de fábrica incluye el selector de animación.
- **HU-EB-002 (Ejecución neutral Base):** La animación cumple con el espíritu de dar retroalimentación visual sin revelar el scoring DISC durante la ejecución. No muestra dimensiones, solo progreso de nivel.

---

## Criterios de aceptación

- [ ] `runner.html` muestra el panel lateral en desktop (≥768px) y strip en mobile
- [ ] En Expedición Base: escalador pixel art avanza con cada respuesta confirmada
- [ ] En otros retos: se muestra TV estática sin errores
- [ ] El nivel actual se comunica via `aria-live` para lectores de pantalla
- [ ] Con `prefers-reduced-motion`: sin animaciones de movimiento, solo cambio de texto
- [ ] Si los assets de sprite no existen: emoji de fallback funciona correctamente
- [ ] El runner funciona normalmente si el módulo de animación falla (degradación elegante)
- [ ] En mobile: panel horizontal de 100px no bloquea el área de preguntas

---

*Documento generado: 2026-06-29 | Versión: 1.0 | Responsable: Andrés Muñoz + Diego (assets)*
