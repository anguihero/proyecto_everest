// =====================================================
// admin.js — Panel de Administración (OrgAdmin)
// HU-CA-007: Panel de administración organizacional
// =====================================================

import { sb, requireAuth, logout } from './auth.js';
import { ROUTES } from './config.js';
import { getErrorMessage } from './error-utils.js';
import { buildOptionalDate } from './date-utils.js';

// ─── Estado ─────────────────────────────────────────
let currentProfile = null;
let orgUsers = [];
let experiences = [];
let activeTab = 'users';

// ─── Inicialización ─────────────────────────────────
export async function initAdmin() {
  currentProfile = await requireAuth();
  if (!currentProfile) return;

  // Guardia de rol — defensa en profundidad (la auth ya redirigió por rol)
  if (currentProfile.role !== 'org_admin') {
    window.location.href = ROUTES.hub;
    return;
  }

  renderHeader();
  setupTabs();
  setupLogout();

  // Carga paralela de datos iniciales
  await Promise.all([
    loadUsers(),
    loadExperiences(),
  ]);

  // El progreso solo carga cuando el tab es activado
  setupDueDateSelectors();
  setupAssignmentModal();
  setupInviteModal();
  setupAssignmentActions();
}

// ─── Header ─────────────────────────────────────────
async function renderHeader() {
  const nameEl = document.getElementById('user-name');
  const orgEl  = document.getElementById('org-name');
  if (nameEl) nameEl.textContent = currentProfile.preferred_name ?? 'Administrador';

  if (orgEl) {
    const { data: org } = await sb
      .from('organizations')
      .select('name')
      .eq('id', currentProfile.org_id)
      .single();
    orgEl.textContent = org?.name ?? '';
  }
}

// ─── Tabs ────────────────────────────────────────────
function setupTabs() {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.dataset.tab;
      switchTab(tab);
    });
  });
}

function switchTab(tabName) {
  activeTab = tabName;

  document.querySelectorAll('.tab-btn').forEach(btn => {
    const isActive = btn.dataset.tab === tabName;
    btn.setAttribute('aria-selected', String(isActive));
    btn.classList.toggle('border-ev-green',  isActive);
    btn.classList.toggle('text-ev-green',    isActive);
    btn.classList.toggle('border-transparent', !isActive);
    btn.classList.toggle('text-gray-500',    !isActive);
  });

  ['users', 'assignments', 'progress'].forEach(id => {
    const panel = document.getElementById(`tab-${id}`);
    if (panel) panel.classList.toggle('hidden', id !== tabName);
  });

  // Carga diferida del progreso
  if (tabName === 'progress') loadProgress();
  if (tabName === 'assignments') renderAssignmentsList();
}

// ─── Usuarios de la organización ────────────────────
async function loadUsers() {
  const tbodyEl  = document.getElementById('users-tbody');
  const tableEl  = document.getElementById('users-table');
  const emptyEl  = document.getElementById('users-empty');
  const loadEl   = document.getElementById('users-loading');

  try {
    const { data, error } = await sb
      .from('profiles')
      .select('id, preferred_name, role, is_active, created_at')
      .eq('org_id', currentProfile.org_id)
      .order('role')
      .order('preferred_name');

    if (error) throw error;

    orgUsers = data ?? [];
    loadEl?.classList.add('hidden');

    if (orgUsers.length === 0) {
      emptyEl?.classList.remove('hidden');
      return;
    }

    tbodyEl.innerHTML = orgUsers.map(renderUserRow).join('');
    tableEl?.classList.remove('hidden');

    // Poblar select del modal con todos los usuarios asignables (excluye sys_admin)
    const selUser = document.getElementById('sel-user');
    if (selUser) {
      const roleLabel = { player: 'Jugador', coach: 'Líder', org_admin: 'Administrador' };
      const assignable = orgUsers.filter(u => u.role !== 'sys_admin');
      assignable.forEach(u => {
        const opt = document.createElement('option');
        opt.value = u.id;
        opt.textContent = `${u.preferred_name ?? u.id} (${roleLabel[u.role] ?? u.role})`;
        selUser.appendChild(opt);
      });
    }
  } catch (err) {
    loadEl?.classList.add('hidden');
    showGlobalError('No se pudieron cargar los usuarios. ' + err.message);
  }
}

function renderUserRow(user) {
  const roleLabels = {
    player:    'Jugador',
    coach:     'Líder',
    org_admin: 'Administrador',
    sys_admin: 'SysAdmin',
  };
  const roleBadge = {
    player:    'bg-blue-100 text-blue-700',
    coach:     'bg-yellow-100 text-yellow-700',
    org_admin: 'bg-green-100 text-green-700',
    sys_admin: 'bg-red-100 text-red-700',
  };
  const created = user.created_at
    ? new Date(user.created_at).toLocaleDateString('es-CO', { year: 'numeric', month: 'short', day: 'numeric' })
    : '—';

  return `
    <tr>
      <td class="px-4 py-3 font-medium text-gray-900">
        ${escapeHtml(user.preferred_name ?? 'Sin nombre')}
      </td>
      <td class="px-4 py-3">
        <span class="text-xs font-semibold px-2 py-0.5 rounded-full
                     ${roleBadge[user.role] ?? 'bg-gray-100 text-gray-600'}">
          ${roleLabels[user.role] ?? user.role}
        </span>
      </td>
      <td class="px-4 py-3 hidden sm:table-cell">
        <span class="text-xs ${user.is_active ? 'text-green-600' : 'text-red-500'}">
          ${user.is_active ? 'Activo' : 'Inactivo'}
        </span>
      </td>
      <td class="px-4 py-3 text-gray-400 text-xs hidden md:table-cell">${created}</td>
    </tr>
  `;
}

// ─── Experiencias disponibles (catálogo) ────────────
async function loadExperiences() {
  const { data, error } = await sb
    .from('experience_definitions')
    .select('id, slug, name, type')
    .eq('is_active', true)
    .order('name');

  if (!error && data) {
    experiences = data;
    const selExp = document.getElementById('sel-experience');
    if (selExp) {
      data.forEach(exp => {
        const opt = document.createElement('option');
        opt.value = exp.id;
        opt.textContent = exp.name ?? exp.slug;
        selExp.appendChild(opt);
      });
    }
  }
}

// ─── Asignaciones ────────────────────────────────────
async function renderAssignmentsList() {
  const listEl    = document.getElementById('assignments-list');
  const emptyEl   = document.getElementById('assignments-empty');
  const loadingEl = document.getElementById('assignments-loading');

  if (!listEl || listEl.children.length > 0) return; // ya renderizado

  try {
    const { data, error } = await sb
      .from('experience_assignments')
      .select(`
        id, status, due_at, assigned_at,
        profiles!user_id (preferred_name),
        experience_definitions!experience_id (name, slug)
      `)
      .eq('org_id', currentProfile.org_id)
      .order('assigned_at', { ascending: false });

    if (error) throw error;

    loadingEl?.classList.add('hidden');

    if (!data || data.length === 0) {
      emptyEl?.classList.remove('hidden');
      return;
    }

    listEl.innerHTML = data.map(renderAssignmentCard).join('');
    listEl.classList.remove('hidden');

  } catch (err) {
    loadingEl?.classList.add('hidden');
    showGlobalError('No se pudieron cargar las asignaciones. ' + err.message);
  }
}

function renderAssignmentCard(assignment) {
  const userName = assignment.profiles?.preferred_name ?? 'Usuario';
  const expName  = assignment.experience_definitions?.name ?? assignment.experience_definitions?.slug ?? 'Experiencia';
  const dueText  = assignment.due_at
    ? `Vence: ${formatInclusiveDueDate(assignment.due_at)}`
    : 'Sin fecha límite';
  const statusBadge = {
    assigned:    'bg-green-100 text-green-700',
    in_progress: 'bg-blue-100 text-blue-700',
    completed:   'bg-gray-100 text-gray-600',
    revoked:     'bg-red-100 text-red-600',
  };
  const statusLabel = {
    assigned:    'Asignada',
    in_progress: 'En progreso',
    completed:   'Completada',
    revoked:     'Revocada',
  };

  const { status, id } = assignment;
  const actionBtnBase = 'text-xs font-semibold px-2 py-0.5 rounded transition-colors focus:outline-none focus:ring-1';

  let actionBtns = '';
  if (status === 'assigned' || status === 'in_progress') {
    actionBtns += `
      <button type="button" data-action="revoke" data-id="${id}"
              class="${actionBtnBase} text-amber-600 hover:text-amber-800 focus:ring-amber-400">
        Revocar
      </button>`;
  }
  if (status === 'revoked') {
    actionBtns += `
      <button type="button" data-action="reopen" data-id="${id}"
              class="${actionBtnBase} text-green-600 hover:text-green-800 focus:ring-green-400">
        Reactivar
      </button>`;
  }
  if (status === 'assigned') {
    actionBtns += `
      <button type="button" data-action="remove" data-id="${id}"
              class="${actionBtnBase} text-red-500 hover:text-red-700 focus:ring-red-400">
        Eliminar sin iniciar
      </button>`;
  }

  return `
    <div class="bg-white rounded-xl border border-gray-200 px-5 py-4">
      <div class="flex items-center justify-between gap-4">
        <div class="min-w-0">
          <p class="font-semibold text-gray-900 text-sm truncate">${escapeHtml(userName)}</p>
          <p class="text-xs text-gray-500 mt-0.5">${escapeHtml(expName)} · ${dueText}</p>
        </div>
        <span class="shrink-0 text-xs font-semibold px-2 py-0.5 rounded-full
                     ${statusBadge[status] ?? 'bg-gray-100 text-gray-600'}">
          ${statusLabel[status] ?? status}
        </span>
      </div>
      <div class="flex items-center gap-3 mt-3 pt-3 border-t border-gray-100 justify-end">
        ${actionBtns}
      </div>
    </div>
  `;
}

function formatInclusiveDueDate(exclusiveDueAt) {
  const inclusiveInstant = new Date(new Date(exclusiveDueAt).getTime() - 1);
  return inclusiveInstant.toLocaleDateString('es-CO', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    timeZone: 'America/Bogota',
  });
}

// ─── Acciones sobre asignaciones ────────────────────

function setupAssignmentActions() {
  const listEl = document.getElementById('assignments-list');
  if (!listEl) return;

  listEl.addEventListener('click', async e => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;

    const { action, id } = btn.dataset;
    if (!id) return;

    if (action === 'remove') {
      if (!confirm('¿Eliminar esta asignación sin iniciar?')) return;
      await manageAssignment(id, 'remove');
    } else if (action === 'revoke') {
      await manageAssignment(id, 'revoke');
    } else if (action === 'reopen') {
      await manageAssignment(id, 'reactivate');
    }
  });
}

async function manageAssignment(id, action) {
  try {
    const { error } = await sb.rpc('manage_assignment', {
      p_assignment_id: id,
      p_action: action,
    });
    if (error) throw error;
    reloadAssignments();
  } catch (err) {
    showGlobalError(getErrorMessage(
      err,
      'No se pudo actualizar la asignación. Inténtalo de nuevo.',
    ));
  }
}

function reloadAssignments() {
  const listEl  = document.getElementById('assignments-list');
  const emptyEl = document.getElementById('assignments-empty');
  if (listEl)  { listEl.innerHTML = ''; listEl.classList.add('hidden'); }
  emptyEl?.classList.add('hidden');
  renderAssignmentsList();
}

// ─── Progreso (sesiones de la org) ──────────────────
async function loadProgress() {
  const statsEl   = document.getElementById('progress-stats');
  const tableEl   = document.getElementById('progress-table');
  const tbodyEl   = document.getElementById('progress-tbody');
  const emptyEl   = document.getElementById('progress-empty');

  if (tbodyEl && tbodyEl.children.length > 0) return; // ya cargado

  try {
    const { data, error } = await sb
      .from('experience_sessions')
      .select(`
        id, status, current_step, last_saved_at, completed_at,
        profiles!user_id (preferred_name),
        experience_versions!experience_version_id (
          experience_definitions!experience_id (name, slug)
        )
      `)
      .eq('org_id', currentProfile.org_id)
      .order('last_saved_at', { ascending: false, nullsFirst: false });

    if (error) throw error;

    // Calcular stats
    const sessions = data ?? [];
    const counts = {
      total:       sessions.length,
      completed:   sessions.filter(s => s.status === 'completed').length,
      in_progress: sessions.filter(s => s.status === 'in_progress').length,
      not_started: sessions.filter(s => s.status === 'not_started').length,
    };

    if (statsEl) {
      statsEl.innerHTML = [
        { value: counts.total,       label: 'Sesiones totales', color: 'text-gray-800' },
        { value: counts.completed,   label: 'Completadas',      color: 'text-green-600' },
        { value: counts.in_progress, label: 'En progreso',      color: 'text-blue-600' },
        { value: counts.not_started, label: 'Sin iniciar',      color: 'text-gray-400' },
      ].map(s => `
        <div class="bg-white rounded-xl border border-gray-200 p-5">
          <p class="text-3xl font-bold ${s.color}">${s.value}</p>
          <p class="text-xs text-gray-500 mt-1">${s.label}</p>
        </div>
      `).join('');
    }

    if (sessions.length === 0) {
      emptyEl?.classList.remove('hidden');
      return;
    }

    const statusMap = {
      not_started: { label: 'Sin iniciar',  cls: 'bg-gray-100 text-gray-500'   },
      in_progress: { label: 'En progreso',  cls: 'bg-blue-100 text-blue-600'   },
      paused:      { label: 'En pausa',     cls: 'bg-yellow-100 text-yellow-700' },
      completed:   { label: 'Completada',   cls: 'bg-green-100 text-green-700' },
      expired:     { label: 'Expirada',     cls: 'bg-red-100 text-red-600'     },
    };

    tbodyEl.innerHTML = sessions.map(s => {
      const badge   = statusMap[s.status] ?? statusMap.not_started;
      const name    = s.profiles?.preferred_name ?? '—';
      const expName = s.experience_versions?.experience_definitions?.name
                   ?? s.experience_versions?.experience_definitions?.slug
                   ?? '—';
      const tsRaw = s.completed_at ?? s.last_saved_at;
      const ts = tsRaw
        ? new Date(tsRaw).toLocaleString('es-CO', { dateStyle: 'short', timeStyle: 'short' })
        : '—';
      return `
        <tr>
          <td class="px-4 py-3 font-medium text-gray-900 text-sm">${escapeHtml(name)}</td>
          <td class="px-4 py-3 text-gray-600 text-sm">${escapeHtml(expName)}</td>
          <td class="px-4 py-3">
            <span class="text-xs font-semibold px-2 py-0.5 rounded-full ${badge.cls}">${badge.label}</span>
          </td>
          <td class="px-4 py-3 text-gray-400 text-xs hidden md:table-cell">${s.current_step ?? 0}</td>
          <td class="px-4 py-3 text-gray-400 text-xs hidden lg:table-cell">${ts}</td>
        </tr>
      `;
    }).join('');

    tableEl?.classList.remove('hidden');

  } catch (err) {
    showGlobalError('No se pudo cargar el progreso. ' + err.message);
  }
}

// ─── Modal: nueva asignación ─────────────────────────
function setupAssignmentModal() {
  const modal       = document.getElementById('modal-assignment');
  const btnOpen     = document.getElementById('btn-new-assignment');
  const btnCancel   = document.getElementById('btn-cancel-modal');
  const backdrop    = document.getElementById('modal-backdrop');
  const form        = document.getElementById('form-assignment');
  const errorEl     = document.getElementById('modal-error');
  const btnSubmit   = document.getElementById('btn-submit-assignment');

  if (!modal || !btnOpen) return;

  const openModal  = () => modal.classList.remove('hidden');
  const closeModal = () => {
    modal.classList.add('hidden');
    form.reset();
    errorEl?.classList.add('hidden');
  };

  btnOpen.addEventListener('click', openModal);
  btnCancel?.addEventListener('click', closeModal);
  backdrop?.addEventListener('click', closeModal);

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !modal.classList.contains('hidden')) closeModal();
  });

  form?.addEventListener('submit', async e => {
    e.preventDefault();
    errorEl?.classList.add('hidden');

    const userId = document.getElementById('sel-user')?.value;
    const expId  = document.getElementById('sel-experience')?.value;
    let due;

    try {
      due = buildOptionalDate({
        day: document.getElementById('sel-due-day')?.value,
        month: document.getElementById('sel-due-month')?.value,
        year: document.getElementById('sel-due-year')?.value,
      }, getBogotaTodayISO());
    } catch (dateError) {
      if (errorEl) {
        errorEl.textContent = getErrorMessage(dateError, 'La fecha límite no es válida.');
        errorEl.classList.remove('hidden');
      }
      return;
    }

    if (!userId || !expId) {
      if (errorEl) {
        errorEl.textContent = 'Selecciona un usuario y una experiencia.';
        errorEl.classList.remove('hidden');
      }
      return;
    }

    btnSubmit.disabled = true;
    btnSubmit.textContent = 'Asignando…';

    try {
      const { error } = await sb.rpc('assign_experience', {
        p_user_id: userId,
        p_experience_id: expId,
        p_due_date: due,
      });

      if (error) throw error;

      closeModal();
      // Limpiar cache de asignaciones para forzar recarga
      const listEl = document.getElementById('assignments-list');
      if (listEl) listEl.innerHTML = '';
      renderAssignmentsList();

    } catch (err) {
      if (errorEl) {
        errorEl.textContent = getErrorMessage(
          err,
          'No se pudo crear la asignación. Inténtalo de nuevo.',
        );
        errorEl.classList.remove('hidden');
      }
    } finally {
      btnSubmit.disabled = false;
      btnSubmit.textContent = 'Asignar';
    }
  });
}

function setupDueDateSelectors() {
  const daySelect = document.getElementById('sel-due-day');
  const monthSelect = document.getElementById('sel-due-month');
  const yearSelect = document.getElementById('sel-due-year');
  if (!daySelect || !monthSelect || !yearSelect) return;

  for (let day = 1; day <= 31; day++) {
    daySelect.add(new Option(String(day), String(day)));
  }

  const months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  months.forEach((month, index) => {
    monthSelect.add(new Option(month, String(index + 1)));
  });

  const currentYear = Number(getBogotaTodayISO().slice(0, 4));
  for (let year = currentYear; year <= currentYear + 5; year++) {
    yearSelect.add(new Option(String(year), String(year)));
  }
}

function getBogotaTodayISO() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

// ─── Modal: invitar jugador ──────────────────────────
function setupInviteModal() {
  const modal       = document.getElementById('modal-invite');
  const btnOpen     = document.getElementById('btn-invite-user');
  const btnCancel   = document.getElementById('btn-cancel-invite');
  const btnClose    = document.getElementById('btn-close-invite-success');
  const backdrop    = document.getElementById('modal-invite-backdrop');
  const form        = document.getElementById('form-invite');
  const errorEl     = document.getElementById('modal-invite-error');
  const btnSubmit   = document.getElementById('btn-submit-invite');
  const formState   = document.getElementById('invite-form-state');
  const successState = document.getElementById('invite-success-state');
  const successEmail = document.getElementById('invite-success-email');

  if (!modal || !btnOpen) return;

  const openModal = () => {
    formState?.classList.remove('hidden');
    successState?.classList.add('hidden');
    form?.reset();
    errorEl?.classList.add('hidden');
    modal.classList.remove('hidden');
    document.getElementById('inp-invite-email')?.focus();
  };

  const closeModal = () => {
    modal.classList.add('hidden');
    form?.reset();
    errorEl?.classList.add('hidden');
  };

  btnOpen.addEventListener('click', openModal);
  btnCancel?.addEventListener('click', closeModal);
  btnClose?.addEventListener('click', closeModal);
  backdrop?.addEventListener('click', closeModal);
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !modal.classList.contains('hidden')) closeModal();
  });

  form?.addEventListener('submit', async e => {
    e.preventDefault();
    errorEl?.classList.add('hidden');

    const email         = document.getElementById('inp-invite-email')?.value.trim();
    const preferred_name = document.getElementById('inp-invite-name')?.value.trim() || null;

    if (!email) {
      errorEl.textContent = 'El email es requerido.';
      errorEl.classList.remove('hidden');
      return;
    }

    btnSubmit.disabled = true;
    btnSubmit.textContent = 'Enviando…';

    try {
      const { data, error } = await sb.functions.invoke('invite-org-user', {
        body: {
          email,
          preferred_name,
          redirect_to: `${window.location.origin}/index.html`,
        },
      });

      if (error || data?.error) {
        const msg = data?.message ?? error?.message ?? 'No se pudo enviar la invitación.';
        errorEl.textContent = msg;
        errorEl.classList.remove('hidden');
        return;
      }

      // Mostrar estado de éxito
      formState?.classList.add('hidden');
      successState?.classList.remove('hidden');
      if (successEmail) successEmail.textContent = `Se envió la invitación a ${email}`;

      // Refrescar lista de usuarios (limpiar cache)
      orgUsers = [];
      const tbodyEl = document.getElementById('users-tbody');
      const tableEl = document.getElementById('users-table');
      if (tbodyEl) tbodyEl.innerHTML = '';
      tableEl?.classList.add('hidden');
      document.getElementById('users-loading')?.classList.remove('hidden');
      await loadUsers();

    } catch (err) {
      errorEl.textContent = 'Error de conexión. Inténtalo de nuevo.';
      errorEl.classList.remove('hidden');
    } finally {
      btnSubmit.disabled = false;
      btnSubmit.textContent = 'Enviar invitación';
    }
  });
}

// ─── Logout ─────────────────────────────────────────
function setupLogout() {
  document.getElementById('btn-logout')?.addEventListener('click', logout);
}

// ─── Utilidades ─────────────────────────────────────
function showGlobalError(msg) {
  const el = document.getElementById('error-global');
  if (el) {
    el.textContent = msg;
    el.classList.remove('hidden');
  }
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
