// =====================================================
// config.js — Configuración de Supabase y la aplicación
// INSTRUCCIÓN ANTES DE USAR:
//   Reemplaza SUPABASE_URL y SUPABASE_ANON_KEY con los
//   valores de tu proyecto en: app.supabase.com → Settings → API
//
// SEGURIDAD:
//   La ANON KEY es pública por diseño — las políticas RLS
//   controlan el acceso real. La SERVICE ROLE KEY nunca
//   va aquí ni en el cliente.
// =====================================================

export const SUPABASE_CONFIG = {
  url:     'https://fwwkchcxildykvfhrcri.supabase.co',
  anonKey: 'sb_publishable_ScFuHSUlmtnFZopfeBY-cQ_VRANcUHj',
};

export const APP_CONFIG = {
  consentPolicyVersion: '1.0',
  onboardingVersion:    '1.0',
};

// Rutas de la aplicación
export const ROUTES = {
  login:     'index.html',
  hub:       'hub.html',
  onboarding: 'onboarding.html',
  consent:   'consent.html',
  admin:     'admin.html',
  sysadmin:  'sysadmin.html',
  resultsLibrary: 'results-library.html',
};
