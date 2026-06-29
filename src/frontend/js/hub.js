// =====================================================
// hub.js — Módulo del Hub Central
// HU-CA-005: Hub y catálogo personal de experiencias
// =====================================================

import { sb, requireAuth, logout } from './auth.js';

// ─── Estado de la página ────────────────────────────
let currentProfile = null;

// ─── Inicialización ─────────────────────────────────
export async function initHub() {
  currentProfile = await requireAuth();
  if (!currentProfile) return; // requireAuth ya redirigió

  renderHeader(currentProfile);
  if (currentProfile.role === 'coach') {
    document.getElementById('btn-team-results')?.classList.remove('hidden');
  }

  // Cargar experiencias propias y, para coaches, sección de equipo
  await Promise.all([
    loadAssignments(),
    currentProfile.role === 'coach' ? initTeamSection() : Promise.resolve(),
  ]);
}

// ─── Header personalizado ───────────────────────────
function renderHeader(profile) {
  const nameEl = document.getElementById('user-name');
  const roleEl = document.getElementById('user-role');
  if (nameEl) nameEl.textContent = profile.preferred_name ?? 'Expedicionario';
  if (roleEl) {
    const labels = {
      player: 'Jugador',
      coach:  'Líder',
    };
    roleEl.textContent = labels[profile.role] ?? profile.role;
  }
}

// ─── Sección Mi Equipo (coaches) ────────────────────
async function initTeamSection() {
  const section = document.getElementById('team-section');
  if (!section) return;
  section.classList.remove('hidden');

  const loadingEl = document.getElementById('team-loading');
  const listEl    = document.getElementById('team-list');
  const pendingEl = document.getElementById('team-pending');

  try {
    // Coaches solo ven sus propios datos por RLS en Ola 1.
    // La visibilidad de equipo (DEC-P-01) requiere aprobación de Óscar.
    // Por ahora se muestra el aviso de configuración pendiente.
    const { data: players, error } = await sb
      .from('profiles')
      .select('id, preferred_name, role')
      .eq('role', 'player')
      .eq('org_id', currentProfile.org_id);

    loadingEl?.classList.add('hidden');

    if (error || !players || players.length === 0) {
      // RLS no permite acceso aún: mostrar aviso pendiente
      pendingEl?.classList.remove('hidden');
      return;
    }

    listEl?.classList.remove('hidden');
    listEl.innerHTML = players.map(renderTeamMemberRow).join('');

  } catch {
    loadingEl?.classList.add('hidden');
    pendingEl?.classList.remove('hidden');
  }
}

function renderTeamMemberRow(player) {
  return `
    <div class="bg-white rounded-xl border border-gray-200 px-5 py-4 flex items-center gap-4">
      <div class="w-9 h-9 rounded-full bg-ev-green/10 flex items-center justify-center shrink-0"
           aria-hidden="true">
        <span class="text-ev-green font-bold text-sm">
          ${(player.preferred_name ?? 'U').charAt(0).toUpperCase()}
        </span>
      </div>
      <div>
        <p class="text-sm font-semibold text-gray-900">${player.preferred_name ?? 'Sin nombre'}</p>
        <p class="text-xs text-gray-400">Jugador</p>
      </div>
    </div>
  `;
}

// ─── Cargar asignaciones del Hub ────────────────────
async function loadAssignments() {
  const grid    = document.getElementById('experience-grid');
  const empty   = document.getElementById('empty-state');
  const loading = document.getElementById('loading-state');

  if (!grid) return;

  setLoadingState(true);

  try {
    const { data: assignments, error } = await sb.rpc('get_player_hub');

    if (error) throw error;

    setLoadingState(false);

    if (!assignments || assignments.length === 0) {
      grid.classList.add('hidden');
      empty?.classList.remove('hidden');
      return;
    }

    empty?.classList.add('hidden');
    grid.classList.remove('hidden');
    grid.innerHTML = assignments.map(renderExperienceCard).join('');

    grid.querySelectorAll('a[data-assignment-id]').forEach(link => {
      link.addEventListener('click', () => {
        sessionStorage.setItem('ev_pending_assignment', link.dataset.assignmentId);
      });
    });

  } catch (err) {
    setLoadingState(false);
    showError('No pudimos cargar tus experiencias. Por favor intenta de nuevo.');
    console.error('[Hub] Error cargando asignaciones:', err.message);
  }
}

// ─── Renderizar tarjeta de experiencia ──────────────
function renderExperienceCard(item) {
  const cta = getCTA(item);
  const badge = getStatusBadge(item);
  const typeLabel = item.experience_type === 'exploration'
    ? 'Exploración conductual'
    : 'Simulación empresarial';

  return `
    <article class="bg-white rounded-xl border border-gray-200 shadow-sm hover:shadow-md
                    transition-shadow overflow-hidden flex flex-col"
             aria-label="${item.experience_name ?? getExperienceName(item.experience_slug)}">
      <div class="p-6 flex-1">
        <div class="flex items-start justify-between mb-3">
          <span class="text-xs font-semibold text-ev-green uppercase tracking-wider">
            ${typeLabel}
          </span>
          ${badge}
        </div>
        <h3 class="text-lg font-bold text-gray-900 mb-2">
          ${item.experience_name ?? getExperienceName(item.experience_slug)}
        </h3>
        <p class="text-sm text-gray-500">
          ${item.experience_description ?? getExperienceDescription(item.experience_slug)}
        </p>
        ${item.current_step > 0 && item.session_status === 'in_progress'
          ? `<p class="mt-3 text-xs text-gray-400">
               Paso ${item.current_step} completado
             </p>`
          : ''}
      </div>
      <div class="px-6 pb-6">
        <a href="${cta.href}"
           ${cta.assignmentId ? `data-assignment-id="${cta.assignmentId}"` : ''}
           class="block w-full py-3 px-4 rounded-lg text-center font-semibold text-sm
                  ${cta.primary
                    ? 'bg-ev-green hover:bg-ev-dark text-white'
                    : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}
                  transition-colors
                  focus:outline-none focus:ring-2 focus:ring-ev-green focus:ring-offset-1"
        >
          ${cta.label}
        </a>
      </div>
    </article>
  `;
}

// ─── CTA según el estado de la asignación ───────────
function getCTA(item) {
  if (item.session_status === 'completed') {
    return { label: 'Ver resultado', href: `results.html?session=${item.session_id}`, primary: false };
  }
  if (item.session_status === 'in_progress' || item.session_status === 'paused') {
    return { label: 'Continuar expedición', href: `runner.html?assignment=${item.assignment_id}`, primary: true, assignmentId: item.assignment_id };
  }
  return { label: 'Iniciar expedición', href: `runner.html?assignment=${item.assignment_id}`, primary: true, assignmentId: item.assignment_id };
}

// ─── Badge de estado ────────────────────────────────
function getStatusBadge(item) {
  const map = {
    completed:   { text: 'Completado',  cls: 'bg-green-100 text-green-700' },
    in_progress: { text: 'En progreso', cls: 'bg-blue-100 text-blue-700'   },
    paused:      { text: 'En pausa',    cls: 'bg-yellow-100 text-yellow-700' },
    not_started: { text: 'Disponible',  cls: 'bg-gray-100 text-gray-600'   },
  };
  const state = item.session_status ?? 'not_started';
  const badge = map[state] ?? map.not_started;
  return `<span class="text-xs font-semibold px-2 py-1 rounded-full ${badge.cls}">${badge.text}</span>`;
}

// ─── Nombres y descripciones de experiencias ────────
// En Ola 2 estos datos vendrán del content del casete.
function getExperienceName(slug) {
  const names = {
    'expedicion-base':   'Expedición Base',
    'expedicion-cumbre': 'Expedición Cumbre',
  };
  return names[slug] ?? slug;
}

function getExperienceDescription(slug) {
  const descs = {
    'expedicion-base':
      'Explora tus tendencias de liderazgo en 10 escenarios situacionales. Resultado: perfil conductual exploratorio.',
    'expedicion-cumbre':
      'Dirige una empresa ficticia a través de 10 decisiones ambiguas asistidas por tres perspectivas de coaching.',
  };
  return descs[slug] ?? '';
}

// ─── Estado de carga ────────────────────────────────
function setLoadingState(on) {
  document.getElementById('loading-state')?.classList.toggle('hidden', !on);
  document.getElementById('experience-grid')?.classList.toggle('hidden', on);
}

function showError(msg) {
  const el = document.getElementById('error-message');
  if (el) {
    el.textContent = msg;
    el.classList.remove('hidden');
  }
}

// ─── Logout ─────────────────────────────────────────
document.getElementById('btn-logout')?.addEventListener('click', logout);
