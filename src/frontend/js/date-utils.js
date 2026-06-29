export function buildOptionalDate({ day, month, year }, todayISO) {
  const parts = [day, month, year];
  if (parts.every(part => !part)) return null;
  if (parts.some(part => !part)) throw new Error('due_date_incomplete');

  const y = Number(year);
  const m = Number(month);
  const d = Number(day);
  const date = new Date(Date.UTC(y, m - 1, d));
  const isValid = date.getUTCFullYear() === y
    && date.getUTCMonth() === m - 1
    && date.getUTCDate() === d;

  if (!isValid) throw new Error('due_date_invalid');

  const iso = `${String(y).padStart(4, '0')}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
  if (todayISO && iso < todayISO) throw new Error('due_date_in_past');
  return iso;
}

