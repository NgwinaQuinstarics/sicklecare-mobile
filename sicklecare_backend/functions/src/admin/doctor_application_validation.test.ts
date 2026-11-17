import {
  parseDoctorApplicationPageRequest,
  parseDoctorApplicationPayload,
  parseDoctorApplicationReviewRequest,
} from './doctor_application_validation';

const validApplication = {
  fullName: 'Dr. Amara Nfor',
  email: 'doctor@example.org',
  phone: '+237 600 000 000',
  specialty: 'Haematology',
  licenseNumber: 'CM-12345',
  qualifications: 'MBBS, MSc Haematology',
  facilityName: 'Regional Hospital Buea',
  yearsOfExperience: 5,
  availabilityDays: ['Mon', 'Wed'],
  bio: 'Sickle cell care',
};

describe('parseDoctorApplicationPayload', () => {
  it('accepts a bounded application for the authenticated email', () => {
    expect(
      parseDoctorApplicationPayload(validApplication, 'DOCTOR@example.org'),
    ).toEqual({ ...validApplication, email: 'doctor@example.org' });
  });

  it('rejects an email that differs from the signed-in account', () => {
    expect(() =>
      parseDoctorApplicationPayload(validApplication, 'other@example.org'),
    ).toThrow('must match the signed-in account');
  });

  it.each([
    ['unsupported specialty', { ...validApplication, specialty: 'Surgeon' }],
    ['invalid years', { ...validApplication, yearsOfExperience: 81 }],
    ['duplicate days', { ...validApplication, availabilityDays: ['Mon', 'Mon'] }],
    ['missing license', { ...validApplication, licenseNumber: ' ' }],
  ])('rejects %s', (_description, payload) => {
    expect(() => parseDoctorApplicationPayload(payload, 'doctor@example.org'))
      .toThrow();
  });
});

describe('doctor application admin request validation', () => {
  it('caps page size and accepts an optional cursor', () => {
    expect(parseDoctorApplicationPageRequest({ pageSize: 50, pageToken: 'abc' }))
      .toEqual({ pageSize: 50, pageToken: 'abc', status: 'pending' });
    expect(() => parseDoctorApplicationPageRequest({ pageSize: 51 })).toThrow();
  });

  it('accepts only known moderation actions and bounded notes', () => {
    expect(parseDoctorApplicationReviewRequest({
      uid: 'user_123',
      action: 'reject',
      notes: 'Please upload a clearer document.',
    })).toEqual({
      uid: 'user_123',
      action: 'reject',
      notes: 'Please upload a clearer document.',
    });
    expect(() => parseDoctorApplicationReviewRequest({
      uid: 'user_123',
      action: 'delete',
    })).toThrow();
  });
});
