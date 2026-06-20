import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/pit_refill.dart';
import '../../domain/entities/refill_payment.dart';
import '../../domain/repositories/refill_repository.dart';

class RefillRepositoryImpl implements RefillRepository {
  RefillRepositoryImpl._();
  static final _instance = RefillRepositoryImpl._();
  factory RefillRepositoryImpl() => _instance;

  @override
  Future<void> recordRefill({
    required PitRefill refill,
    RefillPayment? payment,
  }) async {
    final batch = firestore.batch();

    final pitRef = firestore.collection(FirestorePaths.pits).doc(refill.pitId);
    final pitSnap = await pitRef.get();
    if (!pitSnap.exists) {
      throw Exception('Pit not found');
    }
    final currentVolume =
        (pitSnap.data()?['currentVolume'] as num?)?.toDouble() ?? 0;
    batch.update(pitRef, {
      'currentVolume': currentVolume + refill.volume,
    });

    final refillRef =
        firestore.collection(FirestorePaths.pitRefills).doc(refill.id);
    batch.set(refillRef, refill.toMap());

    if (payment != null) {
      final payRef = firestore
          .collection(FirestorePaths.refillPayments)
          .doc(payment.id);
      batch.set(payRef, payment.toMap());
    }

    await batch.commit();
  }

  @override
  Stream<List<PitRefill>> watchRefills() {
    return firestore
        .collection(FirestorePaths.pitRefills)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => PitRefill.fromMap(d.data())).toList(),
        );
  }
}

final refillRepository = RefillRepositoryImpl();
