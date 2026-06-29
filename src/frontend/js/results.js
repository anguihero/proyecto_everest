// =====================================================
// results.js — Pantalla de resultados DISC
// HU-CM-006: Scoring y finalización determinísticos
// =====================================================

import { sb, requireAuth, logout } from './auth.js';
import { ROUTES } from './config.js';
import { buildRadarModel, formatAverageTime } from './result-utils.js';

let currentResultId = null;

const DISC = {
  D: {
    label:   'Dominancia',
    color:   'bg-red-500',
    ring:    'ring-red-500',
    text:    'text-red-600',
    bg:      'bg-red-50',
    desc:    'Directo, decidido y orientado a resultados. Acepta desafíos y actúa con rapidez.',
  },
  I: {
    label:   'Influencia',
    color:   'bg-yellow-400',
    ring:    'ring-yellow-400',
    text:    'text-yellow-600',
    bg:      'bg-yellow-50',
    desc:    'Comunicativo, entusiasta y orientado a las personas. Genera energía y colaboración.',
  },
  S: {
    label:   'Estabilidad',
    color:   'bg-green-500',
    ring:    'ring-green-500',
    text:    'text-green-600',
    bg:      'bg-green-50',
    desc:    'Paciente, constante y orientado al equipo. Construye confianza y ambientes seguros.',
  },
  C: {
    label:   'Conciencia',
    color:   'bg-blue-500',
    ring:    'ring-blue-500',
    text:    'text-blue-600',
    bg:      'bg-blue-50',
    desc:    'Analítico, preciso y orientado a la calidad. Toma decisiones basadas en datos.',
  },
};

async function init() {
  const profile = await requireAuth();
  if (!profile) return;

  const params    = new URLSearchParams(window.location.search);
  const sessionId = params.get('session');

  if (!sessionId) {
    showError('No se encontró la sesión de resultados.');
    return;
  }

  try {
    const { data, error } = await sb.rpc('get_session_result', {
      p_session_id: sessionId,
    });

    if (error) throw error;
    if (!data)  throw new Error('Sin resultados para esta sesión.');

    renderResults(data, profile);

  } catch (err) {
    showError('No pudimos cargar tus resultados. ' + err.message);
  }
}

function renderResults(data, profile) {
  // Encabezado
  document.getElementById('user-name').textContent =
    data.participant_name ?? profile.preferred_name ?? 'Expedicionario';
  document.getElementById('experience-name').textContent =
    data.experience_name ?? 'Expedición';

  const completedDate = data.completed_at
    ? new Date(data.completed_at).toLocaleDateString('es-CO', {
        day: 'numeric', month: 'long', year: 'numeric',
      })
    : '';
  document.getElementById('completed-date').textContent =
    completedDate ? `Completado el ${completedDate}` : '';

  const backRoutes = {
    org_admin: ROUTES.admin,
    sys_admin: ROUTES.sysadmin,
  };
  document.getElementById('btn-hub').href = backRoutes[profile.role] ?? ROUTES.hub;
  document.getElementById('btn-hub-error').href = backRoutes[profile.role] ?? ROUTES.hub;

  // Determinar dimensión primaria
  const scores  = data.scores; // {D: 0.33, I: 0.0, S: 0.67, C: 0.0}
  const primary = Object.entries(scores).sort((a, b) => b[1] - a[1])[0][0];

  // Renderizar perfil primario
  const pd = DISC[primary];
  const profileEl = document.getElementById('primary-profile');
  profileEl.innerHTML = `
    <div class="flex items-center gap-4 mb-4">
      <div class="w-14 h-14 rounded-full ${pd.bg} ${pd.ring} ring-4
                  flex items-center justify-center shrink-0">
        <span class="text-2xl font-black ${pd.text}">${primary}</span>
      </div>
      <div>
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-widest">
          Tu perfil primario
        </p>
        <h2 class="text-2xl font-bold text-gray-900">${pd.label}</h2>
      </div>
    </div>
    <p class="text-sm text-gray-600 leading-relaxed">${pd.desc}</p>
  `;

  // Renderizar barras DISC
  renderRadar(scores);
  const barsEl = document.getElementById('disc-bars');
  const dimOrder = ['D', 'I', 'S', 'C'];
  barsEl.innerHTML = dimOrder.map(dim => {
    const d    = DISC[dim];
    const pct  = Math.round((scores[dim] ?? 0) * 100);
    const bold = dim === primary;
    return `
      <div class="space-y-1">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="font-black ${d.text} text-sm w-4">${dim}</span>
            <span class="text-sm ${bold ? 'font-semibold text-gray-900' : 'text-gray-500'}">
              ${d.label}
            </span>
            ${bold ? '<span class="text-xs bg-ev-green/10 text-ev-green font-semibold px-2 py-0.5 rounded-full">Primario</span>' : ''}
          </div>
          <span class="text-sm font-bold ${bold ? d.text : 'text-gray-400'}">${pct}%</span>
        </div>
        <div class="h-2.5 bg-gray-100 rounded-full overflow-hidden">
          <div class="h-full rounded-full transition-all duration-700 ${d.color}"
               style="width: ${pct}%"></div>
        </div>
      </div>
    `;
  }).join('');

  renderMetricsAndAudit(data);

  // Mostrar pantalla
  document.getElementById('loading-state').classList.add('hidden');
  document.getElementById('results-content').classList.remove('hidden');
}

function renderRadar(scores) {
  const radar = buildRadarModel(scores);
  const radarMaxPct = Math.ceil(radar.maxValue * 1000) / 10;
  const labels = {
    D: { x: 120, y: 18, anchor: 'middle', color: '#ef4444' },
    I: { x: 226, y: 124, anchor: 'end', color: '#eab308' },
    S: { x: 120, y: 232, anchor: 'middle', color: '#22c55e' },
    C: { x: 14, y: 124, anchor: 'start', color: '#3b82f6' },
  };
  const aria = ['D', 'I', 'S', 'C']
    .map(dim => `${DISC[dim].label} ${Math.round((scores[dim] ?? 0) * 100)} por ciento`)
    .join(', ');

  document.getElementById('disc-radar').innerHTML = `
    <svg viewBox="0 0 240 240" class="w-full max-w-[280px]"
         role="img" aria-label="Gráfico radar. ${aria}. Escala máxima ${radarMaxPct} por ciento, equivalente al 110 por ciento del valor DISC mayor.">
      ${radar.gridPolygons.map((points, index) => `
        <polygon points="${points}" fill="${index % 2 ? '#f9fafb' : 'none'}"
                 stroke="#d1d5db" stroke-width="1"/>
      `).join('')}
      ${radar.axisPoints.map(point => `
        <line x1="${radar.center}" y1="${radar.center}"
              x2="${point.x}" y2="${point.y}"
              stroke="#d1d5db" stroke-width="1"/>
      `).join('')}
      <polygon points="${radar.dataPolygon}" fill="#2E7D3240"
               stroke="#2E7D32" stroke-width="3" stroke-linejoin="round"/>
      ${radar.dataPoints.map(point => `
        <circle cx="${point.x}" cy="${point.y}" r="4"
                fill="${labels[point.dimension].color}" stroke="white" stroke-width="2"/>
      `).join('')}
      ${Object.entries(labels).map(([dim, label]) => `
        <text x="${label.x}" y="${label.y}" text-anchor="${label.anchor}"
              dominant-baseline="middle" font-size="13" font-weight="700"
              fill="${label.color}">${dim} ${Math.round((scores[dim] ?? 0) * 100)}%</text>
      `).join('')}
      <text x="120" y="218" text-anchor="middle" font-size="8" fill="#9ca3af">
        Escala radial: 0–${radarMaxPct}% (máximo × 1,10)
      </text>
    </svg>
  `;
}

function renderMetricsAndAudit(data) {
  const time = formatAverageTime(
    data.average_response_secs,
    data.timed_answers,
    data.answered_steps,
  );
  document.getElementById('average-time').textContent = time.value;
  document.getElementById('average-time-detail').textContent = time.detail;

  currentResultId = data.result_id;
  document.getElementById('result-reference').textContent =
    data.result_reference ?? data.result_id;
  document.getElementById('result-version').textContent =
    `Experiencia ${data.experience_version ?? '—'} · Scoring ${data.scoring_version ?? '—'}`;
}

async function copyResultId() {
  if (!currentResultId) return;
  const status = document.getElementById('copy-result-status');
  try {
    await navigator.clipboard.writeText(currentResultId);
    status.textContent = 'ID copiado.';
  } catch {
    status.textContent = `ID completo: ${currentResultId}`;
  }
}

function showError(msg) {
  document.getElementById('loading-state').classList.add('hidden');
  const errEl = document.getElementById('error-state');
  errEl.classList.remove('hidden');
  document.getElementById('error-message').textContent = msg;
}

// ─── Eventos ─────────────────────────────────────────
document.getElementById('btn-logout')?.addEventListener('click', logout);
document.getElementById('btn-copy-result-id')?.addEventListener('click', copyResultId);

// ─── Arranque ────────────────────────────────────────
init();
