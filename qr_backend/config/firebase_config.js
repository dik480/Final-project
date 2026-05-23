const admin = require('firebase-admin');

// IMPORTANT: Add your service account JSON file securely to your server
// and reference its path here or use env vars.
// For example:
// const serviceAccount = require('../serviceAccountKey.json');

// By default if running in Google Cloud/Firebase Functions this works:
admin.initializeApp({
  // credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

module.exports = { db, admin };
