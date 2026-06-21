import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

initializeApp({
  credential: applicationDefault(),
  projectId: 'sarian-supplier',
});

const db = getFirestore();

const uid  = 'YPLwxgAjepX66IS3tMbunXwlkPs1';
const email = 'joychandra198@gmail.com';

await db.collection('users').doc(uid).set({
  name:      'Joy Chandra',
  email,
  phone:     '',
  role:      'admin',
  isActive:  true,
  photoUrl:  null,
  createdAt: FieldValue.serverTimestamp(),
}, { merge: true });

console.log(`✅  Admin user doc created/updated for ${email} (uid: ${uid})`);
process.exit(0);
