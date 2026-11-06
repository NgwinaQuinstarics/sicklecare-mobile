import { isValidTrackerEntry } from './tracker_validation';

const validEntry = {
  id: 'entry-1',
  date: '2026-11-06T03:00:00.000',
  painLevel: 4,
  hydrationMl: 1250,
  mood: 'calm',
  notes: 'Feeling well',
};

describe('isValidTrackerEntry', () => {
  it('accepts a tracker payload that matches the Flutter model', () => {
    expect(isValidTrackerEntry(validEntry, 'entry-1')).toBe(true);
  });

  it('rejects a document id that differs from the payload id', () => {
    expect(isValidTrackerEntry(validEntry, 'another-entry')).toBe(false);
  });

  it.each([
    ['pain below the allowed range', { painLevel: -1 }],
    ['pain above the allowed range', { painLevel: 11 }],
    ['fractional pain values', { painLevel: 1.5 }],
    ['negative hydration', { hydrationMl: -1 }],
    ['excessive hydration', { hydrationMl: 10001 }],
    ['invalid dates', { date: 'not-a-date' }],
    ['unsupported fields', { role: 'admin' }],
  ])('rejects %s', (_description, override) => {
    expect(
      isValidTrackerEntry({ ...validEntry, ...override }, 'entry-1'),
    ).toBe(false);
  });

  it('rejects non-object payloads', () => {
    expect(isValidTrackerEntry(null, 'entry-1')).toBe(false);
    expect(isValidTrackerEntry([], 'entry-1')).toBe(false);
  });
});
