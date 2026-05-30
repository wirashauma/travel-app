// Usage: node promote_superadmin.js <email>
// Promotes the user (Firestore users/{uid}) to role 'super_admin'
const admin = require('firebase-admin');
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';
let serviceAccount;
try {
  serviceAccount = require(serviceAccountPath);
} catch (err) {
  console.error('Failed to load service account JSON. Set GOOGLE_APPLICATION_CREDENTIALS or place serviceAccountKey.json in tools/.');
  console.error(err.message);
  process.exit(1);
}
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const auth = admin.auth();
const db = admin.firestore();

async function promote(email) {
  try {
    console.log('Looking up user by email:', email);
    const userRecord = await auth.getUserByEmail(email);
    console.log('Found user uid=', userRecord.uid);
    const uid = userRecord.uid;
    const docRef = db.collection('users').doc(uid);
    const doc = await docRef.get();
    if (!doc.exists) {
      console.error('User document not found in Firestore at users/' + uid);
      process.exit(1);
    }
    await docRef.update({ role: 'super_admin' });
    console.log('Updated users/' + uid + ' role -> super_admin');
  } catch (e) {
    console.error('Error promoting user:', e);
    process.exit(1);
  }
}

(async () => {
  const args = process.argv.slice(2);
  if (args.length < 1) {
    console.error('Usage: node promote_superadmin.js <email>');
    process.exit(1);
  }
  await promote(args[0]);
})();
