import test from 'node:test';
import assert from 'node:assert/strict';
import { buildOptionalDate } from '../src/frontend/js/date-utils.js';

test('empty date remains optional', () => {
  assert.equal(
    buildOptionalDate({ day: '', month: '', year: '' }, '2026-06-29'),
    null,
  );
});

test('builds a valid ISO date', () => {
  assert.equal(
    buildOptionalDate({ day: '12', month: '7', year: '2026' }, '2026-06-29'),
    '2026-07-12',
  );
});

test('rejects incomplete, impossible and past dates', () => {
  assert.throws(
    () => buildOptionalDate({ day: '12', month: '', year: '2026' }, '2026-06-29'),
    /due_date_incomplete/,
  );
  assert.throws(
    () => buildOptionalDate({ day: '31', month: '2', year: '2027' }, '2026-06-29'),
    /due_date_invalid/,
  );
  assert.throws(
    () => buildOptionalDate({ day: '1', month: '1', year: '2026' }, '2026-06-29'),
    /due_date_in_past/,
  );
});
