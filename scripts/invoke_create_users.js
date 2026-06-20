/**
 * Seed script: creates 5 Firebase Auth users + Firestore profiles
 * via the createBootstrapUsers Cloud Function.
 *
 * Usage:
 *   node scripts/invoke_create_users.js
 *
 * Prerequisites:
 *   1. Cloud Functions deployed: cd functions && firebase deploy --only functions
 *   2. Node.js 18+ (uses built-in fetch)
 */

const FUNCTION_URL =
  'https://us-central1-gen-lang-client-0557342357.cloudfunctions.net/createBootstrapUsers';

const BOOTSTRAP_SECRET = 'ss-ragrama-bootstrap-2026';

const USERS = [
  { displayName: 'ssragraga',    email: 'ssragraga@gmail.com',      password: '123654789d', role: 'Admin'  },
  { displayName: 'Mohamed',      email: 'ssragraga.user1@gmail.com', password: '123654user1', role: 'Worker' },
  { displayName: 'Abdessadek',   email: 'ssragraga.user2@gmail.com', password: '123654user2', role: 'Worker' },
  { displayName: 'ABDilah',      email: 'ssragraga.user3@gmail.com', password: '123654user3', role: 'Worker' },
  { displayName: 'SSRAG-audit',  email: 'ssragragaadmin@gmail.com',  password: '123654789a', role: 'Audit'  },
];

async function main() {
  console.log('Creating users via Cloud Function...');
  console.log(`  URL: ${FUNCTION_URL}`);
  console.log(`  Users: ${USERS.length}`);
  console.log('');

  const response = await fetch(FUNCTION_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ secret: BOOTSTRAP_SECRET, users: USERS }),
  });

  const data = await response.json();

  if (response.status !== 200) {
    console.error('Function returned error:', JSON.stringify(data, null, 2));
    process.exit(1);
  }

  console.log(`Created: ${data.created}  Failed: ${data.failed}`);
  console.log('');

  for (const r of data.results) {
    const icon = r.status === 'created' ? 'OK' : 'FAIL';
    console.log(`  [${icon}] ${r.email}${r.uid ? ` → ${r.uid}` : ''}${r.error ? ` — ${r.error}` : ''}`);
  }

  console.log('');
  console.log('Done.');
}

main().catch((err) => {
  console.error('Script failed:', err);
  process.exit(1);
});
