// =====================================================
// sysadmin.js — Panel del Sistema (SysAdmin)
// HU-CA-008: Panel de administración global del sistema
// =====================================================

import { sb, requireAuth, logout } from './auth.js';
import { ROUTES } from './config.js';

// ─── Estado ─────────────────────────────────────────
let currentProfile = null;

// Banco de Preguntas
const EXPEDICION_BASE_ID = 'b0000000-0000-0000-0000-000000000001';
const DIFF_LABELS = { 1: 'Fácil', 2: 'Medio', 3: 'Difícil' };
let bankReady            = false;
let viewingQuestionId    = null;
let viewingQuestionTitle = null;

// ─── Inicialización ─────────────────────────────────
export async function initSysAdmin() {
  currentProfile = await requireAuth();
  if (!currentProfile) return;

  // Guardia de rol — defensa en profundidad
  if (currentProfile.role !== 'sys_admin') {
    window.location.href = ROUTES.hub;
    return;
  }

  renderHeader();
  setupTabs();
  setupLogout();
  setupPasswordModal();

  // La pestaña Overview carga al iniciar
  await loadOverview();
}

// ─── Header ─────────────────────────────────────────
function renderHeader() {
  const nameEl = document.getElementById('user-name');
  if (nameEl) nameEl.textContent = currentProfile.preferred_name ?? 'Sistema';
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
  document.querySelectorAll('.tab-btn').forEach(btn => {
    const isActive = btn.dataset.tab === tabName;
    btn.setAttribute('aria-selected', String(isActive));
    btn.classList.toggle('border-gray-900',      isActive);
    btn.classList.toggle('text-gray-900',         isActive);
    btn.classList.toggle('border-transparent',    !isActive);
    btn.classList.toggle('text-gray-500',         !isActive);
  });

  ['overview', 'orgs', 'users', 'catalog', 'audit', 'bank', 'fabrica'].forEach(id => {
    const panel = document.getElementById(`tab-${id}`);
    if (panel) panel.classList.toggle('hidden', id !== tabName);
  });

  // Carga diferida por tab
  if (tabName === 'orgs')     loadOrganizations();
  if (tabName === 'users')    loadSystemUsers();
  if (tabName === 'catalog')  loadCatalog();
  if (tabName === 'audit')    loadAuditLog();
  if (tabName === 'bank')     initQuestionBank();
  if (tabName === 'fabrica')  initFabrica();
}

async function loadSystemUsers() {
  const loading = document.getElementById('system-users-loading');
  const list = document.getElementById('system-users-list');
  if (!list || list.children.length) return;

  const { data, error } = await sb
    .from('profiles')
    .select('id, preferred_name, role, is_active, organizations(name)')
    .order('preferred_name');
  loading?.classList.add('hidden');
  if (error) {
    showGlobalError('No se pudieron cargar los usuarios.');
    return;
  }

  list.innerHTML = data.map(user => `
    <article class="bg-white border border-gray-200 rounded-xl p-4 flex items-center gap-4">
      <div class="flex-1">
        <p class="font-semibold text-gray-900">${escapeHtml(user.preferred_name ?? 'Sin nombre')}</p>
        <p class="text-xs text-gray-500">${escapeHtml(user.organizations?.name ?? '—')} · ${escapeHtml(user.role)}</p>
      </div>
      <button type="button" data-password-user="${user.id}"
              data-password-name="${escapeHtml(user.preferred_name ?? 'Usuario')}"
              class="text-sm font-semibold text-gray-700 border border-gray-300 rounded-lg px-3 py-2 hover:bg-gray-50">
        Cambiar contraseña
      </button>
    </article>
  `).join('');
  list.classList.remove('hidden');
}

function setupPasswordModal() {
  const modal = document.getElementById('modal-password');
  const form = document.getElementById('form-password');
  const close = () => {
    modal?.classList.add('hidden');
    form?.reset();
    document.getElementById('password-error')?.classList.add('hidden');
    document.getElementById('password-success')?.classList.add('hidden');
  };

  document.getElementById('system-users-list')?.addEventListener('click', event => {
    const button = event.target.closest('[data-password-user]');
    if (!button) return;
    document.getElementById('password-target-id').value = button.dataset.passwordUser;
    document.getElementById('password-target-name').textContent =
      `Usuario: ${button.dataset.passwordName}`;
    modal?.classList.remove('hidden');
  });
  document.getElementById('btn-cancel-password')?.addEventListener('click', close);
  document.getElementById('modal-password-backdrop')?.addEventListener('click', close);

  form?.addEventListener('submit', async event => {
    event.preventDefault();
    const password = document.getElementById('new-password').value;
    const confirmation = document.getElementById('confirm-password').value;
    const errorEl = document.getElementById('password-error');
    const successEl = document.getElementById('password-success');
    errorEl.classList.add('hidden');
    successEl.classList.add('hidden');
    if (password !== confirmation) {
      errorEl.textContent = 'Las contraseñas no coinciden.';
      errorEl.classList.remove('hidden');
      return;
    }

    const submit = document.getElementById('btn-submit-password');
    submit.disabled = true;
    const { data, error } = await sb.functions.invoke('sysadmin-set-password', {
      body: {
        user_id: document.getElementById('password-target-id').value,
        new_password: password,
      },
    });
    submit.disabled = false;
    if (error || !data?.updated) {
      errorEl.textContent = data?.message ?? 'No se pudo cambiar la contraseña.';
      errorEl.classList.remove('hidden');
      return;
    }
    form.reset();
    successEl.textContent = 'Contraseña actualizada y evento auditado.';
    successEl.classList.remove('hidden');
  });
}

// ─── Resumen (Overview) ──────────────────────────────
async function loadOverview() {
  await Promise.all([
    loadStats(),
    loadRecentOrgs(),
    loadRecentAuditEvents(),
  ]);
}

async function loadStats() {
  const gridEl = document.getElementById('stats-grid');
  if (!gridEl) return;

  try {
    // Queries paralelas para las métricas
    const [
      { count: totalOrgs  },
      { count: totalUsers },
      { count: totalSessions },
      { count: todayEvents },
    ] = await Promise.all([
      sb.from('organizations').select('id', { count: 'exact', head: true }),
      sb.from('profiles').select('id', { count: 'exact', head: true }),
      sb.from('experience_sessions').select('id', { count: 'exact', head: true }),
      sb.from('audit_events')
        .select('id', { count: 'exact', head: true })
        .gte('created_at', new Date(new Date().setHours(0, 0, 0, 0)).toISOString()),
    ]);

    gridEl.innerHTML = [
      { value: totalOrgs     ?? 0, label: 'Organizaciones',         color: 'text-gray-800' },
      { value: totalUsers    ?? 0, label: 'Usuarios registrados',   color: 'text-ev-green' },
      { value: totalSessions ?? 0, label: 'Sesiones en el sistema', color: 'text-blue-600'  },
      { value: todayEvents   ?? 0, label: 'Eventos hoy',            color: 'text-ev-gold'   },
    ].map(s => `
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <p class="text-3xl font-bold ${s.color}">${s.value}</p>
        <p class="text-xs text-gray-500 mt-1">${s.label}</p>
      </div>
    `).join('');

  } catch (err) {
    if (gridEl) gridEl.innerHTML = `<p class="text-red-500 text-sm col-span-4">Error cargando métricas: ${err.message}</p>`;
  }
}

async function loadRecentOrgs() {
  const el = document.getElementById('recent-orgs');
  if (!el) return;

  try {
    const { data, error } = await sb
      .from('organizations')
      .select('id, name, slug, is_active, created_at')
      .order('created_at', { ascending: false })
      .limit(5);

    if (error) throw error;

    if (!data || data.length === 0) {
      el.innerHTML = '<p class="p-6 text-center text-sm text-gray-400">Sin organizaciones registradas.</p>';
      return;
    }

    el.innerHTML = `
      <div class="divide-y divide-gray-100">
        ${data.map(org => `
          <div class="px-5 py-3 flex items-center justify-between">
            <div>
              <p class="text-sm font-semibold text-gray-900">${escapeHtml(org.name)}</p>
              <p class="text-xs text-gray-400">${escapeHtml(org.slug)}</p>
            </div>
            <span class="text-xs ${org.is_active ? 'text-green-600' : 'text-red-500'}">
              ${org.is_active ? 'Activa' : 'Inactiva'}
            </span>
          </div>
        `).join('')}
      </div>
    `;
  } catch (err) {
    el.innerHTML = `<p class="p-6 text-sm text-red-500">Error: ${escapeHtml(err.message)}</p>`;
  }
}

async function loadRecentAuditEvents() {
  const el = document.getElementById('recent-audit');
  if (!el) return;

  try {
    const { data, error } = await sb
      .from('audit_events')
      .select('id, action, resource_type, org_id, created_at, profiles(role, preferred_name)')
      .order('created_at', { ascending: false })
      .limit(8);

    if (error) throw error;

    if (!data || data.length === 0) {
      el.innerHTML = '<p class="p-6 text-center text-sm text-gray-400">Sin eventos registrados aún.</p>';
      return;
    }

    el.innerHTML = `
      <div class="divide-y divide-gray-100">
        ${data.map(ev => renderAuditRow(ev)).join('')}
      </div>
    `;
  } catch (err) {
    el.innerHTML = `<p class="p-6 text-sm text-red-500">Error: ${escapeHtml(err.message)}</p>`;
  }
}

// ─── Organizaciones ──────────────────────────────────
async function loadOrganizations() {
  const loadingEl = document.getElementById('orgs-loading');
  const tableEl   = document.getElementById('orgs-table');
  const tbodyEl   = document.getElementById('orgs-tbody');

  if (tbodyEl && tbodyEl.children.length > 0) return;

  try {
    const { data, error } = await sb
      .from('organizations')
      .select('id, name, slug, is_active, created_at')
      .order('created_at', { ascending: false });

    if (error) throw error;

    loadingEl?.classList.add('hidden');

    if (!data || data.length === 0) {
      if (tbodyEl) tbodyEl.innerHTML = '<tr><td colspan="4" class="px-4 py-8 text-center text-gray-400 text-sm">Sin organizaciones.</td></tr>';
      tableEl?.classList.remove('hidden');
      return;
    }

    tbodyEl.innerHTML = data.map(org => {
      const created = org.created_at
        ? new Date(org.created_at).toLocaleDateString('es-CO', { year: 'numeric', month: 'short', day: 'numeric' })
        : '—';
      return `
        <tr>
          <td class="px-4 py-3 font-semibold text-gray-900 text-sm">${escapeHtml(org.name)}</td>
          <td class="px-4 py-3 text-gray-500 text-sm font-mono">${escapeHtml(org.slug)}</td>
          <td class="px-4 py-3">
            <span class="text-xs font-semibold ${org.is_active ? 'text-green-600' : 'text-red-500'}">
              ${org.is_active ? 'Activa' : 'Inactiva'}
            </span>
          </td>
          <td class="px-4 py-3 text-gray-400 text-xs hidden md:table-cell">${created}</td>
        </tr>
      `;
    }).join('');

    tableEl?.classList.remove('hidden');

  } catch (err) {
    loadingEl?.classList.add('hidden');
    showGlobalError('Error cargando organizaciones: ' + err.message);
  }
}

// ─── Catálogo de experiencias ─────────────────────────
async function loadCatalog() {
  const loadingEl = document.getElementById('catalog-loading');
  const listEl    = document.getElementById('catalog-list');
  const emptyEl   = document.getElementById('catalog-empty');

  if (listEl && listEl.children.length > 0) return;

  try {
    const { data, error } = await sb
      .from('experience_definitions')
      .select(`
        id, slug, name, description, type, is_active,
        experience_versions (id, version, status, created_at)
      `)
      .order('created_at');

    if (error) throw error;

    loadingEl?.classList.add('hidden');

    if (!data || data.length === 0) {
      emptyEl?.classList.remove('hidden');
      return;
    }

    const typeLabels = {
      exploration: 'Exploración conductual',
      simulation:  'Simulación empresarial',
    };
    const statusBadge = {
      draft:     'bg-gray-100 text-gray-500',
      pilot:     'bg-yellow-100 text-yellow-700',
      published: 'bg-green-100 text-green-700',
      retired:   'bg-red-100 text-red-500',
    };

    listEl.innerHTML = data.map(exp => {
      const versions = exp.experience_versions ?? [];
      const publishedVersions = versions.filter(v => v.status === 'published');
      return `
        <div class="bg-white rounded-xl border border-gray-200 p-5">
          <div class="flex items-start justify-between mb-2">
            <div>
              <h3 class="font-bold text-gray-900">${escapeHtml(exp.name ?? exp.slug)}</h3>
              <p class="text-xs text-gray-400 font-mono mt-0.5">${escapeHtml(exp.slug)}</p>
            </div>
            <span class="text-xs font-semibold px-2 py-0.5 rounded-full
                         ${exp.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}">
              ${exp.is_active ? 'Activa' : 'Inactiva'}
            </span>
          </div>
          ${exp.description ? `<p class="text-sm text-gray-500 mb-3">${escapeHtml(exp.description)}</p>` : ''}
          <div class="flex flex-wrap gap-2 mt-3">
            <span class="text-xs bg-blue-50 text-blue-600 px-2 py-0.5 rounded-full">
              ${typeLabels[exp.type] ?? exp.type}
            </span>
            <span class="text-xs text-gray-400">
              ${versions.length} versión(es) · ${publishedVersions.length} publicada(s)
            </span>
          </div>
          ${versions.length > 0 ? `
            <div class="mt-3 pt-3 border-t border-gray-100 flex flex-wrap gap-2">
              ${versions.slice(0, 5).map(v => `
                <span class="text-xs font-mono px-2 py-0.5 rounded-full
                             ${statusBadge[v.status] ?? 'bg-gray-100 text-gray-500'}">
                  v${escapeHtml(v.version)} · ${v.status}
                </span>
              `).join('')}
            </div>
          ` : ''}
        </div>
      `;
    }).join('');

    listEl.classList.remove('hidden');

  } catch (err) {
    loadingEl?.classList.add('hidden');
    showGlobalError('Error cargando catálogo: ' + err.message);
  }
}

// ─── Registro de auditoría ────────────────────────────
async function loadAuditLog() {
  const loadingEl = document.getElementById('audit-loading');
  const tableEl   = document.getElementById('audit-table');
  const tbodyEl   = document.getElementById('audit-tbody');
  const emptyEl   = document.getElementById('audit-empty');

  if (tbodyEl && tbodyEl.children.length > 0) return;

  try {
    const { data, error } = await sb
      .from('audit_events')
      .select('id, action, resource_type, org_id, created_at, profiles(role, preferred_name)')
      .order('created_at', { ascending: false })
      .limit(200);

    if (error) throw error;

    loadingEl?.classList.add('hidden');

    if (!data || data.length === 0) {
      emptyEl?.classList.remove('hidden');
      return;
    }

    tbodyEl.innerHTML = data.map(renderAuditTableRow).join('');
    tableEl?.classList.remove('hidden');

  } catch (err) {
    loadingEl?.classList.add('hidden');
    showGlobalError('Error cargando auditoría: ' + err.message);
  }
}

// ─── Helpers compartidos ──────────────────────────────
function renderAuditRow(ev) {
  const ts = ev.created_at
    ? new Date(ev.created_at).toLocaleString('es-CO', { dateStyle: 'short', timeStyle: 'short' })
    : '—';
  const roleLabel = {
    player:    'Jugador',
    coach:     'Líder',
    org_admin: 'Admin',
    sys_admin: 'Sistema',
  };
  const actor    = ev.profiles?.preferred_name ?? '—';
  const roleName = roleLabel[ev.profiles?.role] ?? ev.profiles?.role ?? '—';
  const resource = ev.resource_type ? ` · ${escapeHtml(ev.resource_type)}` : '';
  return `
    <div class="px-5 py-3 flex items-center gap-4 text-sm">
      <span class="font-mono text-xs text-gray-700 min-w-[14rem]">${escapeHtml(ev.action ?? '—')}${resource}</span>
      <span class="text-xs text-gray-500">${escapeHtml(actor)}</span>
      <span class="text-xs text-gray-400">${escapeHtml(roleName)}</span>
      <span class="text-xs text-gray-300 hidden lg:block ml-auto">${ts}</span>
    </div>
  `;
}

function renderAuditTableRow(ev) {
  const ts = ev.created_at
    ? new Date(ev.created_at).toLocaleString('es-CO', { dateStyle: 'short', timeStyle: 'short' })
    : '—';
  const roleLabel = { player: 'Jugador', coach: 'Líder', org_admin: 'Admin', sys_admin: 'Sistema' };
  const actor    = ev.profiles?.preferred_name ?? '—';
  const roleName = roleLabel[ev.profiles?.role] ?? ev.profiles?.role ?? '—';
  const action   = ev.resource_type
    ? `${escapeHtml(ev.action)} · ${escapeHtml(ev.resource_type)}`
    : escapeHtml(ev.action ?? '—');
  return `
    <tr class="hover:bg-gray-50 transition-colors">
      <td class="px-4 py-3 font-mono text-xs text-gray-700">${action}</td>
      <td class="px-4 py-3 text-sm text-gray-500 hidden sm:table-cell">${escapeHtml(actor)}</td>
      <td class="px-4 py-3 text-xs text-gray-400">${escapeHtml(roleName)}</td>
      <td class="px-4 py-3 text-xs text-gray-300 hidden md:table-cell">${ts}</td>
    </tr>
  `;
}

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

// ─── Banco de Preguntas ──────────────────────────────

function initQuestionBank() {
  if (bankReady) return;
  bankReady = true;

  // Sub-tabs internos
  document.querySelectorAll('.bank-tab-btn').forEach(btn =>
    btn.addEventListener('click', () => switchBankTab(btn.dataset.bankTab)));

  // Botón nueva pregunta / nueva opción (context-aware según vista activa)
  document.getElementById('btn-new-question')
    ?.addEventListener('click', () => {
      if (viewingQuestionId) {
        openOptionModal(null, viewingQuestionId);
      } else {
        openQuestionModal(null);
      }
    });
  document.getElementById('btn-cancel-question')
    ?.addEventListener('click', closeQuestionModal);
  document.getElementById('form-question')
    ?.addEventListener('submit', e => { e.preventDefault(); saveQuestion(); });
  document.getElementById('modal-question-backdrop')
    ?.addEventListener('click', closeQuestionModal);

  // Modal opción
  document.getElementById('btn-cancel-option')
    ?.addEventListener('click', closeOptionModal);
  document.getElementById('form-option')
    ?.addEventListener('submit', e => { e.preventDefault(); saveOption(); });
  document.getElementById('modal-option-backdrop')
    ?.addEventListener('click', closeOptionModal);

  // Suma DISC en tiempo real
  ['opt-disc-d','opt-disc-i','opt-disc-s','opt-disc-c'].forEach(id =>
    document.getElementById(id)?.addEventListener('input', updateDiscSum));

  // Ensamblar versión
  document.getElementById('btn-assemble')
    ?.addEventListener('click', assembleVersion);

  // Delegación de eventos sobre la lista dinámica de preguntas/opciones
  document.getElementById('questions-list')
    ?.addEventListener('click', handleQuestionsListClick);

  // Cargas iniciales
  loadQuestions();
  loadCompositions();
  loadVersions();
}

function switchBankTab(name) {
  document.querySelectorAll('.bank-tab-btn').forEach(btn => {
    const active = btn.dataset.bankTab === name;
    btn.classList.toggle('border-gray-900',     active);
    btn.classList.toggle('text-gray-900',        active);
    btn.classList.toggle('border-transparent',  !active);
    btn.classList.toggle('text-gray-500',       !active);
  });
  document.querySelectorAll('.bank-tab-content').forEach(panel =>
    panel.classList.add('hidden'));
  document.getElementById(`bank-${name}`)?.classList.remove('hidden');
}

// ── Delegación de eventos ────────────────────────────

function handleQuestionsListClick(e) {
  const btn = e.target.closest('button[data-action]');
  if (!btn) return;
  const { action, id, extra, qid } = btn.dataset;
  switch (action) {
    case 'edit-q':      editQuestion(id);                        break;
    case 'view-opts':   loadOptionsView(id, extra);              break;
    case 'toggle-q':    toggleQuestion(id, extra === 'true');    break;
    case 'back-qs':     exitOptionsView();                       break;
    case 'edit-opt':    editOption(id, qid);                     break;
    case 'toggle-opt':  toggleOption(id, extra === 'true', qid); break;
    case 'new-opt':     openOptionModal(null, id);               break;
  }
}

// ── Lista de preguntas ───────────────────────────────

async function loadQuestions() {
  const el = document.getElementById('questions-list');
  if (!el) return;
  el.innerHTML = '<p class="text-gray-400 text-sm">Cargando…</p>';

  try {
    const { data, error } = await sb
      .from('questions')
      .select('id, title, text, difficulty, avg_time_secs, is_active, question_options(count)')
      .order('title');

    if (error) throw error;

    if (!data || data.length === 0) {
      el.innerHTML = '<p class="text-gray-400 text-sm">No hay preguntas. Crea la primera.</p>';
      return;
    }

    el.innerHTML = data.map(q => {
      const optCount = q.question_options?.[0]?.count ?? 0;
      const diffLabel = DIFF_LABELS[q.difficulty] ?? q.difficulty;
      return `
        <div class="bg-white border border-gray-200 rounded-xl p-4 flex items-start gap-3">
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-gray-900 text-sm">${escapeHtml(q.title)}</p>
            <p class="text-xs text-gray-400 mt-0.5 line-clamp-2">${escapeHtml(q.text)}</p>
            <div class="flex gap-3 mt-1.5">
              <span class="text-xs text-gray-400">${diffLabel}</span>
              <span class="text-xs text-gray-400">~${q.avg_time_secs}s</span>
              <span class="text-xs ${q.is_active ? 'text-green-600' : 'text-gray-400'}">
                ${q.is_active ? 'Activa' : 'Inactiva'}
              </span>
            </div>
          </div>
          <div class="flex gap-2 shrink-0 flex-wrap justify-end">
            <button type="button" data-action="edit-q" data-id="${q.id}"
                    class="text-xs px-2.5 py-1 rounded border border-gray-200 hover:bg-gray-50">
              Editar
            </button>
            <button type="button" data-action="view-opts" data-id="${q.id}" data-extra="${escapeHtml(q.title)}"
                    class="text-xs px-2.5 py-1 rounded border border-blue-200 text-blue-600 hover:bg-blue-50">
              Opciones (${optCount})
            </button>
            <button type="button" data-action="toggle-q" data-id="${q.id}" data-extra="${!q.is_active}"
                    class="text-xs px-2.5 py-1 rounded border ${q.is_active
                      ? 'border-red-200 text-red-500 hover:bg-red-50'
                      : 'border-green-200 text-green-600 hover:bg-green-50'}">
              ${q.is_active ? 'Ocultar' : 'Activar'}
            </button>
          </div>
        </div>
      `;
    }).join('');

  } catch (err) {
    el.innerHTML = `<p class="text-red-500 text-sm">Error: ${escapeHtml(err.message)}</p>`;
  }
}

// ── Vista de opciones de una pregunta ────────────────

async function loadOptionsView(questionId, questionTitle) {
  viewingQuestionId    = questionId;
  viewingQuestionTitle = questionTitle;

  // Actualizar cabecera y botón de la sección
  const headEl = document.querySelector('#bank-questions h2');
  if (headEl) headEl.textContent = `Opciones — ${questionTitle}`;

  const btnNew = document.getElementById('btn-new-question');
  if (btnNew) btnNew.textContent = '+ Nueva opción';

  const el = document.getElementById('questions-list');
  if (!el) return;
  el.innerHTML = '<p class="text-gray-400 text-sm">Cargando opciones…</p>';

  try {
    const { data, error } = await sb
      .from('question_options')
      .select('id, text, feedback, disc_d, disc_i, disc_s, disc_c, sort_order, is_active')
      .eq('question_id', questionId)
      .order('sort_order');

    if (error) throw error;

    const optRows = (!data || data.length === 0)
      ? '<p class="text-gray-400 text-sm">Sin opciones. Usa "+ Nueva opción" para agregar.</p>'
      : data.map(opt => `
          <div class="bg-white border border-gray-200 rounded-xl p-4 flex items-start gap-3">
            <div class="flex-1 min-w-0">
              <p class="text-sm text-gray-900 line-clamp-3">${escapeHtml(opt.text)}</p>
              <div class="flex flex-wrap gap-3 mt-1.5 text-xs">
                <span class="text-red-500 font-mono">D:${opt.disc_d}</span>
                <span class="text-yellow-600 font-mono">I:${opt.disc_i}</span>
                <span class="text-green-600 font-mono">S:${opt.disc_s}</span>
                <span class="text-blue-600 font-mono">C:${opt.disc_c}</span>
                <span class="text-gray-400">orden:${opt.sort_order}</span>
                <span class="${opt.is_active ? 'text-green-600' : 'text-gray-400'}">
                  ${opt.is_active ? 'Activa' : 'Inactiva'}
                </span>
              </div>
              ${opt.feedback ? `<p class="text-xs text-gray-400 italic mt-1 line-clamp-1">${escapeHtml(opt.feedback)}</p>` : ''}
            </div>
            <div class="flex gap-2 shrink-0">
              <button type="button" data-action="edit-opt" data-id="${opt.id}" data-qid="${questionId}"
                      class="text-xs px-2.5 py-1 rounded border border-gray-200 hover:bg-gray-50">
                Editar
              </button>
              <button type="button" data-action="toggle-opt" data-id="${opt.id}" data-extra="${!opt.is_active}" data-qid="${questionId}"
                      class="text-xs px-2.5 py-1 rounded border ${opt.is_active
                        ? 'border-red-200 text-red-500 hover:bg-red-50'
                        : 'border-green-200 text-green-600 hover:bg-green-50'}">
                ${opt.is_active ? 'Ocultar' : 'Activar'}
              </button>
            </div>
          </div>
        `).join('');

    el.innerHTML = `
      <button type="button" data-action="back-qs"
              class="text-sm text-ev-green hover:underline flex items-center gap-1 mb-3">
        ← Volver a preguntas
      </button>
      ${optRows}
    `;

  } catch (err) {
    el.innerHTML = `
      <button type="button" data-action="back-qs"
              class="text-sm text-ev-green hover:underline flex items-center gap-1 mb-3">
        ← Volver a preguntas
      </button>
      <p class="text-red-500 text-sm">Error: ${escapeHtml(err.message)}</p>
    `;
  }
}

function exitOptionsView() {
  viewingQuestionId    = null;
  viewingQuestionTitle = null;

  const headEl = document.querySelector('#bank-questions h2');
  if (headEl) headEl.textContent = 'Preguntas del banco';

  const btnNew = document.getElementById('btn-new-question');
  if (btnNew) btnNew.textContent = '+ Nueva pregunta';

  loadQuestions();
}

// ── Composición del reto ─────────────────────────────

async function loadCompositions() {
  const el = document.getElementById('compositions-list');
  if (!el) return;
  el.innerHTML = '<p class="text-gray-400 text-sm">Cargando…</p>';

  try {
    const { data, error } = await sb
      .from('reto_compositions')
      .select('id, sort_order, is_active, questions(id, title, difficulty)')
      .eq('experience_id', EXPEDICION_BASE_ID)
      .order('sort_order');

    if (error) throw error;

    if (!data || data.length === 0) {
      el.innerHTML = '<p class="text-gray-400 text-sm">Sin preguntas en la composición.</p>';
      return;
    }

    el.innerHTML = data.map(rc => `
      <div class="flex items-center gap-3 bg-white border border-gray-200 rounded-xl px-4 py-3">
        <span class="text-sm font-mono text-gray-400 w-6 text-right shrink-0">${rc.sort_order}</span>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-semibold text-gray-900 truncate">${escapeHtml(rc.questions?.title ?? '—')}</p>
          <p class="text-xs text-gray-400">${DIFF_LABELS[rc.questions?.difficulty] ?? '—'}</p>
        </div>
        <span class="text-xs shrink-0 ${rc.is_active ? 'text-green-600' : 'text-gray-400'}">
          ${rc.is_active ? 'Incluida' : 'Excluida'}
        </span>
      </div>
    `).join('');

  } catch (err) {
    el.innerHTML = `<p class="text-red-500 text-sm">Error: ${escapeHtml(err.message)}</p>`;
  }
}

// ── Versiones publicadas ──────────────────────────────

async function loadVersions() {
  const el = document.getElementById('versions-list');
  if (!el) return;
  el.innerHTML = '<p class="text-sm text-gray-400">Cargando…</p>';

  try {
    const { data, error } = await sb
      .from('experience_versions')
      .select('id, version, schema_version, scoring_version, status, created_at')
      .eq('experience_id', EXPEDICION_BASE_ID)
      .order('created_at', { ascending: false })
      .limit(10);

    if (error) throw error;

    if (!data || data.length === 0) {
      el.innerHTML = '<p class="text-sm text-gray-400">Sin versiones publicadas aún.</p>';
      return;
    }

    const statusColor = {
      published: 'bg-green-100 text-green-700',
      draft:     'bg-gray-100 text-gray-500',
      retired:   'bg-red-100 text-red-500',
      pilot:     'bg-yellow-100 text-yellow-700',
    };

    el.innerHTML = data.map(v => {
      const ts = v.created_at
        ? new Date(v.created_at).toLocaleString('es-CO', { dateStyle: 'short', timeStyle: 'short' })
        : '—';
      return `
        <div class="flex items-center gap-3 py-2 border-b border-gray-100 last:border-0">
          <span class="font-mono text-sm text-gray-800 font-semibold">v${escapeHtml(v.version)}</span>
          <span class="text-xs px-2 py-0.5 rounded-full ${statusColor[v.status] ?? 'bg-gray-100 text-gray-500'}">
            ${v.status}
          </span>
          <span class="text-xs text-gray-400">schema ${v.schema_version}</span>
          <span class="text-xs text-gray-300 ml-auto">${ts}</span>
        </div>
      `;
    }).join('');

  } catch (err) {
    el.innerHTML = `<p class="text-sm text-red-500">Error: ${escapeHtml(err.message)}</p>`;
  }
}

// ── Modal: pregunta ──────────────────────────────────

function openQuestionModal(question) {
  document.getElementById('modal-q-title').textContent =
    question ? 'Editar pregunta' : 'Nueva pregunta';
  document.getElementById('q-id').value          = question?.id             ?? '';
  document.getElementById('q-title').value       = question?.title          ?? '';
  document.getElementById('q-text').value        = question?.text           ?? '';
  document.getElementById('q-difficulty').value  = question?.difficulty     ?? 2;
  document.getElementById('q-time').value        = question?.avg_time_secs  ?? 60;
  document.getElementById('q-notes').value       = question?.context_notes  ?? '';
  document.getElementById('modal-q-error').classList.add('hidden');
  document.getElementById('modal-question').classList.remove('hidden');
  document.getElementById('q-title').focus();
}

function closeQuestionModal() {
  document.getElementById('modal-question').classList.add('hidden');
}

async function saveQuestion() {
  const qId   = document.getElementById('q-id').value;
  const errEl = document.getElementById('modal-q-error');
  errEl.classList.add('hidden');

  const payload = {
    title:         document.getElementById('q-title').value.trim(),
    text:          document.getElementById('q-text').value.trim(),
    difficulty:    parseInt(document.getElementById('q-difficulty').value, 10),
    avg_time_secs: parseInt(document.getElementById('q-time').value, 10),
    context_notes: document.getElementById('q-notes').value.trim() || null,
  };

  if (!payload.title || !payload.text) {
    errEl.textContent = 'Título y texto del escenario son obligatorios.';
    errEl.classList.remove('hidden');
    return;
  }

  try {
    let error;
    if (qId) {
      ({ error } = await sb.from('questions').update(payload).eq('id', qId));
    } else {
      ({ error } = await sb.from('questions').insert({ ...payload, created_by: currentProfile.id }));
    }
    if (error) throw error;
    closeQuestionModal();
    loadQuestions();
    loadCompositions();
  } catch (err) {
    errEl.textContent = 'Error guardando: ' + err.message;
    errEl.classList.remove('hidden');
  }
}

// ── Modal: opción ─────────────────────────────────────

function openOptionModal(option, questionId) {
  document.getElementById('modal-opt-title').textContent =
    option ? 'Editar opción' : 'Nueva opción';
  document.getElementById('opt-id').value          = option?.id          ?? '';
  document.getElementById('opt-question-id').value = questionId ?? option?.question_id ?? '';
  document.getElementById('opt-text').value        = option?.text        ?? '';
  document.getElementById('opt-feedback').value    = option?.feedback    ?? '';
  document.getElementById('opt-disc-d').value      = option?.disc_d      ?? 0.25;
  document.getElementById('opt-disc-i').value      = option?.disc_i      ?? 0.25;
  document.getElementById('opt-disc-s').value      = option?.disc_s      ?? 0.25;
  document.getElementById('opt-disc-c').value      = option?.disc_c      ?? 0.25;
  document.getElementById('opt-sort-order').value  = option?.sort_order  ?? 0;
  document.getElementById('modal-opt-error').classList.add('hidden');
  updateDiscSum();
  document.getElementById('modal-option').classList.remove('hidden');
  document.getElementById('opt-text').focus();
}

function closeOptionModal() {
  document.getElementById('modal-option').classList.add('hidden');
}

function updateDiscSum() {
  const d = parseFloat(document.getElementById('opt-disc-d').value) || 0;
  const i = parseFloat(document.getElementById('opt-disc-i').value) || 0;
  const s = parseFloat(document.getElementById('opt-disc-s').value) || 0;
  const c = parseFloat(document.getElementById('opt-disc-c').value) || 0;
  const sum  = d + i + s + c;
  const ok   = Math.abs(sum - 1.0) < 0.01;
  const el   = document.getElementById('disc-sum-display');
  if (el) {
    el.textContent = `Suma: ${sum.toFixed(2)}`;
    el.className   = `text-xs text-center mt-1 ${ok ? 'text-green-600' : 'text-red-500 font-semibold'}`;
  }
}

async function saveOption() {
  const optId      = document.getElementById('opt-id').value;
  const questionId = document.getElementById('opt-question-id').value;
  const errEl      = document.getElementById('modal-opt-error');
  errEl.classList.add('hidden');

  const disc_d = parseFloat(document.getElementById('opt-disc-d').value) || 0;
  const disc_i = parseFloat(document.getElementById('opt-disc-i').value) || 0;
  const disc_s = parseFloat(document.getElementById('opt-disc-s').value) || 0;
  const disc_c = parseFloat(document.getElementById('opt-disc-c').value) || 0;
  const sum    = disc_d + disc_i + disc_s + disc_c;

  if (Math.abs(sum - 1.0) >= 0.01) {
    errEl.textContent = `Los pesos DISC deben sumar 1.00 (suma actual: ${sum.toFixed(2)}).`;
    errEl.classList.remove('hidden');
    return;
  }

  const payload = {
    question_id:  questionId,
    text:         document.getElementById('opt-text').value.trim(),
    feedback:     document.getElementById('opt-feedback').value.trim() || null,
    disc_d, disc_i, disc_s, disc_c,
    sort_order:   parseInt(document.getElementById('opt-sort-order').value, 10) || 0,
  };

  if (!payload.text) {
    errEl.textContent = 'El texto de la opción es obligatorio.';
    errEl.classList.remove('hidden');
    return;
  }

  try {
    let error;
    if (optId) {
      ({ error } = await sb.from('question_options').update(payload).eq('id', optId));
    } else {
      ({ error } = await sb.from('question_options').insert(payload));
    }
    if (error) throw error;
    closeOptionModal();
    if (viewingQuestionId) {
      loadOptionsView(viewingQuestionId, viewingQuestionTitle);
    }
  } catch (err) {
    errEl.textContent = 'Error guardando: ' + err.message;
    errEl.classList.remove('hidden');
  }
}

// ── Toggle activo / inactivo ─────────────────────────

async function toggleQuestion(id, active) {
  const { error } = await sb.from('questions').update({ is_active: active }).eq('id', id);
  if (error) { showGlobalError('Error actualizando: ' + error.message); return; }
  loadQuestions();
  loadCompositions();
}

async function toggleOption(id, active, questionId) {
  const { error } = await sb.from('question_options').update({ is_active: active }).eq('id', id);
  if (error) { showGlobalError('Error actualizando: ' + error.message); return; }
  loadOptionsView(questionId, viewingQuestionTitle);
}

// ── Editar (carga desde DB) ──────────────────────────

async function editQuestion(id) {
  try {
    const { data, error } = await sb
      .from('questions')
      .select('id, title, text, difficulty, avg_time_secs, context_notes')
      .eq('id', id)
      .single();
    if (error) throw error;
    openQuestionModal(data);
  } catch (err) {
    showGlobalError('Error cargando pregunta: ' + err.message);
  }
}

async function editOption(optId, questionId) {
  try {
    const { data, error } = await sb
      .from('question_options')
      .select('id, question_id, text, feedback, disc_d, disc_i, disc_s, disc_c, sort_order')
      .eq('id', optId)
      .single();
    if (error) throw error;
    openOptionModal(data, questionId);
  } catch (err) {
    showGlobalError('Error cargando opción: ' + err.message);
  }
}

// ── Ensamblar y publicar versión ─────────────────────

async function assembleVersion() {
  const btn    = document.getElementById('btn-assemble');
  const errEl  = document.getElementById('pub-error');
  const succEl = document.getElementById('pub-success');
  errEl.classList.add('hidden');
  succEl.classList.add('hidden');

  btn.disabled    = true;
  btn.textContent = 'Ensamblando…';

  const experienceId = document.getElementById('pub-experience').value;
  const versionLabel = document.getElementById('pub-version-label').value.trim() || null;

  try {
    const { data, error } = await sb.rpc('assemble_reto_version', {
      p_experience_id: experienceId,
      p_version_label: versionLabel,
      p_created_by:    currentProfile.id,
    });
    if (error) throw error;

    succEl.textContent = `Versión publicada exitosamente. ID: ${data}`;
    succEl.classList.remove('hidden');
    document.getElementById('pub-version-label').value = '';
    loadVersions();

  } catch (err) {
    errEl.textContent = 'Error ensamblando: ' + err.message;
    errEl.classList.remove('hidden');
  } finally {
    btn.disabled    = false;
    btn.textContent = 'Ensamblar y publicar';
  }
}

// ─── Logout ─────────────────────────────────────────
function setupLogout() {
  document.getElementById('btn-logout')?.addEventListener('click', logout);
}

// ═══════════════════════════════════════════════════════════════
// FÁBRICA DE CONTENIDO
// ═══════════════════════════════════════════════════════════════

let fabricaReady    = false;
let fabChallengeTypes = [];   // [{id, name, scoring_engine, dimensions}]
let fabCurrentTypeId  = null; // filtro activo en pestaña Preguntas
let fabCurrentRetoId  = null; // reto seleccionado en Composición

async function initFabrica() {
  if (fabricaReady) return;
  fabricaReady = true;

  // Sub-tab switching
  document.querySelectorAll('.fab-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => switchFabTab(btn.dataset.fabtab));
  });

  // Wires de botones principales
  document.getElementById('fab-btn-new-reto')
    ?.addEventListener('click', () => showRetoForm(true));
  document.getElementById('fab-btn-cancel-reto')
    ?.addEventListener('click', () => showRetoForm(false));
  document.getElementById('fab-btn-save-reto')
    ?.addEventListener('click', saveReto);

  document.getElementById('fab-btn-new-question')
    ?.addEventListener('click', () => showQuestionForm(true));
  document.getElementById('fab-btn-cancel-question')
    ?.addEventListener('click', () => showQuestionForm(false));
  document.getElementById('fab-btn-save-question')
    ?.addEventListener('click', saveQuestion);

  document.getElementById('fab-filter-type')
    ?.addEventListener('change', e => {
      fabCurrentTypeId = e.target.value || null;
      loadQuestions();
    });

  document.getElementById('fab-comp-reto')
    ?.addEventListener('change', e => {
      fabCurrentRetoId = e.target.value || null;
      loadComposition();
    });

  document.getElementById('fab-btn-publish')
    ?.addEventListener('click', publishVersion);

  // Cuando cambia la metodología en el form de pregunta, regenerar inputs de opciones
  document.getElementById('fab-q-type')
    ?.addEventListener('change', e => renderOptionInputs(e.target.value));

  // Cargar tipos y poblar todo lo dependiente
  await loadChallengeTypes();
  loadFabRetos();
}

// ── Sub-tab navigation ─────────────────────────────────────────
function switchFabTab(name) {
  document.querySelectorAll('.fab-tab-btn').forEach(btn => {
    const active = btn.dataset.fabtab === name;
    btn.setAttribute('aria-selected', String(active));
    btn.classList.toggle('border-ev-green', active);
    btn.classList.toggle('text-ev-green',   active);
    btn.classList.toggle('border-transparent', !active);
    btn.classList.toggle('text-gray-500',      !active);
  });

  ['tipos', 'retos', 'preguntas', 'composicion'].forEach(id => {
    document.getElementById(`fabtab-${id}`)
      ?.classList.toggle('hidden', id !== name);
  });

  if (name === 'preguntas')   loadQuestions();
  if (name === 'composicion') loadCompositionRetos();
}

// ── Challenge types ────────────────────────────────────────────
async function loadChallengeTypes() {
  const loading = document.getElementById('fab-tipos-loading');
  const list    = document.getElementById('fab-tipos-list');

  try {
    const { data, error } = await sb.rpc('get_challenge_types');
    if (error) throw error;

    fabChallengeTypes = data ?? [];

    // Render tipo cards
    if (list) {
      list.innerHTML = fabChallengeTypes.map(ct => `
        <div class="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-200">
          <div>
            <p class="font-semibold text-gray-900 text-sm">${esc(ct.name)}</p>
            <p class="text-xs text-gray-500 mt-0.5">${esc(ct.scoring_engine)} · ${ct.reto_count ?? 0} reto(s)</p>
          </div>
          <span class="text-xs font-mono bg-white border border-gray-200 rounded px-2 py-1 text-gray-400">${esc(ct.id)}</span>
        </div>
      `).join('');
      loading?.classList.add('hidden');
      list.classList.remove('hidden');
    }

    // Poblar selects que dependen de tipos
    populateTypeSelects();

  } catch (err) {
    if (loading) loading.textContent = 'Error cargando tipos: ' + err.message;
  }
}

function populateTypeSelects() {
  const options = fabChallengeTypes.map(
    ct => `<option value="${ct.id}">${esc(ct.name)}</option>`
  ).join('');

  ['fab-reto-type', 'fab-q-type', 'fab-filter-type'].forEach(id => {
    const sel = document.getElementById(id);
    if (!sel) return;
    const first = sel.options[0];
    sel.innerHTML = '';
    sel.appendChild(first.cloneNode(true));
    sel.insertAdjacentHTML('beforeend', options);
  });
}

// ── Retos ──────────────────────────────────────────────────────
async function loadFabRetos() {
  const loading = document.getElementById('fab-retos-loading');
  const list    = document.getElementById('fab-retos-list');
  if (!list) return;

  try {
    const { data, error } = await sb
      .from('experience_definitions')
      .select('id, name, slug, is_active, challenge_type_id, challenge_types(name)')
      .order('name');
    if (error) throw error;

    if ((data ?? []).length === 0) {
      if (loading) loading.textContent = 'No hay retos aún. Crea el primero.';
      return;
    }

    list.innerHTML = (data ?? []).map(r => `
      <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg border border-gray-200">
        <div>
          <p class="text-sm font-semibold text-gray-900">${esc(r.name)}</p>
          <p class="text-xs text-gray-400">${esc(r.challenge_types?.name ?? '—')} · <code class="font-mono">${esc(r.slug)}</code></p>
        </div>
        <span class="text-xs px-2 py-0.5 rounded-full font-semibold ${r.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-500'}">
          ${r.is_active ? 'Activo' : 'Inactivo'}
        </span>
      </div>
    `).join('');

    loading?.classList.add('hidden');
    list.classList.remove('hidden');

    // Poblar selector de composición
    const compSel = document.getElementById('fab-comp-reto');
    if (compSel) {
      const first = compSel.options[0];
      compSel.innerHTML = '';
      compSel.appendChild(first.cloneNode(true));
      (data ?? []).forEach(r => {
        const opt = document.createElement('option');
        opt.value       = r.id;
        opt.textContent = r.name;
        compSel.appendChild(opt);
      });
    }

  } catch (err) {
    if (loading) loading.textContent = 'Error: ' + err.message;
  }
}

function showRetoForm(show) {
  document.getElementById('fab-form-reto')?.classList.toggle('hidden', !show);
  if (!show) {
    document.getElementById('fab-reto-type').value = '';
    document.getElementById('fab-reto-name').value = '';
    document.getElementById('fab-reto-desc').value = '';
    document.getElementById('fab-reto-anim').value = 'tv_static';
    document.getElementById('fab-reto-error')?.classList.add('hidden');
  }
}

async function saveReto() {
  const typeId = document.getElementById('fab-reto-type').value;
  const name   = document.getElementById('fab-reto-name').value.trim();
  const desc   = document.getElementById('fab-reto-desc').value.trim();
  const anim   = document.getElementById('fab-reto-anim').value;
  const errEl  = document.getElementById('fab-reto-error');
  const btn    = document.getElementById('fab-btn-save-reto');

  if (!typeId || !name) {
    errEl.textContent = 'Metodología y nombre son obligatorios.';
    errEl.classList.remove('hidden');
    return;
  }

  const slug = name.toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

  const animConfig = anim === 'none'
    ? { type: 'none' }
    : anim === 'pixel_climber'
      ? { type: 'pixel_climber', background: 'assets/bg_aconcagua_path.png',
          climber_sprite: 'assets/sprite_climber_01.png', summit_label: 'Aconcagua 6.961m' }
      : { type: 'tv_static' };

  btn.disabled = true;
  btn.textContent = 'Guardando…';
  errEl.classList.add('hidden');

  try {
    const { error } = await sb.from('experience_definitions').insert({
      challenge_type_id: typeId,
      name,
      slug,
      description: desc || null,
      animation_config: animConfig,
      is_active: true,
    });
    if (error) throw error;

    showRetoForm(false);
    fabricaReady = false; // re-init para refrescar listas
    initFabrica();
  } catch (err) {
    errEl.textContent = err.message;
    errEl.classList.remove('hidden');
  } finally {
    btn.disabled = false;
    btn.textContent = 'Guardar reto';
  }
}

// ── Preguntas ──────────────────────────────────────────────────
async function loadQuestions() {
  const loading = document.getElementById('fab-questions-loading');
  const list    = document.getElementById('fab-questions-list');
  if (!list) return;

  if (!fabCurrentTypeId) {
    if (loading) {
      loading.textContent = 'Selecciona una metodología para ver las preguntas.';
      loading.classList.remove('hidden');
    }
    list.classList.add('hidden');
    return;
  }

  if (loading) loading.textContent = 'Cargando…';
  list.classList.add('hidden');

  try {
    const { data, error } = await sb.rpc('get_questions_by_type', {
      p_challenge_type_id: fabCurrentTypeId,
      p_include_inactive: true,
    });
    if (error) throw error;

    if ((data ?? []).length === 0) {
      if (loading) loading.textContent = 'Sin preguntas aún para esta metodología.';
      return;
    }

    list.innerHTML = (data ?? []).map(q => `
      <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg border border-gray-200 gap-3">
        <div class="min-w-0">
          <p class="text-sm font-semibold text-gray-900 truncate">${esc(q.title)}</p>
          <p class="text-xs text-gray-400 truncate mt-0.5">${esc(q.question_text?.slice(0, 80) ?? '')}…</p>
        </div>
        <span class="text-xs shrink-0 font-medium text-gray-500">${DIFF_LABELS[q.difficulty] ?? q.difficulty}</span>
      </div>
    `).join('');

    loading?.classList.add('hidden');
    list.classList.remove('hidden');

  } catch (err) {
    if (loading) loading.textContent = 'Error: ' + err.message;
  }
}

function showQuestionForm(show) {
  document.getElementById('fab-form-question')?.classList.toggle('hidden', !show);
  if (!show) {
    ['fab-q-type', 'fab-q-title', 'fab-q-text', 'fab-q-framework'].forEach(id => {
      const el = document.getElementById(id);
      if (el) el.value = '';
    });
    document.getElementById('fab-q-difficulty').value = '2';
    document.getElementById('fab-options-container').innerHTML = '';
    document.getElementById('fab-q-error')?.classList.add('hidden');
  }
}

function renderOptionInputs(challengeTypeId) {
  const container = document.getElementById('fab-options-container');
  if (!container) return;

  const ct = fabChallengeTypes.find(c => c.id === challengeTypeId);
  if (!ct) { container.innerHTML = ''; return; }

  const dims = ct.dimensions ?? [];
  const LETTER = ['A', 'B', 'C', 'D'];

  container.innerHTML = LETTER.map((letter, i) => `
    <div class="bg-white rounded-lg border border-gray-200 p-4">
      <p class="text-xs font-bold text-gray-600 mb-2 uppercase tracking-wide">Opción ${letter}</p>
      <textarea id="fab-opt-text-${i}" rows="2"
                placeholder="Texto de la opción ${letter}…"
                aria-label="Texto opción ${letter}"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ev-green resize-none mb-3"></textarea>
      <div class="grid grid-cols-2 gap-2">
        ${dims.map(d => `
          <label class="flex items-center justify-between gap-2 text-xs">
            <span class="font-semibold text-gray-600">${esc(d.key.toUpperCase())} — ${esc(d.label)}</span>
            <input type="number" id="fab-opt-${i}-${d.key}" min="0" max="1" step="0.05" value="0"
                   aria-label="Peso ${d.label} para opción ${letter}"
                   class="w-20 border border-gray-200 rounded px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-ev-green text-right"/>
          </label>
        `).join('')}
      </div>
    </div>
  `).join('');
}

async function saveQuestion() {
  const typeId = document.getElementById('fab-q-type').value;
  const title  = document.getElementById('fab-q-title').value.trim();
  const text   = document.getElementById('fab-q-text').value.trim();
  const diff   = parseInt(document.getElementById('fab-q-difficulty').value, 10);
  const notes  = document.getElementById('fab-q-framework').value.trim();
  const errEl  = document.getElementById('fab-q-error');
  const btn    = document.getElementById('fab-btn-save-question');

  if (!typeId || !title || !text) {
    errEl.textContent = 'Metodología, título y escenario son obligatorios.';
    errEl.classList.remove('hidden');
    return;
  }

  const ct   = fabChallengeTypes.find(c => c.id === typeId);
  const dims = ct?.dimensions ?? [];

  const options = [0, 1, 2, 3].map(i => {
    const optText = document.getElementById(`fab-opt-text-${i}`)?.value.trim() ?? '';
    const scores  = {};
    dims.forEach(d => {
      const val = parseFloat(document.getElementById(`fab-opt-${i}-${d.key}`)?.value ?? '0');
      scores[d.key] = isNaN(val) ? 0 : val;
    });
    return { text: optText, dimension_scores: scores };
  });

  if (options.some(o => !o.text)) {
    errEl.textContent = 'Todas las opciones deben tener texto.';
    errEl.classList.remove('hidden');
    return;
  }

  btn.disabled = true;
  btn.textContent = 'Guardando…';
  errEl.classList.add('hidden');

  try {
    const { error } = await sb.rpc('create_question', {
      p_challenge_type_id: typeId,
      p_title:             title,
      p_text:              text,
      p_difficulty:        diff,
      p_avg_time_secs:     60,
      p_context_notes:     null,
      p_framework_notes:   notes || null,
      p_options:           options,
    });
    if (error) throw error;

    showQuestionForm(false);
    fabCurrentTypeId = typeId;
    document.getElementById('fab-filter-type').value = typeId;
    loadQuestions();
  } catch (err) {
    errEl.textContent = err.message;
    errEl.classList.remove('hidden');
  } finally {
    btn.disabled = false;
    btn.textContent = 'Guardar pregunta';
  }
}

// ── Composición ────────────────────────────────────────────────
async function loadCompositionRetos() {
  // El select ya se pobló en loadFabRetos — sólo mostrar estado vacío
  const loading = document.getElementById('fab-comp-loading');
  const content = document.getElementById('fab-comp-content');
  if (loading) loading.classList.remove('hidden');
  if (content) content.classList.add('hidden');
}

async function loadComposition() {
  const loading = document.getElementById('fab-comp-loading');
  const content = document.getElementById('fab-comp-content');

  if (!fabCurrentRetoId) {
    if (loading) { loading.textContent = 'Selecciona un reto para ver su composición.'; loading.classList.remove('hidden'); }
    if (content) content.classList.add('hidden');
    return;
  }

  if (loading) { loading.textContent = 'Cargando…'; loading.classList.remove('hidden'); }
  if (content) content.classList.add('hidden');

  try {
    // Obtener el challenge_type_id del reto seleccionado
    const { data: retoDef, error: retoErr } = await sb
      .from('experience_definitions')
      .select('challenge_type_id')
      .eq('id', fabCurrentRetoId)
      .single();
    if (retoErr) throw retoErr;

    // Preguntas en composición actual
    const { data: inReto, error: inErr } = await sb
      .from('reto_compositions')
      .select('question_id, display_order, questions(id, title)')
      .eq('experience_id', fabCurrentRetoId)
      .order('display_order');
    if (inErr) throw inErr;

    // Preguntas disponibles (misma metodología, no en la composición)
    const includedIds = (inReto ?? []).map(r => r.question_id);
    const { data: available, error: avErr } = await sb
      .from('questions')
      .select('id, title, difficulty')
      .eq('challenge_type_id', retoDef.challenge_type_id)
      .eq('is_active', true)
      .not('id', 'in', `(${includedIds.length ? includedIds.join(',') : '00000000-0000-0000-0000-000000000000'})`);
    if (avErr) throw avErr;

    // Render incluídas
    const includedEl = document.getElementById('fab-comp-included');
    const countEl    = document.getElementById('fab-comp-count');
    if (countEl) countEl.textContent = (inReto ?? []).length;
    if (includedEl) {
      includedEl.innerHTML = (inReto ?? []).length === 0
        ? '<p class="text-xs text-gray-400 py-4 text-center">Sin preguntas aún.</p>'
        : (inReto ?? []).map(r => `
            <div class="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200 gap-2">
              <p class="text-sm text-gray-900 truncate">${esc(r.questions?.title ?? r.question_id)}</p>
              <button type="button" data-remove="${r.question_id}"
                      aria-label="Quitar pregunta"
                      class="fab-remove-btn shrink-0 text-xs text-red-500 hover:text-red-700 font-semibold px-2 py-1">
                Quitar
              </button>
            </div>
          `).join('');

      includedEl.querySelectorAll('.fab-remove-btn').forEach(btn => {
        btn.addEventListener('click', () => removeFromComposition(btn.dataset.remove));
      });
    }

    // Render disponibles
    const availableEl = document.getElementById('fab-comp-available');
    if (availableEl) {
      availableEl.innerHTML = (available ?? []).length === 0
        ? '<p class="text-xs text-gray-400 py-4 text-center">Todas las preguntas ya están incluídas.</p>'
        : (available ?? []).map(q => `
            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg border border-gray-200 gap-2">
              <div class="min-w-0">
                <p class="text-sm text-gray-900 truncate">${esc(q.title)}</p>
                <p class="text-xs text-gray-400">${DIFF_LABELS[q.difficulty] ?? q.difficulty}</p>
              </div>
              <button type="button" data-add="${q.id}"
                      aria-label="Agregar pregunta"
                      class="fab-add-btn shrink-0 text-xs bg-ev-green text-white hover:bg-ev-dark font-semibold px-3 py-1 rounded-lg transition-colors">
                + Agregar
              </button>
            </div>
          `).join('');

      availableEl.querySelectorAll('.fab-add-btn').forEach(btn => {
        btn.addEventListener('click', () => addToComposition(btn.dataset.add));
      });
    }

    if (loading) loading.classList.add('hidden');
    if (content) content.classList.remove('hidden');

    // Reset publish result
    const pubResult = document.getElementById('fab-publish-result');
    if (pubResult) pubResult.classList.add('hidden');

  } catch (err) {
    if (loading) loading.textContent = 'Error: ' + err.message;
  }
}

async function addToComposition(questionId) {
  const { data: maxRow } = await sb
    .from('reto_compositions')
    .select('display_order')
    .eq('experience_id', fabCurrentRetoId)
    .order('display_order', { ascending: false })
    .limit(1)
    .single();

  const nextOrder = (maxRow?.display_order ?? 0) + 1;

  const { error } = await sb.from('reto_compositions').insert({
    experience_id: fabCurrentRetoId,
    question_id:   questionId,
    display_order: nextOrder,
    is_required:   false,
  });
  if (!error) loadComposition();
}

async function removeFromComposition(questionId) {
  const { error } = await sb.from('reto_compositions')
    .delete()
    .eq('experience_id', fabCurrentRetoId)
    .eq('question_id', questionId);
  if (!error) loadComposition();
}

async function publishVersion() {
  const btn       = document.getElementById('fab-btn-publish');
  const resultEl  = document.getElementById('fab-publish-result');
  if (!fabCurrentRetoId || !btn) return;

  btn.disabled = true;
  btn.textContent = 'Publicando…';
  if (resultEl) resultEl.classList.add('hidden');

  try {
    // Genera label automático con fecha
    const label = `v${new Date().toISOString().slice(0,10).replace(/-/g,'.')}`;

    const { data, error } = await sb.rpc('assemble_reto_version', {
      p_experience_id: fabCurrentRetoId,
      p_version_label: label,
      p_created_by:    currentProfile.id,
    });
    if (error) throw error;

    if (resultEl) {
      resultEl.textContent = `Versión "${label}" publicada exitosamente. ID: ${data}`;
      resultEl.className = 'mt-3 text-sm rounded-lg px-4 py-3 bg-green-50 text-green-800 border border-green-200';
      resultEl.classList.remove('hidden');
    }
  } catch (err) {
    if (resultEl) {
      resultEl.textContent = 'Error al publicar: ' + err.message;
      resultEl.className = 'mt-3 text-sm rounded-lg px-4 py-3 bg-red-50 text-red-700 border border-red-200';
      resultEl.classList.remove('hidden');
    }
  } finally {
    btn.disabled = false;
    btn.textContent = 'Publicar versión →';
  }
}

// ── Util ───────────────────────────────────────────────────────
function esc(str) {
  return String(str ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
