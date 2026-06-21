import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/pump.dart';
import '../../domain/repositories/pump_repository.dart';

class PumpRepositoryImpl implements PumpRepository {
  final DatabaseDataSource _ds;

  PumpRepositoryImpl(this._ds);

  @override
  Stream<List<Pump>> watchPumps() {
    return _ds.streamQueryMulti(
      FirestorePaths.pumps,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    ).map((snap) => snap.docs.map((d) => Pump.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<Pump?> getPump(String id) async {
    final doc = await _ds.getDoc(FirestorePaths.pumps, id);
    if (!doc.exists) return null;
    return Pump.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> createPump(Pump pump) async {
    await _ds.setDoc(FirestorePaths.pumps, pump.id, pump.toMap());
  }

  @override
  Future<void> updatePump(Pump pump) async {
    await _ds.updateDoc(FirestorePaths.pumps, pump.id, pump.toMap());
  }

  @override
  Future<void> archivePump(String id) async {
    await _ds.updateDoc(FirestorePaths.pumps, id, {'isDeleted': true});
  }

  @override
  Future<void> restorePump(String id) async {
    await _ds.updateDoc(FirestorePaths.pumps, id, {'isDeleted': false});
  }
}
