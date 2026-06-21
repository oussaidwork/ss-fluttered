import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/client_fleet.dart';
import '../../domain/repositories/client_fleet_repository.dart';

class ClientFleetRepositoryImpl implements ClientFleetRepository {
  final DatabaseDataSource _ds;

  ClientFleetRepositoryImpl(this._ds);

  @override
  Stream<List<ClientFleet>> watchClientFleet(String clientId) {
    return _ds.streamQueryMulti(
      FirestorePaths.clientFleet,
      filters: [
        QueryFilter(field: 'clientId', value: clientId),
        QueryFilter(field: 'isDeleted', value: false),
      ],
    ).map((snap) => snap.docs.map((d) => ClientFleet.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Stream<List<ClientFleet>> watchAllClientFleet() {
    return _ds.streamQueryMulti(
      FirestorePaths.clientFleet,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    ).map((snap) => snap.docs.map((d) => ClientFleet.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<void> createClientFleet(ClientFleet fleet) async {
    await _ds.setDoc(FirestorePaths.clientFleet, fleet.id, fleet.toMap());
  }

  @override
  Future<void> updateClientFleet(ClientFleet fleet) async {
    await _ds.updateDoc(FirestorePaths.clientFleet, fleet.id, fleet.toMap());
  }

  @override
  Future<void> archiveClientFleet(String id) async {
    await _ds.updateDoc(FirestorePaths.clientFleet, id, {'isDeleted': true});
  }
}
