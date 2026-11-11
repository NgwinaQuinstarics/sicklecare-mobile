import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { checkRateLimit } from '../utils';
import { requireAdminUid } from './auth';
import {
  parseAdminUserDataPageRequest,
  parseAdminUserPageRequest,
  type AdminUserDataPageRequest,
  type AdminUserPageRequest,
} from './validation';
import {
  parseAdminHomeContentRequest,
  parseAdminInboxUpdateRequest,
} from './request_validation';
import type { MessageStatus } from './types';

const db = admin.firestore();
const openStatuses = ['new', 'in_progress'];

async function enforceRateLimit(
  userId: string,
  action: string,
  limit: number,
): Promise<void> {
  if (!(await checkRateLimit(userId, action, limit, 60000))) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Too many requests; wait a moment and try again',
    );
  }
}

export const getAdminDashboardSummary = functions.https.onCall(
  async (_data, context) => {
    const userId = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(userId, 'adminDashboardSummary', 30);

    try {
      const recentCutoff = Timestamp.fromDate(
        new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      );
      const [users, newUsers, openSupport, openContacts] = await Promise.all([
        db.collection('users').count().get(),
        db.collection('users')
          .where('createdAt', '>=', recentCutoff)
          .count()
          .get(),
        db.collection('support_messages')
          .where('status', 'in', openStatuses)
          .count()
          .get(),
        db.collection('contacts')
          .where('status', 'in', openStatuses)
          .count()
          .get(),
      ]);

      return {
        userCount: users.data().count,
        newUsersLast7Days: newUsers.data().count,
        openSupportCount: openSupport.data().count,
        openContactCount: openContacts.data().count,
        generatedAt: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Failed to build admin dashboard summary:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Dashboard summary is temporarily unavailable',
      );
    }
  },
);

export const listAdminUsers = functions.https.onCall(async (data, context) => {
  const userId = requireAdminUid(
    context.auth?.uid,
    context.auth?.token.admin,
  );
  await enforceRateLimit(userId, 'listAdminUsers', 30);

  let page: AdminUserPageRequest;
  try {
    page = parseAdminUserPageRequest(data);
  } catch (error) {
    if (error instanceof TypeError) {
      throw new functions.https.HttpsError('invalid-argument', error.message);
    }
    throw error;
  }

  try {
    const result = await admin.auth().listUsers(page.pageSize, page.pageToken);
    const profiles = result.users.length > 0 ? await db.getAll(
      ...result.users.map((user) => db.collection('users').doc(user.uid)),
    ) : [];

    return {
      users: result.users.map((user, index) => {
        const requestedAccountType =
          profiles[index].data()?.requestedAccountType;
        return {
          uid: user.uid,
          email: user.email ?? null,
          displayName: user.displayName ?? null,
          disabled: user.disabled,
          emailVerified: user.emailVerified,
          createdAt: user.metadata.creationTime,
          lastSignInAt: user.metadata.lastSignInTime ?? null,
          requestedAccountType:
            requestedAccountType === 'patient' ||
            requestedAccountType === 'doctor' ?
              requestedAccountType : null,
        };
      }),
      nextPageToken: result.pageToken ?? null,
    };
  } catch (error) {
    console.error('Failed to list admin dashboard users:', error);
    throw new functions.https.HttpsError(
      'internal',
      'User directory is temporarily unavailable',
    );
  }
});

export const updateAdminInboxStatus = functions.https.onCall(
  async (data, context) => {
    const userId = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(userId, 'updateAdminInboxStatus', 30);

    let request;
    try {
      request = parseAdminInboxUpdateRequest(data);
    } catch (error) {
      if (error instanceof TypeError) {
        throw new functions.https.HttpsError('invalid-argument', error.message);
      }
      throw error;
    }

    try {
      const requestRef = db.collection(request.kind).doc(request.id);
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            'The inbox request no longer exists',
          );
        }

        const auditRef = db.collection('admin_audit_logs').doc();
        transaction.update(requestRef, {
          status: request.status as MessageStatus,
          updatedAt: FieldValue.serverTimestamp(),
        });
        transaction.create(auditRef, {
          actorUid: userId,
          action: 'inbox.status.updated',
          resource: request.kind,
          resourceId: request.id,
          status: request.status,
          createdAt: FieldValue.serverTimestamp(),
        });
      });

      return { success: true };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error('Failed to update admin inbox status:', error);
      throw new functions.https.HttpsError(
        'internal',
        'The request could not be updated',
      );
    }
  },
);

export const updateAdminHomeContent = functions.https.onCall(
  async (data, context) => {
    const userId = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(userId, 'updateAdminHomeContent', 20);

    let content;
    try {
      content = parseAdminHomeContentRequest(data);
    } catch (error) {
      if (error instanceof TypeError) {
        throw new functions.https.HttpsError('invalid-argument', error.message);
      }
      throw error;
    }

    try {
      const contentRef = db.collection('content').doc('home');
      await db.runTransaction(async (transaction) => {
        await transaction.get(contentRef);
        const auditRef = db.collection('admin_audit_logs').doc();
        transaction.set(contentRef, {
          ...content,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        transaction.create(auditRef, {
          actorUid: userId,
          action: 'content.home.updated',
          resource: 'content/home',
          changedFields: ['heroTitle', 'heroBody'],
          createdAt: FieldValue.serverTimestamp(),
        });
      });

      return { success: true };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error('Failed to update admin home content:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Home content could not be published',
      );
    }
  },
);

export const getAdminUserDetails = functions.https.onCall(
  async (data, context) => {
    const actorUid = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(actorUid, 'getAdminUserDetails', 20);

    let request: AdminUserDataPageRequest;
    try {
      request = parseAdminUserDataPageRequest(data);
    } catch (error) {
      if (error instanceof TypeError) {
        throw new functions.https.HttpsError('invalid-argument', error.message);
      }
      throw error;
    }

    try {
      const account = await admin.auth().getUser(request.uid);
      const profileSnapshot = await db.collection('users')
        .doc(request.uid)
        .get();
      const profile = profileSnapshot.data() ?? {};
      const entriesRef = db.collection('users')
        .doc(request.uid)
        .collection('tracker_entries');

      let entriesQuery = entriesRef.orderBy('date', 'desc');
      if (request.pageToken) {
        const cursor = await entriesRef.doc(request.pageToken).get();
        if (!cursor.exists) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Record page token is no longer valid',
          );
        }
        entriesQuery = entriesQuery.startAfter(cursor);
      }

      const page = await entriesQuery.limit(request.pageSize + 1).get();
      const pageDocs = page.docs.slice(0, request.pageSize);
      const hasMore = page.docs.length > request.pageSize;
      const auditRef = db.collection('admin_audit_logs').doc();
      await auditRef.create({
        actorUid,
        action: 'health.records.viewed',
        resource: `users/${request.uid}/tracker_entries`,
        resourceId: request.uid,
        recordCount: pageDocs.length,
        createdAt: FieldValue.serverTimestamp(),
      });

      const profileCreatedAt = profile.createdAt instanceof Timestamp
        ? profile.createdAt.toDate().toISOString()
        : account.metadata.creationTime;

      return {
        user: {
          uid: account.uid,
          email: account.email ?? null,
          displayName: account.displayName ?? null,
          disabled: account.disabled,
          emailVerified: account.emailVerified,
          createdAt: account.metadata.creationTime,
          lastSignInAt: account.metadata.lastSignInTime ?? null,
          name: typeof profile.name === 'string' ? profile.name : null,
          genotype: typeof profile.genotype === 'string' ?
            profile.genotype : null,
          phone: typeof profile.phone === 'string' ? profile.phone : null,
          role: typeof profile.role === 'string' ? profile.role : null,
          requestedAccountType:
            profile.requestedAccountType === 'patient' ||
            profile.requestedAccountType === 'doctor' ?
              profile.requestedAccountType : null,
          profileCreatedAt,
        },
        entries: pageDocs.map((entry) => {
          const record = entry.data();
          return {
            id: entry.id,
            date: typeof record.date === 'string' ? record.date :
              record.date instanceof Timestamp ?
                record.date.toDate().toISOString() : null,
            painLevel: typeof record.painLevel === 'number' &&
              Number.isFinite(record.painLevel) ? record.painLevel : null,
            hydrationMl: typeof record.hydrationMl === 'number' &&
              Number.isFinite(record.hydrationMl) ? record.hydrationMl : null,
            mood: typeof record.mood === 'string' ? record.mood : null,
            notes: typeof record.notes === 'string' ? record.notes : null,
          };
        }),
        nextPageToken: hasMore ? pageDocs[pageDocs.length - 1]?.id ?? null : null,
      };
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
      console.error('Failed to load admin user health records:', error);
      throw new functions.https.HttpsError(
        'internal',
        'User details are temporarily unavailable',
      );
    }
  },
);

export const listAdminAuditLogs = functions.https.onCall(
  async (_data, context) => {
    const userId = requireAdminUid(
      context.auth?.uid,
      context.auth?.token.admin,
    );
    await enforceRateLimit(userId, 'listAdminAuditLogs', 30);

    try {
      const snapshot = await db.collection('admin_audit_logs')
        .orderBy('createdAt', 'desc')
        .limit(50)
        .get();

      return {
        entries: snapshot.docs.map((entry) => {
          const record = entry.data();
          return {
            id: entry.id,
            actorUid: typeof record.actorUid === 'string' ? record.actorUid : '',
            action: typeof record.action === 'string' ? record.action : '',
            resource: typeof record.resource === 'string' ? record.resource : '',
            resourceId: typeof record.resourceId === 'string' ?
              record.resourceId : null,
            status: typeof record.status === 'string' ? record.status : null,
            changedFields: Array.isArray(record.changedFields) ?
              record.changedFields.filter(
                (field): field is string => typeof field === 'string',
              ) : [],
            recordCount: typeof record.recordCount === 'number' &&
              Number.isInteger(record.recordCount) &&
              record.recordCount >= 0 ? record.recordCount : null,
            createdAt: record.createdAt instanceof Timestamp ?
              record.createdAt.toDate().toISOString() : null,
          };
        }),
      };
    } catch (error) {
      console.error('Failed to list admin audit events:', error);
      throw new functions.https.HttpsError(
        'internal',
        'The activity log is temporarily unavailable',
      );
    }
  },
);

export const adminFunctions = {
  getAdminDashboardSummary,
  listAdminUsers,
  updateAdminInboxStatus,
  updateAdminHomeContent,
  getAdminUserDetails,
  listAdminAuditLogs,
};
