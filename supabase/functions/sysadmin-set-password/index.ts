import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const json = (body: object, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...CORS, 'Content-Type': 'application/json' },
});

Deno.serve(async req => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'missing_auth' }, 401);

    const url = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) return json({ error: 'invalid_token' }, 401);

    const { data: caller } = await userClient
      .from('profiles')
      .select('id, org_id, role, is_active')
      .eq('id', user.id)
      .single();
    if (!caller?.is_active || caller.role !== 'sys_admin') {
      return json({ error: 'forbidden' }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const targetUserId = String(body.user_id ?? '');
    const password = String(body.new_password ?? '');

    if (!/^[0-9a-f-]{36}$/i.test(targetUserId)) {
      return json({ error: 'invalid_user_id' }, 422);
    }
    const strongPassword = password.length >= 12
      && /[a-z]/.test(password)
      && /[A-Z]/.test(password)
      && /\d/.test(password)
      && /[^A-Za-z0-9]/.test(password);
    if (!strongPassword) {
      return json({
        error: 'weak_password',
        message: 'Usa mínimo 12 caracteres, mayúscula, minúscula, número y símbolo.',
      }, 422);
    }

    const admin = createClient(url, serviceRoleKey);
    const { data: target } = await admin
      .from('profiles')
      .select('id, org_id')
      .eq('id', targetUserId)
      .single();
    if (!target) return json({ error: 'user_not_found' }, 404);

    const { error: updateError } = await admin.auth.admin.updateUserById(
      targetUserId,
      { password },
    );
    if (updateError) {
      console.error('[sysadmin-set-password] update failed', updateError.code);
      return json({ error: 'password_update_failed' }, 400);
    }

    await admin.from('audit_events').insert({
      user_id: caller.id,
      org_id: caller.org_id,
      action: 'security_event',
      resource_type: 'auth_user',
      resource_id: targetUserId,
      metadata: {
        event: 'password_changed_by_sysadmin',
        target_org_id: target.org_id,
      },
    });

    return json({ updated: true, user_id: targetUserId });
  } catch (error) {
    console.error('[sysadmin-set-password]', error);
    return json({ error: 'internal_error' }, 500);
  }
});
