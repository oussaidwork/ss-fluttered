import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl._();
  static final _instance = PaymentRepositoryImpl._();
  factory PaymentRepositoryImpl() => _instance;

  @override
  Stream<List<Payment>> watchPendingPayments() {
    return firestore
        .collection(FirestorePaths.payments)
        .where('status', isEqualTo: 'PENDING')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Payment.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<void> clearCheck(String paymentId) async {
    await firestore.runTransaction((txn) async {
      final ref =
          firestore.collection(FirestorePaths.payments).doc(paymentId);
      final snap = await txn.get(ref);

      if (!snap.exists) {
        throw Exception('Payment not found');
      }

      final data = snap.data()!;
      final currentStatus = data['status'] as String? ?? '';

      if (currentStatus != 'PENDING') {
        throw Exception('Can only clear PENDING payments');
      }

      txn.update(ref, {
        'status': 'COMPLETED',
        'clearedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  @override
  Future<void> rejectCheck(String paymentId) async {
    await firestore.runTransaction((txn) async {
      final ref =
          firestore.collection(FirestorePaths.payments).doc(paymentId);
      final snap = await txn.get(ref);

      if (!snap.exists) {
        throw Exception('Payment not found');
      }

      final data = snap.data()!;
      final currentStatus = data['status'] as String? ?? '';

      if (currentStatus != 'PENDING') {
        throw Exception('Can only reject PENDING payments');
      }

      txn.update(ref, {
        'status': 'REJECTED',
        'clearedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }
}

final paymentRepository = PaymentRepositoryImpl();
