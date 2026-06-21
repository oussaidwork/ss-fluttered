import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/pit.dart';
import '../../domain/repositories/pit_repository.dart';

class PitRepositoryImpl implements PitRepository {
  final DatabaseDataSource _ds;

  PitRepositoryImpl(this._ds);

  @override
  Stream<List<Pit>> watchPits() {
    return _ds.streamQueryMulti(
      FirestorePaths.pits,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    ).map((snap) => snap.docs.map((d) => Pit.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<Pit?> getPit(String id) async {
    final doc = await _ds.getDoc(FirestorePaths.pits, id);
    if (!doc.exists) return null;
    return Pit.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> createPit(Pit pit) async {
    await _ds.setDoc(FirestorePaths.pits, pit.id, pit.toMap());
  }

  @override
  Future<void> updatePit(Pit pit) async {
    await _ds.updateDoc(FirestorePaths.pits, pit.id, pit.toMap());
  }

  @override
  Future<void> archivePit(String id) async {
    await _ds.updateDoc(FirestorePaths.pits, id, {'isDeleted': true});
  }

  @override
  Future<void> restorePit(String id) async {
    await _ds.updateDoc(FirestorePaths.pits, id, {'isDeleted': false});
  }
}
