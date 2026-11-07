import * as functions from 'firebase-functions';
import { requireAdminUid } from './auth';

describe('requireAdminUid', () => {
  it('rejects unauthenticated callers', () => {
    try {
      requireAdminUid(undefined, undefined);
      throw new Error('Expected unauthenticated rejection');
    } catch (error) {
      expect(error).toBeInstanceOf(functions.https.HttpsError);
      expect((error as functions.https.HttpsError).code).toBe('unauthenticated');
    }
  });

  it.each([undefined, false, 'true', 1])(
    'rejects callers without the literal admin claim: %p',
    (adminClaim) => {
      expect(() => requireAdminUid('user-id', adminClaim))
        .toThrow(expect.objectContaining({ code: 'permission-denied' }));
    },
  );

  it('returns the uid only when the trusted boolean claim is true', () => {
    expect(requireAdminUid('trusted-admin', true)).toBe('trusted-admin');
  });
});
