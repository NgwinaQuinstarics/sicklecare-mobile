import { ArrowRight, Eye, EyeOff, ShieldCheck } from 'lucide-react';
import {
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
} from 'firebase/auth';
import { useState, type FormEvent } from 'react';
import { auth } from './firebase';

interface SignInProps {
  accessError: string;
}

function authErrorMessage(code: string): string {
  switch (code) {
    case 'auth/invalid-credential':
    case 'auth/user-not-found':
    case 'auth/wrong-password':
      return 'That email and password combination could not be verified.';
    case 'auth/too-many-requests':
      return 'Too many attempts. Wait a little while before trying again.';
    case 'auth/network-request-failed':
      return 'Could not reach the sign-in service. Check your connection.';
    case 'auth/invalid-email':
      return 'Enter a valid email address.';
    case 'auth/operation-not-allowed':
      return 'Email/password sign-in is disabled. Ask your Firebase project operator to enable it.';
    case 'auth/user-disabled':
      return 'This account is disabled. Ask your Firebase project operator for help.';
    default:
      return 'Sign-in could not be completed. Please try again.';
  }
}

export function SignIn({ accessError }: SignInProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [visible, setVisible] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(accessError);
  const [notice, setNotice] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');
    setNotice('');
    setBusy(true);
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
    } catch (signInError) {
      const code = (signInError as { code?: string }).code ?? '';
      setError(authErrorMessage(code));
    } finally {
      setBusy(false);
    }
  }

  async function resetPassword() {
    if (!email.trim()) {
      setError('Enter your administrator email first, then request a reset.');
      return;
    }

    setError('');
    setNotice('');
    setBusy(true);
    try {
      await sendPasswordResetEmail(auth, email.trim());
      setNotice('If this account is eligible, a password reset email has been sent.');
    } catch (resetError) {
      const code = (resetError as { code?: string }).code ?? '';
      setError(authErrorMessage(code));
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="signin-page">
      <div className="signin-visual">
        <div className="signin-visual-inner">
          <a className="brand brand-light" href="/">
            <img className="brand-mark" src="/app-icon.jpeg" alt="" />
            <span>
              <strong>SickleCare</strong>
              <small>ADMIN CONSOLE</small>
            </span>
          </a>
          <div className="signin-message">
            <span className="visual-overline">CARE, WITH CLARITY</span>
            <h1>Better care starts with a clearer picture.</h1>
            <p>
              A secure workspace to support the people and teams behind
              SickleCare.
            </p>
          </div>
          <div className="visual-caption">
            <ShieldCheck size={17} />
            <span>Private by design. Access verified at every sign-in.</span>
          </div>
          <div className="visual-orbit orbit-one" />
          <div className="visual-orbit orbit-two" />
          <div className="visual-spark spark-one" />
          <div className="visual-spark spark-two" />
        </div>
      </div>
      <div className="signin-panel">
        <div className="signin-card">
          <div className="signin-mobile-brand">
            <img className="brand-mark" src="/app-icon.jpeg" alt="" />
            <strong>SickleCare</strong>
          </div>
          <span className="eyebrow">WELCOME BACK</span>
          <h2>Sign in to your workspace</h2>
          <p className="signin-intro">
            Use an account created in Firebase Authentication. An authorized
            Firebase operator must grant it admin access; there is no default
            or shared administrator password.
          </p>

          <form onSubmit={submit} className="signin-form">
            <label htmlFor="admin-email">Work email</label>
            <input
              autoComplete="username"
              autoFocus
              id="admin-email"
              onChange={(event) => setEmail(event.target.value)}
              placeholder="name@organization.com"
              required
              type="email"
              value={email}
            />
            <div className="password-label">
              <label htmlFor="admin-password">Password</label>
              <button
                className="text-button small-text-button"
                disabled={busy}
                onClick={resetPassword}
                type="button"
              >
                Forgot password?
              </button>
            </div>
            <div className="password-input">
              <input
                autoComplete="current-password"
                id="admin-password"
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Enter your password"
                required
                type={visible ? 'text' : 'password'}
                value={password}
              />
              <button
                aria-label={visible ? 'Hide password' : 'Show password'}
                className="password-toggle"
                onClick={() => setVisible((value) => !value)}
                type="button"
              >
                {visible ? <EyeOff size={17} /> : <Eye size={17} />}
              </button>
            </div>
            {error && <div className="form-error" role="alert">{error}</div>}
            {notice && <div className="form-notice" role="status">{notice}</div>}
            <button className="button button-primary signin-submit" disabled={busy}>
              {busy ? 'Please wait…' : 'Sign in securely'}
              {!busy && <ArrowRight size={17} />}
            </button>
          </form>

          <div className="signin-assurance">
            <ShieldCheck size={17} />
            <span>Protected with Firebase Authentication</span>
          </div>
        </div>
        <div className="signin-footer">© SickleCare · Authorized access only</div>
      </div>
    </main>
  );
}
