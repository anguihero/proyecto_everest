import test from 'node:test';
import assert from 'node:assert/strict';
import { buildRadarModel, formatAverageTime } from '../src/frontend/js/result-utils.js';

test('scales the radar to 110 percent of the observed maximum', () => {
  const radar = buildRadarModel({ D: 0.28, I: 0.25, S: 0.25, C: 0.22 });
  assert.equal(radar.axisPoints.length, 4);
  assert.equal(radar.dataPoints.length, 4);
  assert.equal(radar.gridPolygons.length, 5);
  assert.ok(Math.abs(radar.maxValue - 0.308) < 0.000001);
  assert.equal(radar.dataPolygon.split(' ').length, 4);
});

test('formats average response time and historical absence', () => {
  assert.deepEqual(formatAverageTime(null, 0, 3), {
    value: 'No disponible',
    detail: 'Este intento no registró tiempos de respuesta.',
  });
  assert.deepEqual(formatAverageTime(12.34, 20, 20), {
    value: '12,3 s',
    detail: 'Promedio de 20 de 20 preguntas respondidas.',
  });
});
