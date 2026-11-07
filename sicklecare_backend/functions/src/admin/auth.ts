import * as functions from 'firebase-functions';

export function requireAdminUid(
  uid: string | undefined,
  adminClaim: unknown,
): string {
  if (!uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in to continue',
    );
  }

  if (adminClaim !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Administrator access is required',
    );
  }

  return uid;
}
