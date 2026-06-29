import test from 'node:test';
import assert from 'node:assert/strict';
import {
  getErrorKey,
  getErrorMessage,
  getSafeErrorDiagnostic,
} from '../src/frontend/js/error-utils.js';

test('recognizes a semantic backend error inside a decorated message', () => {
  const error = { message: 'P0001: assignment_revoked', code: 'P0001' };
  assert.equal(getErrorKey(error), 'assignment_revoked');
  assert.match(getErrorMessage(error, 'fallback'), /revocada/);
});

test('uses details and does not expose raw database text', () => {
  const error = {
    message: 'Database error',
    details: 'consent_required',
    code: 'P0001',
  };
  assert.match(getErrorMessage(error, 'fallback'), /consentimiento/);
  assert.deepEqual(getSafeErrorDiagnostic(error), {
    key: 'consent_required',
    code: 'P0001',
  });
});

test('returns the provided fallback for an unknown error', () => {
  assert.equal(
    getErrorMessage({ message: 'internal relation xyz failed' }, 'Mensaje seguro'),
    'Mensaje seguro',
  );
});

