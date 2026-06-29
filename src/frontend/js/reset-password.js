// reset-password.js — Flujo de nueva contraseña desde enlace de email
// Plan: PLAN_AUTH_CREDENCIALES_AUTONOMAS.md — Fase B
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SUPABASE_CONFIG } from './config.js';

const sb = createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);

// ── Elementos del DOM ──────────────────────────────────
const stateLoading = document.getElementById('state-loading');
const stateInvalid = document.getElementById('state-invalid');
const stateForm    = document.getElementById('state-form');
const stateSuccess = document.getElementById('state-success');
const pwInput      = document.getElementById('password');
const pwConfirm    = document.getElementById('password-confirm');
const submitBtn    = document.getElementById('submit-btn');
const formError    = document.getElementById('form-error');
const matchError   = document.getElementById('match-error');
const strengthBar  = document.getElementById('strength-bar');
const strengthLbl  = document.getElementById('strength-label');
const togglePwBtn  = document.getElementById('toggle-pw');

// ── Inicialización ─────────────────────────────────────
async function init() {
  show('loading');

  // Supabase pone el access_token en el hash de la URL al hacer clic en el email
  // Formato: #access_token=...&type=recovery
  const hash   = window.location.hash.substring(1);
  const params = new URLSearchParams(hash);
  const type   = params.get('type');

  if (type !== 'recovery') {
    // No es un enlace de recuperación válido
    show('invalid');
    return;
  }

  // Intentar intercambiar el token — Supabase lo procesa automáticamente
  // al detectar el hash en la URL. Verificamos que haya sesión activa.
  const { data: { session }, error } = await sb.auth.getSession();

  if (error || !session) {
    show('invalid');
    return;
  }

  show('form');
}

// ── Validación de fortaleza ────────────────────────────
const RULES = {
  length:  { re: /.{12,}/,                id: 'req-length'  },
  upper:   { re: /[A-Z]/,                 id: 'req-upper'   },
  lower:   { re: /[a-z]/,                 id: 'req-lower'   },
  number:  { re: /[0-9]/,                 id: 'req-number'  },
  symbol:  { re: /[^A-Za-z0-9]/,          id: 'req-symbol'  },
};

function checkStrength(value) {
  let passed = 0;
  for (const [, rule] of Object.entries(RULES)) {
    const ok = rule.re.test(value);
    const li = document.getElementById(rule.id);
    const icon = li.querySelector('.req-icon');
    if (ok) {
      li.classList.replace('text-gray-400', 'text-green-600');
      icon.textContent = '✓';
      passed++;
    } else {
      li.classList.replace('text-green-600', 'text-gray-400');
      icon.textContent = '○';
    }
  }
  return passed;
}

const STRENGTH_CONFIG = [
  { pct: '20%',  color: 'bg-red-400',    label: 'Muy débil'  },
  { pct: '40%',  color: 'bg-orange-400', label: 'Débil'      },
  { pct: '60%',  color: 'bg-yellow-400', label: 'Regular'    },
  { pct: '80%',  color: 'bg-lime-500',   label: 'Buena'      },
  { pct: '100%', color: 'bg-green-600',  label: 'Excelente'  },
];

function updateStrengthBar(passed) {
  const cfg = STRENGTH_CONFIG[passed - 1] ?? { pct: '0%', color: 'bg-gray-300', label: '' };
  strengthBar.style.width = cfg.pct;
  strengthBar.className = `strength-bar h-full rounded-full ${cfg.color}`;
  strengthLbl.textContent = cfg.label;
}

function isFormValid() {
  const pw  = pwInput.value;
  const pw2 = pwConfirm.value;
  return (
    Object.values(RULES).every(r => r.re.test(pw)) &&
    pw === pw2
  );
}

// ── Listeners ──────────────────────────────────────────
pwInput.addEventListener('input', () => {
  const passed = checkStrength(pwInput.value);
  updateStrengthBar(passed);
  validateMatch();
  submitBtn.disabled = !isFormValid();
});

pwConfirm.addEventListener('input', () => {
  validateMatch();
  submitBtn.disabled = !isFormValid();
});

function validateMatch() {
  const mismatch = pwInput.value && pwConfirm.value && pwInput.value !== pwConfirm.value;
  matchError.classList.toggle('hidden', !mismatch);
}

togglePwBtn.addEventListener('click', () => {
  const isText = pwInput.type === 'text';
  pwInput.type = isText ? 'password' : 'text';
  togglePwBtn.textContent = isText ? '👁️' : '🙈';
});

// ── Submit ─────────────────────────────────────────────
stateForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  if (!isFormValid()) return;

  hideError();
  submitBtn.disabled = true;
  submitBtn.textContent = 'Guardando…';

  const { error } = await sb.auth.updateUser({ password: pwInput.value });

  if (error) {
    showError(mapError(error));
    submitBtn.disabled = false;
    submitBtn.textContent = 'Guardar nueva contraseña';
    return;
  }

  // Cerrar sesión de recuperación y mostrar éxito
  await sb.auth.signOut();
  show('success');
});

// ── Helpers ────────────────────────────────────────────
function show(state) {
  stateLoading.classList.toggle('hidden', state !== 'loading');
  stateInvalid.classList.toggle('hidden', state !== 'invalid');
  stateForm.classList.toggle(   'hidden', state !== 'form');
  stateSuccess.classList.toggle('hidden', state !== 'success');
}

function showError(msg) {
  formError.textContent = msg;
  formError.classList.remove('hidden');
}

function hideError() {
  formError.classList.add('hidden');
}

function mapError(err) {
  const msg = err?.message ?? '';
  if (msg.includes('Password should be'))  return 'La contraseña no cumple los requisitos de seguridad.';
  if (msg.includes('expired'))             return 'El enlace ha expirado. Solicita uno nuevo.';
  if (msg.includes('invalid'))             return 'El enlace es inválido. Solicita uno nuevo.';
  return 'Ocurrió un error al actualizar la contraseña. Intenta de nuevo.';
}

init();
