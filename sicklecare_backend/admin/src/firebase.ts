import { initializeApp } from 'firebase/app';
import {
  browserSessionPersistence,
  connectAuthEmulator,
  getAuth,
  setPersistence,
} from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
import { connectFunctionsEmulator, getFunctions } from 'firebase/functions';

const useEmulators =
  import.meta.env.DEV && import.meta.env.VITE_USE_FIREBASE_EMULATORS === 'true';

const firebaseApp = initializeApp({
  apiKey: 'AIzaSyA3ZziIdNkiBv97yeWMbKYZYElxo5dNx1c',
  appId: '1:822337344078:web:6b4f8c1b3800b797fe291f',
  authDomain: 'sicklecare-15d7a.firebaseapp.com',
  messagingSenderId: '822337344078',
  projectId: useEmulators ? 'demo-sicklecare' : 'sicklecare-15d7a',
  storageBucket: 'sicklecare-15d7a.firebasestorage.app',
});

export const auth = getAuth(firebaseApp);
export const db = getFirestore(firebaseApp);
export const functions = getFunctions(firebaseApp);

if (useEmulators) {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
  connectFunctionsEmulator(functions, '127.0.0.1', 5001);
}

export const sessionReady = setPersistence(auth, browserSessionPersistence);
