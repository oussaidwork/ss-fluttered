import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/gas_type.dart';
import '../../domain/repositories/gas_type_repository.dart';

class GasTypeRepositoryImpl implements GasTypeRepository {
  final DatabaseDataSource _ds;

  GasTypeRepositoryImpl(this._ds);

  @override
  Stream<List<GasType>> watchGasTypes() {
    return _ds.streamQuery(
      FirestorePaths.gasTypes,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    ).map((snap) => snap.docs.map((d) => GasType.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<GasType?> getGasType(String id) async {
    final doc = await _ds.getDoc(FirestorePaths.gasTypes, id);
    if (doc == null) return null;
    return GasType.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> createGasType(GasType gasType) async {
    await _ds.setDoc(FirestorePaths.gasTypes, gasType.id, gasType.toMap());
  }

  @override
  Future<void> updateGasType(GasType gasType) async {
    await _ds.updateDoc(FirestorePaths.gasTypes, gasType.id, gasType.toMap());
  }

  @override
  Future<void> archiveGasType(String id) async {
    await _ds.updateDoc(FirestorePaths.gasTypes, id, {'isDeleted': true});
  }

  @override
  Future<void> restoreGasType(String id) async {
    await _ds.updateDoc(FirestorePaths.gasTypes, id, {'isDeleted': false});
  }
}
