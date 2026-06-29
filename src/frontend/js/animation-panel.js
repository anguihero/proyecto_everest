// animation-panel.js — Panel de animación contextual del runner
// Plan: PLAN_ANIMACION_PIXEL_ART_ESCALADOR.md
// Soporta: pixel_climber (Aconcagua DISC) | tv_static (fallback)

// Waypoints del camino en el asset bg_aconcagua_path.png
// Coordenadas en % relativas al contenedor (x, y desde top-left)
// Ajustar con Diego una vez el asset final esté listo
const CLIMB_WAYPOINTS = [
  { x: 18, y: 91 }, // nivel 0 — base
  { x: 22, y: 85 }, // nivel 1
  { x: 28, y: 79 }, // nivel 2
  { x: 35, y: 74 }, // nivel 3
  { x: 30, y: 68 }, // nivel 4
  { x: 24, y: 62 }, // nivel 5
  { x: 30, y: 56 }, // nivel 6
  { x: 38, y: 52 }, // nivel 7
  { x: 45, y: 47 }, // nivel 8
  { x: 50, y: 43 }, // nivel 9
  { x: 55, y: 38 }, // nivel 10 — mitad
  { x: 60, y: 34 }, // nivel 11
  { x: 65, y: 30 }, // nivel 12
  { x: 70, y: 26 }, // nivel 13
  { x: 72, y: 22 }, // nivel 14
  { x: 68, y: 18 }, // nivel 15
  { x: 65, y: 14 }, // nivel 16
  { x: 68, y: 11 }, // nivel 17
  { x: 72, y: 8  }, // nivel 18
  { x: 75, y: 5  }, // nivel 19
  { x: 78, y: 3  }, // nivel 20
  { x: 80, y: 1  }, // nivel 21 — CIMA
];

const CLIMB_MESSAGES = [
  'Buen paso',
  'Sigue subiendo',
  'Cada decisión cuenta',
  'El Sherpa confía en ti',
  'Avanzando con criterio',
  'La cima se acerca',
  'Tu liderazgo se revela',
  'Paso a paso',
  'Sin rendirse',
  'Mente clara',
];

function getClimbMessage(level) {
  if (level === 10) return '¡Mitad del camino!';
  if (level >= 18)  return 'La cima está cerca…';
  if (level === 20) return '¡Último paso!';
  return CLIMB_MESSAGES[level % CLIMB_MESSAGES.length];
}

// ── Clase principal ────────────────────────────────────
export class AnimationPanel {
  constructor(container, config, totalLevels) {
    this.container    = container;
    this.config       = config    ?? { type: 'none', fallback: 'tv_static' };
    this.totalLevels  = totalLevels ?? 20;
    this.currentLevel = 0;
    this._staticTimer = null;
    this._advanceTimer = null;
  }

  init() {
    if (!this.container) return;
    const type = this.config?.type ?? 'none';

    if (type === 'pixel_climber') {
      this._initPixelClimber();
    } else {
      this._initTVStatic();
    }
  }

  // Llamar desde runner.js después de cada respuesta confirmada
  advanceLevel() {
    if (this.currentLevel >= this.totalLevels) return;
    this.currentLevel++;
    this._updateClimberPosition();
    this._showAdvanceCelebration();

    if (this.currentLevel === this.totalLevels) {
      clearTimeout(this._advanceTimer);
      this._advanceTimer = setTimeout(() => this._showSummitCelebration(), 700);
    }
  }

  destroy() {
    clearInterval(this._staticTimer);
    clearTimeout(this._advanceTimer);
  }

  // ── Pixel Climber ──────────────────────────────────
  _initPixelClimber() {
    const cfg = this.config;
    this.container.innerHTML = `
      <div class="pixel-climber-panel" style="display:flex;flex-direction:column;gap:10px;height:100%">

        <!-- Montaña -->
        <div id="mountain-wrap" style="
          position:relative;flex:1;min-height:0;
          border-radius:10px;overflow:hidden;
          background:#c8e6c9;
          image-rendering:pixelated">

          <img id="mountain-bg"
            src="${cfg.background ?? 'assets/bg_aconcagua_path.png'}"
            alt=""
            aria-hidden="true"
            onerror="this.style.display='none'"
            style="width:100%;height:100%;object-fit:cover;image-rendering:pixelated;display:block"/>

          <!-- Escalador -->
          <div id="climber-el" aria-hidden="true"
            style="
              position:absolute;
              font-size:16px;
              line-height:1;
              transition:left .6s cubic-bezier(.4,0,.2,1), top .6s cubic-bezier(.4,0,.2,1);
              z-index:10;
              filter:drop-shadow(0 1px 2px rgba(0,0,0,.4))">
            <img src="${cfg.climber_sprite ?? 'assets/sprite_climber_01.png'}"
                 alt="" aria-hidden="true" width="20" height="20"
                 onerror="this.outerHTML='🧗'"
                 style="image-rendering:pixelated;display:block"/>
          </div>

          <!-- Bandera en cima (oculta al inicio) -->
          <div id="summit-flag-el" aria-hidden="true"
            style="
              position:absolute;
              font-size:18px;
              display:none;
              z-index:11;
              animation:flagWave 1s ease-in-out infinite alternate">
            🚩
          </div>

          <!-- Etiqueta flotante de avance -->
          <div id="advance-label" aria-hidden="true"
            style="
              position:absolute;
              font-size:11px;font-weight:700;
              color:#fff;background:rgba(46,125,50,.9);
              padding:2px 8px;border-radius:99px;
              opacity:0;pointer-events:none;z-index:12;
              transition:opacity .2s">
            +1
          </div>

          <!-- Label cima -->
          <div id="summit-label" aria-hidden="true"
            style="
              position:absolute;bottom:6px;left:50%;transform:translateX(-50%);
              font-size:10px;font-weight:700;color:#fff;
              background:rgba(27,94,32,.85);padding:2px 10px;border-radius:99px;
              white-space:nowrap;display:none">
            ${cfg.summit_label ?? 'Aconcagua 6.961m'}
          </div>
        </div>

        <!-- Barra de progreso -->
        <div style="padding:0 2px">
          <div style="height:6px;background:#e5e7eb;border-radius:3px;overflow:hidden">
            <div id="level-fill"
              style="height:100%;width:0%;background:#2E7D32;border-radius:3px;transition:width .4s ease"></div>
          </div>
          <p id="level-text" role="status" aria-live="polite"
            style="font-size:11px;color:#6b7280;text-align:center;margin-top:4px">
            Nivel 0 de ${this.totalLevels}
          </p>
          <p id="climb-msg" aria-hidden="true"
            style="font-size:10px;color:#9ca3af;text-align:center;min-height:14px"></p>
        </div>
      </div>
    `;

    // Inyectar keyframe de bandera si no existe
    if (!document.getElementById('ev-anim-styles')) {
      const s = document.createElement('style');
      s.id = 'ev-anim-styles';
      s.textContent = `
        @keyframes flagWave { from{transform:rotate(-5deg)} to{transform:rotate(5deg)} }
        @keyframes popIn { 0%{transform:scale(.6);opacity:0} 60%{transform:scale(1.2);opacity:1} 100%{transform:scale(1);opacity:1} }
        @media (prefers-reduced-motion:reduce) {
          #climber-el { transition:none !important; }
          #level-fill  { transition:none !important; }
          #summit-flag-el { animation:none !important; }
        }
      `;
      document.head.appendChild(s);
    }

    this._updateClimberPosition(true);
  }

  _updateClimberPosition(instant = false) {
    const wrap    = document.getElementById('mountain-wrap');
    const climber = document.getElementById('climber-el');
    const fill    = document.getElementById('level-fill');
    const txt     = document.getElementById('level-text');
    if (!wrap || !climber) return;

    const wp  = CLIMB_WAYPOINTS[this.currentLevel] ?? CLIMB_WAYPOINTS[CLIMB_WAYPOINTS.length - 1];
    const pct = (this.currentLevel / this.totalLevels) * 100;

    if (instant) climber.style.transition = 'none';
    climber.style.left = `calc(${wp.x}% - 10px)`;
    climber.style.top  = `calc(${wp.y}% - 16px)`;
    if (instant) requestAnimationFrame(() => { climber.style.transition = ''; });

    if (fill) fill.style.width = `${pct}%`;
    if (txt)  txt.textContent  = `Nivel ${this.currentLevel} de ${this.totalLevels}`;

    const msg = document.getElementById('climb-msg');
    if (msg && this.currentLevel > 0) msg.textContent = getClimbMessage(this.currentLevel);
  }

  _showAdvanceCelebration() {
    const lbl = document.getElementById('advance-label');
    const climber = document.getElementById('climber-el');
    if (!lbl || !climber) return;

    const x = parseFloat(climber.style.left);
    const y = parseFloat(climber.style.top);
    lbl.style.left    = `calc(${x}px + 18px)`;
    lbl.style.top     = `calc(${y}px - 6px)`;
    lbl.style.opacity = '1';

    setTimeout(() => { lbl.style.opacity = '0'; }, 900);
  }

  _showSummitCelebration() {
    const flag  = document.getElementById('summit-flag-el');
    const lbl   = document.getElementById('summit-label');
    const txt   = document.getElementById('level-text');
    const wrap  = document.getElementById('mountain-wrap');
    const climb = document.getElementById('climber-el');

    if (flag) { flag.style.display = 'block'; flag.style.left = '74%'; flag.style.top = '-2%'; }
    if (lbl)  lbl.style.display = 'block';
    if (txt)  txt.textContent = `🏔️ ¡${this.config?.summit_label ?? 'Cima'} — ¡Lo lograste!`;
    if (wrap) wrap.style.filter = 'sepia(.25) brightness(1.08)';
    if (climb) climb.style.display = 'none'; // el escalador "llega" y desaparece bajo la bandera
  }

  // ── TV Static ─────────────────────────────────────
  _initTVStatic() {
    this.container.innerHTML = `
      <div style="display:flex;flex-direction:column;gap:10px;height:100%;align-items:center;justify-content:center">
        <div style="
          background:#111;border-radius:10px;overflow:hidden;
          border:3px solid #374151;position:relative;
          width:100%;max-width:220px;aspect-ratio:4/3">
          <canvas id="tv-canvas" style="width:100%;height:100%;display:block"></canvas>
          <!-- Scanlines overlay -->
          <div style="
            position:absolute;inset:0;
            background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,0,0,.15) 2px,rgba(0,0,0,.15) 4px);
            pointer-events:none"></div>
          <!-- Antenas -->
          <div style="
            position:absolute;top:-18px;left:50%;transform:translateX(-50%);
            display:flex;gap:20px">
            <div style="width:2px;height:18px;background:#374151;transform:rotate(-20deg);transform-origin:bottom"></div>
            <div style="width:2px;height:18px;background:#374151;transform:rotate(20deg);transform-origin:bottom"></div>
          </div>
        </div>
        <p style="font-size:10px;color:#9ca3af;text-align:center;margin:0">
          Animación próximamente
        </p>
        <p id="tv-level" role="status" aria-live="polite"
          style="font-size:11px;color:#6b7280;text-align:center;margin:0">
          Paso 0 de ${this.totalLevels}
        </p>
      </div>
    `;

    this._startStaticAnimation();
    this._updateTVLevel();
  }

  _startStaticAnimation() {
    const canvas = document.getElementById('tv-canvas');
    if (!canvas) return;

    // Respetar prefers-reduced-motion
    if (window.matchMedia('(prefers-reduced-motion:reduce)').matches) {
      const ctx = canvas.getContext('2d');
      canvas.width  = 120;
      canvas.height = 90;
      ctx.fillStyle = '#333';
      ctx.fillRect(0, 0, 120, 90);
      return;
    }

    canvas.width  = 120;
    canvas.height = 90;
    const ctx = canvas.getContext('2d');

    const drawNoise = () => {
      const img = ctx.createImageData(120, 90);
      for (let i = 0; i < img.data.length; i += 4) {
        const v = Math.random() > 0.5 ? 200 + Math.random() * 55 : 20 + Math.random() * 40;
        img.data[i] = img.data[i + 1] = img.data[i + 2] = v;
        img.data[i + 3] = 255;
      }
      ctx.putImageData(img, 0, 0);
    };

    this._staticTimer = setInterval(drawNoise, 80);
  }

  _updateTVLevel() {
    const lbl = document.getElementById('tv-level');
    if (lbl) lbl.textContent = `Paso ${this.currentLevel} de ${this.totalLevels}`;
  }
}

// Para el caso TV static, sobrescribimos advanceLevel
const _origAdvance = AnimationPanel.prototype.advanceLevel;
AnimationPanel.prototype.advanceLevel = function () {
  if (this.config?.type !== 'pixel_climber') {
    if (this.currentLevel < this.totalLevels) this.currentLevel++;
    this._updateTVLevel?.();
  } else {
    _origAdvance.call(this);
  }
};
