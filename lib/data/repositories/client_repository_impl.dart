import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl._();
  static final _instance = ClientRepositoryImpl._();
  factory ClientRepositoryImpl() => _instance;

  @override
  Stream<List<Client>> watchClients() {
    return firestore
        .collection(FirestorePaths.clients)
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Client.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<double> getClientBalance(String clientId) async {
    final debtsSnap = await firestore
        .collection(FirestorePaths.debts)
        .where('clientId', isEqualTo: clientId)
        .where('isDeleted', isEqualTo: false)
        .get();

    double totalDebts = 0;
    for (final doc in debtsSnap.docs) {
      totalDebts += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }

    final paymentsSnap = await firestore
        .collection(FirestorePaths.payments)
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'COMPLETED')
        .where('isDeleted', isEqualTo: false)
        .get();

    double totalPayments = 0;
    for (final doc in paymentsSnap.docs) {
      totalPayments += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }

    return totalDebts - totalPayments;
  }

  @override
  Future<void> createClient(Client client) async {
    await firestore
        .collection(FirestorePaths.clients)
        .doc(client.id)
        .set(client.toMap());
  }

  @override
  Future<void> updateClient(Client client) async {
    await firestore
        .collection(FirestorePaths.clients)
        .doc(client.id)
        .update(client.toMap());
  }

  @override
  Future<void> archiveClient(String clientId) async {
    await firestore
        .collection(FirestorePaths.clients)
        .doc(clientId)
        .update({'isDeleted': true});
  }

  @override
  Future<void> restoreClient(String clientId) async {
    await firestore
        .collection(FirestorePaths.clients)
        .doc(clientId)
        .update({'isDeleted': false});
  }
}

final clientRepository = ClientRepositoryImpl();
