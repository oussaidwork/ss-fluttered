import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final DatabaseDataSource _ds;

  PaymentRepositoryImpl(this._ds);

  @override
  Stream<List<Payment>> watchPendingPayments() {
    return _ds.streamQueryMulti(
      FirestorePaths.payments,
      filters: [
        QueryFilter(field: 'status', value: 'PENDING'),
        QueryFilter(field: 'isDeleted', value: false),
      ],
      orderByField: 'createdAt',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => Payment.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }

  @override
  Future<void> clearCheck(String paymentId) async {
    await _ds.runTransaction((txn) async {
      final ref = _ds.docRef(FirestorePaths.payments, paymentId);
      final snap = await txn.get(ref);

      if (!snap.exists) {
        throw Exception('Payment not found');
      }

      final data = snap.data() as Map<String, dynamic>;
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
    await _ds.runTransaction((txn) async {
      final ref = _ds.docRef(FirestorePaths.payments, paymentId);
      final snap = await txn.get(ref);

      if (!snap.exists) {
        throw Exception('Payment not found');
      }

      final data = snap.data() as Map<String, dynamic>;
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
