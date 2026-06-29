// =====================================================
// runner.js — Motor de experiencias (runner genérico)
// HU-CM-003: Inicio de sesión versionada
// HU-CM-004: Runner genérico de pasos y elecciones
// HU-CM-005: Autosave, pausa y reanudación
// HU-CM-006: Scoring y finalización determinísticos
// =====================================================

import { sb, requireAuth, logout } from './auth.js';
import { ROUTES } from './config.js';
import { getErrorMessage, getSafeErrorDiagnostic } from './error-utils.js';
import { AnimationPanel } from './animation-panel.js';

// ─── Estado de la sesión ────────────────────────────
let currentProfile  = null;
let sessionId       = null;
let content         = null;      // casete content JSONB
let totalSteps      = 0;
let currentStep     = 0;         // posición de display (0-based)
let selectedOption  = null;
let isSaving        = false;
let displayOrder    = null;      // null = orden canonical; array = orden aleatorio

// Timer
let timerInterval  = null;
let stepStartTime  = null;       // Date.now() al renderizar el paso

// Panel de animación
let animPanel = null;

// ─── Formas por posición de display ─────────────────
// Asociadas al ORDEN en que aparece la opción, no a su identidad DISC.
// Las 4 formas en SVG inline (18×18 px):
const POSITION_SHAPES = [
  {
    color: 'text-amber-500',
    ring:  'has-[:checked]:ring-amber-400',
    svg:   '<svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true" class="shrink-0"><polygon points="9,2 17,16 1,16" fill="currentColor"/></svg>',
  },
  {
    color: 'text-blue-500',
    ring:  'has-[:checked]:ring-blue-400',
    svg:   '<svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true" class="shrink-0"><circle cx="9" cy="9" r="7" fill="currentColor"/></svg>',
  },
  {
    color: 'text-emerald-500',
    ring:  'has-[:checked]:ring-emerald-400',
    svg:   '<svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true" class="shrink-0"><rect x="2" y="2" width="14" height="14" fill="currentColor"/></svg>',
  },
  {
    color: 'text-violet-500',
    ring:  'has-[:checked]:ring-violet-400',
    svg:   '<svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true" class="shrink-0"><polygon points="9,1 17,9 9,17 1,9" fill="currentColor"/></svg>',
  },
];

// ─── Inicialización ─────────────────────────────────
async function init() {
  currentProfile = await requireAuth();
  if (!currentProfile) return;

  const params       = new URLSearchParams(window.location.search);
  const assignmentId = params.get('assignment')
    || sessionStorage.getItem('ev_pending_assignment');

  if (assignmentId) sessionStorage.removeItem('ev_pending_assignment');

  if (!assignmentId) {
    showError('No se encontró la experiencia. Vuelve al Hub.', true);
    return;
  }

  setView('loading');
  await startOrResume(assignmentId);
}

// ─── Iniciar o reanudar sesión ───────────────────────
async function startOrResume(assignmentId) {
  try {
    const { data, error } = await sb.rpc('start_or_resume_session', {
      p_assignment_id: assignmentId,
    });

    if (error) throw error;
    if (!data)  throw new Error('Respuesta vacía del servidor.');

    if (data.status === 'completed') {
      window.location.href = `results.html?session=${data.session_id}`;
      return;
    }

    sessionId   = data.session_id;
    content     = data.content;
    totalSteps  = data.total_steps ?? content.meta.total_steps;
    currentStep = data.current_step ?? 0;

    // Inicializar orden de display para content v2 (randomización anti-memorización)
    if (isV2Content(content)) {
      initDisplayOrder(currentStep);
    }

    document.getElementById('exp-name').textContent =
      content.meta.name ?? 'Expedición';

    setView('runner');
    _initAnimationPanel();
    renderStep(currentStep);

  } catch (err) {
    const diagnostic = getSafeErrorDiagnostic(err);
    console.error('[Runner] No se pudo iniciar/reanudar', diagnostic);
    showError(
      getErrorMessage(err, 'No pudimos cargar la experiencia. Inténtalo de nuevo.'),
      true,
      diagnostic,
    );
  }
}

// ─── Panel de animación ──────────────────────────────
function _initAnimationPanel() {
  const panelEl = document.getElementById('animation-panel');
  if (!panelEl) return;

  const animConfig = content?.meta?.animation_config ?? null;

  // Sin config o type=none: ocultar el panel (sin aside lateral)
  if (!animConfig || animConfig.type === 'none') return;

  panelEl.classList.remove('hidden');
  animPanel = new AnimationPanel(panelEl, animConfig, totalSteps);
  animPanel.init();
}

// ─── Randomización ───────────────────────────────────

function isV2Content(c) {
  return (c?.schema_version ?? c?.meta?.schema_version) === '2.0';
}

function fisherYates(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ─── Timer ────────────────────────────────────────────

function startTimer(totalSecs) {
  clearInterval(timerInterval);
  stepStartTime = Date.now();

  const widget  = document.getElementById('timer-widget');
  const display = document.getElementById('timer-display');
  const icon    = document.getElementById('timer-icon');
  if (widget) {
    widget.classList.remove('hidden');
    widget.classList.add('flex');
  }

  function tick() {
    const elapsed    = (Date.now() - stepStartTime) / 1000;
    const remaining  = totalSecs - elapsed;
    const overtime   = remaining < 0;
    const secsToShow = overtime ? Math.floor(-remaining) : Math.ceil(remaining);
    const m          = Math.floor(secsToShow / 60);
    const s          = secsToShow % 60;
    const label      = (overtime ? '+' : '') + m + ':' + String(s).padStart(2, '0');

    if (display) {
      display.textContent = label;
      const pct = remaining / totalSecs;
      // Color: verde → ámbar (≤50%) → rojo (≤25% o tiempo excedido)
      const colorClass =
        overtime    ? 'text-red-600'   :
        pct < 0.25  ? 'text-red-500'  :
        pct < 0.50  ? 'text-amber-500' :
                      'text-ev-green';
      display.className =
        'text-sm font-bold font-mono tabular-nums transition-colors duration-300 ' + colorClass;
    }
    if (icon) {
      icon.setAttribute('class', 'w-3.5 h-3.5 shrink-0 ' + (
        overtime   ? 'text-red-600'   :
        remaining / totalSecs < 0.25 ? 'text-red-500' :
        remaining / totalSecs < 0.50 ? 'text-amber-500' :
                     'text-ev-green'
      ));
    }
  }

  tick();
  timerInterval = setInterval(tick, 500);
}

function stopTimer() {
  clearInterval(timerInterval);
  timerInterval = null;
  const widget = document.getElementById('timer-widget');
  if (widget) {
    widget.classList.add('hidden');
    widget.classList.remove('flex');
  }
}

function getElapsedSecs() {
  if (stepStartTime === null) return null;
  return Math.round((Date.now() - stepStartTime) / 100) / 10;  // 1 decimal
}

function initDisplayOrder(resumedAtStep) {
  const key    = `ev_order_${sessionId}`;
  const stored = sessionStorage.getItem(key);

  if (stored) {
    try {
      const parsed = JSON.parse(stored);
      if (Array.isArray(parsed) && parsed.length === totalSteps) {
        displayOrder = parsed;
        return;
      }
    } catch { /* fall through */ }
  }

  if (resumedAtStep === 0) {
    // Nueva sesión: generar shuffle y persistir
    displayOrder = fisherYates([...Array(totalSteps).keys()]);
    sessionStorage.setItem(key, JSON.stringify(displayOrder));
  } else {
    // Reanudación sin shuffle guardado → orden canonical como fallback
    displayOrder = [...Array(totalSteps).keys()];
  }
}

function getCanonicalIndex(displayIndex) {
  return displayOrder ? displayOrder[displayIndex] : displayIndex;
}

function getDisplayOptions(step) {
  if (!displayOrder) return step.options;

  const key    = `ev_opts_${sessionId}_${step.id}`;
  const stored = sessionStorage.getItem(key);

  if (stored) {
    try {
      const parsed = JSON.parse(stored);
      if (Array.isArray(parsed)) return parsed;
    } catch { /* fall through */ }
  }

  const shuffled = fisherYates(step.options);
  sessionStorage.setItem(key, JSON.stringify(shuffled));
  return shuffled;
}

// ─── Renderizar paso ─────────────────────────────────
function renderStep(displayIndex) {
  selectedOption = null;
  isSaving       = false;

  const canonicalIndex = getCanonicalIndex(displayIndex);
  const step           = content.steps[canonicalIndex];
  if (!step) return;

  // Progreso
  const pct = Math.round((displayIndex / totalSteps) * 100);
  document.getElementById('progress-bar').style.width = `${pct}%`;
  document.getElementById('step-counter').textContent =
    `Paso ${displayIndex + 1} de ${totalSteps}`;

  // Contenido
  document.getElementById('step-title').textContent     = step.content.title;
  document.getElementById('step-narrative').textContent = step.content.narrative;

  // Timer: iniciar con el tiempo de la pregunta (fallback 60s)
  const timeSecs = step.content?.time_secs ?? 60;
  startTimer(timeSecs);

  // Opciones con forma+color por posición de display (anti-memorización)
  const options   = getDisplayOptions(step);
  const optionsEl = document.getElementById('options-group');
  optionsEl.innerHTML = options
    .filter(o => o.visible)
    .map((o, displayPos) => {
      const shape = POSITION_SHAPES[displayPos % POSITION_SHAPES.length];
      return `
        <label class="option-label flex items-start gap-3 cursor-pointer rounded-xl
                       border-2 border-gray-200 hover:border-gray-300 bg-white p-4
                       transition-colors has-[:checked]:border-ev-green has-[:checked]:bg-ev-green/5">
          <input type="radio" name="choice" value="${escapeHtml(o.key)}"
                 class="sr-only" aria-label="Opción ${displayPos + 1}">
          <span class="${shape.color} mt-0.5 leading-none" aria-hidden="true">
            ${shape.svg}
          </span>
          <span class="text-sm text-gray-700 leading-relaxed">${escapeHtml(o.text)}</span>
        </label>
      `;
    }).join('');

  optionsEl.querySelectorAll('input[name="choice"]').forEach(input => {
    input.addEventListener('change', () => {
      selectedOption = input.value;
      setConfirmEnabled(true);
    });
  });

  // Reset botón
  setConfirmEnabled(false);
  document.getElementById('btn-confirm-text').textContent = 'Confirmar decisión';

  // Mostrar panel pregunta, ocultar feedback
  document.getElementById('question-panel').classList.remove('hidden');
  document.getElementById('feedback-panel').classList.add('hidden');
  document.getElementById('inline-error').classList.add('hidden');
}

// ─── Confirmar elección ──────────────────────────────
async function confirmChoice() {
  if (!selectedOption || isSaving) return;

  isSaving = true;
  const elapsedSecs = getElapsedSecs();   // capturar antes de detener el timer
  stopTimer();
  setSavingState(true);

  try {
    const { data, error } = await sb.rpc('save_step_answer', {
      p_session_id:   sessionId,
      p_step_index:   currentStep,        // posición de display (0, 1, 2…)
      p_option_key:   selectedOption,     // UUID en v2; letra "A/B/C/D" en v1
      p_elapsed_secs: elapsedSecs,        // segundos reales de respuesta
    });

    if (error) throw error;

    // Feedback client-side (toma prioridad sobre el del servidor)
    // En v2 el servidor devuelve null porque usa índice canonical vs. display
    const canonicalIndex   = getCanonicalIndex(currentStep);
    const step             = content.steps[canonicalIndex];
    const clientFeedback   = step?.feedback?.[selectedOption];
    const feedbackText     = clientFeedback ?? data.feedback;

    currentStep++;
    animPanel?.advanceLevel();
    showFeedback(feedbackText, selectedOption, step);

  } catch (err) {
    isSaving = false;
    setSavingState(false);
    document.getElementById('inline-error').textContent =
      'No pudimos guardar tu respuesta. Inténtalo de nuevo.';
    document.getElementById('inline-error').classList.remove('hidden');
  }
}

// ─── Mostrar retroalimentación ───────────────────────
function showFeedback(feedbackText, optionKey, step) {
  setSavingState(false);

  const chosenOption = step.options.find(o => o.key === optionKey);
  document.getElementById('feedback-choice').textContent =
    `Tu decisión: "${chosenOption?.text ?? optionKey}"`;
  document.getElementById('feedback-text').textContent =
    feedbackText ?? 'Decisión registrada.';

  const isLast = currentStep >= totalSteps;
  const btnNext = document.getElementById('btn-next');
  btnNext.textContent = isLast ? 'Ver mi perfil de liderazgo →' : 'Siguiente escenario';
  btnNext.classList.toggle('bg-ev-gold',         isLast);
  btnNext.classList.toggle('hover:bg-amber-500', isLast);
  btnNext.classList.toggle('bg-ev-green',        !isLast);
  btnNext.classList.toggle('hover:bg-ev-dark',   !isLast);

  if (isLast) {
    document.getElementById('progress-bar').style.width = '100%';
    document.getElementById('step-counter').textContent =
      `Paso ${totalSteps} de ${totalSteps}`;
  }

  document.getElementById('question-panel').classList.add('hidden');
  document.getElementById('feedback-panel').classList.remove('hidden');
}

// ─── Avanzar o finalizar ─────────────────────────────
async function advanceOrFinish() {
  const isLast = currentStep >= totalSteps;

  if (!isLast) {
    isSaving = false;
    renderStep(currentStep);
    return;
  }

  const btnNext = document.getElementById('btn-next');
  btnNext.disabled    = true;
  btnNext.textContent = 'Calculando tu perfil…';

  try {
    const { data, error } = await sb.rpc('complete_session', {
      p_session_id: sessionId,
    });

    if (error) throw error;

    // Limpiar estado de sesión al completar
    stopTimer();
    sessionStorage.removeItem(`ev_order_${sessionId}`);

    window.location.href = `results.html?session=${sessionId}`;

  } catch (err) {
    btnNext.disabled    = false;
    btnNext.textContent = 'Ver mi perfil de liderazgo →';
    document.getElementById('inline-error').textContent =
      'No pudimos calcular tu perfil. Inténtalo de nuevo.';
    document.getElementById('inline-error').classList.remove('hidden');
  }
}

// ─── Guardar y salir ─────────────────────────────────
function saveAndExit() {
  // La sesión ya está guardada paso a paso.
  window.location.href = ROUTES.hub;
}

// ─── Helpers de UI ──────────────────────────────────
function setView(view) {
  ['loading', 'error', 'runner'].forEach(v => {
    document.getElementById(`view-${v}`)?.classList.toggle('hidden', v !== view);
  });
}

function setConfirmEnabled(on) {
  const btn = document.getElementById('btn-confirm');
  btn.disabled = !on;
}

function setSavingState(saving) {
  const btn  = document.getElementById('btn-confirm');
  const text = document.getElementById('btn-confirm-text');
  const spin = document.getElementById('btn-confirm-spinner');
  btn.disabled = saving;
  text?.classList.toggle('hidden', saving);
  spin?.classList.toggle('hidden', !saving);
}

function showError(msg, withBackBtn, diagnostic = null) {
  setView('error');
  document.getElementById('error-message').textContent = msg;
  const diagnosticEl = document.getElementById('error-diagnostic');
  if (diagnosticEl) {
    diagnosticEl.textContent = diagnostic
      ? `Código de referencia: ${diagnostic.key}${diagnostic.code ? ` / ${diagnostic.code}` : ''}`
      : '';
    diagnosticEl.classList.toggle('hidden', !diagnostic);
  }
  const backBtn = document.getElementById('error-back-btn');
  if (backBtn) backBtn.classList.toggle('hidden', !withBackBtn);
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// ─── Eventos ─────────────────────────────────────────
document.getElementById('btn-confirm')?.addEventListener('click', confirmChoice);
document.getElementById('btn-next')?.addEventListener('click',    advanceOrFinish);
document.getElementById('btn-save-exit')?.addEventListener('click', saveAndExit);
document.getElementById('btn-logout')?.addEventListener('click', logout);

// ─── Arranque ────────────────────────────────────────
init();
