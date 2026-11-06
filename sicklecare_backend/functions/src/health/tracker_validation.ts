export interface TrackerEntry {
  id: string;
  date: string;
  painLevel: number;
  hydrationMl: number;
  mood: string;
  notes: string;
}

export function isValidTrackerEntry(
  value: unknown,
  entryId: string,
): value is TrackerEntry {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    return false;
  }

  const data = value as Record<string, unknown>;
  const allowedFields = [
    'id',
    'date',
    'painLevel',
    'hydrationMl',
    'mood',
    'notes',
  ];

  return entryId.length <= 128 &&
    Object.keys(data).every((field) => allowedFields.includes(field)) &&
    data.id === entryId &&
    typeof data.date === 'string' &&
    data.date.length <= 32 &&
    Number.isFinite(Date.parse(data.date)) &&
    Number.isInteger(data.painLevel) &&
    Number(data.painLevel) >= 0 &&
    Number(data.painLevel) <= 10 &&
    Number.isInteger(data.hydrationMl) &&
    Number(data.hydrationMl) >= 0 &&
    Number(data.hydrationMl) <= 10000 &&
    typeof data.mood === 'string' &&
    data.mood.length <= 32 &&
    typeof data.notes === 'string' &&
    data.notes.length <= 2000;
}
