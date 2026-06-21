import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final DatabaseDataSource _ds;

  ClientRepositoryImpl(this._ds);

  @override
  Stream<List<Client>> watchClients() {
    return _ds.streamQueryMulti(
      FirestorePaths.clients,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
      orderByField: 'name',
    ).map(
      (snap) => snap.docs
          .map((d) => Client.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }

  @override
  Future<double> getClientBalance(String clientId) async {
    final debtsSnap = await _ds.queryMulti(
      FirestorePaths.debts,
      filters: [
        QueryFilter(field: 'clientId', value: clientId),
        QueryFilter(field: 'isDeleted', value: false),
      ],
    );

    double totalDebts = 0;
    for (final doc in debtsSnap.docs) {
      totalDebts += ((doc.data() as Map<String, dynamic>?)?['amount'] as num?)?.toDouble() ?? 0;
    }

    final paymentsSnap = await _ds.queryMulti(
      FirestorePaths.payments,
      filters: [
        QueryFilter(field: 'clientId', value: clientId),
        QueryFilter(field: 'status', value: 'COMPLETED'),
        QueryFilter(field: 'isDeleted', value: false),
      ],
    );

    double totalPayments = 0;
    for (final doc in paymentsSnap.docs) {
      totalPayments += ((doc.data() as Map<String, dynamic>?)?['amount'] as num?)?.toDouble() ?? 0;
    }

    return totalDebts - totalPayments;
  }

  @override
  Future<void> createClient(Client client) async {
    await _ds.setDoc(FirestorePaths.clients, client.id, client.toMap());
  }

  @override
  Future<void> updateClient(Client client) async {
    await _ds.updateDoc(FirestorePaths.clients, client.id, client.toMap());
  }

  @override
  Future<void> archiveClient(String clientId) async {
    await _ds.updateDoc(FirestorePaths.clients, clientId, {'isDeleted': true});
  }

  @override
  Future<void> restoreClient(String clientId) async {
    await _ds.updateDoc(FirestorePaths.clients, clientId, {'isDeleted': false});
  }
}
