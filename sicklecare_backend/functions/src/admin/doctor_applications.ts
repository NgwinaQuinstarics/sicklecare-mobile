import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { randomUUID } from 'crypto';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { checkRateLimit } from '../utils';
import { requireAdminUid } from './auth';
import {
  parseDoctorApplicationPageRequest,
  parseDoctorApplicationPayload,
  parseDoctorApplicationReviewRequest,
  parseDoctorApplicationUid,
  type DoctorApplicationPayload,
} from './doctor_application_validation';

const db = admin.firestore();
const credentialBucket = admin.storage().bucket();
const maxCredentialBytes = 10 * 1024 * 1024;
const allowedCredentialTypes = new Set([
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
]);

function requireApplicantUid(context: functions.https.CallableContext): string {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in to submit a professional application',
    );
  }
  return context.auth.uid;
}

async function enforceRateLimit(
  uid: string,
  action: string,
  limit: number,
): Promise<void> {
  if (!(await checkRateLimit(uid, action, limit, 60000))) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Too many requests; wait a moment and try again',
    );
  }
}

function invalidArgument(error: unknown): never {
  if (error instanceof TypeError) {
    throw new functions.https.HttpsError('invalid-argument', error.message);
  }
  throw error;
}

function toApplicationSummary(
  id: string,
  record: FirebaseFirestore.DocumentData,
): Record<string, unknown> {
  const createdAt = record.createdAt instanceof Timestamp ?
    record.createdAt.toDate().toISOString() : null;
  const updatedAt = record.updatedAt instanceof Timestamp ?
    record.updatedAt.toDate().toISOString() : null;
  return {
    uid: id,
    fullName: record.fullName,
    email: record.email,
    phone: record.phone,
    specialty: record.specialty,
    licenseNumber: record.licenseNumber,
    qualifications: record.qualifications,
    facilityName: record.facilityName,
    yearsOfExperience: record.yearsOfExperience,
    availabilityDays: record.availabilityDays,
    bio: record.bio,
    status: record.status,
    reviewNotes: typeof record.reviewNotes === 'string' ?
      record.reviewNotes : '',
    createdAt,
    updatedAt,
    hasCredential: typeof record.credential?.path === 'string',
  };
}

function matchesCredentialSignature(bytes: Buffer, contentType: string): boolean {
  switch (contentType) {
    case 'application/pdf':
      return bytes.subarray(0, 5).toString('ascii') === '%PDF-';
    case 'image/jpeg':
      return bytes.length >= 3 &&
        bytes[0] === 0xff &&
        bytes[1] === 0xd8 &&
        bytes[2] === 0xff;
    case 'image/png':
      return bytes.subarray(0, 8).equals(
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      );
    case 'image/webp':
      return bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
        bytes.subarray(8, 12).toString('ascii') === 'WEBP';
    default:
      return false;
  }
}

export const createDoctorApplication = functions.https.onCall(
  async (data, context) => {
    const uid = requireApplicantUid(context);
    await enforceRateLimit(uid, 'createDoctorApplication', 5);

    let application: DoctorApplicationPayload;
    try {
      application = parseDoctorApplicationPayload(data, context.auth?.token.email);
    } catch (error) {
      invalidArgument(error);
    }

    const applicationRef = db.collection('doctor_applications').doc(uid);
    const profileRef = db.collection('users').doc(uid);
    const uploadPath = `doctor_credentials/${uid}/${randomUUID()}`;

    try {
      const result = await db.runTransaction(async (transaction) => {
        const existing = await transaction.get(applicationRef);
        const prior = existing.data();
        if (
          prior?.status === 'upload_required' &&
          typeof prior.credentialUploadPath === 'string'
        ) {
          return {
            status: prior.status as string,
            uploadPath: prior.credentialUploadPath as string,
          };
        }
        if (
          prior &&
          prior.status !== 'rejected'
        ) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'An application is already being reviewed or this account is not eligible to apply',
          );
        }
        if (typeof prior?.credential?.path === 'string') {
          transaction.create(
            applicationRef.collection('credential_history').doc(),
            {
              ...prior.credential,
              reviewStatus: prior.status,
              archivedAt: FieldValue.serverTimestamp(),
            },
          );
        }

        const applicationData = {
          ...application,
          uid,
          status: 'upload_required',
          credentialUploadPath: uploadPath,
          submissionCount: (prior?.submissionCount ?? 0) + 1,
          createdAt: prior?.createdAt ?? FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          reviewNotes: FieldValue.delete(),
          reviewedAt: FieldValue.delete(),
          reviewedBy: FieldValue.delete(),
          credential: FieldValue.delete(),
        };
        transaction.set(applicationRef, applicationData, { merge: true });
        transaction.set(profileRef, {
          requestedAccountType: 'doctor',
          doctorStatus: 'upload_required',
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        return { status: 'upload_required', uploadPath };
      });

      return result;
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error('Unable to create doctor application:', error);
      throw new functions.https.HttpsError(
        'internal',
        'The professional application could not be saved',
      );
    }
  },
);

export const prepareDoctorCredentialResubmission = functions.https.onCall(
  async (_data, context) => {
    const uid = requireApplicantUid(context);
    await enforceRateLimit(uid, 'prepareDoctorCredentialResubmission', 3);
    const applicationRef = db.collection('doctor_applications').doc(uid);
    const uploadPath = `doctor_credentials/${uid}/${randomUUID()}`;
    try {
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(applicationRef);
        const application = snapshot.data();
        if (!snapshot.exists || application?.status !== 'rejected') {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Only a rejected application can be resubmitted',
          );
        }
        if (typeof application.credential?.path === 'string') {
          transaction.create(
            applicationRef.collection('credential_history').doc(),
            {
              ...application.credential,
              reviewStatus: 'rejected',
              archivedAt: FieldValue.serverTimestamp(),
            },
          );
        }
        transaction.update(applicationRef, {
          status: 'upload_required',
          credentialUploadPath: uploadPath,
          credential: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        transaction.set(db.collection('users').doc(uid), {
          doctorStatus: 'upload_required',
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        transaction.create(db.collection('doctor_application_events').doc(), {
          actorUid: uid,
          action: 'doctor.application.resubmission_started',
          resourceId: uid,
          createdAt: FieldValue.serverTimestamp(),
        });
      });
      return { status: 'upload_required' };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error('Unable to prepare doctor credential resubmission:', error);
      throw new functions.https.HttpsError(
        'internal',
        'The application could not be prepared for resubmission',
      );
    }
  },
);

export const finalizeDoctorApplication = functions.https.onCall(
  async (data, context) => {
    const uid = requireApplicantUid(context);
    await enforceRateLimit(uid, 'finalizeDoctorApplication', 5);

    if (typeof data !== 'object' || data === null || Array.isArray(data)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Credential details are required',
      );
    }
    const input = data as Record<string, unknown>;
    const credentialType = input.credentialType;
    const issuer = input.issuer;
    const referenceNumber = input.referenceNumber ?? '';
    if (
      typeof credentialType !== 'string' ||
      credentialType.trim().length === 0 ||
      credentialType.length > 80 ||
      typeof issuer !== 'string' ||
      issuer.trim().length === 0 ||
      issuer.length > 160 ||
      typeof referenceNumber !== 'string' ||
      referenceNumber.length > 80
    ) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Provide a document type and issuing organisation',
      );
    }

    const applicationRef = db.collection('doctor_applications').doc(uid);
    try {
      const applicationSnapshot = await applicationRef.get();
      const application = applicationSnapshot.data();
      if (
        !applicationSnapshot.exists ||
        application?.status !== 'upload_required' ||
        typeof application.credentialUploadPath !== 'string' ||
        !application.credentialUploadPath.startsWith(`doctor_credentials/${uid}/`)
      ) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Start or update your application before uploading credentials',
        );
      }

      const file = credentialBucket.file(application.credentialUploadPath);
      const [metadata] = await file.getMetadata();
      const size = Number(metadata.size);
      if (
        !allowedCredentialTypes.has(metadata.contentType ?? '') ||
        !Number.isSafeInteger(size) ||
        size < 1 ||
        size > maxCredentialBytes
      ) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Upload a PDF or image no larger than 10 MB',
        );
      }
      const [contents] = await file.download();
      if (!matchesCredentialSignature(contents, metadata.contentType ?? '')) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'The uploaded file does not match its declared document type',
        );
      }

      await db.runTransaction(async (transaction) => {
        const current = await transaction.get(applicationRef);
        if (current.data()?.status !== 'upload_required') {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'The application has already been submitted',
          );
        }
        const eventRef = db.collection('doctor_application_events').doc();
        transaction.update(applicationRef, {
          status: 'pending',
          credentialUploadPath: FieldValue.delete(),
          credential: {
            path: application.credentialUploadPath,
            type: credentialType.trim(),
            issuer: issuer.trim(),
            referenceNumber: referenceNumber.trim(),
            contentType: metadata.contentType,
            size,
            submittedAt: FieldValue.serverTimestamp(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        });
        transaction.set(db.collection('users').doc(uid), {
          doctorStatus: 'pending',
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        transaction.create(eventRef, {
          actorUid: uid,
          action: 'doctor.application.submitted',
          resourceId: uid,
          createdAt: FieldValue.serverTimestamp(),
        });
      });
      return { status: 'pending' };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 404
      ) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Upload the credential file before submitting',
        );
      }
      console.error('Unable to finalize doctor application:', error);
      throw new functions.https.HttpsError(
        'internal',
        'The credential could not be submitted for review',
      );
    }
  },
);

export const listDoctorApplications = functions.https.onCall(
  async (data, context) => {
    const actorUid = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(actorUid, 'listDoctorApplications', 30);

    let request;
    try {
      request = parseDoctorApplicationPageRequest(data);
    } catch (error) {
      invalidArgument(error);
    }

    try {
      let pageQuery: FirebaseFirestore.Query =
        db.collection('doctor_applications');
      if (request.status !== 'all') {
        pageQuery = pageQuery.where('status', '==', request.status);
      }
      pageQuery = pageQuery.orderBy('updatedAt', 'desc');
      if (request.pageToken) {
        const cursor = await db.collection('doctor_applications')
          .doc(request.pageToken)
          .get();
        if (!cursor.exists) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'The application page cursor is no longer valid',
          );
        }
        pageQuery = pageQuery.startAfter(cursor);
      }
      const page = await pageQuery.limit(request.pageSize + 1).get();
      const docs = page.docs.slice(0, request.pageSize);
      const hasMore = page.docs.length > request.pageSize;
      return {
        applications: docs.map((doc) =>
          toApplicationSummary(doc.id, doc.data()),
        ),
        nextPageToken: hasMore ? docs[docs.length - 1]?.id ?? null : null,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error('Unable to list doctor applications:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Doctor applications are temporarily unavailable',
      );
    }
  },
);

export const getDoctorApplicationCredential = functions.https.onCall(
  async (data, context) => {
    const actorUid = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(actorUid, 'getDoctorApplicationCredential', 20);
    let uid: string;
    try {
      uid = parseDoctorApplicationUid(data);
    } catch (error) {
      invalidArgument(error);
    }

    try {
      const applicationRef = db.collection('doctor_applications').doc(uid);
      const snapshot = await applicationRef.get();
      const credentialPath = snapshot.data()?.credential?.path;
      if (
        !snapshot.exists ||
        typeof credentialPath !== 'string' ||
        !credentialPath.startsWith(`doctor_credentials/${uid}/`)
      ) {
        throw new functions.https.HttpsError(
          'not-found',
          'No credential is available for this application',
        );
      }
      await db.collection('admin_audit_logs').add({
        actorUid,
        action: 'doctor.credential.viewed',
        resource: 'doctor_applications',
        resourceId: uid,
        createdAt: FieldValue.serverTimestamp(),
      });
      return {
        path: credentialPath,
        contentType: snapshot.data()?.credential?.contentType ?? 'application/pdf',
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error('Unable to authorize credential review:', error);
      throw new functions.https.HttpsError(
        'internal',
        'The credential could not be opened',
      );
    }
  },
);

export const reviewDoctorApplication = functions.https.onCall(
  async (data, context) => {
    const actorUid = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(actorUid, 'reviewDoctorApplication', 20);

    let request;
    try {
      request = parseDoctorApplicationReviewRequest(data);
    } catch (error) {
      invalidArgument(error);
    }

    const applicationRef = db.collection('doctor_applications').doc(request.uid);
    const userRef = db.collection('users').doc(request.uid);
    try {
      const [applicationSnapshot, user] = await Promise.all([
        applicationRef.get(),
        admin.auth().getUser(request.uid),
      ]);
      if (!applicationSnapshot.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Doctor application was not found',
        );
      }
      const currentStatus = applicationSnapshot.data()?.status;
      if (request.action === 'deactivate') {
        if (currentStatus === 'deactivated') {
          return { success: true, status: 'deactivated' };
        }
        await admin.auth().updateUser(request.uid, { disabled: true });
        const claims = { ...(user.customClaims ?? {}) };
        delete claims.doctor;
        await admin.auth().setCustomUserClaims(request.uid, claims);
        await admin.auth().revokeRefreshTokens(request.uid);
        await db.runTransaction(async (transaction) => {
          transaction.update(applicationRef, {
            status: 'deactivated',
            deactivatedFromStatus: currentStatus,
            reviewNotes: request.notes,
            reviewedBy: actorUid,
            reviewedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          transaction.set(userRef, {
            doctorStatus: 'deactivated',
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
          transaction.create(db.collection('admin_audit_logs').doc(), {
            actorUid,
            action: 'doctor.account.deactivated',
            resource: 'doctor_applications',
            resourceId: request.uid,
            status: 'deactivated',
            createdAt: FieldValue.serverTimestamp(),
          });
        });
        return { success: true, status: 'deactivated' };
      }

      if (request.action === 'reactivate') {
        if (currentStatus !== 'deactivated') {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Only a deactivated account can be reactivated',
          );
        }
        const previousStatus = applicationSnapshot.data()?.deactivatedFromStatus;
        if (
          previousStatus !== 'approved' &&
          previousStatus !== 'rejected' &&
          previousStatus !== 'pending' &&
          previousStatus !== 'upload_required'
        ) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'The prior application status cannot be restored',
          );
        }
        if (previousStatus === 'approved') {
          const credentialPath = applicationSnapshot.data()?.credential?.path;
          if (
            typeof credentialPath !== 'string' ||
            !credentialPath.startsWith(`doctor_credentials/${request.uid}/`)
          ) {
            throw new functions.https.HttpsError(
              'failed-precondition',
              'The approved credential is unavailable; the account cannot be reactivated',
            );
          }
          const [credentialExists] =
            await credentialBucket.file(credentialPath).exists();
          if (!credentialExists) {
            throw new functions.https.HttpsError(
              'failed-precondition',
              'The approved credential is unavailable; the account cannot be reactivated',
            );
          }
        }
        const claims = { ...(user.customClaims ?? {}) };
        if (previousStatus === 'approved') {
          claims.doctor = true;
        } else {
          delete claims.doctor;
        }
        await admin.auth().setCustomUserClaims(request.uid, claims);
        await admin.auth().updateUser(request.uid, { disabled: false });
        await admin.auth().revokeRefreshTokens(request.uid);
        await db.runTransaction(async (transaction) => {
          transaction.update(applicationRef, {
            status: previousStatus,
            deactivatedFromStatus: FieldValue.delete(),
            reviewedBy: actorUid,
            reviewedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          transaction.set(userRef, {
            doctorStatus: previousStatus,
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
          transaction.create(db.collection('admin_audit_logs').doc(), {
            actorUid,
            action: 'doctor.account.reactivated',
            resource: 'doctor_applications',
            resourceId: request.uid,
            status: previousStatus,
            createdAt: FieldValue.serverTimestamp(),
          });
        });
        return { success: true, status: previousStatus };
      }

      if (currentStatus !== 'pending') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Only pending applications can be approved or rejected',
        );
      }

      if (request.action === 'approve' && user.disabled) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'A disabled account cannot be approved',
        );
      }
      if (request.action === 'approve') {
        const credentialPath = applicationSnapshot.data()?.credential?.path;
        if (
          typeof credentialPath !== 'string' ||
          !credentialPath.startsWith(`doctor_credentials/${request.uid}/`)
        ) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'A submitted credential is required before approval',
          );
        }
        const [credentialExists] =
          await credentialBucket.file(credentialPath).exists();
        if (!credentialExists) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'The submitted credential is no longer available',
          );
        }
      }

      const status = request.action === 'approve' ? 'approved' : 'rejected';
      await db.runTransaction(async (transaction) => {
        const latest = await transaction.get(applicationRef);
        if (latest.data()?.status !== 'pending') {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'This application has already been reviewed',
          );
        }
        transaction.update(applicationRef, {
          status,
          reviewNotes: request.notes,
          reviewedBy: actorUid,
          reviewedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        transaction.set(userRef, {
          doctorStatus: status,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        transaction.create(db.collection('admin_audit_logs').doc(), {
          actorUid,
          action: `doctor.application.${status}`,
          resource: 'doctor_applications',
          resourceId: request.uid,
          status,
          createdAt: FieldValue.serverTimestamp(),
        });
      });

      try {
        const claims = { ...(user.customClaims ?? {}) };
        if (request.action === 'approve') {
          claims.doctor = true;
        } else {
          delete claims.doctor;
        }
        await admin.auth().setCustomUserClaims(request.uid, claims);
      } catch (claimError) {
          await db.runTransaction(async (transaction) => {
            transaction.update(applicationRef, {
              status: 'pending',
              reviewNotes: '',
              reviewedBy: FieldValue.delete(),
              reviewedAt: FieldValue.delete(),
              updatedAt: FieldValue.serverTimestamp(),
            });
            transaction.set(userRef, {
              doctorStatus: 'pending',
              updatedAt: FieldValue.serverTimestamp(),
            }, { merge: true });
            transaction.create(db.collection('admin_audit_logs').doc(), {
              actorUid,
              action: 'doctor.application.approval_claim_failed',
              resource: 'doctor_applications',
              resourceId: request.uid,
              status: 'pending',
              createdAt: FieldValue.serverTimestamp(),
            });
          });
          throw claimError;
      }

      return { success: true, status };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'auth/user-not-found'
      ) {
        throw new functions.https.HttpsError('not-found', 'User was not found');
      }
      console.error('Unable to review doctor application:', error);
      throw new functions.https.HttpsError(
        'internal',
        'The application review could not be completed',
      );
    }
  },
);

export const doctorApplicationFunctions = {
  createDoctorApplication,
  prepareDoctorCredentialResubmission,
  finalizeDoctorApplication,
  listDoctorApplications,
  getDoctorApplicationCredential,
  reviewDoctorApplication,
};
