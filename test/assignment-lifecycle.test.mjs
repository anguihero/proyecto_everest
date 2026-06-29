import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const migrationPath = new URL(
  '../supabase/migrations/20260629000011_assignment_lifecycle.sql',
  import.meta.url,
);
const adminPath = new URL('../src/frontend/js/admin.js', import.meta.url);

test('assignment lifecycle is centralized in authenticated RPCs', async () => {
  const sql = await readFile(migrationPath, 'utf8');

  assert.match(sql, /FUNCTION public\.assign_experience\(/);
  assert.match(sql, /FUNCTION public\.manage_assignment\(/);
  assert.match(sql, /GRANT EXECUTE ON FUNCTION public\.assign_experience.*TO authenticated/s);
  assert.match(sql, /GRANT EXECUTE ON FUNCTION public\.manage_assignment.*TO authenticated/s);
  assert.match(sql, /RAISE EXCEPTION 'assignment_has_history'/);
});

test('one assignment cannot create multiple sessions', async () => {
  const sql = await readFile(migrationPath, 'utf8');
  assert.match(
    sql,
    /CREATE UNIQUE INDEX IF NOT EXISTS uq_experience_sessions_assignment/,
  );
  assert.match(sql, /EXCEPTION WHEN unique_violation/);
});

test('OrgAdmin no longer mutates assignments directly', async () => {
  const source = await readFile(adminPath, 'utf8');

  assert.match(source, /sb\.rpc\('assign_experience'/);
  assert.match(source, /sb\.rpc\('manage_assignment'/);
  assert.doesNotMatch(source, /\.from\('experience_assignments'\)\s*\.delete\(/s);
  assert.doesNotMatch(source, /\.from\('experience_assignments'\)\s*\.insert\(/s);
});
