// Usage: node seed_admin.js <email> <password> "Full Name" <phone>
// Requires: npm install firebase-admin
// Set GOOGLE_APPLICATION_CREDENTIALS to path of serviceAccountKey.json or place serviceAccountKey.json in this folder.

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

async function createAdmin(email, password, name, phone) {
  try {
    console.log('Creating Firebase Auth user...', email);
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name,
      emailVerified: false,
    });

    const uid = userRecord.uid;
    console.log('Created auth user uid=', uid);

    const docRef = db.collection('users').doc(uid);
    await docRef.set({
      uid,
      email,
      namaLengkap: name,
      nomorHp: phone || '',
      role: 'admin',
      isSuspended: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Firestore user doc written with role=admin');
    console.log('Done.');
  } catch (e) {
    console.error('Error creating admin:', e);
    process.exit(1);
  }
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 3) {
    console.error('Usage: node seed_admin.js <email> <password> "Full Name" <phone>');
    process.exit(1);
  }
  const [email, password, name, phone] = [args[0], args[1], args[2], args[3] || ''];
  await createAdmin(email, password, name, phone);
}

main();
