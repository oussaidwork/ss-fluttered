import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/payment.dart';

final pendingPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return firestore.collection('payments')
    .where('status', isEqualTo: 'PENDING')
    .where('isDeleted', isEqualTo: false)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snap) => snap.docs.map((d) => Payment.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList());
});
