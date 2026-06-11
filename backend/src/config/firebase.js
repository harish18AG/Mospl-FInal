const admin = require('firebase-admin');

let app = null;
let db = null;
let auth = null;
let configured = false;

function loadCredentials() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    const json = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8');
    return JSON.parse(json);
  }
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  }
  return null;
}

try {
  const credentials = loadCredentials();
  if (credentials) {
    app = admin.initializeApp({
      credential: admin.credential.cert(credentials),
      projectId: credentials.project_id || process.env.FIREBASE_PROJECT_ID,
    });
    configured = true;
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    app = admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
    configured = true;
  }
  if (configured) {
    db = admin.firestore(app);
    auth = admin.auth(app);
  }
} catch (error) {
  console.warn('Firebase Admin not configured. Using in-memory development store.', error.message);
}

module.exports = {
  admin,
  db,
  auth,
  isFirebaseConfigured: configured,
};
