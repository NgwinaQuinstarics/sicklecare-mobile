import {
  Activity,
  ArrowRight,
  ArrowUpRight,
  BadgeCheck,
  Check,
  ChevronLeft,
  ChevronRight,
  CircleHelp,
  Clock3,
  FileText,
  HeartPulse,
  Inbox,
  ListChecks,
  LoaderCircle,
  Mail,
  MessageSquareText,
  RefreshCw,
  Search,
  Send,
  ShieldCheck,
  Users,
  X,
} from 'lucide-react';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  onSnapshot,
  orderBy,
  query,
  type DocumentData,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type FormEvent,
  type ReactNode,
} from 'react';
import { db, functions } from './firebase';
import type {
  AdminUser,
  AdminUserDetails,
  AdminTrackerEntry,
  AdminActivity,
  DashboardSummary,
  HomeContent,
  InboxMessage,
  MessageKind,
  Section,
} from './types';

interface PageHeadingProps {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
}

function PageHeading({ eyebrow, title, description, action }: PageHeadingProps) {
  return (
    <div className="page-heading">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="page-description">{description}</p>
      </div>
      {action}
    </div>
  );
}

function formatDate(value: string | null | undefined): string {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(date);
}

function formatTimestamp(value: InboxMessage['createdAt']): string {
  if (!value) return 'Just now';
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(value.toDate());
}

function EmptyState({
  icon: Icon,
  title,
  description,
}: {
  icon: typeof Inbox;
  title: string;
  description: string;
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon"><Icon size={21} /></div>
      <strong>{title}</strong>
      <span>{description}</span>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const resolved = status === 'resolved' || status === 'closed';
  const progress = status === 'in_progress';
  return (
    <span className={`status-badge ${resolved ? 'status-resolved' : progress ? 'status-progress' : 'status-new'}`}>
      <span />
      {resolved ? 'Resolved' : progress ? 'In progress' : 'New'}
    </span>
  );
}

function MetricCard({
  label,
  value,
  detail,
  icon: Icon,
  tone,
  onClick,
}: {
  label: string;
  value: number | null;
  detail: string;
  icon: typeof Users;
  tone: 'blue' | 'violet' | 'green' | 'amber';
  onClick?: () => void;
}) {
  return (
    <button
      className={`metric-card metric-${tone} ${onClick ? 'metric-clickable' : ''}`}
      onClick={onClick}
      type="button"
    >
      <div className="metric-top">
        <span className="metric-label">{label}</span>
        <span className="metric-icon"><Icon size={19} /></span>
      </div>
      <div className="metric-value">{value === null ? '—' : value.toLocaleString()}</div>
      <div className="metric-foot">
        <span>{detail}</span>
        {onClick && <ArrowUpRight size={15} />}
      </div>
    </button>
  );
}

interface OverviewViewProps {
  onNavigate: (section: Section) => void;
}

export function OverviewView({ onNavigate }: OverviewViewProps) {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [messages, setMessages] = useState<InboxMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');

    const fetchSummary = httpsCallable<Record<string, never>, DashboardSummary>(
      functions,
      'getAdminDashboardSummary',
    );
    const fetchLatest = async () => {
      try {
        const [summaryResult, supportSnapshot, contactsSnapshot] =
          await Promise.all([
            fetchSummary({}),
            getDocs(query(collection(db, 'support_messages'), orderBy('createdAt', 'desc'), limit(4))),
            getDocs(query(collection(db, 'contacts'), orderBy('createdAt', 'desc'), limit(4))),
          ]);
        if (!active) return;
        setSummary(summaryResult.data);
        const recent: InboxMessage[] = [
          ...supportSnapshot.docs.map((snapshot) =>
            toInboxMessage(snapshot.id, 'support_messages', snapshot.data()),
          ),
          ...contactsSnapshot.docs.map((snapshot) =>
            toInboxMessage(snapshot.id, 'contacts', snapshot.data()),
          ),
        ];
        setMessages(
          recent.sort(
            (left, right) =>
              (right.createdAt?.toMillis() ?? 0) -
              (left.createdAt?.toMillis() ?? 0),
          ).slice(0, 5),
        );
      } catch (loadError) {
        console.error('Failed to load dashboard overview:', loadError);
        if (active) setError('Dashboard data could not be loaded.');
      } finally {
        if (active) setLoading(false);
      }
    };

    void fetchLatest();
    return () => {
      active = false;
    };
  }, [refreshKey]);

  const openCount = (summary?.openSupportCount ?? 0) + (summary?.openContactCount ?? 0);

  return (
    <>
      <PageHeading
        eyebrow="YOUR WORKSPACE"
        title="Good to see you"
        description="A clear view of your community and the support that needs attention."
        action={
          <button
            className="button button-secondary refresh-button"
            disabled={loading}
            onClick={() => setRefreshKey((key) => key + 1)}
          >
            <RefreshCw className={loading ? 'spin' : ''} size={16} />
            Refresh
          </button>
        }
      />

      {error && (
        <div className="inline-alert" role="alert">
          <CircleHelp size={17} />
          <span>{error}</span>
          <button onClick={() => setRefreshKey((key) => key + 1)}>Try again</button>
        </div>
      )}

      <div className="metric-grid">
        <MetricCard
          label="Registered accounts"
          value={summary?.userCount ?? (loading ? null : 0)}
          detail={`${summary?.newUsersLast7Days ?? 0} joined in the last 7 days`}
          icon={Users}
          tone="blue"
          onClick={() => onNavigate('users')}
        />
        <MetricCard
          label="Open support requests"
          value={summary ? openCount : loading ? null : 0}
          detail="Support messages and contact forms"
          icon={Inbox}
          tone="violet"
          onClick={() => onNavigate('inbox')}
        />
        <MetricCard
          label="Support messages"
          value={summary?.openSupportCount ?? (loading ? null : 0)}
          detail="Waiting for your team"
          icon={MessageSquareText}
          tone="amber"
          onClick={() => onNavigate('inbox')}
        />
        <MetricCard
          label="Contact requests"
          value={summary?.openContactCount ?? (loading ? null : 0)}
          detail="Public contact form submissions"
          icon={Mail}
          tone="green"
          onClick={() => onNavigate('inbox')}
        />
      </div>

      <div className="overview-grid">
        <section className="panel recent-panel">
          <div className="panel-heading">
            <div>
              <h2>Latest requests</h2>
              <p>Recent messages from your community</p>
            </div>
            <button className="link-button" onClick={() => onNavigate('inbox')}>
              Open inbox <ArrowRight size={15} />
            </button>
          </div>
          {loading && messages.length === 0 ? (
            <div className="loading-row"><LoaderCircle className="spin" size={19} /> Loading requests…</div>
          ) : messages.length === 0 ? (
            <EmptyState
              icon={Inbox}
              title="Your inbox is clear"
              description="New support messages will appear here."
            />
          ) : (
            <div className="recent-list">
              {messages.map((message) => (
                <button
                  className="recent-item"
                  key={`${message.kind}:${message.id}`}
                  onClick={() => onNavigate('inbox')}
                >
                  <span className={`recent-avatar ${message.kind === 'contacts' ? 'recent-avatar-green' : ''}`}>
                    {message.kind === 'contacts' ? <Mail size={17} /> : <MessageSquareText size={17} />}
                  </span>
                  <span className="recent-copy">
                    <strong>{message.subject || 'No subject'}</strong>
                    <small>{message.name || message.email || 'SickleCare user'}</small>
                  </span>
                  <span className="recent-time">{formatTimestamp(message.createdAt)}</span>
                  <ArrowUpRight className="recent-arrow" size={15} />
                </button>
              ))}
            </div>
          )}
        </section>

        <section className="panel pulse-panel">
          <div className="panel-heading">
            <div>
              <h2>Workspace pulse</h2>
              <p>A quick operational check-in</p>
            </div>
            <span className="pulse-icon"><Activity size={18} /></span>
          </div>
          <div className="pulse-content">
            <div className="pulse-item">
              <span className="pulse-check"><Check size={14} /></span>
              <span><strong>Admin access verified</strong><small>Protected by Firebase custom claims</small></span>
            </div>
            <div className="pulse-item">
              <span className="pulse-check"><Check size={14} /></span>
              <span><strong>Support inbox connected</strong><small>Messages are protected by Firestore rules</small></span>
            </div>
            <div className="pulse-item">
              <span className={`pulse-indicator ${openCount > 0 ? 'pulse-indicator-warn' : ''}`} />
              <span><strong>{openCount > 0 ? `${openCount} requests need attention` : 'No open requests'}</strong><small>Across support and contact forms</small></span>
            </div>
          </div>
          <div className="pulse-footer">
            <span><ShieldCheck size={14} /> Individual health records are available in the user directory; every view is audited</span>
          </div>
        </section>
      </div>

      <section className="quick-actions">
        <div className="quick-intro">
          <span className="quick-kicker">GET THINGS DONE</span>
          <strong>Quick actions</strong>
          <span>Jump straight into your daily work.</span>
        </div>
        <button className="quick-action" onClick={() => onNavigate('inbox')}>
          <span className="quick-action-icon quick-purple"><Inbox size={18} /></span>
          <span><strong>Review support</strong><small>Manage incoming requests</small></span>
          <ArrowUpRight size={16} />
        </button>
        <button className="quick-action" onClick={() => onNavigate('content')}>
          <span className="quick-action-icon quick-blue"><FileText size={18} /></span>
          <span><strong>Update home content</strong><small>Edit the app's welcome message</small></span>
          <ArrowUpRight size={16} />
        </button>
        <button className="quick-action" onClick={() => onNavigate('users')}>
          <span className="quick-action-icon quick-green"><Users size={18} /></span>
          <span><strong>Browse accounts</strong><small>View the protected directory</small></span>
          <ArrowUpRight size={16} />
        </button>
      </section>
    </>
  );
}

function toInboxMessage(
  id: string,
  kind: MessageKind,
  data: DocumentData,
): InboxMessage {
  return {
    id,
    kind,
    name: typeof data.name === 'string' ? data.name : '',
    email: typeof data.email === 'string' ? data.email : '',
    subject: typeof data.subject === 'string' ? data.subject : '',
    message: typeof data.message === 'string' ? data.message : '',
    status: typeof data.status === 'string' ? data.status : 'new',
    createdAt: data.createdAt ?? null,
  };
}

interface InboxViewProps {
  onNotify: (message: string) => void;
}

export function InboxView({ onNotify }: InboxViewProps) {
  const [messages, setMessages] = useState<InboxMessage[]>([]);
  const [selected, setSelected] = useState<InboxMessage | null>(null);
  const [filter, setFilter] = useState<'all' | 'open' | 'resolved'>('open');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    let supportLoaded = false;
    let contactsLoaded = false;
    const next = new Map<string, InboxMessage[]>();
    const publish = () => {
      if (!supportLoaded || !contactsLoaded) return;
      setMessages(
        [...(next.get('support_messages') ?? []), ...(next.get('contacts') ?? [])]
          .sort(
            (left, right) =>
              (right.createdAt?.toMillis() ?? 0) -
              (left.createdAt?.toMillis() ?? 0),
          ),
      );
      setLoading(false);
    };

    const onFailure = (stream: string) => (streamError: Error) => {
      console.error(`Failed to load ${stream}:`, streamError);
      setError('Inbox could not be loaded. Check your admin access and retry.');
      setLoading(false);
    };

    const unsubscribeSupport = onSnapshot(
      query(collection(db, 'support_messages'), orderBy('createdAt', 'desc'), limit(100)),
      (snapshot) => {
        next.set('support_messages', snapshot.docs.map((item) =>
          toInboxMessage(item.id, 'support_messages', item.data()),
        ));
        supportLoaded = true;
        publish();
      },
      onFailure('support messages'),
    );
    const unsubscribeContacts = onSnapshot(
      query(collection(db, 'contacts'), orderBy('createdAt', 'desc'), limit(100)),
      (snapshot) => {
        next.set('contacts', snapshot.docs.map((item) =>
          toInboxMessage(item.id, 'contacts', item.data()),
        ));
        contactsLoaded = true;
        publish();
      },
      onFailure('contact requests'),
    );

    return () => {
      unsubscribeSupport();
      unsubscribeContacts();
    };
  }, []);

  const visibleMessages = useMemo(() => {
    const term = search.trim().toLowerCase();
    return messages.filter((message) => {
      const isResolved = message.status === 'resolved' || message.status === 'closed';
      const matchesFilter = filter === 'all' ||
        (filter === 'resolved' ? isResolved : !isResolved);
      const matchesSearch = !term ||
        `${message.name} ${message.email} ${message.subject} ${message.message}`
          .toLowerCase()
          .includes(term);
      return matchesFilter && matchesSearch;
    });
  }, [filter, messages, search]);

  const openCount = messages.filter((message) =>
    message.status !== 'resolved' && message.status !== 'closed',
  ).length;

  const changeStatus = useCallback(async (message: InboxMessage, status: string) => {
    setUpdating(true);
    try {
      const updateInboxStatus = httpsCallable<
        { id: string; kind: MessageKind; status: string },
        { success: boolean }
      >(functions, 'updateAdminInboxStatus');
      await updateInboxStatus({
        id: message.id,
        kind: message.kind,
        status,
      });
      setSelected((current) => current?.id === message.id && current.kind === message.kind
        ? { ...current, status }
        : current);
      onNotify(status === 'resolved' ? 'Request marked as resolved.' : 'Request status updated.');
    } catch (updateError) {
      console.error('Failed to update inbox request:', updateError);
      onNotify('The request could not be updated. Check permissions and retry.');
    } finally {
      setUpdating(false);
    }
  }, [onNotify]);

  return (
    <>
      <PageHeading
        eyebrow="COMMUNITY CARE"
        title="Support inbox"
        description="Review incoming support messages and contact requests in one place."
        action={
          <span className="inbox-open-count">
            <span /> {openCount} open {openCount === 1 ? 'request' : 'requests'}
          </span>
        }
      />
      <section className="panel inbox-panel">
        <div className="inbox-toolbar">
          <div className="filter-tabs" role="tablist" aria-label="Filter inbox">
            {([
              ['open', 'Open'],
              ['all', 'All requests'],
              ['resolved', 'Resolved'],
            ] as const).map(([id, label]) => (
              <button
                aria-selected={filter === id}
                className={`filter-tab ${filter === id ? 'filter-tab-active' : ''}`}
                key={id}
                onClick={() => setFilter(id)}
                role="tab"
              >
                {label}
                {id === 'open' && <span className="filter-count">{openCount}</span>}
              </button>
            ))}
          </div>
          <label className="search-field inbox-search">
            <Search size={16} />
            <input
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search messages"
              type="search"
              value={search}
            />
            {search && <button aria-label="Clear search" onClick={() => setSearch('')}><X size={15} /></button>}
          </label>
        </div>
        {error ? (
          <div className="panel-error" role="alert">
            <CircleHelp size={19} />
            <strong>{error}</strong>
            <button className="button button-secondary" onClick={() => window.location.reload()}>Reload inbox</button>
          </div>
        ) : loading ? (
          <div className="loading-state"><LoaderCircle className="spin" size={22} /> Loading inbox…</div>
        ) : visibleMessages.length === 0 ? (
          <EmptyState
            icon={search || filter !== 'open' ? Search : Inbox}
            title={search ? 'No matching requests' : filter === 'open' ? 'All caught up' : 'No requests here'}
            description={search ? 'Try another name, email, or keyword.' : 'New messages will appear here when someone reaches out.'}
          />
        ) : (
          <div className="inbox-list">
            {visibleMessages.map((message) => (
              <button
                className="inbox-row"
                key={`${message.kind}:${message.id}`}
                onClick={() => setSelected(message)}
              >
                <span className={`inbox-row-icon ${message.kind === 'contacts' ? 'inbox-row-icon-contact' : ''}`}>
                  {message.kind === 'contacts' ? <Mail size={18} /> : <MessageSquareText size={18} />}
                </span>
                <span className="inbox-row-main">
                  <span className="inbox-row-title">
                    <strong>{message.subject || 'No subject'}</strong>
                    <StatusBadge status={message.status} />
                  </span>
                  <span className="inbox-row-preview">{message.message || 'No message content'}</span>
                  <span className="inbox-row-meta">
                    <span>{message.name || 'Unknown sender'}</span>
                    <span className="meta-dot" />
                    <span>{message.email || 'No email provided'}</span>
                    <span className="meta-dot" />
                    <span>{message.kind === 'contacts' ? 'Contact form' : 'Support'}</span>
                  </span>
                </span>
                <span className="inbox-row-time"><Clock3 size={14} />{formatTimestamp(message.createdAt)}</span>
                <ChevronRight className="inbox-row-chevron" size={17} />
              </button>
            ))}
          </div>
        )}
        <div className="inbox-footnote">
          <ShieldCheck size={14} />
          <span>Only authorized administrators can view these messages.</span>
          <span className="footnote-spacer" />
          <span>Showing up to 100 newest requests per inbox</span>
        </div>
      </section>

      {selected && (
        <div className="modal-backdrop" onMouseDown={(event) => {
          if (event.target === event.currentTarget) setSelected(null);
        }}>
          <section aria-labelledby="message-title" aria-modal="true" className="message-modal" role="dialog">
            <div className="modal-header">
              <div>
                <span className="eyebrow">{selected.kind === 'contacts' ? 'CONTACT REQUEST' : 'SUPPORT MESSAGE'}</span>
                <h2 id="message-title">{selected.subject || 'No subject'}</h2>
              </div>
              <button aria-label="Close message" className="icon-button" onClick={() => setSelected(null)}><X size={19} /></button>
            </div>
            <div className="modal-sender">
              <span className="sender-avatar">{(selected.name || selected.email || '?').slice(0, 1).toUpperCase()}</span>
              <span><strong>{selected.name || 'Unknown sender'}</strong><small>{selected.email || 'No email provided'}</small></span>
              <StatusBadge status={selected.status} />
            </div>
            <div className="modal-meta">
              <span><Clock3 size={15} /> Received {formatTimestamp(selected.createdAt)}</span>
              <span>{selected.kind === 'contacts' ? 'Public contact form' : 'In-app support'}</span>
            </div>
            <div className="message-body">{selected.message || 'No message content.'}</div>
            <div className="modal-response-note">
              <CircleHelp size={16} />
              <span>Replies are not sent from this console. Contact the sender using your approved support channel.</span>
            </div>
            <div className="modal-actions">
              {selected.email && (
                <a
                  className="button button-secondary"
                  href={`mailto:${encodeURIComponent(selected.email)}?subject=${encodeURIComponent(`Re: ${selected.subject || 'SickleCare support'}`)}`}
                >
                  <Send size={15} /> Compose email
                </a>
              )}
              {selected.status !== 'in_progress' && selected.status !== 'resolved' && selected.status !== 'closed' && (
                <button className="button button-secondary" disabled={updating} onClick={() => changeStatus(selected, 'in_progress')}>
                  Mark in progress
                </button>
              )}
              {selected.status === 'resolved' || selected.status === 'closed' ? (
                <button className="button button-primary" disabled={updating} onClick={() => changeStatus(selected, 'new')}>
                  {updating ? 'Updating…' : 'Reopen request'}
                </button>
              ) : (
                <button className="button button-primary" disabled={updating} onClick={() => changeStatus(selected, 'resolved')}>
                  {updating ? 'Updating…' : <><Check size={16} /> Mark resolved</>}
                </button>
              )}
            </div>
          </section>
        </div>
      )}
    </>
  );
}

interface AdminUserPage {
  users: AdminUser[];
  nextPageToken: string | null;
}

interface AdminUserDetailsPage {
  user: AdminUserDetails;
  entries: AdminTrackerEntry[];
  nextPageToken: string | null;
}

export function UsersView() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [tokens, setTokens] = useState<Array<string | undefined>>([undefined]);
  const [pageIndex, setPageIndex] = useState(0);
  const [nextPageToken, setNextPageToken] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [userDetails, setUserDetails] = useState<AdminUserDetailsPage | null>(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [detailsError, setDetailsError] = useState('');
  const [detailsPageTokens, setDetailsPageTokens] =
    useState<Array<string | undefined>>([undefined]);
  const [detailsPageIndex, setDetailsPageIndex] = useState(0);
  const [nextDetailsPageToken, setNextDetailsPageToken] =
    useState<string | null>(null);
  const [detailsRetryKey, setDetailsRetryKey] = useState(0);
  const selectedUid = selectedUser?.uid;

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');
    const listUsers = httpsCallable<
      { pageSize: number; pageToken?: string },
      AdminUserPage
    >(functions, 'listAdminUsers');
    const pageToken = tokens[pageIndex];

    listUsers({ pageSize: 25, ...(pageToken ? { pageToken } : {}) })
      .then(({ data }) => {
        if (!active) return;
        setUsers(data.users);
        setNextPageToken(data.nextPageToken);
      })
      .catch((requestError: unknown) => {
        console.error('Failed to load account directory:', requestError);
        if (active) setError('The account directory could not be loaded.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [pageIndex, refreshKey, tokens]);

  useEffect(() => {
    if (!selectedUid) return;
    let active = true;
    setDetailsLoading(true);
    setDetailsError('');
    setUserDetails(null);
    setNextDetailsPageToken(null);
    const getUserDetails = httpsCallable<
      { uid: string; pageSize: number; pageToken?: string },
      AdminUserDetailsPage
    >(functions, 'getAdminUserDetails');
    const pageToken = detailsPageTokens[detailsPageIndex];

    getUserDetails({
      uid: selectedUid,
      pageSize: 10,
      ...(pageToken ? { pageToken } : {}),
    })
      .then(({ data }) => {
        if (!active) return;
        setUserDetails(data);
        setNextDetailsPageToken(data.nextPageToken);
      })
      .catch((requestError: unknown) => {
        console.error('Failed to load user details:', requestError);
        if (active) {
          setDetailsError('User details could not be loaded. Try again.');
        }
      })
      .finally(() => {
        if (active) setDetailsLoading(false);
      });

    return () => {
      active = false;
    };
  }, [detailsPageIndex, detailsPageTokens, detailsRetryKey, selectedUid]);

  function openUserDetails(user: AdminUser) {
    setUserDetails(null);
    setDetailsError('');
    setDetailsPageTokens([undefined]);
    setDetailsPageIndex(0);
    setSelectedUser(user);
  }

  function closeUserDetails() {
    setSelectedUser(null);
    setUserDetails(null);
    setDetailsError('');
    setDetailsPageTokens([undefined]);
    setDetailsPageIndex(0);
    setNextDetailsPageToken(null);
  }

  function nextDetailsPage() {
    if (!nextDetailsPageToken) return;
    setDetailsPageTokens((current) => [
      ...current.slice(0, detailsPageIndex + 1),
      nextDetailsPageToken,
    ]);
    setDetailsPageIndex((current) => current + 1);
  }

  const filteredUsers = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return users;
    return users.filter((user) =>
      `${user.displayName ?? ''} ${user.email ?? ''} ${user.uid}`
        .toLowerCase()
        .includes(term),
    );
  }, [search, users]);

  function nextPage() {
    if (!nextPageToken) return;
    setTokens((current) => [...current.slice(0, pageIndex + 1), nextPageToken]);
    setPageIndex((current) => current + 1);
  }

  function previousPage() {
    setPageIndex((current) => Math.max(0, current - 1));
  }

  return (
    <>
      <PageHeading
        eyebrow="ACCOUNT MANAGEMENT"
        title="User directory"
        description="Review account details and, when needed, view a user's synced health records. Health-data access is audited."
        action={
          <button className="button button-secondary refresh-button" disabled={loading} onClick={() => setRefreshKey((key) => key + 1)}>
            <RefreshCw className={loading ? 'spin' : ''} size={16} />
            Refresh
          </button>
        }
      />
      <section className="panel directory-panel">
        <div className="directory-toolbar">
          <div className="directory-heading">
            <div className="directory-heading-icon"><Users size={18} /></div>
            <div><strong>Accounts</strong><span>Secure, read-only Firebase account directory</span></div>
          </div>
          <label className="search-field directory-search">
            <Search size={16} />
            <input
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search this page"
              type="search"
              value={search}
            />
            {search && <button aria-label="Clear search" onClick={() => setSearch('')}><X size={15} /></button>}
          </label>
        </div>
        <div className="table-scroll">
          <table className="data-table">
            <thead>
              <tr><th>ACCOUNT</th><th>STATUS</th><th>EMAIL</th><th>LAST SIGN-IN</th><th>CREATED</th><th>DETAILS</th></tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td className="table-message" colSpan={6}><LoaderCircle className="spin" size={19} /> Loading accounts…</td></tr>
              ) : error ? (
                <tr><td className="table-message table-error" colSpan={6}>{error} <button className="link-button" onClick={() => setRefreshKey((key) => key + 1)}>Try again</button></td></tr>
              ) : filteredUsers.length === 0 ? (
                <tr><td className="table-message" colSpan={6}>{search ? 'No accounts match your search on this page.' : 'No accounts found.'}</td></tr>
              ) : filteredUsers.map((user) => (
                <tr key={user.uid}>
                  <td>
                    <div className="table-user">
                      <span className="table-avatar">{(user.displayName || user.email || 'U').slice(0, 1).toUpperCase()}</span>
                      <span><strong>{user.displayName || 'Unnamed account'}</strong><small>ID {user.uid.slice(0, 8)}…</small></span>
                    </div>
                  </td>
                  <td>
                    <span className={`account-status ${user.disabled ? 'account-disabled' : 'account-active'}`}>
                      <span /> {user.disabled ? 'Disabled' : 'Active'}
                    </span>
                  </td>
                  <td className="table-email">
                    {user.email || '—'}
                    {user.emailVerified && <BadgeCheck aria-label="Verified email" className="verified-icon" size={15} />}
                  </td>
                  <td>{formatDate(user.lastSignInAt)}</td>
                  <td>{formatDate(user.createdAt)}</td>
                  <td>
                    <button
                      aria-label={`View details for ${user.displayName || user.email || 'user'}`}
                      className="link-button"
                      onClick={() => openUserDetails(user)}
                      type="button"
                    >
                      View details
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="table-footer">
          <span>Page {pageIndex + 1} · {filteredUsers.length} {filteredUsers.length === 1 ? 'account' : 'accounts'}</span>
          <div className="pagination">
            <button aria-label="Previous page" className="icon-button" disabled={pageIndex === 0 || loading} onClick={previousPage}><ChevronLeft size={17} /></button>
            <button aria-label="Next page" className="icon-button" disabled={!nextPageToken || loading} onClick={nextPage}><ChevronRight size={17} /></button>
          </div>
        </div>
        <div className="inbox-footnote directory-footnote">
          <ShieldCheck size={14} />
          <span>Personal and health data is returned only by an admin-claim protected function; each health-record view is recorded in the activity log.</span>
        </div>
      </section>
      {selectedUser && (
        <div className="modal-backdrop">
          <section
            aria-labelledby="user-details-title"
            aria-modal="true"
            className="message-modal user-details-modal"
            role="dialog"
          >
            <div className="modal-header">
              <div>
                <span className="eyebrow">PRIVATE USER RECORD</span>
                <h2 id="user-details-title">
                  {userDetails?.user.name ||
                    selectedUser.displayName ||
                    'User details'}
                </h2>
              </div>
              <button
                aria-label="Close user details"
                className="icon-button"
                onClick={closeUserDetails}
                type="button"
              >
                <X size={18} />
              </button>
            </div>
            <div className="sensitive-data-note">
              <ShieldCheck size={16} />
              <span>Confidential health information. This access is audited; records are read-only.</span>
            </div>
            {detailsError && (
              <div className="panel-error" role="alert">
                <span>{detailsError}</span>
                <button
                  className="link-button"
                  onClick={() => setDetailsRetryKey((current) => current + 1)}
                  type="button"
                >
                  Retry
                </button>
              </div>
            )}
            {detailsLoading && (
              <div className="loading-state">
                <LoaderCircle className="spin" size={18} />
                Loading user records…
              </div>
            )}
            {!detailsLoading && userDetails && (
              <>
                <div className="user-detail-grid">
                  <div><span>Email</span><strong>{userDetails.user.email || '—'}</strong></div>
                  <div><span>Phone</span><strong>{userDetails.user.phone || '—'}</strong></div>
                  <div><span>Genotype</span><strong>{userDetails.user.genotype || '—'}</strong></div>
                  <div><span>Account status</span><strong>{userDetails.user.disabled ? 'Disabled' : 'Active'}</strong></div>
                  <div><span>Role</span><strong>{userDetails.user.role || '—'}</strong></div>
                  <div><span>Account created</span><strong>{formatDate(userDetails.user.profileCreatedAt)}</strong></div>
                  <div><span>Last sign-in</span><strong>{formatDate(userDetails.user.lastSignInAt)}</strong></div>
                </div>
                <div className="user-record-heading">
                  <div>
                    <HeartPulse size={18} />
                    <strong>Synced health tracker records</strong>
                  </div>
                  <span>{detailsPageIndex + 1} · {userDetails.entries.length} records on this page</span>
                </div>
                <div className="table-scroll user-record-scroll">
                  <table className="data-table user-record-table">
                    <thead>
                      <tr><th>DATE</th><th>PAIN (0–10)</th><th>HYDRATION (ML)</th><th>MOOD</th><th>NOTES</th></tr>
                    </thead>
                    <tbody>
                      {userDetails.entries.length === 0 ? (
                        <tr><td className="table-message" colSpan={5}>No tracker records have synced from this account.</td></tr>
                      ) : userDetails.entries.map((entry) => (
                        <tr key={entry.id}>
                          <td>{formatDate(entry.date)}</td>
                          <td>{entry.painLevel ?? '—'}</td>
                          <td>{entry.hydrationMl ?? '—'}</td>
                          <td>{entry.mood || '—'}</td>
                          <td className="user-record-notes">{entry.notes || '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="table-footer">
                  <span>Only records synced to Firebase are available here. Device-only data is not included.</span>
                  <div className="pagination">
                    <button
                      aria-label="Previous health records"
                      className="icon-button"
                      disabled={detailsPageIndex === 0 || detailsLoading}
                      onClick={() => setDetailsPageIndex((current) => current - 1)}
                      type="button"
                    >
                      <ChevronLeft size={17} />
                    </button>
                    <button
                      aria-label="Next health records"
                      className="icon-button"
                      disabled={!nextDetailsPageToken || detailsLoading}
                      onClick={nextDetailsPage}
                      type="button"
                    >
                      <ChevronRight size={17} />
                    </button>
                  </div>
                </div>
              </>
            )}
          </section>
        </div>
      )}
    </>
  );
}

export function ActivityView() {
  const [entries, setEntries] = useState<AdminActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');
    const listAuditEvents = httpsCallable<
      Record<string, never>,
      { entries: AdminActivity[] }
    >(functions, 'listAdminAuditLogs');

    listAuditEvents({})
      .then(({ data }) => {
        if (active) setEntries(data.entries);
      })
      .catch((requestError: unknown) => {
        console.error('Failed to load administrator activity:', requestError);
        if (active) setError('The activity log could not be loaded.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [refreshKey]);

  return (
    <>
      <PageHeading
        eyebrow="ACCOUNTABILITY"
        title="Activity log"
        description="Review administrative changes and health-record access recorded by trusted backend functions."
        action={
          <button
            className="button button-secondary refresh-button"
            disabled={loading}
            onClick={() => setRefreshKey((key) => key + 1)}
          >
            <RefreshCw className={loading ? 'spin' : ''} size={16} />
            Refresh
          </button>
        }
      />
      <section className="panel activity-panel">
        <div className="directory-toolbar">
          <div className="directory-heading">
            <div className="directory-heading-icon activity-heading-icon">
              <ListChecks size={18} />
            </div>
            <div>
              <strong>Administrator actions</strong>
              <span>Latest 50 events · recorded by trusted backend functions</span>
            </div>
          </div>
        </div>
        {error ? (
          <div className="panel-error" role="alert">
            <CircleHelp size={19} />
            <strong>{error}</strong>
            <button
              className="button button-secondary"
              onClick={() => setRefreshKey((key) => key + 1)}
            >
              Try again
            </button>
          </div>
        ) : loading ? (
          <div className="loading-state">
            <LoaderCircle className="spin" size={22} /> Loading activity…
          </div>
        ) : entries.length === 0 ? (
          <EmptyState
            icon={ListChecks}
            title="No activity recorded yet"
            description="Content changes, inbox updates, and health-record views will appear here."
          />
        ) : (
          <div className="activity-list">
            {entries.map((entry) => (
              <div className="activity-row" key={entry.id}>
                <span className="activity-event-icon">
                  {entry.action === 'health.records.viewed'
                    ? <HeartPulse size={17} />
                    : entry.action === 'content.home.updated'
                    ? <FileText size={17} />
                    : <MessageSquareText size={17} />}
                </span>
                <span className="activity-event-copy">
                  <strong>
                    {entry.action === 'health.records.viewed'
                      ? 'Viewed user health records'
                      : entry.action === 'content.home.updated'
                      ? 'Published home content'
                      : entry.action === 'inbox.status.updated'
                        ? 'Updated an inbox request'
                        : 'Administrator action'}
                  </strong>
                  <small>
                    {entry.resource}
                    {entry.resourceId ? ` · ${entry.resourceId}` : ''}
                    {entry.status ? ` · ${entry.status.replace('_', ' ')}` : ''}
                    {entry.changedFields.length
                      ? ` · ${entry.changedFields.join(', ')}`
                      : ''}
                    {entry.recordCount !== null
                      ? ` · ${entry.recordCount} ${entry.recordCount === 1 ? 'record' : 'records'}`
                      : ''}
                  </small>
                </span>
                <span className="activity-actor">
                  <span className="activity-actor-avatar"><ShieldCheck size={14} /></span>
                  <span>Admin {entry.actorUid ? `${entry.actorUid.slice(0, 8)}…` : ''}</span>
                </span>
                <span className="activity-date">{formatDate(entry.createdAt)}</span>
              </div>
            ))}
          </div>
        )}
        <div className="inbox-footnote">
          <ShieldCheck size={14} />
          <span>
            Activity entries are written by admin-only Cloud Functions. This
            log records access metadata, never tracker values or notes.
          </span>
        </div>
      </section>
    </>
  );
}

interface ContentViewProps {
  onNotify: (message: string) => void;
}

const blankContent: HomeContent = { heroTitle: '', heroBody: '' };

export function ContentView({ onNotify }: ContentViewProps) {
  const [content, setContent] = useState<HomeContent>(blankContent);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [loaded, setLoaded] = useState(false);

  const loadContent = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const snapshot = await getDoc(doc(db, 'content', 'home'));
      const data = snapshot.data();
      setContent({
        heroTitle: typeof data?.heroTitle === 'string' ? data.heroTitle : '',
        heroBody: typeof data?.heroBody === 'string' ? data.heroBody : '',
      });
      setLoaded(true);
    } catch (loadError) {
      console.error('Failed to load home content:', loadError);
      setError('Home content could not be loaded. Check your admin access and retry.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadContent();
  }, [loadContent]);

  async function saveContent(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const heroTitle = content.heroTitle.trim();
    const heroBody = content.heroBody.trim();
    if (!heroTitle || !heroBody) {
      setError('Add both a title and a welcome message before saving.');
      return;
    }
    if (heroTitle.length > 120 || heroBody.length > 2000) {
      setError('The title or message is longer than the supported limit.');
      return;
    }

    setSaving(true);
    setError('');
    try {
      const publishContent = httpsCallable<
        HomeContent,
        { success: boolean }
      >(functions, 'updateAdminHomeContent');
      await publishContent({ heroTitle, heroBody });
      setContent({ heroTitle, heroBody });
      onNotify('Home content published successfully.');
    } catch (saveError) {
      console.error('Failed to save home content:', saveError);
      setError('Changes could not be published. Check your admin access and retry.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <>
      <PageHeading
        eyebrow="APP EXPERIENCE"
        title="Home content"
        description="Update the welcome message shown in the SickleCare app."
      />
      {error && <div className="inline-alert" role="alert"><CircleHelp size={17} /><span>{error}</span>{loaded && <button onClick={() => setError('')}>Dismiss</button>}</div>}
      {loading ? (
        <div className="panel loading-state content-loading"><LoaderCircle className="spin" size={22} /> Loading published content…</div>
      ) : (
        <div className="content-layout">
          <section className="panel editor-panel">
            <div className="panel-heading">
              <div><h2>Welcome section</h2><p>Changes are published immediately to the app.</p></div>
              <span className="live-badge"><span /> LIVE</span>
            </div>
            <form className="content-form" onSubmit={saveContent}>
              <label htmlFor="hero-title">Headline <span>Required</span></label>
              <input
                id="hero-title"
                maxLength={120}
                onChange={(event) => setContent((current) => ({ ...current, heroTitle: event.target.value }))}
                placeholder="A warm welcome for your community"
                required
                value={content.heroTitle}
              />
              <div className="field-footer"><span>Keep your headline clear and welcoming.</span><span>{content.heroTitle.length}/120</span></div>
              <label htmlFor="hero-body">Welcome message <span>Required</span></label>
              <textarea
                id="hero-body"
                maxLength={2000}
                onChange={(event) => setContent((current) => ({ ...current, heroBody: event.target.value }))}
                placeholder="Write a supportive message to everyone using SickleCare."
                required
                rows={7}
                value={content.heroBody}
              />
              <div className="field-footer"><span>Use supportive, clear language.</span><span>{content.heroBody.length}/2000</span></div>
              <div className="form-actions">
                <span><ShieldCheck size={14} /> Only administrators can publish content.</span>
                <button className="button button-primary" disabled={saving || !loaded}>
                  {saving ? <><LoaderCircle className="spin" size={16} /> Publishing…</> : <><Check size={16} /> Publish changes</>}
                </button>
              </div>
            </form>
          </section>
          <aside className="content-preview-wrap">
            <div className="preview-heading"><span>LIVE PREVIEW</span><span className="preview-device">App home</span></div>
            <div className="content-preview">
              <div className="preview-top"><img className="preview-logo" src="/app-icon.jpeg" alt="" /><span>SickleCare</span><span className="preview-menu">•••</span></div>
              <div className="preview-greeting">YOUR DAILY COMPANION</div>
              <h3>{content.heroTitle || 'Your welcome headline'}</h3>
              <p>{content.heroBody || 'Your welcome message will appear here as you write.'}</p>
              <div className="preview-card"><span className="preview-card-mark"><Activity size={15} /></span><span><strong>Your health, your way</strong><small>Track how you are feeling each day</small></span><ArrowRight size={15} /></div>
              <div className="preview-note">Preview only · Changes publish to the app</div>
            </div>
            <div className="preview-help"><CircleHelp size={16} /><span>Use plain language. Avoid adding private or individual health information to public app content.</span></div>
          </aside>
        </div>
      )}
    </>
  );
}
