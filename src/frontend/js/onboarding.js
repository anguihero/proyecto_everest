// =====================================================
// onboarding.js — Onboarding inicial + consentimiento
// HU-CA-006: Onboarding inicial de la consola
// HU-CA-003: Consentimiento informado y versionado
// =====================================================

import { sb, requireAuth } from './auth.js';
import { APP_CONFIG, ROUTES } from './config.js';

// ─── Estado ─────────────────────────────────────────
let currentProfile = null;
let currentStep    = 1;
const TOTAL_STEPS  = 3;

// ─── Configuración por paso ──────────────────────────
const STEP_CONFIG = {
  1: { title: 'La expedición te espera',       subtitle: 'Primer acceso — 3 pasos rápidos' },
  2: { title: 'Así funciona el ascenso',        subtitle: 'Entiende el camino antes de partir' },
  3: { title: 'Tus datos y tu consentimiento',  subtitle: 'Requerido antes de comenzar' },
};

// ─── Inicialización ──────────────────────────────────
async function init() {
  currentProfile = await requireAuth();
  if (!currentProfile) return;

  // Si ya completó el onboarding, redirigir al panel correspondiente
  if (currentProfile.onboarding_version === APP_CONFIG.onboardingVersion) {
    window.location.href = _roleDestination(currentProfile.role);
    return;
  }

  _bindEvents();
  renderStep(1);
}

// ─── Renderizado de paso ─────────────────────────────
function renderStep(n) {
  currentStep = n;

  // Mostrar/ocultar secciones
  for (let i = 1; i <= TOTAL_STEPS; i++) {
    const section = document.getElementById(`step-${i}`);
    if (section) section.classList.toggle('hidden', i !== n);
  }

  // Actualizar cabecera
  const cfg = STEP_CONFIG[n];
  document.getElementById('step-title').textContent    = cfg.title;
  document.getElementById('step-subtitle').textContent = cfg.subtitle;

  // Indicadores de paso (dots)
  for (let i = 1; i <= TOTAL_STEPS; i++) {
    const dot  = document.getElementById(`dot-btn-${i}`);
    const done = i < n;
    const curr = i === n;
    dot.className = [
      'flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold transition-colors',
      curr ? 'bg-white text-ev-green ring-2 ring-white/50' :
      done ? 'bg-white/70 text-ev-green' :
             'bg-white/20 text-white',
    ].join(' ');
    dot.setAttribute('aria-current', curr ? 'step' : 'false');
  }

  // Líneas de conexión
  for (let i = 1; i < TOTAL_STEPS; i++) {
    const line = document.getElementById(`line-${i}`);
    if (line) line.className = `flex-1 h-0.5 transition-colors ${i < n ? 'bg-white/70' : 'bg-white/20'}`;
  }

  // Progressbar
  const progressbar = document.querySelector('[role="progressbar"]');
  if (progressbar) progressbar.setAttribute('aria-valuenow', String(n));

  // Botón Anterior
  const btnBack = document.getElementById('btn-back');
  btnBack.classList.toggle('hidden', n === 1);

  // Botón Siguiente / Comenzar
  const btnNextText    = document.getElementById('btn-next-text');
  const btnNext        = document.getElementById('btn-next');
  btnNextText.textContent = n === TOTAL_STEPS ? 'Comenzar expedición' : 'Siguiente';
  btnNext.disabled = false;

  // En paso 3 validar consent para habilitar el botón
  if (n === TOTAL_STEPS) {
    _updateConsentButton();
  }

  // Ocultar errores al cambiar de paso
  document.getElementById('alert-error').classList.add('hidden');
}

// ─── Eventos ─────────────────────────────────────────
function _bindEvents() {
  document.getElementById('btn-next').addEventListener('click', handleNext);
  document.getElementById('btn-back').addEventListener('click', () => renderStep(currentStep - 1));

  // Skip links
  document.getElementById('btn-skip-1')?.addEventListener('click', () => renderStep(TOTAL_STEPS));
  document.getElementById('btn-skip-2')?.addEventListener('click', () => renderStep(TOTAL_STEPS));

  // Dots de paso (solo pasos ya visitados o anteriores)
  for (let i = 1; i <= TOTAL_STEPS; i++) {
    const dot = document.getElementById(`dot-btn-${i}`);
    dot.addEventListener('click', () => {
      if (i < currentStep) renderStep(i);
    });
  }

  // Validación en tiempo real de checkboxes en paso 3
  document.getElementById('consent-data')?.addEventListener('change', _updateConsentButton);
  document.getElementById('consent-ai')?.addEventListener('change',   _updateConsentButton);
}

// ─── Lógica de navegación ────────────────────────────
async function handleNext() {
  if (currentStep < TOTAL_STEPS) {
    renderStep(currentStep + 1);
    return;
  }
  // Paso final → validar y completar onboarding
  await completeOnboarding();
}

// ─── Habilitación del botón en paso 3 ───────────────
function _updateConsentButton() {
  const dataOk = document.getElementById('consent-data')?.checked ?? false;
  const aiOk   = document.getElementById('consent-ai')?.checked   ?? false;
  document.getElementById('btn-next').disabled = !(dataOk && aiOk);
}

// ─── Completar onboarding (HU-CA-003 + HU-CA-006) ───
async function completeOnboarding() {
  const dataChecked  = document.getElementById('consent-data').checked;
  const aiChecked    = document.getElementById('consent-ai').checked;
  const coachChecked = document.getElementById('consent-coach').checked;

  if (!dataChecked || !aiChecked) {
    _showConsentError('Debes aceptar las finalidades requeridas para continuar.');
    return;
  }

  _setLoading(true);

  try {
    // 1. Registrar consentimiento (HU-CA-003)
    const { error: consentErr } = await sb.from('consent_records').insert({
      user_id:        currentProfile.id,
      org_id:         currentProfile.org_id,
      policy_version: APP_CONFIG.consentPolicyVersion,
      purposes: {
        data_processing: dataChecked,
        ai_processing:   aiChecked,
        coach_sharing:   coachChecked,
      },
    });

    // Ignorar error de duplicado (usuario que ya tenía registro)
    if (consentErr && !consentErr.code?.includes('23505')) {
      throw consentErr;
    }

    // 2. Marcar onboarding completado (HU-CA-006)
    const { error: profileErr } = await sb
      .from('profiles')
      .update({ onboarding_version: APP_CONFIG.onboardingVersion })
      .eq('id', currentProfile.id);

    if (profileErr) throw profileErr;

    // 3. Redirigir al panel correspondiente
    window.location.href = _roleDestination(currentProfile.role);

  } catch (err) {
    _showError('No pudimos guardar tu consentimiento. Por favor, inténtalo de nuevo.');
    _setLoading(false);
  }
}

// ─── Helpers ─────────────────────────────────────────
function _roleDestination(role) {
  return { player: ROUTES.hub, coach: ROUTES.hub, org_admin: ROUTES.admin, sys_admin: ROUTES.sysadmin }[role] ?? ROUTES.hub;
}

function _setLoading(on) {
  const btn     = document.getElementById('btn-next');
  const txtEl   = document.getElementById('btn-next-text');
  const spinner = document.getElementById('btn-next-spinner');
  btn.disabled = on;
  txtEl.classList.toggle('hidden', on);
  spinner.classList.toggle('hidden', !on);
}

function _showError(msg) {
  const el = document.getElementById('alert-error');
  el.textContent = msg;
  el.classList.remove('hidden');
}

function _showConsentError(msg) {
  const el = document.getElementById('consent-error');
  el.textContent = msg;
  el.classList.remove('hidden');
}

// ─── Arranque ────────────────────────────────────────
init();
