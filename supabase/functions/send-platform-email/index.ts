// send-platform-email — Edge Function
// Envía emails transaccionales usando Resend API.
// Roles permitidos: sys_admin (todos los templates), org_admin (welcome + invitation de su org)
//
// Request body:
//   { template_slug: string, recipient_id: string, variables: Record<string,string> }
//
// Secrets requeridos (Supabase Dashboard → Edge Functions → Secrets):
//   RESEND_API_KEY  — clave de Resend
//   RESEND_FROM     — "Everest Experience <no-reply@everestexperience.co>"

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  try {
    // ── Auth ──────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return err(401, 'missing_authorization');

    const sb = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authErr } = await sb.auth.getUser();
    if (authErr || !user) return err(401, 'unauthorized');

    const sbAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Obtener perfil del llamador
    const { data: callerProfile, error: profileErr } = await sbAdmin
      .from('profiles')
      .select('id, role, org_id')
      .eq('id', user.id)
      .single();

    if (profileErr || !callerProfile) return err(403, 'profile_not_found');

    const callerRole = callerProfile.role as string;
    if (!['sys_admin', 'org_admin'].includes(callerRole)) {
      return err(403, 'forbidden: solo sys_admin y org_admin pueden enviar emails');
    }

    // ── Payload ───────────────────────────────────────────────────
    const body = await req.json() as {
      template_slug: string;
      recipient_id:  string;
      variables:     Record<string, string>;
    };

    const { template_slug, recipient_id, variables = {} } = body;
    if (!template_slug || !recipient_id) return err(400, 'missing_fields: template_slug, recipient_id');

    // ── Templates permitidos por rol ──────────────────────────────
    const SYS_ADMIN_TEMPLATES  = ['welcome', 'password_reset', 'invitation'];
    const ORG_ADMIN_TEMPLATES  = ['welcome', 'invitation'];

    const allowed = callerRole === 'sys_admin'
      ? SYS_ADMIN_TEMPLATES
      : ORG_ADMIN_TEMPLATES;

    if (!allowed.includes(template_slug)) {
      return err(403, `forbidden: template "${template_slug}" no permitido para rol ${callerRole}`);
    }

    // ── Obtener destinatario ──────────────────────────────────────
    const { data: recipient, error: recipErr } = await sbAdmin
      .from('profiles')
      .select('id, preferred_name, org_id')
      .eq('id', recipient_id)
      .single();

    if (recipErr || !recipient) return err(404, 'recipient_not_found');

    // OrgAdmin solo puede enviar a usuarios de su misma organización
    if (callerRole === 'org_admin' && recipient.org_id !== callerProfile.org_id) {
      return err(403, 'forbidden: destinatario no pertenece a tu organización');
    }

    // Email del destinatario (desde auth.users, requiere service role)
    const { data: { user: recipUser }, error: recipAuthErr } = await sbAdmin.auth.admin.getUserById(recipient_id);
    if (recipAuthErr || !recipUser?.email) return err(404, 'recipient_email_not_found');

    // ── Obtener template ──────────────────────────────────────────
    const { data: tmpl, error: tmplErr } = await sbAdmin
      .from('email_templates')
      .select('subject, body_html, is_active')
      .eq('slug', template_slug)
      .single();

    if (tmplErr || !tmpl) return err(404, `template_not_found: ${template_slug}`);
    if (!tmpl.is_active)  return err(422, `template_inactive: ${template_slug}`);

    // ── Reemplazar variables en subject y body ────────────────────
    const allVars: Record<string, string> = {
      name:     recipient.preferred_name ?? recipUser.email,
      ...variables,
    };

    let subject  = tmpl.subject;
    let bodyHtml = tmpl.body_html;

    for (const [key, val] of Object.entries(allVars)) {
      const re = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
      subject  = subject.replace(re, val);
      bodyHtml = bodyHtml.replace(re, val);
    }

    // ── Enviar via Resend ─────────────────────────────────────────
    const resendKey  = Deno.env.get('RESEND_API_KEY');
    const resendFrom = Deno.env.get('RESEND_FROM') ?? 'Everest Experience <no-reply@everestexperience.co>';

    if (!resendKey) return err(500, 'missing_env: RESEND_API_KEY');

    const resendRes = await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: {
        'Authorization': `Bearer ${resendKey}`,
        'Content-Type':  'application/json',
      },
      body: JSON.stringify({
        from:    resendFrom,
        to:      [recipUser.email],
        subject,
        html:    bodyHtml,
      }),
    });

    const resendData = await resendRes.json() as { id?: string; message?: string };

    const logStatus = resendRes.ok ? 'sent' : 'failed';
    const logError  = resendRes.ok ? null : (resendData.message ?? 'resend_error');

    // ── Registrar en email_log ────────────────────────────────────
    await sbAdmin.from('email_log').insert({
      template_slug,
      recipient_id,
      triggered_by:  callerProfile.id,
      status:        logStatus,
      provider_id:   resendData.id ?? null,
      error_message: logError,
      sent_at:       new Date().toISOString(),
    });

    if (!resendRes.ok) {
      console.error('Resend error:', resendData);
      return err(502, `email_delivery_failed: ${logError}`);
    }

    return ok({ message_id: resendData.id, template: template_slug, recipient: recipUser.email });

  } catch (e) {
    console.error('send-platform-email unhandled:', e);
    return err(500, 'internal_error');
  }
});

// ── Helpers ───────────────────────────────────────────────────────
function ok(data: unknown): Response {
  return new Response(JSON.stringify(data), {
    status:  200,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

function err(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}
