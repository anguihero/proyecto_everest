/**
 * seed_users.mjs — Crea los usuarios de prueba via Supabase Admin API
 *
 * La Admin API llama a GoTrue internamente → todos los campos internos
 * se inicializan correctamente (evita el error 500 del INSERT directo en SQL).
 *
 * Uso (PowerShell):
 *   $env:SUPABASE_SERVICE_KEY = "tu_service_role_key"
 *   node src/backend/supabase/seed/seed_users.mjs
 *
 * La SERVICE_ROLE_KEY se obtiene de:
 *   Supabase Dashboard → Project Settings → API → service_role (secret)
 *
 * NUNCA commitear la key. NUNCA usarla en código del cliente.
 */

const PROJECT_URL = 'https://fwwkchcxildykvfhrcri.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('\n✗ SUPABASE_SERVICE_KEY no definida.\n');
  console.error('Ejecutar en PowerShell:');
  console.error('  $env:SUPABASE_SERVICE_KEY = "tu_service_role_key"');
  console.error('  node src/backend/supabase/seed/seed_users.mjs\n');
  process.exit(1);
}

const ORG_ID   = 'a0000000-0000-0000-0000-000000000001';
const PASSWORD = 'EverestMVP2026!';

const USERS = [
  { email: 'diegoms@alienyticslab.com',  role: 'player',    name: 'Diego'   },
  { email: 'andresms@alienyticslab.com', role: 'org_admin', name: 'Andrés'  },
  { email: 'oscar@everest.oscar',         role: 'coach',     name: 'Óscar'   },
  { email: 'everest@alienyticslab.com',  role: 'sys_admin', name: 'Everest' },
];

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'apikey': SERVICE_KEY,
};

async function adminFetch(method, path, body) {
  const res = await fetch(`${PROJECT_URL}/auth/v1/${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, data: await res.json() };
}

async function getUserByEmail(email) {
  const { data } = await adminFetch('GET', 'admin/users?per_page=100');
  return data.users?.find(u => u.email === email) ?? null;
}

async function main() {
  console.log('\n=== Seed de usuarios de prueba — Everest Experience ===\n');

  for (const u of USERS) {
    process.stdout.write(`${u.role.padEnd(9)} | ${u.email} ... `);

    const { status, data } = await adminFetch('POST', 'admin/users', {
      email:         u.email,
      password:      PASSWORD,
      email_confirm: true,
      // Sin user_metadata: el trigger handle_new_auth_user detecta org_id=NULL
      // y hace RETURN NEW sin tocar profiles. Los perfiles se crean via PASO C SQL.
    });

    if (status === 200 || status === 201) {
      console.log(`✓ creado (${data.id})`);
      continue;
    }

    // Usuario ya existe → resetear contraseña y metadata
    if (status === 422) {
      const existing = await getUserByEmail(u.email);
      if (existing) {
        await adminFetch('PATCH', `admin/users/${existing.id}`, {
          password:      PASSWORD,
          email_confirm: true,
        });
        console.log(`↺ ya existía — contraseña y metadata actualizados`);
      } else {
        console.log(`✗ 422 pero usuario no encontrado — ${JSON.stringify(data)}`);
      }
      continue;
    }

    console.log(`✗ ERROR ${status}: ${JSON.stringify(data)}`);
  }

  console.log('\n✓ Seed completo.');
  console.log('  Próximo paso: ejecutar PASO C+D de 004_safe_recreate.sql para crear perfiles y consent.\n');
}

main().catch(err => { console.error(err); process.exit(1); });
