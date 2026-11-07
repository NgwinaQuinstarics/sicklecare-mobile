import {
  parseAdminUserDataPageRequest,
  parseAdminUserPageRequest,
} from './validation';

describe('parseAdminUserPageRequest', () => {
  it('uses the bounded default page size', () => {
    expect(parseAdminUserPageRequest({})).toEqual({ pageSize: 25 });
  });

  describe('parseAdminUserDataPageRequest', () => {
    it('accepts a user id and bounded record page', () => {
      expect(parseAdminUserDataPageRequest({
        uid: 'user_uid-123',
        pageSize: 10,
        pageToken: 'entry-2',
      })).toEqual({
        uid: 'user_uid-123',
        pageSize: 10,
        pageToken: 'entry-2',
      });
    });

    it.each([
      null,
      [],
      {},
      { uid: '../other-user' },
      { uid: 'valid-uid', pageSize: 26 },
      { uid: 'valid-uid', pageSize: 0 },
      { uid: 'valid-uid', pageToken: 'nested/entry' },
      { uid: 'valid-uid', isAdmin: true },
    ])('rejects invalid user data requests: %p', (request) => {
      expect(() => parseAdminUserDataPageRequest(request)).toThrow(TypeError);
    });
  });

  it('preserves a valid pagination token', () => {
    expect(parseAdminUserPageRequest({
      pageSize: 50,
      pageToken: 'next-page',
    })).toEqual({ pageSize: 50, pageToken: 'next-page' });
  });

  it.each([0, 51, 1.5, '25', null])(
    'rejects invalid page sizes: %p',
    (pageSize) => {
      expect(() => parseAdminUserPageRequest({ pageSize })).toThrow(TypeError);
    },
  );

  it.each(['', 'x'.repeat(2049), 42, null])(
    'rejects invalid page tokens: %p',
    (pageToken) => {
      expect(() => parseAdminUserPageRequest({ pageToken })).toThrow(TypeError);
    },
  );

  it('rejects non-object requests', () => {
    expect(() => parseAdminUserPageRequest(null)).toThrow(TypeError);
    expect(() => parseAdminUserPageRequest([])).toThrow(TypeError);
  });
});
