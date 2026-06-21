import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/pit_refill.dart';
import '../../domain/entities/refill_payment.dart';
import '../../domain/repositories/refill_repository.dart';

class RefillRepositoryImpl implements RefillRepository {
  final DatabaseDataSource _ds;

  RefillRepositoryImpl(this._ds);

  @override
  Future<void> recordRefill({
    required PitRefill refill,
    RefillPayment? payment,
  }) async {
    final batch = _ds.batch();

    final pitRef = _ds.docRef(FirestorePaths.pits, refill.pitId);
    final pitSnap = await pitRef.get();
    if (!pitSnap.exists) {
      throw Exception('Pit not found');
    }
    final pitData = pitSnap.data() as Map<String, dynamic>?;
    final currentVolume =
        (pitData?['currentVolume'] as num?)?.toDouble() ?? 0;
    batch.update(pitRef, {
      'currentVolume': currentVolume + refill.volume,
    });

    final refillRef = _ds.docRef(FirestorePaths.pitRefills, refill.id);
    batch.set(refillRef, refill.toMap());

    if (payment != null) {
      final payRef = _ds.docRef(FirestorePaths.refillPayments, payment.id);
      batch.set(payRef, payment.toMap());
    }

    await batch.commit();
  }

  @override
  Stream<List<PitRefill>> watchRefills() {
    return _ds.streamQuery(
      FirestorePaths.pitRefills,
      orderByField: 'timestamp',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => PitRefill.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
    );
  }
}
