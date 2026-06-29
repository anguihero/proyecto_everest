// =====================================================
// results.js — Pantalla de resultados multi-metodología
// Soporta: DISC (radar 4 ejes) | VIA (radar hexagonal 6 virtudes)
// HU-CM-006, HU-RS-001
// =====================================================

import { sb, requireAuth, logout } from './auth.js';
import { ROUTES } from './config.js';
import { buildRadarModel, formatAverageTime } from './result-utils.js';

let currentResultId = null;

// ── DISC ──────────────────────────────────────────────
const DISC = {
  D: { label:'Dominancia',  color:'bg-red-500',    ring:'ring-red-500',    text:'text-red-600',   bg:'bg-red-50',    svgColor:'#ef4444',
       desc:'Directo, decidido y orientado a resultados. Acepta desafíos y actúa con rapidez.' },
  I: { label:'Influencia',  color:'bg-yellow-400', ring:'ring-yellow-400', text:'text-yellow-600',bg:'bg-yellow-50', svgColor:'#eab308',
       desc:'Comunicativo, entusiasta y orientado a las personas. Genera energía y colaboración.' },
  S: { label:'Estabilidad', color:'bg-green-500',  ring:'ring-green-500',  text:'text-green-600', bg:'bg-green-50',  svgColor:'#22c55e',
       desc:'Paciente, constante y orientado al equipo. Construye confianza y ambientes seguros.' },
  C: { label:'Conciencia',  color:'bg-blue-500',   ring:'ring-blue-500',   text:'text-blue-600',  bg:'bg-blue-50',   svgColor:'#3b82f6',
       desc:'Analítico, preciso y orientado a la calidad. Toma decisiones basadas en datos.' },
};

// Orden canónico de virtudes VIA para el radar hexagonal
const VIA_VIRTUE_ORDER = ['sabiduria','coraje','humanidad','justicia','templanza','trascendencia'];

// ── Init ──────────────────────────────────────────────
async function init() {
  const profile = await requireAuth();
  if (!profile) return;

  const params    = new URLSearchParams(window.location.search);
  const sessionId = params.get('session');

  if (!sessionId) { showError('No se encontró la sesión de resultados.'); return; }

  try {
    const { data, error } = await sb.rpc('get_session_result', { p_session_id: sessionId });
    if (error) throw error;
    if (!data)  throw new Error('Sin resultados para esta sesión.');
    renderResults(data, profile);
  } catch (err) {
    showError('No pudimos cargar tus resultados. ' + err.message);
  }
}

// ── Dispatcher ───────────────────────────────────────
function renderResults(data, profile) {
  // Cabecera común
  document.getElementById('user-name').textContent =
    data.participant_name ?? profile.preferred_name ?? 'Expedicionario';
  document.getElementById('experience-name').textContent = data.experience_name ?? 'Expedición';
  document.getElementById('completed-date').textContent = data.completed_at
    ? `Completado el ${new Date(data.completed_at).toLocaleDateString('es-CO', { day:'numeric', month:'long', year:'numeric' })}`
    : '';

  const backRoutes = { org_admin: ROUTES.admin, sys_admin: ROUTES.sysadmin };
  document.getElementById('btn-hub').href       = backRoutes[profile.role] ?? ROUTES.hub;
  document.getElementById('btn-hub-error').href = backRoutes[profile.role] ?? ROUTES.hub;

  // Detección de metodología
  const engine = data.scoring_engine ?? 'disc_weighted';

  if (engine === 'via_weighted') {
    renderVIA(data);
  } else {
    renderDISC(data);
  }

  renderMetricsAndAudit(data);

  document.getElementById('loading-state').classList.add('hidden');
  document.getElementById('results-content').classList.remove('hidden');
}

// ══════════════════════════════════════════════════════
// DISC
// ══════════════════════════════════════════════════════

function renderDISC(data) {
  const scores  = data.scores ?? {};
  const primary = Object.entries(scores).sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'D';
  const pd      = DISC[primary];

  // Perfil primario
  document.getElementById('primary-profile').innerHTML = `
    <div class="flex items-center gap-4 mb-4">
      <div class="w-14 h-14 rounded-full ${pd.bg} ${pd.ring} ring-4
                  flex items-center justify-center shrink-0">
        <span class="text-2xl font-black ${pd.text}">${primary}</span>
      </div>
      <div>
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-widest">Tu perfil primario</p>
        <h2 class="text-2xl font-bold text-gray-900">${pd.label}</h2>
      </div>
    </div>
    <p class="text-sm text-gray-600 leading-relaxed">${pd.desc}</p>
  `;

  // Radar 4 ejes
  document.getElementById('distribution-title').textContent = 'Distribución DISC';
  renderDiscRadar(scores);

  // Barras
  const barsEl = document.getElementById('dimensions-container');
  barsEl.innerHTML = ['D','I','S','C'].map(dim => {
    const d    = DISC[dim];
    const pct  = Math.round((scores[dim] ?? 0) * 100);
    const bold = dim === primary;
    return `
      <div class="space-y-1">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="font-black ${d.text} text-sm w-4">${dim}</span>
            <span class="text-sm ${bold ? 'font-semibold text-gray-900' : 'text-gray-500'}">${d.label}</span>
            ${bold ? '<span class="text-xs bg-ev-green/10 text-ev-green font-semibold px-2 py-0.5 rounded-full">Primario</span>' : ''}
          </div>
          <span class="text-sm font-bold ${bold ? d.text : 'text-gray-400'}">${pct}%</span>
        </div>
        <div class="h-2.5 bg-gray-100 rounded-full overflow-hidden">
          <div class="h-full rounded-full transition-all duration-700 ${d.color}" style="width:${pct}%"></div>
        </div>
      </div>
    `;
  }).join('');

  // Disclaimer
  document.getElementById('methodology-disclaimer').innerHTML =
    '<strong>Nota:</strong> Este perfil es exploratorio y descriptivo — refleja tus tendencias conductuales en estos escenarios, no un diagnóstico definitivo. Los perfiles DISC pueden variar según el contexto y el momento.';
}

function renderDiscRadar(scores) {
  const radar       = buildRadarModel(scores);
  const radarMaxPct = Math.ceil(radar.maxValue * 1000) / 10;
  const labels = {
    D: { x:120, y:18,  anchor:'middle', color:'#ef4444' },
    I: { x:226, y:124, anchor:'end',    color:'#eab308' },
    S: { x:120, y:232, anchor:'middle', color:'#22c55e' },
    C: { x:14,  y:124, anchor:'start',  color:'#3b82f6' },
  };
  const aria = ['D','I','S','C']
    .map(d => `${DISC[d].label} ${Math.round((scores[d] ?? 0) * 100)} por ciento`).join(', ');

  document.getElementById('radar-container').innerHTML = `
    <svg viewBox="0 0 240 240" class="w-full max-w-[280px]"
         role="img" aria-label="Gráfico radar DISC. ${aria}. Escala máxima ${radarMaxPct} por ciento.">
      ${radar.gridPolygons.map((pts, i) =>
        `<polygon points="${pts}" fill="${i % 2 ? '#f9fafb' : 'none'}" stroke="#d1d5db" stroke-width="1"/>`
      ).join('')}
      ${radar.axisPoints.map(pt =>
        `<line x1="${radar.center}" y1="${radar.center}" x2="${pt.x}" y2="${pt.y}" stroke="#d1d5db" stroke-width="1"/>`
      ).join('')}
      <polygon points="${radar.dataPolygon}" fill="#2E7D3240" stroke="#2E7D32" stroke-width="3" stroke-linejoin="round"/>
      ${radar.dataPoints.map(pt =>
        `<circle cx="${pt.x}" cy="${pt.y}" r="4" fill="${labels[pt.dimension].color}" stroke="white" stroke-width="2"/>`
      ).join('')}
      ${Object.entries(labels).map(([dim, l]) =>
        `<text x="${l.x}" y="${l.y}" text-anchor="${l.anchor}" dominant-baseline="middle"
               font-size="13" font-weight="700" fill="${l.color}">${dim} ${Math.round((scores[dim] ?? 0) * 100)}%</text>`
      ).join('')}
      <text x="120" y="218" text-anchor="middle" font-size="8" fill="#9ca3af">
        Escala radial: 0–${radarMaxPct}% (máximo × 1,10)
      </text>
    </svg>
  `;
}

// ══════════════════════════════════════════════════════
// VIA — Fortalezas de Carácter
// ══════════════════════════════════════════════════════

function renderVIA(data) {
  const scores        = data.scores ?? {};
  const resultTmpl    = data.result_template ?? {};
  const virtueMap     = resultTmpl.virtues ?? {};

  // Calcular promedio por virtud
  const virtueScores = {};
  for (const [vKey, vDef] of Object.entries(virtueMap)) {
    const keys   = vDef.keys ?? [];
    const values = keys.map(k => scores[k] ?? 0);
    virtueScores[vKey] = values.length
      ? values.reduce((a, b) => a + b, 0) / values.length
      : 0;
  }

  // Virtud primaria
  const primaryVirtue = Object.entries(virtueScores)
    .sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'sabiduria';
  const pvDef = virtueMap[primaryVirtue] ?? {};

  // Perfil primario
  const pvColor = pvDef.color ?? '#805AD5';
  document.getElementById('primary-profile').innerHTML = `
    <div class="flex items-center gap-4 mb-4">
      <div class="w-14 h-14 rounded-full flex items-center justify-center shrink-0 ring-4"
           style="background:${pvColor}20;ring-color:${pvColor}">
        <span class="text-2xl" aria-hidden="true">✨</span>
      </div>
      <div>
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-widest">Tu virtud principal</p>
        <h2 class="text-2xl font-bold text-gray-900" style="color:${pvColor}">${pvDef.label ?? primaryVirtue}</h2>
      </div>
    </div>
    <p class="text-sm text-gray-600 leading-relaxed">
      Tu comportamiento en estos escenarios expresa con mayor fuerza las fortalezas de
      <strong>${pvDef.label ?? primaryVirtue}</strong>. Las fortalezas VIA son descriptivas —
      reflejan tendencias, no categorías fijas.
    </p>
  `;

  // Radar hexagonal de 6 virtudes
  document.getElementById('distribution-title').textContent = 'Distribución por virtudes';
  renderVIARadar(virtueScores, virtueMap);

  // Resumen de virtudes (barras)
  const dimsEl = document.getElementById('dimensions-container');
  const ordered = VIA_VIRTUE_ORDER.filter(k => virtueMap[k]);
  dimsEl.innerHTML = ordered.map(vKey => {
    const vd   = virtueMap[vKey] ?? {};
    const pct  = Math.round((virtueScores[vKey] ?? 0) * 100);
    const bold = vKey === primaryVirtue;
    const col  = vd.color ?? '#805AD5';
    return `
      <div class="space-y-1">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="text-sm ${bold ? 'font-semibold text-gray-900' : 'text-gray-500'}">${vd.label ?? vKey}</span>
            ${bold ? `<span class="text-xs font-semibold px-2 py-0.5 rounded-full" style="background:${col}18;color:${col}">Principal</span>` : ''}
          </div>
          <span class="text-sm font-bold ${bold ? '' : 'text-gray-400'}" style="${bold ? `color:${col}` : ''}">${pct}%</span>
        </div>
        <div class="h-2.5 bg-gray-100 rounded-full overflow-hidden">
          <div class="h-full rounded-full transition-all duration-700"
               style="width:${pct}%;background:${col}"></div>
        </div>
      </div>
    `;
  }).join('');

  // Top 5 fortalezas individuales
  renderVIATop5(scores, virtueMap);

  // Disclaimer
  document.getElementById('methodology-disclaimer').innerHTML =
    '<strong>Nota:</strong> Este perfil refleja tus tendencias al responder estos escenarios según el modelo VIA de Fortalezas de Carácter (Peterson & Seligman, 2004). Es exploratorio — no es un diagnóstico clínico ni una evaluación de desempeño.';
}

function renderVIARadar(virtueScores, virtueMap) {
  const CX = 120, CY = 120, R = 88;
  const ordered = VIA_VIRTUE_ORDER.filter(k => virtueMap[k]);
  const n       = ordered.length; // 6
  const step    = (2 * Math.PI) / n;
  const startAngle = -Math.PI / 2; // empieza en el tope

  // Función de coordenadas a partir de índice y radio
  const pt = (i, r) => ({
    x: CX + r * Math.cos(startAngle + i * step),
    y: CY + r * Math.sin(startAngle + i * step),
  });

  // Grid concéntrico (4 niveles)
  const gridLevels = [0.25, 0.5, 0.75, 1.0];
  const gridPolygons = gridLevels.map(level => {
    const pts = ordered.map((_, i) => pt(i, R * level));
    return pts.map(p => `${p.x},${p.y}`).join(' ');
  });

  // Ejes
  const axes = ordered.map((_, i) => ({ outer: pt(i, R) }));

  // Polígono de datos
  const dataPoints = ordered.map((vKey, i) => {
    const val = virtueScores[vKey] ?? 0;
    return { ...pt(i, R * val), vKey, val };
  });
  const dataPolygon = dataPoints.map(p => `${p.x},${p.y}`).join(' ');

  // Labels (un poco más allá del radio)
  const labelR = R + 20;
  const labelAnchors = (i) => {
    const ang = startAngle + i * step;
    if (Math.cos(ang) > 0.3)  return 'start';
    if (Math.cos(ang) < -0.3) return 'end';
    return 'middle';
  };

  const aria = ordered
    .map(k => `${virtueMap[k]?.label ?? k} ${Math.round((virtueScores[k] ?? 0) * 100)} por ciento`)
    .join(', ');

  document.getElementById('radar-container').innerHTML = `
    <svg viewBox="0 0 240 240" class="w-full max-w-[300px]"
         role="img" aria-label="Radar de virtudes VIA. ${aria}.">
      <!-- Grid -->
      ${gridPolygons.map((pts, gi) =>
        `<polygon points="${pts}" fill="${gi % 2 ? '#f9fafb' : 'none'}" stroke="#d1d5db" stroke-width="1"/>`
      ).join('')}
      <!-- Ejes -->
      ${axes.map(ax =>
        `<line x1="${CX}" y1="${CY}" x2="${ax.outer.x}" y2="${ax.outer.y}" stroke="#d1d5db" stroke-width="1"/>`
      ).join('')}
      <!-- Datos -->
      <polygon points="${dataPolygon}" fill="#2E7D3228" stroke="#2E7D32" stroke-width="2.5" stroke-linejoin="round"/>
      ${dataPoints.map(p => {
        const col = virtueMap[p.vKey]?.color ?? '#805AD5';
        return `<circle cx="${p.x}" cy="${p.y}" r="4" fill="${col}" stroke="white" stroke-width="2"/>`;
      }).join('')}
      <!-- Labels -->
      ${ordered.map((vKey, i) => {
        const lp  = pt(i, labelR);
        const col = virtueMap[vKey]?.color ?? '#805AD5';
        const pct = Math.round((virtueScores[vKey] ?? 0) * 100);
        const anc = labelAnchors(i);
        const lbl = (virtueMap[vKey]?.label ?? vKey).slice(0, 12); // truncar si es muy largo
        return `
          <text x="${lp.x}" y="${lp.y - 5}" text-anchor="${anc}" font-size="9" font-weight="700" fill="${col}">${lbl}</text>
          <text x="${lp.x}" y="${lp.y + 7}" text-anchor="${anc}" font-size="9" fill="#6b7280">${pct}%</text>
        `;
      }).join('')}
    </svg>
  `;
}

function renderVIATop5(scores, virtueMap) {
  // Aplanar fortalezas con su virtud
  const flat = [];
  for (const [vKey, vDef] of Object.entries(virtueMap)) {
    for (const sKey of (vDef.keys ?? [])) {
      flat.push({ key: sKey, virtue: vKey, virtueLabel: vDef.label, color: vDef.color, val: scores[sKey] ?? 0 });
    }
  }
  flat.sort((a, b) => b.val - a.val);
  const top5 = flat.slice(0, 6); // top 6 para grid 2x3

  if (top5.length === 0) return;

  document.getElementById('via-top5').classList.remove('hidden');

  // Construir label a partir de la clave (snake_case → Title Case)
  const toLabel = (key) => key
    .replace(/_/g, ' ')
    .replace(/\b\w/g, l => l.toUpperCase());

  document.getElementById('via-top5-list').innerHTML = top5.map(f => {
    const pct = Math.round(f.val * 100);
    const col = f.color ?? '#805AD5';
    return `
      <div class="p-3 rounded-xl border border-gray-100 bg-gray-50">
        <div class="flex items-center justify-between mb-1">
          <p class="text-sm font-semibold text-gray-900">${toLabel(f.key)}</p>
          <span class="text-sm font-bold" style="color:${col}">${pct}%</span>
        </div>
        <p class="text-xs text-gray-400">${f.virtueLabel}</p>
        <div class="h-1.5 bg-gray-200 rounded-full mt-2 overflow-hidden">
          <div class="h-full rounded-full" style="width:${pct}%;background:${col}"></div>
        </div>
      </div>
    `;
  }).join('');
}

// ══════════════════════════════════════════════════════
// Métricas y auditoría (común)
// ══════════════════════════════════════════════════════

function renderMetricsAndAudit(data) {
  const time = formatAverageTime(data.average_response_secs, data.timed_answers, data.answered_steps);
  document.getElementById('average-time').textContent       = time.value;
  document.getElementById('average-time-detail').textContent = time.detail;

  currentResultId = data.result_id;
  document.getElementById('result-reference').textContent = data.result_reference ?? data.result_id;
  document.getElementById('result-version').textContent   =
    `Experiencia ${data.experience_version ?? '—'} · Scoring ${data.scoring_version ?? '—'}`;
}

// ══════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════

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
  document.getElementById('error-state').classList.remove('hidden');
  document.getElementById('error-message').textContent = msg;
}

// ── Eventos ─────────────────────────────────────────
document.getElementById('btn-logout')?.addEventListener('click', logout);
document.getElementById('btn-copy-result-id')?.addEventListener('click', copyResultId);

// ── Arranque ────────────────────────────────────────
init();
