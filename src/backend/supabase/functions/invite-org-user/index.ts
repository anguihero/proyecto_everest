// =====================================================
// Edge Function: invite-org-user
// Invita a un nuevo usuario como jugador de la organización.
// Solo puede ser llamada por un org_admin autenticado.
// El trigger handle_new_auth_user crea el perfil automáticamente
// usando los metadatos pasados en la invitación.
// =====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  const json = (body: object, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...CORS, 'Content-Type': 'application/json' },
    });

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'missing_auth' }, 401);

    const SUPABASE_URL      = Deno.env.get('SUPABASE_URL')!;
    const ANON_KEY          = Deno.env.get('SUPABASE_ANON_KEY')!;
    const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // ── 1. Verificar caller con su propio JWT (respeta RLS) ──────
    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authErr } = await userClient.auth.getUser();
    if (authErr || !user) return json({ error: 'invalid_token' }, 401);

    // ── 2. Verificar que el caller es org_admin ──────────────────
    const { data: callerProfile, error: profileErr } = await userClient
      .from('profiles')
      .select('role, org_id')
      .eq('id', user.id)
      .single();

    if (profileErr || !callerProfile || callerProfile.role !== 'org_admin') {
      return json({ error: 'forbidden' }, 403);
    }

    // ── 3. Parsear y validar body ────────────────────────────────
    const body = await req.json().catch(() => ({}));
    const email          = (body.email ?? '').trim().toLowerCase();
    const preferred_name = (body.preferred_name ?? '').trim() || null;
    const redirect_to    = (body.redirect_to ?? '').trim() || null;

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return json({ error: 'invalid_email', message: 'El email no es válido.' }, 422);
    }

    // ── 4. Invitar usuario con metadatos para el trigger ─────────
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data, error: inviteErr } = await adminClient.auth.admin.inviteUserByEmail(
      email,
      {
        data: {
          org_id:         callerProfile.org_id,
          role:           'player',
          preferred_name,
        },
        ...(redirect_to ? { redirectTo: redirect_to } : {}),
      },
    );

    if (inviteErr) {
      const isDuplicate =
        inviteErr.message?.toLowerCase().includes('already been registered') ||
        inviteErr.message?.toLowerCase().includes('already registered') ||
        inviteErr.status === 422;

      return json(
        {
          error:   isDuplicate ? 'email_already_registered' : 'invite_failed',
          message: isDuplicate
            ? 'Este email ya tiene una cuenta registrada.'
            : inviteErr.message,
        },
        isDuplicate ? 409 : 400,
      );
    }

    return json({ user_id: data.user.id });

  } catch (err) {
    console.error('[invite-org-user]', err);
    return json({ error: 'internal_error', message: 'Error interno del servidor.' }, 500);
  }
});
