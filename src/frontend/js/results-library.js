import { sb, requireAuth, logout } from './auth.js';
import { ROUTES } from './config.js';

async function init() {
  const profile = await requireAuth();
  if (!profile) return;

  const backRoutes = {
    org_admin: ROUTES.admin,
    sys_admin: ROUTES.sysadmin,
  };
  document.getElementById('btn-back').href = backRoutes[profile.role] ?? ROUTES.hub;

  const scopes = {
    player: 'Tus resultados personales.',
    coach: 'Resultados de las personas de tu organización.',
    org_admin: 'Resultados de las personas de tu organización.',
    sys_admin: 'Resultados de todas las organizaciones.',
  };
  document.getElementById('scope-description').textContent = scopes[profile.role];

  const { data, error } = await sb.rpc('list_accessible_results');
  document.getElementById('loading').classList.add('hidden');
  if (error) {
    const el = document.getElementById('error');
    el.textContent = 'No pudimos cargar los resultados.';
    el.classList.remove('hidden');
    return;
  }
  if (!data?.length) {
    document.getElementById('empty').classList.remove('hidden');
    return;
  }

  const list = document.getElementById('results-list');
  list.innerHTML = data.map(result => `
    <article class="bg-white border border-gray-200 rounded-xl p-5 flex flex-col sm:flex-row sm:items-center gap-4">
      <div class="flex-1 min-w-0">
        <p class="font-semibold text-gray-900">${escapeHtml(result.participant_name ?? 'Usuario')}</p>
        <p class="text-sm text-gray-500">${escapeHtml(result.experience_name)} · v${escapeHtml(result.experience_version)}</p>
        <p class="text-xs text-gray-400 mt-1">
          ${escapeHtml(result.organization_name)} ·
          ${new Date(result.completed_at).toLocaleDateString('es-CO')} ·
          <span class="font-mono">${escapeHtml(result.result_reference)}</span>
        </p>
      </div>
      <a href="results.html?session=${encodeURIComponent(result.session_id)}"
         class="px-4 py-2 rounded-lg bg-ev-green text-white text-sm font-semibold text-center hover:bg-ev-dark">
        Ver resultado
      </a>
    </article>
  `).join('');
  list.classList.remove('hidden');
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

document.getElementById('btn-logout')?.addEventListener('click', logout);
init();

