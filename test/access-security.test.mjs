import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const migration = new URL(
  '../supabase/migrations/20260629000013_result_access_matrix.sql',
  import.meta.url,
);
const passwordFunction = new URL(
  '../supabase/functions/sysadmin-set-password/index.ts',
  import.meta.url,
);

test('result access matrix scopes coach/admin by org and sysadmin globally', async () => {
  const sql = await readFile(migration, 'utf8');
  assert.match(sql, /c\.role = 'sys_admin'/);
  assert.match(sql, /c\.role IN \('coach', 'org_admin'\) AND es\.org_id = c\.org_id/);
  assert.match(sql, /es\.user_id = c\.id/);
  assert.match(sql, /'event', 'result_viewed'/);
});

test('password change requires verified active sysadmin and never logs password', async () => {
  const source = await readFile(passwordFunction, 'utf8');
  assert.match(source, /auth\.getUser\(\)/);
  assert.match(source, /caller\.role !== 'sys_admin'/);
  assert.match(source, /auth\.admin\.updateUserById/);
  assert.match(source, /password_changed_by_sysadmin/);
  const metadataBlock = source.slice(
    source.indexOf('metadata:'),
    source.indexOf('    });', source.indexOf('metadata:')),
  );
  assert.doesNotMatch(metadataBlock, /\bpassword\s*[,}]/);
});
