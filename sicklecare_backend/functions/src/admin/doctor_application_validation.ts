const specialties = new Set([
  'Haematology',
  'General practice',
  'Paediatrics',
  'Internal medicine',
  'Nursing',
  'Pharmacy',
  'Other',
]);

const weekdays = new Set(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);

export interface DoctorApplicationPayload {
  fullName: string;
  email: string;
  phone: string;
  specialty: string;
  licenseNumber: string;
  qualifications: string;
  facilityName: string;
  yearsOfExperience: number;
  availabilityDays: string[];
  bio: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function requiredText(
  data: Record<string, unknown>,
  key: string,
  maxLength: number,
): string {
  const value = data[key];
  if (
    typeof value !== 'string' ||
    value.trim().length === 0 ||
    value.trim().length > maxLength
  ) {
    throw new TypeError(`${key} must be a non-empty string of at most ${maxLength} characters`);
  }
  return value.trim();
}

function optionalText(
  data: Record<string, unknown>,
  key: string,
  maxLength: number,
): string {
  const value = data[key];
  if (value === undefined) return '';
  if (typeof value !== 'string' || value.trim().length > maxLength) {
    throw new TypeError(`${key} must be a string of at most ${maxLength} characters`);
  }
  return value.trim();
}

export function parseDoctorApplicationPayload(
  value: unknown,
  authenticatedEmail: string | undefined,
): DoctorApplicationPayload {
  if (!isRecord(value)) throw new TypeError('Application details are required');

  const fullName = requiredText(value, 'fullName', 120);
  const email = requiredText(value, 'email', 254).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new TypeError('A valid email address is required');
  }
  if (!authenticatedEmail || email !== authenticatedEmail.toLowerCase()) {
    throw new TypeError('The application email must match the signed-in account');
  }

  const specialty = requiredText(value, 'specialty', 60);
  if (!specialties.has(specialty)) throw new TypeError('Choose a valid specialty');

  const yearsOfExperience = value.yearsOfExperience;
  if (
    typeof yearsOfExperience !== 'number' ||
    !Number.isInteger(yearsOfExperience) ||
    yearsOfExperience < 0 ||
    yearsOfExperience > 80
  ) {
    throw new TypeError('Years of experience must be an integer from 0 to 80');
  }

  const availabilityDays = value.availabilityDays;
  if (
    !Array.isArray(availabilityDays) ||
    availabilityDays.length < 1 ||
    availabilityDays.length > 7 ||
    availabilityDays.some(
      (day) => typeof day !== 'string' || !weekdays.has(day),
    ) ||
    new Set(availabilityDays).size !== availabilityDays.length
  ) {
    throw new TypeError('Choose one or more valid availability days');
  }

  const validatedAvailabilityDays = availabilityDays.filter(
    (day): day is string => typeof day === 'string',
  );
  return {
    fullName,
    email,
    phone: requiredText(value, 'phone', 40),
    specialty,
    licenseNumber: requiredText(value, 'licenseNumber', 80),
    qualifications: requiredText(value, 'qualifications', 300),
    facilityName: requiredText(value, 'facilityName', 160),
    yearsOfExperience,
    availabilityDays: validatedAvailabilityDays,
    bio: optionalText(value, 'bio', 1000),
  };
}

export interface DoctorApplicationPageRequest {
  pageSize: number;
  pageToken?: string;
  status: 'all' | 'pending' | 'approved' | 'rejected' | 'deactivated';
}

export function parseDoctorApplicationPageRequest(
  value: unknown,
): DoctorApplicationPageRequest {
  if (!isRecord(value)) throw new TypeError('Request must be an object');
  const pageSize = value.pageSize === undefined ? 25 : value.pageSize;
  if (
    typeof pageSize !== 'number' ||
    !Number.isInteger(pageSize) ||
    pageSize < 1 ||
    pageSize > 50
  ) {
    throw new TypeError('pageSize must be an integer from 1 to 50');
  }
  const pageToken = value.pageToken;
  if (
    pageToken !== undefined &&
    (typeof pageToken !== 'string' || pageToken.length < 1 || pageToken.length > 128)
  ) {
    throw new TypeError('pageToken must be a valid document ID');
  }
  const status = value.status === undefined ? 'pending' : value.status;
  if (
    status !== 'all' &&
    status !== 'pending' &&
    status !== 'approved' &&
    status !== 'rejected' &&
    status !== 'deactivated'
  ) {
    throw new TypeError('Choose a valid application status');
  }
  return {
    pageSize,
    pageToken: pageToken as string | undefined,
    status,
  };
}

export interface DoctorApplicationReviewRequest {
  uid: string;
  action: 'approve' | 'reject' | 'deactivate' | 'reactivate';
  notes: string;
}

export function parseDoctorApplicationReviewRequest(
  value: unknown,
): DoctorApplicationReviewRequest {
  if (!isRecord(value)) throw new TypeError('Request must be an object');
  const uid = value.uid;
  if (typeof uid !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new TypeError('A valid user ID is required');
  }
  const action = value.action;
  if (
    action !== 'approve' &&
    action !== 'reject' &&
    action !== 'deactivate' &&
    action !== 'reactivate'
  ) {
    throw new TypeError('Choose a valid application action');
  }
  const notes = optionalText(value, 'notes', 500);
  return { uid, action, notes };
}

export function parseDoctorApplicationUid(value: unknown): string {
  if (
    !isRecord(value) ||
    typeof value.uid !== 'string' ||
    !/^[A-Za-z0-9_-]{1,128}$/.test(value.uid)
  ) {
    throw new TypeError('A valid user ID is required');
  }
  return value.uid;
}
