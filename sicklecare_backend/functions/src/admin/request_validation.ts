import type { MessageKind, MessageStatus } from './types';

export type AdminInboxUpdateRequest = {
  id: string;
  kind: MessageKind;
  status: MessageStatus;
};

export type AdminHomeContentRequest = {
  heroTitle: string;
  heroBody: string;
};

export function parseAdminInboxUpdateRequest(
  data: unknown,
): AdminInboxUpdateRequest {
  if (!isRecord(data) || !hasOnlyKeys(data, ['id', 'kind', 'status'])) {
    throw new TypeError('Request must contain only an inbox id, kind, and status');
  }

  if (typeof data.id !== 'string' || data.id.length === 0 || data.id.length > 128) {
    throw new TypeError('Inbox id is invalid');
  }

  if (
    data.kind !== 'support_messages' &&
    data.kind !== 'contacts'
  ) {
    throw new TypeError('Inbox kind is invalid');
  }

  if (
    data.status !== 'new' &&
    data.status !== 'in_progress' &&
    data.status !== 'resolved' &&
    data.status !== 'closed'
  ) {
    throw new TypeError('Inbox status is invalid');
  }

  return {
    id: data.id,
    kind: data.kind,
    status: data.status,
  };
}

export function parseAdminHomeContentRequest(
  data: unknown,
): AdminHomeContentRequest {
  if (
    !isRecord(data) ||
    !hasOnlyKeys(data, ['heroTitle', 'heroBody']) ||
    typeof data.heroTitle !== 'string' ||
    typeof data.heroBody !== 'string'
  ) {
    throw new TypeError('Request must contain a title and welcome message');
  }

  const heroTitle = data.heroTitle.trim();
  const heroBody = data.heroBody.trim();
  if (
    heroTitle.length === 0 ||
    heroTitle.length > 120 ||
    heroBody.length === 0 ||
    heroBody.length > 2000
  ) {
    throw new TypeError('Title or welcome message is outside the allowed length');
  }

  return { heroTitle, heroBody };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function hasOnlyKeys(
  value: Record<string, unknown>,
  allowedKeys: string[],
): boolean {
  return Object.keys(value).every((key) => allowedKeys.includes(key));
}
