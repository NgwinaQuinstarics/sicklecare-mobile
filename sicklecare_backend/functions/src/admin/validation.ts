export interface AdminUserPageRequest {
  pageToken?: string;
  pageSize: number;
}

export interface AdminUserDataPageRequest {
  uid: string;
  pageToken?: string;
  pageSize: number;
}

export function parseAdminUserPageRequest(data: unknown): AdminUserPageRequest {
  if (data === null || typeof data !== 'object' || Array.isArray(data)) {
    throw new TypeError('Request must be an object');
  }

  const request = data as Record<string, unknown>;
  let pageSize = 25;
  if (request.pageSize !== undefined) {
    if (
      typeof request.pageSize !== 'number' ||
      !Number.isInteger(request.pageSize) ||
      request.pageSize < 1 ||
      request.pageSize > 50
    ) {
      throw new TypeError('Page size must be an integer between 1 and 50');
    }
    pageSize = request.pageSize;
  }

  const pageToken = request.pageToken;
  if (
    pageToken !== undefined &&
    (typeof pageToken !== 'string' ||
      pageToken.length === 0 ||
      pageToken.length > 2048)
  ) {
    throw new TypeError('Page token is invalid');
  }

  return {
    pageSize,
    ...(typeof pageToken === 'string' ? { pageToken } : {}),
  };
}

export function parseAdminUserDataPageRequest(
  data: unknown,
): AdminUserDataPageRequest {
  if (data === null || typeof data !== 'object' || Array.isArray(data)) {
    throw new TypeError('Request must be an object');
  }

  const request = data as Record<string, unknown>;
  if (
    Object.keys(request).some(
      (key) => !['uid', 'pageSize', 'pageToken'].includes(key),
    ) ||
    typeof request.uid !== 'string' ||
    request.uid.length === 0 ||
    request.uid.length > 128 ||
    request.uid.includes('/')
  ) {
    throw new TypeError('User id is invalid');
  }

  let pageSize = 20;
  if (request.pageSize !== undefined) {
    if (
      typeof request.pageSize !== 'number' ||
      !Number.isInteger(request.pageSize) ||
      request.pageSize < 1 ||
      request.pageSize > 25
    ) {
      throw new TypeError('Page size must be an integer between 1 and 25');
    }
    pageSize = request.pageSize;
  }

  const pageToken = request.pageToken;
  if (
    pageToken !== undefined &&
    (typeof pageToken !== 'string' ||
      pageToken.length === 0 ||
      pageToken.length > 128 ||
      pageToken.includes('/'))
  ) {
    throw new TypeError('Page token is invalid');
  }

  return {
    uid: request.uid,
    pageSize,
    ...(typeof pageToken === 'string' ? { pageToken } : {}),
  };
}
