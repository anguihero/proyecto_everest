const ERROR_MESSAGES = {
  assignment_not_found: 'Esta experiencia no está disponible para tu usuario.',
  assignment_revoked: 'Esta experiencia fue revocada por tu organización.',
  assignment_due_date_passed: 'La fecha límite de esta experiencia ya terminó.',
  version_not_published: 'La experiencia no está publicada todavía.',
  session_version_not_found: 'La versión de esta experiencia ya no está disponible.',
  consent_required: 'Necesitas aceptar el consentimiento antes de empezar.',
  assignment_has_history: 'No se puede eliminar porque ya tiene actividad. Revócala para conservar el historial.',
  completed_assignment_is_immutable: 'Una asignación completada no se puede modificar.',
  assignment_already_exists: 'Este usuario ya tiene esta experiencia asignada.',
  due_date_in_past: 'La fecha límite no puede estar en el pasado.',
  due_date_incomplete: 'Selecciona día, mes y año, o deja toda la fecha vacía.',
  due_date_invalid: 'La fecha seleccionada no existe.',
  target_user_not_assignable: 'El usuario no está activo o no pertenece a tu organización.',
  published_version_not_found: 'Esta experiencia no tiene una versión publicada.',
};

export function getErrorKey(error) {
  const source = [
    error?.message,
    error?.details,
    error?.hint,
    error?.code,
  ].filter(Boolean).join(' ').toLowerCase();

  return Object.keys(ERROR_MESSAGES).find(key => source.includes(key)) ?? null;
}

export function getErrorMessage(error, fallback) {
  const key = getErrorKey(error);
  return key ? ERROR_MESSAGES[key] : fallback;
}

export function getSafeErrorDiagnostic(error) {
  return {
    key: getErrorKey(error) ?? 'unexpected_error',
    code: error?.code ?? null,
  };
}
