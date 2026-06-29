export const RADAR_DIMENSIONS = ['D', 'I', 'S', 'C'];

export function buildRadarModel(scores, {
  center = 120,
  radius = 82,
  maxValue = null,
} = {}) {
  const observedMax = Math.max(
    ...RADAR_DIMENSIONS.map(dimension => Math.max(0, Number(scores?.[dimension] ?? 0))),
  );
  const effectiveMax = maxValue ?? Math.max(observedMax * 1.1, 0.01);

  const axisPoints = RADAR_DIMENSIONS.map((dimension, index) => {
    const angle = -Math.PI / 2 + index * (Math.PI * 2 / RADAR_DIMENSIONS.length);
    return {
      dimension,
      x: center + Math.cos(angle) * radius,
      y: center + Math.sin(angle) * radius,
      angle,
    };
  });

  const dataPoints = axisPoints.map(point => {
    const value = Math.max(0, Number(scores?.[point.dimension] ?? 0));
    const ratio = Math.min(value / effectiveMax, 1);
    return {
      ...point,
      value,
      x: center + Math.cos(point.angle) * radius * ratio,
      y: center + Math.sin(point.angle) * radius * ratio,
    };
  });

  const gridPolygons = [0.2, 0.4, 0.6, 0.8, 1].map(ratio => (
    axisPoints
      .map(point => `${round(center + Math.cos(point.angle) * radius * ratio)},${round(center + Math.sin(point.angle) * radius * ratio)}`)
      .join(' ')
  ));

  return {
    center,
    radius,
    maxValue: effectiveMax,
    axisPoints,
    dataPoints,
    gridPolygons,
    dataPolygon: dataPoints.map(point => `${round(point.x)},${round(point.y)}`).join(' '),
  };
}

export function formatAverageTime(seconds, timedAnswers, answeredSteps) {
  const value = Number(seconds);
  if (!Number.isFinite(value) || Number(timedAnswers) === 0) {
    return {
      value: 'No disponible',
      detail: 'Este intento no registró tiempos de respuesta.',
    };
  }

  return {
    value: `${value.toLocaleString('es-CO', {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    })} s`,
    detail: `Promedio de ${timedAnswers} de ${answeredSteps} preguntas respondidas.`,
  };
}

function round(value) {
  return Math.round(value * 100) / 100;
}
