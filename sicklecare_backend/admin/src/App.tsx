import {
  Activity,
  BookOpenText,
  Check,
  ChevronDown,
  Clock3,
  Inbox,
  LayoutDashboard,
  LoaderCircle,
  LogOut,
  Menu,
  ShieldCheck,
  ShieldX,
  Users,
  X,
} from 'lucide-react';
import {
  getIdTokenResult,
  onIdTokenChanged,
  signOut,
  type User,
} from 'firebase/auth';
import { useCallback, useEffect, useRef, useState } from 'react';
import { auth, sessionReady } from './firebase';
import {
  ActivityView,
  ContentView,
  InboxView,
  OverviewView,
  UsersView,
} from './pages';
import type { Section } from './types';
import { SignIn } from './SignIn';

const navigation: Array<{
  id: Section;
  label: string;
  icon: typeof LayoutDashboard;
}> = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard },
  { id: 'users', label: 'User directory', icon: Users },
  { id: 'inbox', label: 'Support inbox', icon: Inbox },
  { id: 'content', label: 'Home content', icon: BookOpenText },
  { id: 'activity', label: 'Activity log', icon: Clock3 },
];

export function App() {
  const [user, setUser] = useState<User | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const [accessError, setAccessError] = useState('');
  const [section, setSection] = useState<Section>('overview');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [toast, setToast] = useState('');
  const authGeneration = useRef(0);

  useEffect(() => {
    let active = true;
    let unsubscribe: (() => void) | undefined;

    sessionReady
      .then(() => {
        if (!active) return;
        unsubscribe = onIdTokenChanged(auth, async (nextUser) => {
          const generation = ++authGeneration.current;
          setUser(nextUser);
          setIsAdmin(false);
          setAccessError('');
          if (!nextUser) {
            setLoading(false);
            return;
          }

          setLoading(true);
          try {
            const token = await getIdTokenResult(nextUser);
            if (!active || generation !== authGeneration.current) return;
            setIsAdmin(token.claims.admin === true);
          } catch (error) {
            console.error('Unable to verify administrator access:', error);
            if (active && generation === authGeneration.current) {
              setAccessError(
                'Your access could not be verified. Check your connection and try again.',
              );
            }
          } finally {
            if (active && generation === authGeneration.current) {
              setLoading(false);
            }
          }
        });
      })
      .catch((error: unknown) => {
        console.error('Unable to initialize the secure admin session:', error);
        if (active) {
          setAccessError(
            'A secure session could not be started. Reload the page to try again.',
          );
          setLoading(false);
        }
      });

    return () => {
      active = false;
      unsubscribe?.();
    };
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3500);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const refreshAccess = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    setAccessError('');
    try {
      const token = await getIdTokenResult(user, true);
      setIsAdmin(token.claims.admin === true);
    } catch (error) {
      console.error('Unable to refresh administrator access:', error);
      setAccessError('Access could not be refreshed. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [user]);

  const handleSignOut = () => {
    void signOut(auth).catch((error: unknown) => {
      console.error('Unable to sign out:', error);
      setToast('Sign-out failed. Close this browser tab to end the session.');
    });
  };

  if (loading) {
    return (
      <div className="full-screen-state">
        <LoaderCircle className="spin" size={28} />
        <span>Securing your session…</span>
      </div>
    );
  }

  if (!user) {
    return <SignIn accessError={accessError} />;
  }

  if (!isAdmin) {
    return (
      <div className="access-page">
        <div className="access-card">
          <div className="access-icon"><ShieldX size={25} /></div>
          <p className="eyebrow">SICKLECARE ADMIN</p>
          <h1>Administrator access required</h1>
          <p>
            This account is signed in, but it does not have the trusted
            administrator permission required for this console.
          </p>
          {accessError && <p className="inline-error">{accessError}</p>}
          <button className="button button-secondary button-wide" onClick={refreshAccess}>
            Refresh access
            <Activity size={16} />
          </button>
          <button className="text-button" onClick={handleSignOut}>
            Sign in with another account
          </button>
        </div>
      </div>
    );
  }

  const currentPage = navigation.find((item) => item.id === section)!;
  const initials = (user.displayName || user.email || 'Admin')
    .split(/[\s@._-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('');

  const showToast = (message: string) => setToast(message);

  return (
    <div className="app-shell">
      {mobileMenuOpen && (
        <button
          aria-label="Close navigation"
          className="mobile-backdrop"
          onClick={() => setMobileMenuOpen(false)}
        />
      )}
      <aside className={`sidebar ${mobileMenuOpen ? 'sidebar-open' : ''}`}>
        <div className="sidebar-brand-row">
          <div className="brand">
            <img className="brand-mark" src="/app-icon.jpeg" alt="" />
            <span>
              <strong>SickleCare</strong>
              <small>ADMIN CONSOLE</small>
            </span>
          </div>
          <button
            aria-label="Close navigation"
            className="icon-button mobile-close"
            onClick={() => setMobileMenuOpen(false)}
          >
            <X size={19} />
          </button>
        </div>

        <div className="nav-label">WORKSPACE</div>
        <nav className="side-nav" aria-label="Admin sections">
          {navigation.map(({ id, label, icon: Icon }) => (
            <button
              className={`nav-item ${section === id ? 'nav-item-active' : ''}`}
              key={id}
              onClick={() => {
                setSection(id);
                setMobileMenuOpen(false);
              }}
            >
              <Icon size={18} />
              <span>{label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <div className="security-note">
            <div className="security-note-icon"><ShieldCheck size={17} /></div>
            <div>
              <strong>Protected workspace</strong>
              <span>Role verified by Firebase</span>
            </div>
          </div>
          <button className="profile-menu" onClick={handleSignOut}>
            <span className="avatar">{initials || 'A'}</span>
            <span className="profile-copy">
              <strong>{user.displayName || 'Administrator'}</strong>
              <small>{user.email}</small>
            </span>
            <LogOut size={17} />
          </button>
        </div>
      </aside>

      <main className="main-shell">
        <header className="topbar">
          <button
            aria-label="Open navigation"
            className="icon-button mobile-menu-button"
            onClick={() => setMobileMenuOpen(true)}
          >
            <Menu size={21} />
          </button>
          <div className="breadcrumb">
            <span>Workspace</span>
            <span className="breadcrumb-divider">/</span>
            <strong>{currentPage.label}</strong>
          </div>
          <div className="topbar-actions">
            <span className="secure-badge"><span /> Secure session</span>
            <button
              className="topbar-avatar"
              aria-label="Sign out"
              title="Sign out"
              onClick={handleSignOut}
            >
              {initials || 'A'}
              <ChevronDown size={13} />
            </button>
          </div>
        </header>

        <div className="page-content">
          {section === 'overview' && <OverviewView onNavigate={setSection} />}
          {section === 'users' && <UsersView />}
          {section === 'inbox' && <InboxView onNotify={showToast} />}
          {section === 'content' && <ContentView onNotify={showToast} />}
          {section === 'activity' && <ActivityView />}
        </div>
        <footer className="app-footer">
          <span>SickleCare administration</span>
          <span><ShieldCheck size={14} /> Access controlled by Firebase</span>
        </footer>
      </main>

      {toast && (
        <div className="toast" role="status">
          <span className="toast-check"><Check size={15} /></span>
          {toast}
        </div>
      )}
    </div>
  );
}
