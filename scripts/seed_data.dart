import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ss_fluttered/firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase (web config is used by default)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // 1️⃣ Fuel types (example)
  final fuelTypes = [
    {'name': 'Unleaded 92', 'pricePerLiter': 1.25},
    {'name': 'Diesel', 'pricePerLiter': 1.10},
    {'name': 'Premium 95', 'pricePerLiter': 1.40},
  ];
  for (var ft in fuelTypes) {
    await firestore.collection('fuelTypes').add(ft);
  }

  // 2️⃣ Payment types (example)
  final paymentTypes = [
    {'name': 'Cash', 'code': 'CASH'},
    {'name': 'Credit Card', 'code': 'CARD'},
    {'name': 'Mobile Pay', 'code': 'MOBILE'},
  ];
  for (var pt in paymentTypes) {
    await firestore.collection('paymentTypes').add(pt);
  }

  // 3️⃣ Demo admin user profile (no auth user created here; assume you created one manually)
  // Replace <ADMIN_UID> with the UID of a user you created via Firebase console.
  const adminUid = '<ADMIN_UID>'; // TODO: replace with real UID
  final adminProfile = {
    'role': 'Admin',
    'displayName': 'Demo Admin',
    'email': 'admin@example.com',
    'createdAt': FieldValue.serverTimestamp(),
  };
  if (adminUid != '<ADMIN_UID>') {
    await firestore.collection('users').doc(adminUid).set(adminProfile);
    print('Admin profile created for UID $adminUid');
  } else {
    print('⚠️ Skipped admin profile creation – replace <ADMIN_UID> with a real UID.');
  }

  print('✅ Seed data completed.');
}
