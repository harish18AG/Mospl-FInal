const bcrypt = require('bcryptjs');

const { auth, db, isFirebaseConfigured } = require('../config/firebase');
const { signApiToken } = require('../middleware/authMiddleware');
const { httpError } = require('../utils/httpError');
const store = require('./store');

function sanitizeUser(user) {
  if (!user) return null;
  const { passwordHash, ...safe } = user;
  return safe;
}

async function resolveRole({ uid, email, claims }) {
  if (claims?.role === 'admin') return 'admin';
  if (!db) return 'customer';

  const uidDoc = await db.collection('admins').doc(uid).get();
  if (uidDoc.exists && uidDoc.data().active !== false) return 'admin';

  const emailSnapshot = await db.collection('admins').where('email', '==', email).where('active', '==', true).limit(1).get();
  if (!emailSnapshot.empty) return 'admin';

  return 'customer';
}

async function register({ name, email, password }) {
  const cleanEmail = email.trim().toLowerCase();
  let user;
  if (isFirebaseConfigured && auth) {
    let firebaseUser;
    try {
      firebaseUser = await auth.createUser({
        email: cleanEmail,
        password,
        displayName: name,
        emailVerified: false,
      });
    } catch (error) {
      if (error.code !== 'auth/email-already-exists') throw error;
      firebaseUser = await auth.getUserByEmail(cleanEmail);
      if (name && firebaseUser.displayName !== name) {
        firebaseUser = await auth.updateUser(firebaseUser.uid, { displayName: name });
      }
    }
    const role = await resolveRole({ uid: firebaseUser.uid, email: cleanEmail, claims: firebaseUser.customClaims });
    user = { uid: firebaseUser.uid, email: cleanEmail, name, role, createdAt: new Date().toISOString() };
    if (db) await db.collection('users').doc(firebaseUser.uid).set(user, { merge: true });
  } else {
    if (store.users.has(cleanEmail)) throw new Error('Email already exists.');
    user = {
      uid: `dev-${Date.now()}`,
      email: cleanEmail,
      name,
      role: 'customer',
      passwordHash: await bcrypt.hash(password, 10),
      createdAt: new Date().toISOString(),
    };
    store.users.set(cleanEmail, user);
  }
  const token = signApiToken(user);
  return { user: sanitizeUser(user), token };
}

async function login({ email, password }) {
  const cleanEmail = email.trim().toLowerCase();
  if (!isFirebaseConfigured) {
    const user = store.users.get(cleanEmail);
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      throw new Error('Invalid email or password.');
    }
    return { user: sanitizeUser(user), token: signApiToken(user) };
  }

  if (!process.env.FIREBASE_WEB_API_KEY) throw new Error('FIREBASE_WEB_API_KEY is required for Firebase Email/Password login.');
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_WEB_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: cleanEmail, password, returnSecureToken: true }),
    },
  );
  if (!response.ok) throw new Error('Invalid email or password.');
  const userRecord = await auth.getUserByEmail(cleanEmail);
  const role = await resolveRole({ uid: userRecord.uid, email: cleanEmail, claims: userRecord.customClaims });
  const user = {
    uid: userRecord.uid,
    email: cleanEmail,
    name: userRecord.displayName || cleanEmail.split('@')[0],
    role,
    updatedAt: new Date().toISOString(),
  };
  if (db) await db.collection('users').doc(userRecord.uid).set(user, { merge: true });
  return { user, token: signApiToken(user) };
}

async function firebaseSession({ idToken }) {
  if (!isFirebaseConfigured || !auth) {
    throw httpError(503, 'Firebase Admin is not configured.');
  }
  const decoded = await auth.verifyIdToken(idToken);
  const userRecord = await auth.getUser(decoded.uid);
  const email = userRecord.email || decoded.email;
  const role = await resolveRole({ uid: userRecord.uid, email, claims: userRecord.customClaims });
  const user = {
    uid: userRecord.uid,
    email,
    name: userRecord.displayName || decoded.name || (email || 'customer').split('@')[0],
    role,
    updatedAt: new Date().toISOString(),
  };
  if (db) await db.collection('users').doc(user.uid).set(user, { merge: true });
  return { user, token: signApiToken(user) };
}

async function forgotPassword(email) {
  const cleanEmail = email.trim().toLowerCase();
  if (isFirebaseConfigured && auth) {
    const link = await auth.generatePasswordResetLink(cleanEmail);
    return { message: 'Firebase password reset link generated.', resetLink: link };
  }
  return { message: `Password reset link would be sent to ${cleanEmail} in development mode.` };
}

async function updateProfile(uid, payload) {
  const user = [...store.users.values()].find((item) => item.uid === uid);
  if (!isFirebaseConfigured) {
    if (!user) return null;
    Object.assign(user, { name: payload.name || user.name, email: payload.email || user.email, updatedAt: new Date().toISOString() });
    return sanitizeUser(user);
  }
  await auth.updateUser(uid, { displayName: payload.name, email: payload.email });
  const userRecord = await auth.getUser(uid);
  const email = payload.email || userRecord.email;
  const role = await resolveRole({ uid, email, claims: userRecord.customClaims });
  const updated = {
    uid,
    name: payload.name || userRecord.displayName || (email || 'customer').split('@')[0],
    email,
    role,
    updatedAt: new Date().toISOString(),
  };
  if (db) await db.collection('users').doc(uid).set(updated, { merge: true });
  return updated;
}

module.exports = { register, login, firebaseSession, forgotPassword, updateProfile, sanitizeUser };
