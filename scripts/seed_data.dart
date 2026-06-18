import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ss_fluttered/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // 1. Gas types
  final gasTypes = [
    {'name': 'Unleaded 92', 'priceIn': 9.50, 'priceOut': 10.72, 'color': '#2196F3', 'isDeleted': false},
    {'name': 'Diesel', 'priceIn': 8.80, 'priceOut': 9.95, 'color': '#FF9800', 'isDeleted': false},
    {'name': 'Premium 95', 'priceIn': 10.20, 'priceOut': 11.50, 'color': '#4CAF50', 'isDeleted': false},
  ];
  for (var gt in gasTypes) {
    await firestore.collection('gas_types').add(gt);
  }

  // 2. Payment types
  final paymentTypes = [
    {'name': 'Cash', 'code': 'CASH', 'icon': 'money'},
    {'name': 'Credit Card', 'code': 'CARD', 'icon': 'credit_card'},
    {'name': 'Mobile Pay', 'code': 'MOBILE', 'icon': 'phone_android'},
    {'name': 'Check', 'code': 'CHECK', 'icon': 'receipt'},
  ];
  for (var pt in paymentTypes) {
    await firestore.collection('payment_types').add(pt);
  }

  // 3. Sample pits
  final pits = [
    {'name': 'Pit 1 - Unleaded', 'capacity': 30000, 'currentVolume': 15000, 'isDeleted': false},
    {'name': 'Pit 2 - Diesel', 'capacity': 25000, 'currentVolume': 12000, 'isDeleted': false},
  ];
  for (var pit in pits) {
    await firestore.collection('pits').add(pit);
  }

  // 4. Sample admin user profile
  const adminUid = '<ADMIN_UID>'; // TODO: replace with real UID
  final adminProfile = {
    'fullName': 'Demo Admin',
    'email': 'admin@example.com',
    'role': 'Admin',
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
  };
  if (adminUid != '<ADMIN_UID>') {
    await firestore.collection('users').doc(adminUid).set(adminProfile);
    print('Admin profile created for UID $adminUid');
  } else {
    print('Skipped admin profile creation - replace <ADMIN_UID> with a real UID');
  }

  print('Seed data completed.');
}
