// =====================================================
// auth.js — Módulo de autenticación
// HU-CA-001: Autenticación y recuperación segura
// HU-CA-002: Resolución de organización, rol y autorización
// =====================================================

import { createClient }             from 'https://esm.sh/@supabase/supabase-js@2';
import { SUPABASE_CONFIG, APP_CONFIG, ROUTES } from './config.js';

// Instancia única del cliente Supabase
export const sb = createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);

// =====================================================
// SESIÓN
// =====================================================

/** Devuelve la sesión activa o null. */
export async function getSession() {
  const { data: { session } } = await sb.auth.getSession();
  return session;
}

/**
 * Devuelve el perfil del usuario autenticado o null.
 * Consulta profiles con org_id, role, onboarding_version y estado.
 */
export async function getProfile() {
  const session = await getSession();
  if (!session) return null;

  const { data, error } = await sb
    .from('profiles')
    .select('id, org_id, role, preferred_name, is_active, onboarding_version')
    .eq('id', session.user.id)
    .single();

  if (error || !data) return null;
  return data;
}

// =====================================================
// AUTENTICACIÓN
// =====================================================

/**
 * Inicia sesión con email y contraseña.
 * RS-SEC-05: el mensaje de error es genérico (no revela si el email existe).
 * En caso de éxito, redirige automáticamente según rol y estado del usuario.
 */
export async function login(email, password) {
  const { data, error } = await sb.auth.signInWithPassword({ email, password });

  if (error) {
    throw new Error('Credenciales incorrectas. Verifica tu email y contraseña.');
  }

  const profile = await getProfile();
  if (!profile || !profile.is_active) {
    await sb.auth.signOut();
    throw new Error('Tu cuenta no está activa. Contacta al administrador de tu organización.');
  }

  _redirectAfterLogin(profile);
  return data;
}

/** Cierra la sesión y redirige al login. */
export async function logout() {
  await sb.auth.signOut();
  window.location.href = ROUTES.login;
}

/**
 * Solicita recuperación de contraseña.
 * Siempre responde de forma neutra (anti-enumeración, HU-CA-001).
 * El email de recuperación redirige a reset-password.html.
 */
export async function requestPasswordReset(email) {
  await sb.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/reset-password.html`,
  });
  // No lanzamos error aunque el email no exista.
}

// =====================================================
// GUARDIAS DE RUTA
// =====================================================

/**
 * Requiere sesión activa y perfil válido.
 * Si no hay sesión, redirige al login.
 * Usar en el inicio de cada página protegida.
 * @returns {Promise<object|null>} El perfil si está autenticado, null si fue redirigido.
 */
export async function requireAuth() {
  const profile = await getProfile();
  if (!profile || !profile.is_active) {
    await sb.auth.signOut();
    window.location.href = ROUTES.login;
    return null;
  }
  return profile;
}

/**
 * Requiere que NO haya sesión activa.
 * Si ya hay sesión, redirige al destino correcto según el rol.
 * Usar en la página de login para no mostrarla si ya está autenticado.
 */
export async function requireNoAuth() {
  const profile = await getProfile();
  if (profile && profile.is_active) {
    _redirectAfterLogin(profile);
  }
}

// =====================================================
// ENRUTAMIENTO
// =====================================================

/**
 * Determina y ejecuta la redirección post-login según el estado del perfil.
 * Orden: onboarding pendiente → consentimiento → destino por rol.
 */
function _redirectAfterLogin(profile) {
  // Onboarding pendiente (HU-CA-006)
  if (!profile.onboarding_version
      || profile.onboarding_version !== APP_CONFIG.onboardingVersion) {
    window.location.href = ROUTES.onboarding;
    return;
  }

  // Destino por rol
  const destinations = {
    player:    ROUTES.hub,
    coach:     ROUTES.hub,
    org_admin: ROUTES.admin,
    sys_admin: ROUTES.sysadmin,
  };
  window.location.href = destinations[profile.role] ?? ROUTES.hub;
}
