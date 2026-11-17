import {
  Check,
  CircleHelp,
  FileText,
  LoaderCircle,
  RefreshCw,
  ShieldOff,
  X,
} from 'lucide-react';
import { httpsCallable } from 'firebase/functions';
import { useCallback, useEffect, useState } from 'react';
import { functions } from './firebase';
import './doctor-applications.css';

type ApplicationStatus = 'pending' | 'approved' | 'rejected' | 'deactivated';
type StatusFilter = 'all' | ApplicationStatus;

interface DoctorApplication {
  uid: string;
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
  status: ApplicationStatus | 'upload_required';
  reviewNotes: string;
  createdAt: string | null;
  updatedAt: string | null;
  hasCredential: boolean;
}

interface ListResult {
  applications: DoctorApplication[];
  nextPageToken: string | null;
}

interface CredentialResult {
  url: string;
  contentType: string;
}

interface CredentialFile {
  url: string;
  extension: string;
}

const pageSize = 25;

function formatDate(value: string | null): string {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime())
    ? '—'
    : new Intl.DateTimeFormat(undefined, {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      }).format(date);
}

function statusLabel(status: DoctorApplication['status']): string {
  if (status === 'upload_required') return 'Needs credentials';
  return status.charAt(0).toUpperCase() + status.slice(1);
}

export function DoctorApplicationsView({
  onNotify,
}: {
  onNotify: (message: string) => void;
}) {
  const [status, setStatus] = useState<StatusFilter>('pending');
  const [applications, setApplications] = useState<DoctorApplication[]>([]);
  const [nextPageToken, setNextPageToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busyUid, setBusyUid] = useState('');
  const [credentialFiles, setCredentialFiles] =
    useState<Record<string, CredentialFile>>({});
  const [reviewNotes, setReviewNotes] = useState<Record<string, string>>({});
  const [refreshKey, setRefreshKey] = useState(0);

  const loadApplications = useCallback(async (pageToken?: string) => {
    setLoading(true);
    setError('');
    try {
      const list = httpsCallable<
        { pageSize: number; pageToken?: string; status: StatusFilter },
        ListResult
      >(functions, 'listDoctorApplications');
      const result = await list({
        pageSize,
        status,
        ...(pageToken ? { pageToken } : {}),
      });
      setApplications((previous) =>
        pageToken ? [...previous, ...result.data.applications] : result.data.applications,
      );
      setNextPageToken(result.data.nextPageToken);
    } catch (loadError) {
      console.error('Unable to load doctor applications:', loadError);
      setError('Doctor applications could not be loaded. Check access and connection.');
    } finally {
      setLoading(false);
    }
  }, [status]);

  useEffect(() => {
    setApplications([]);
    setNextPageToken(null);
    void loadApplications();
  }, [loadApplications, refreshKey]);

  const openCredential = async (application: DoctorApplication) => {
    setBusyUid(application.uid);
    setError('');
    try {
      const getCredential = httpsCallable<{ uid: string }, CredentialResult>(
        functions,
        'getDoctorApplicationCredential',
      );
      const { data } = await getCredential({ uid: application.uid });
      const extension = {
        'application/pdf': 'pdf',
        'image/jpeg': 'jpg',
        'image/png': 'png',
        'image/webp': 'webp',
      }[data.contentType] ?? 'bin';
      setCredentialFiles((previous) => ({
        ...previous,
        [application.uid]: { url: data.url, extension },
      }));
    } catch (credentialError) {
      console.error('Unable to securely open doctor credential:', credentialError);
      setError('The credential could not be opened. It may have been removed or access may have expired.');
    } finally {
      setBusyUid('');
    }
  };

  const review = async (
    application: DoctorApplication,
    action: 'approve' | 'reject' | 'deactivate' | 'reactivate',
  ) => {
    if (
      action === 'deactivate' &&
      !window.confirm(
        `Deactivate ${application.fullName}'s account? Their records will be retained and sign-in will be disabled.`,
      )
    ) {
      return;
    }
    setBusyUid(application.uid);
    setError('');
    try {
      const update = httpsCallable<
        { uid: string; action: 'approve' | 'reject' | 'deactivate' | 'reactivate'; notes: string },
        { success: boolean; status: DoctorApplication['status'] }
      >(functions, 'reviewDoctorApplication');
      const result = await update({
        uid: application.uid,
        action,
        notes: reviewNotes[application.uid] ?? '',
      });
      setApplications((previous) =>
        previous.map((item) =>
          item.uid === application.uid
            ? { ...item, status: result.data.status }
            : item,
        ),
      );
      onNotify(
        action === 'approve'
          ? 'Doctor approved. Their access updates after their next token refresh.'
          : action === 'reject'
            ? 'Doctor application returned for changes.'
            : action === 'deactivate'
              ? 'Doctor account deactivated; records were retained.'
              : 'Doctor account reactivated using its previous review state.',
      );
    } catch (reviewError) {
      console.error('Unable to update doctor application:', reviewError);
      setError('The application could not be updated. Refresh and try again.');
    } finally {
      setBusyUid('');
    }
  };

  const statuses: StatusFilter[] = [
    'pending',
    'all',
    'approved',
    'rejected',
    'deactivated',
  ];

  return (
    <section className="doctor-applications">
      <div className="page-heading">
        <div>
          <p className="eyebrow">PROFESSIONAL ACCESS</p>
          <h1>Doctor applications</h1>
          <p className="page-description">
            Review credentials before granting doctor access. Deactivation is reversible and preserves application history.
          </p>
        </div>
        <button
          className="button button-secondary refresh-button"
          disabled={loading}
          onClick={() => setRefreshKey((key) => key + 1)}
          type="button"
        >
          <RefreshCw className={loading ? 'spin' : ''} size={16} />
          Refresh
        </button>
      </div>

      {error && (
        <div className="inline-alert" role="alert">
          <CircleHelp size={17} />
          <span>{error}</span>
          <button onClick={() => setRefreshKey((key) => key + 1)} type="button">
            Try again
          </button>
        </div>
      )}

      <div className="doctor-filter-row" aria-label="Filter applications">
        {statuses.map((item) => (
          <button
            aria-pressed={status === item}
            className={`doctor-filter ${status === item ? 'doctor-filter-active' : ''}`}
            key={item}
            onClick={() => setStatus(item)}
            type="button"
          >
            {item === 'all' ? 'All applications' : statusLabel(item)}
          </button>
        ))}
      </div>

      {loading && applications.length === 0 ? (
        <div className="panel doctor-empty">
          <LoaderCircle className="spin" size={25} />
          <span>Loading applications…</span>
        </div>
      ) : applications.length === 0 ? (
        <div className="panel doctor-empty">
          <FileText size={24} />
          <strong>No applications found</strong>
          <span>New doctor applications will appear here after credential submission.</span>
        </div>
      ) : (
        <div className="doctor-application-list">
          {applications.map((application) => {
            const busy = busyUid === application.uid;
            const credentialFile = credentialFiles[application.uid];
            const note = reviewNotes[application.uid] ?? '';
            return (
              <article className="panel doctor-application-card" key={application.uid}>
                <div className="doctor-application-heading">
                  <div>
                    <p className="eyebrow">SUBMITTED {formatDate(application.createdAt)}</p>
                    <h2>{application.fullName}</h2>
                    <span>{application.email} · {application.phone}</span>
                  </div>
                  <span className={`doctor-status doctor-status-${application.status}`}>
                    {statusLabel(application.status)}
                  </span>
                </div>
                <dl className="doctor-application-details">
                  <div><dt>Specialty</dt><dd>{application.specialty}</dd></div>
                  <div><dt>Registration</dt><dd>{application.licenseNumber}</dd></div>
                  <div><dt>Qualifications</dt><dd>{application.qualifications}</dd></div>
                  <div><dt>Facility</dt><dd>{application.facilityName}</dd></div>
                  <div><dt>Experience</dt><dd>{application.yearsOfExperience} years</dd></div>
                  <div><dt>Available</dt><dd>{application.availabilityDays.join(', ')}</dd></div>
                </dl>
                {application.bio && <p className="doctor-application-bio">{application.bio}</p>}
                {application.reviewNotes && (
                  <p className="doctor-review-note">
                    <strong>Previous review note:</strong> {application.reviewNotes}
                  </p>
                )}
                <div className="doctor-application-actions">
                  {application.hasCredential && (
                    credentialFile ? (
                      <a
                        className="button button-secondary"
                        href={credentialFile.url}
                      >
                        <FileText size={15} /> Download credential ({credentialFile.extension.toUpperCase()})
                      </a>
                    ) : (
                      <button
                        className="button button-secondary"
                        disabled={busy}
                        onClick={() => void openCredential(application)}
                        type="button"
                      >
                        {busy ? <LoaderCircle className="spin" size={15} /> : <FileText size={15} />}
                        Review credential
                      </button>
                    )
                  )}
                  {application.status === 'pending' && (
                    <>
                      <input
                        aria-label={`Review note for ${application.fullName}`}
                        className="doctor-review-input"
                        maxLength={500}
                        onChange={(event) =>
                          setReviewNotes((previous) => ({
                            ...previous,
                            [application.uid]: event.target.value,
                          }))
                        }
                        placeholder="Optional review note"
                        value={note}
                      />
                      <button
                        className="button button-primary"
                        disabled={busy || !application.hasCredential}
                        onClick={() => void review(application, 'approve')}
                        type="button"
                      >
                        <Check size={15} /> Approve
                      </button>
                      <button
                        className="button button-secondary"
                        disabled={busy}
                        onClick={() => void review(application, 'reject')}
                        type="button"
                      >
                        <X size={15} /> Return for changes
                      </button>
                    </>
                  )}
                  {application.status !== 'deactivated' && (
                    <button
                      className="button button-secondary button-danger"
                      disabled={busy}
                      onClick={() => void review(application, 'deactivate')}
                      type="button"
                    >
                      <ShieldOff size={15} /> Deactivate account
                    </button>
                  )}
                  {application.status === 'deactivated' && (
                    <button
                      className="button button-secondary"
                      disabled={busy}
                      onClick={() => void review(application, 'reactivate')}
                      type="button"
                    >
                      <Check size={15} /> Reactivate account
                    </button>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      )}

      {nextPageToken && (
        <div className="doctor-load-more">
          <button
            className="button button-secondary"
            disabled={loading}
            onClick={() => void loadApplications(nextPageToken)}
            type="button"
          >
            {loading ? 'Loading…' : 'Load more'}
          </button>
        </div>
      )}
    </section>
  );
}
