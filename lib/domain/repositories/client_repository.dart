import '../entities/client.dart';

abstract class ClientRepository {
  Stream<List<Client>> watchClients();
  Future<double> getClientBalance(String clientId);
  Future<void> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> archiveClient(String clientId);
  Future<void> restoreClient(String clientId);
}
