import '../entities/client_fleet.dart';

abstract class ClientFleetRepository {
  Stream<List<ClientFleet>> watchClientFleet(String clientId);
  Stream<List<ClientFleet>> watchAllClientFleet();
  Future<void> createClientFleet(ClientFleet fleet);
  Future<void> updateClientFleet(ClientFleet fleet);
  Future<void> archiveClientFleet(String id);
}
