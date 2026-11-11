import type { Timestamp } from 'firebase/firestore';

export type Section = 'overview' | 'users' | 'inbox' | 'content' | 'activity';

export interface DashboardSummary {
  userCount: number;
  newUsersLast7Days: number;
  openSupportCount: number;
  openContactCount: number;
  generatedAt: string;
}

export interface AdminUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  requestedAccountType: 'patient' | 'doctor' | null;
  disabled: boolean;
  emailVerified: boolean;
  createdAt: string;
  lastSignInAt: string | null;
}

export interface AdminUserDetails extends AdminUser {
  name: string | null;
  genotype: string | null;
  phone: string | null;
  role: string | null;
  profileCreatedAt: string;
}

export interface AdminTrackerEntry {
  id: string;
  date: string | null;
  painLevel: number | null;
  hydrationMl: number | null;
  mood: string | null;
  notes: string | null;
}

export interface AdminActivity {
  id: string;
  actorUid: string;
  action: string;
  resource: string;
  resourceId: string | null;
  status: string | null;
  changedFields: string[];
  recordCount: number | null;
  createdAt: string | null;
}

export type MessageKind = 'support_messages' | 'contacts';

export interface InboxMessage {
  id: string;
  kind: MessageKind;
  name: string;
  email: string;
  subject: string;
  message: string;
  status: string;
  createdAt: Timestamp | null;
}

export interface HomeContent {
  heroTitle: string;
  heroBody: string;
}
