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

    final pitDoc = await _ds.getDoc(FirestorePaths.pits, refill.pitId);
    if (pitDoc == null || !pitDoc.exists) {
      throw Exception('Pit not found');
    }
    final pitData = pitDoc.data() as Map<String, dynamic>?;
    final currentVolume =
        (pitData?['currentVolume'] as num?)?.toDouble() ?? 0;
    batch.update(FirestorePaths.pits, refill.pitId, {
      'currentVolume': currentVolume + refill.volume,
    });

    batch.set(FirestorePaths.pitRefills, refill.id, refill.toMap());

    if (payment != null) {
      batch.set(FirestorePaths.refillPayments, payment.id, payment.toMap());
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
