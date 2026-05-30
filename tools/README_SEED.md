Seed admin account

This tool helps you create an `admin` account in Firebase Auth and writes the corresponding Firestore `users/{uid}` document with `role: 'admin'`.

Prerequisites

- Node.js installed
- A Firebase service account JSON (create in Firebase Console > Project settings > Service accounts)
- `firebase-admin` package

Steps

1. Copy your service account JSON into `tools/serviceAccountKey.json` OR set environment variable `GOOGLE_APPLICATION_CREDENTIALS` to its absolute path.

2. Install dependency:

```bash
cd d:/Tugas\ Kuliah/travel-app
npm install firebase-admin
```

3. Run the script with parameters:

```bash
node tools/seed_admin.js admin@example.com TempPass123 "Nama Admin" 08123456789
```

Notes

- The script creates a Firebase Auth user (email/password) and a Firestore document under `users/{uid}` with `role: 'admin'`.
- Don't commit your service account JSON to source control.
- For production, consider using Cloud Functions or a protected admin panel instead of running this script locally.
